/*
 * DtdCompare.java
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
 */
public class DtdCompare {
    
    private static App app;
    
    /**
     * Main execution point. 
     */
    public static void main (String[] args) {

        String[] optList = {
            "help", "version", "doc", "system", "public", "catalog", "title", 
            "param"
        };
        app = new App(args, optList, 
            "dtdcompare [<options>]",
            "\nThis utility analyzes a DTD and writes an XML output file. " +
            "Exactly two DTDs should be specified on the command line, with any " +
            "combination of the --doc, --system, and --public options.\n\n"
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
    
        // At least one of these must be given
        if (!line.hasOption("d") && !line.hasOption("s") && !line.hasOption("p")) {
            app.usageError("Exactly two of -d, -s, and -p must be specified!");
        }
        String[] docs = line.getOptionValues("d");
        System.out.println("Number of docs:  " + docs.length);
        for (int i = 0; i < docs.length; ++i) {
            System.out.println("  doc[" + i + "] = '" + docs[i] + "'");
        }
        System.exit(1);


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
            
            // Run the parser to capture all events and create an XML representation of the DTD.
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


        // Now run the XSLT transformation.  This defaults to the identity transform, if
        // no XSLT was specified.

        try {
            InputStreamReader reader = writer.getXML();
            
            Transformer xslt = app.getXslt();
            
            String[] xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.length / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter(xsltParams[2*i], xsltParams[2*i+1]);
                }
            }
            
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
