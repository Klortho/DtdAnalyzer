/*
 * Dtd2Xml2Json.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import org.apache.xml.resolver.tools.*;
import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;
import javax.xml.parsers.*;

/**
 * Creates XML representation of an XML DTD and then transforms it using
 * a provided stylesheet. This is a bare-bones application intended for
 * demonstration and debugging.
 */
public class Dtd2Xml2Json {
    
    private static App app;
    
    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * This application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {

        String[] optList = {
            "help", "version", "doc", "system", "public", "basexslt", "default-minimized",
            "catalog", "title", "roots", "docproc", "markdown", "param"
        };
        app = new App(args, optList, 
            "dtd2xml2json [-d <xml-file> | -s <system-id> | -p <public-id>] " +
            "[-c <catalog>] [-x <xslt>] [-t <title>] [<out>]",
            "\nThis generates an XSLT stylesheet from a DTD.  The stylesheet transforms " +
            "instance XML documents into JSON format."
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
    
        // At least one of these must be given
        if (!line.hasOption("d") && !line.hasOption("s") && !line.hasOption("p")) {
            app.usageError("At least one of -d, -s, or -p must be specified!");
        }

        // There should be at most one thing left on the line, which, if present, specifies the
        // output file.
        Result out = null;
        String[] rest = line.getArgs();
        if (rest.length == 0) {
            out = new StreamResult(System.out);
        }
        else if (rest.length == 1) {
            out = new StreamResult(new File(rest[0]));            
        }
        else {
            app.usageError("Too many arguments!");
        }


        // Perform set-up and parsing here.  The output of this step is a fully chopped up
        // and recorded representation of the DTD, stored in the DtdEventHandler object.
        
        DTDEventHandler dtdEvents = new DTDEventHandler();
        try {
            XMLReader parser = XMLReaderFactory.createXMLReader();
            parser.setContentHandler(dtdEvents);
            parser.setErrorHandler(dtdEvents);
            parser.setProperty( "http://xml.org/sax/properties/lexical-handler", dtdEvents); 
            parser.setProperty( "http://xml.org/sax/properties/declaration-handler", dtdEvents);
            parser.setFeature("http://xml.org/sax/features/validation", true);
            
            // Resolve entities if we have a catalog
            CatalogResolver resolver = app.getResolver();
            if ( resolver != null ) parser.setEntityResolver(resolver); 
            
            // Run the parse to capture all events and create an XML representation of the DTD.
            // XMLReader's parse method either takes a system id as a string, or an InputSource
            if (line.hasOption("d")) {
                parser.parse(line.getOptionValue("d"));
            }
            else {
                parser.parse(app.getDummyXmlFile());
            }
        }

        catch (EndOfDTDException ede) {
            // ignore: this is a normal exception raised to signal the end of processing
        }
        
        catch (Exception e) {
            System.err.println( "Could not process the DTD.  Message from the parser:");
            System.err.println(e.getMessage());
            //e.printStackTrace();
            System.exit(1);
        }


        // The next step is to mung the data from the parsed DTD a bit, building derived
        // data structures.  The output of this step is stored in the ModelBuilder object.

        ModelBuilder model = new ModelBuilder(dtdEvents, app.getDtdTitle());

        // If the --roots switch was given, then add those to our list of root elements:
        String[] roots = app.getRoots();
        try {
            if (roots != null) model.addRoots(roots);
        }
        catch (Exception e) {
            // This is not fatal
            System.err.println("Error trying to add specified root elements: " + 
                e.getMessage());
        }

        // If there are any known root elements (specified either as annotation tags or with
        // the --roots switch, then find reachable elements.
        try {
            if (model.hasRoots()) {
                model.findReachable();
            }
        }
        catch (Exception e) {
            // This is not fatal.
            System.err.println("Error trying to find reachable nodes from set of roots: " +
                e.getMessage());
        }
        XMLWriter writer = new XMLWriter(model);


        // Now run the XSLT transformation.  This will be the dtd2xml2json.xsl
        // stylesheet

        try {
            InputStreamReader reader = writer.getXML();

            File xslFile = new File(app.getHome(), "xslt/dtd2xml2json.xsl");
            Transformer xslt = 
                TransformerFactory.newInstance().newTransformer(new StreamSource(xslFile));
            String[] xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.length / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter(xsltParams[2*i], xsltParams[2*i+1]);
                }
            }

            // Get the basexslt option, if given, and pass those it in as a param
            String basexslt = app.getBaseXslt();
            if (basexslt != null) xslt.setParameter("basexslt", basexslt);
            
            // Get the defaultpretty option, if given, and pass that in.
            boolean defaultMinimized = app.getDefaultMinimized();
            xslt.setParameter("default-minimized", defaultMinimized);

            // Use this constructor because Saxon always 
            // looks for a system id even when a reader is used as the source  
            // If no string is provided for the sysId, we get a null pointer exception
            Source xmlSource = new StreamSource(reader, "");
            xslt.transform(xmlSource, out);
        }

        catch (Exception e){ 
            System.err.println("Could not run the transformation: " + e.getMessage());
            e.printStackTrace(System.out);
        }     
    }
}
