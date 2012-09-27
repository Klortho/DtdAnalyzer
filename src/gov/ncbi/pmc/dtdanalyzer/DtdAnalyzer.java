/*
 * DtdAnalyzer.java
 *
 * Created on November 10, 2005, 12:07 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import java.net.*;
import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import gov.ncbi.pmc.xml.PMCBootStrapper;
import org.apache.xml.resolver.*;
import org.apache.xml.resolver.tools.*;
import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * Creates XML representation of an XML DTD and then transforms it using
 * a provided stylesheet. This is a bare-bones application intended for
 * demonstration and debugging.
 * 
 * @author  Demian Hess
 */
public class DtdAnalyzer {
    
    // CONSTANTS
    
    // ID for SAX driver
    public static final String SAX_DRIVER_PROPERTY = "org.xml.sax.driver";                               
    // SAX driver implementation
    public static final String SAX_DRIVER_DEFAULT = "org.apache.xerces.parsers.SAXParser";               
    // ID for transformer
    public static final String TRANSFORMER_FACTORY_PROPERTY = "javax.xml.transform.TransformerFactory";  
    // Transformer implementation
    public static final String TRANSFORMER_FACTORY_DEFAULT = "com.icl.saxon.TransformerFactoryImpl";     
    // Path to reach OASIS dtd
    public static final String OASIS_DTD = "/org/apache/xml/resolver/etc/catalog.dtd";                   
    // Public id of Oasis DTD
    public static final String OASIS_PUBLIC_ID = "-//OASIS/DTD Entity Resolution XML Catalog V1.0//EN";  
    
    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * Once it has the XML, it transforms it using the specified XSL. The output
     * is placed in the specified location. Application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args){

        // create Options object
        Options options = new Options();
        options.addOption( "h", "help", false, "Get help." );
        options.addOption( 
            OptionBuilder
                .withLongOpt( "doc" )
                .withDescription("Specify an XML document used to find the DTD. This could be just a \"stub\" " +
                    "file, that contains nothing other than the doctype declaration and a root element. " +
                    "This file doesn't need to be valid according to the DTD.")
                .hasArg()
                .withArgName("xml-file")
                .create('d') 
        );
        options.addOption( 
            OptionBuilder
                .withLongOpt( "system" )
                .withDescription("Use the given system identifier to find the DTD. This could be a relative " +
                    "pathname, if the DTD exists in a file on your system, or an HTTP URL.")
                .hasArg()
                .withArgName("system-id")
                .create('s') 
        );
        options.addOption( 
            OptionBuilder
                .withLongOpt( "public" )
                .withDescription("Use the given public identifier to find the DTD. This would be used in " +
                    "conjunction with an OASIS catalog file.")
                .hasArg()
                .withArgName("public-id")
                .create('p') 
        );
        options.addOption( 
            OptionBuilder
                .withLongOpt( "catalog" )
                .withDescription("Specify a file to use as the OASIS catalog, to resolve public identifiers.")
                .hasArg()
                .withArgName("catalog-file")
                .create('c') 
        );
        options.addOption( 
            OptionBuilder
                .withLongOpt( "xslt" )
                .withDescription("An XSLT script to run to post-process the output. This is optional.")
                .hasArg()
                .withArgName("xslt")
                .create('x') 
        );

        options.addOption( 
            OptionBuilder
                .withLongOpt( "title" )
                .withDescription("Specify the title of this DTD. This will be output within a <title> " +
                    "element under the root <declarations> element of the output XML.")
                .hasArg()
                .withArgName("dtd-title")
                .create('t') 
        );

        // create the command line parser
        CommandLineParser clp = new PosixParser();
        try {
            // parse the command line arguments
            CommandLine line = clp.parse( options, args );
        
            if ( line.hasOption( "h" ) ) {
                printUsage(options);
                System.exit(0);
            }
            else {
                if (!line.hasOption("d") && !line.hasOption("s") && !line.hasOption("p")) {
                    throw new ParseException("At least one of -d, -s, or -p must be specified!");
                }
            }

            // Check that, if given, the argument to -d is a valid file
            if (line.hasOption("d")) {
                File xml = new File(line.getOptionValue("d"));
                if ( ! xml.exists() || ! xml.isFile() ) {
                    System.err.println("Error: " + xml.toString() + " is not a file" );
                    System.exit(1);
                }
            }
            
            // Otherwise, construct a stub file in a string
            String xmlFileStr = "<!DOCTYPE root ";
            if (!line.hasOption("d")) {
                if (line.hasOption("s")) {
                    xmlFileStr += "SYSTEM \"" + line.getOptionValue("s") + "\">";
                }
                else {
                    xmlFileStr += "PUBLIC \"" + line.getOptionValue("p") + "\" \"\">";
                }
                String publicId = line.getOptionValue("p");
            }
            xmlFileStr += "\n\n<root/>\n";
            //System.out.println("xmlFileStr is '" + xmlFileStr + "'\n\n");

            File catalog = null;
            if (line.hasOption("c")) {
                catalog = new File(line.getOptionValue("d"));
                if ( ! catalog.exists() || ! catalog.isFile() ) {
                    System.err.println("Error: Specified catalog " + catalog.toString() + " is not a file" );
                    System.exit(1);
                }
            }

            File xsl = null;
            if (line.hasOption("x")) {
                xsl = new File(line.getOptionValue("x"));
                if ( ! xsl.exists() || ! xsl.isFile() ) {
                    System.err.println("Error: Specified xsl " + xsl.toString() + " is not a file" );
                    System.exit(1);
                }
            }
            
            String dtdTitle = null;
            if (line.hasOption("t")) dtdTitle = line.getOptionValue("t");
            //System.err.println("title is " + dtdTitle);
    
            Result out = null;
            String[] rest = line.getArgs();
            if (rest.length == 0) {
                out = new StreamResult(System.out);
            }
            else if (rest.length == 1) {
                out = new StreamResult(new File(rest[0]));            
            }
            else {
                throw new ParseException("Too many arguments!");
            }
    
    
            DTDEventHandler dtdEvents = new DTDEventHandler();
            
            // Set System properties for parsing and transforming
            if ( System.getProperty(SAX_DRIVER_PROPERTY) == null )
                System.setProperty(SAX_DRIVER_PROPERTY, SAX_DRIVER_DEFAULT);     
            
            if ( System.getProperty(TRANSFORMER_FACTORY_PROPERTY) == null )
                System.setProperty(TRANSFORMER_FACTORY_PROPERTY, TRANSFORMER_FACTORY_DEFAULT);
    
            // Perform set-up and parsing here
            try {
                CatalogResolver resolver = null;
                
                // Set up catalog resolution, but only if we have a catalog!
                if ( catalog != null ){
                    PMCBootStrapper bootstrapper = new PMCBootStrapper();
                    CatalogManager catalogManager = new CatalogManager(); 
                    URL oasisCatalog = catalogManager.getClass().getResource(OASIS_DTD);
                    bootstrapper.addMapping(OASIS_PUBLIC_ID, oasisCatalog.toString());
                    catalogManager.setBootstrapResolver(bootstrapper);
                    catalogManager.setCatalogFiles(catalog.toString());
                    resolver = new CatalogResolver(catalogManager); 
                }//if
                
                // Set up the parser
                XMLReader parser = XMLReaderFactory.createXMLReader();
                parser.setContentHandler(dtdEvents);
                parser.setErrorHandler(dtdEvents);
                parser.setProperty( "http://xml.org/sax/properties/lexical-handler", dtdEvents); 
                parser.setProperty( "http://xml.org/sax/properties/declaration-handler", dtdEvents);
                parser.setFeature("http://xml.org/sax/features/validation", true);
                
                // Resolve entities if we have a catalog
                if ( resolver != null )
                    parser.setEntityResolver(resolver); 
                
                // Run the parse to capture all events and create an XML representation of the DTD.
                // XMLReader's parse method either takes a system id as a string, or an InputSource
                if (line.hasOption("d")) {
                    parser.parse(line.getOptionValue("d"));
                }
                else {
                    parser.parse(new InputSource(new StringReader(xmlFileStr)));
                }
            }

            catch (EndOfDTDException ede){
                // ignore: this is a normal exception raised to signal the end of processing
            }
            
            catch (Exception e){
                System.err.println( "Could not process the DTD. ");
                System.err.println(e.getMessage());
                e.printStackTrace();
                System.exit(1);
            }
        
            ModelBuilder model = new ModelBuilder(dtdEvents, dtdTitle);
            XMLWriter writer = new XMLWriter(model);
            
            // Now run the transformation
            try{
                InputStreamReader reader = writer.getXML();    
                TransformerFactory f = TransformerFactory.newInstance();
                // If no xsl was specified, use the identity transformer
                Transformer stylesheet = null;
                if (xsl == null) {
                    stylesheet = f.newTransformer();
                }
                else {
                    stylesheet = f.newTransformer(new StreamSource(xsl));
                }
                
                // Use this constructor because Saxon always 
                // looks for a system id even when a reader is used as the source  
                // If no string is provided for the sysId, we get a null pointer exception
                Source xmlSource = new StreamSource(reader, "");
                stylesheet.transform(xmlSource, out);
            }
            catch(Exception e){ 
                System.out.println("Could not run the transformation: " + e.getMessage());
                e.printStackTrace(System.out);
            }     
        }
        
        // Catch errors from parsing command line arguments
        catch( ParseException exp ) {
            System.out.println(exp.getMessage());
            printUsage(options);
            System.exit(1);
        }
    }
   
   /**
    * Outputs usage message
    */
    private static void printUsage(Options options) {
        // automatically generate the help statement
        HelpFormatter formatter = new HelpFormatter();
        formatter.setSyntaxPrefix("Usage:  ");
        OptionComparator c = new OptionComparator("hsdpcxt");
        formatter.setOptionComparator(c);

        formatter.printHelp(
            "dtdanalyzer [-h] [-d <xml-file> | -s <system-id> | -p <public-id>] " +
              "[-c <catalog>] [-x <xslt>] [-t <title>] [<out>]", 
            "\nThis utility analyzes a DTD and writes an XML output file.",
            options, "");
    }
   
}
