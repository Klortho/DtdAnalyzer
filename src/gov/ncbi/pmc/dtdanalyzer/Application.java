/*
 * Application.java
 *
 * Created on November 10, 2005, 12:07 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

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
public class Application {
    
    // CONSTANTS
    public static final String SAX_DRIVER_PROPERTY = "org.xml.sax.driver";                               // ID for SAX driver
    public static final String SAX_DRIVER_DEFAULT = "org.apache.xerces.parsers.SAXParser";               // SAX driver implementation
    public static final String TRANSFORMER_FACTORY_PROPERTY = "javax.xml.transform.TransformerFactory";  // ID for transformer
    public static final String TRANSFORMER_FACTORY_DEFAULT = "com.icl.saxon.TransformerFactoryImpl";     // Transformer implementation
    public static final String OASIS_DTD = "/org/apache/xml/resolver/etc/catalog.dtd";                   // Path to reach OASIS dtd
    public static final String OASIS_PUBLIC_ID = "-//OASIS/DTD Entity Resolution XML Catalog V1.0//EN";  // Public id of Oasis DTD
    
    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * Once it has the XML, it transforms it using the specified XSL. The output
     * is placed in the specified location. Application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     *
     * @param args arg[0]=XML file; arg[1]=XSL file; arg[2]=Output; arg[3]=Optional Oasis catalog
     */
    public static void main (String[] args){
        boolean error = false; // Flag showing problem in arguments
        
        // Make sure we have the right arguments
        if ( args.length < 3 || args.length > 4 ){
            showUsage();
            System.exit(1);
        }//if
        
        // Retrieve the args
        File xml = new File( args[0] );
        File xsl = new File( args[1] );
        File output = new File( args[2] );
        File catalog = null;
        if (args.length == 4 )
            catalog = new File( args[3] );
        
        // Make sure these are valid
        if ( ! xml.exists() || ! xml.isFile()){
            error = true;
            System.err.println("Error: " + xml.toString() + " is not a file" );
        }//if 

        if ( ! xsl.exists() || ! xml.isFile()){
            error = true;
            System.err.println("Error: " + xsl.toString() + " is not a file" );
        }//if 
        
        if ( catalog != null && (!catalog.exists() || ! catalog.isFile()) ){
            error = true;
            System.err.println("Error: " + catalog.toString() + " is not a file" );
        }// if
        
        if ( error ){
            System.exit(1);
        }//if
        
        DTDEventHandler dtdEvents = new DTDEventHandler();
        
        // Set System properties for parsing and transforming
        if ( System.getProperty(SAX_DRIVER_PROPERTY) == null )
            System.setProperty( SAX_DRIVER_PROPERTY, SAX_DRIVER_DEFAULT);     
        
        if ( System.getProperty(TRANSFORMER_FACTORY_PROPERTY) == null )
            System.setProperty(TRANSFORMER_FACTORY_PROPERTY, TRANSFORMER_FACTORY_DEFAULT);

        //System.setProperty( "javax.xml.parsers.SAXParserFactory", "org.apache.xerces.jaxp.SAXParserFactoryImpl");        
        
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
            
            // Run the parse to capture all events and create an XML representation of the DTD
            parser.parse(xml.toString());
        } // try
        catch (EndOfDTDException ede){
            // ignore: this is a normal exception raised to signal the end of processing
        }//catch
        catch (Exception e){
            System.err.println( "Could not process the DTD. ");
            System.err.println(e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }//catch
    
        ModelBuilder model = new ModelBuilder(dtdEvents);
        XMLWriter writer = new XMLWriter(model);
        
        // Now run the transformation
        try{
            InputStreamReader reader = writer.getXML();    
            TransformerFactory f = TransformerFactory.newInstance();            
            Source xslSource = new StreamSource(xsl);          
            // Use this constructor because Saxon always 
            // looks for a system id even when a reader is used as the source  
            // If no string is provided for the sysId, we get a null pointer exception
            Source xmlSource = new StreamSource(reader, "");  
            Result out = new StreamResult(output);
            Transformer stylesheet = f.newTransformer(xslSource);
            stylesheet.transform(xmlSource, out);
        }//try
        catch(Exception e){ 
            System.out.println("Could not run the transformation: " + e.getMessage());
            e.printStackTrace(System.out);
        }//catch     
   }//main 
    
   /**
    * Outputs usage message
    */
   public static void showUsage(){
       System.err.println("Usage: java gov.ncbi.pmc.dtdanalyzer.Application [xml] [xsl] [output] {catalog}");
       System.err.println("   where:");
       System.err.println("   xml = path to xml instance");
       System.err.println("   xsl = path to xsl stylesheet");
       System.err.println("   output = filename for output");
       System.err.println("   catalog = optional parameter specifying location of OASIS catalog for DTD lookup.");
       System.err.println("             If no catalog is specified, then all DTDs will be located based on the system id in the instance.");
   }
}//Application
