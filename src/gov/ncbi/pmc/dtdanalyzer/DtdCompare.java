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
 * Compares two DTDs
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
            "\nThis utility compares two DTDs and writes an HTML report. " +
            "Exactly two DTDs should be specified on the command line, with any " +
            "combination of the --doc, --system, and --public options.\n\n",
            2  /* this "2" means we want two dtds */
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
        
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

        // Parse DTD 2 and save the results in a temporary file.
        File f = null;

        // Write the results for DTD 2 to a temporary file
        try {
            ModelBuilder model = new ModelBuilder(app.getDtdSpec(1), app.getRoots(), app.getResolver());
            XMLWriter writer = new XMLWriter(model);
            
            f = File.createTempFile("dtdcompare-", ".xml");
            FileWriter fw = new FileWriter(f);
            StringWriter sw = writer.getBuffer();
            fw.write(sw.toString());
            fw.close();
        }
        catch (IOException ioe) {
            System.err.println("Failed to write DTD 2 results to temp file: " +
                ioe.getMessage());
            System.exit(1);
        }
        //System.out.println("Temp file is " + f.getAbsolutePath());
        
        // Parse DTD 1
        ModelBuilder model = new ModelBuilder(app.getDtdSpec(0), app.getRoots(), app.getResolver());
        XMLWriter writer = new XMLWriter(model);
        
        // Now run the XSLT transformation.  This defaults to the identity transform, if
        // no XSLT was specified.

        try {
            InputStreamReader reader = writer.getXML();

            File xslFile = new File(app.getHome(), "xslt/dtdcompare.xsl");
            Transformer xslt = 
                TransformerFactory.newInstance().newTransformer(new StreamSource(xslFile));

            String[] xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.length / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter(xsltParams[2*i], xsltParams[2*i+1]);
                }
            }
            
            // Pass in the dtd2-loc as a parameter
            xslt.setParameter("dtd2-loc", f.getAbsolutePath());
            
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
