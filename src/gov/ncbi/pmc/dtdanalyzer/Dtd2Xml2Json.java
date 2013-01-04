/*
 * Dtd2Xml2Json.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import java.util.HashMap;
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
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.
     */
    private static String[] optList = {
        "help", "version", "doc", "system", "public", 
        "basexslt", "default-minimized",
        "catalog", "title", "roots", "docproc", "markdown", "param",
        "debug", "jxml-out"
    };

    /**
     * The set of options that are unique to this application
     */
    private static HashMap customOpts = initCustomOpts();

    /**
     * This inner class will be invoked for each of the command-line options that was given.
     * If it is a custom option, handle it here, otherwise, kick it back to App.
     */
    private static OptionHandler optHandler = new OptionHandler() {
        public boolean handleOption(Option opt) {
            return false;
        }
    };

    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * This application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {


        app = new App(args, optList, optHandler, customOpts, true,
            "dtd2xml2json [-d <xml-file> | [-s] <system-id> | -p <public-id>] " +
            "[-b <basexslt>] [-u] " +
            "[-c <catalog>] [-t <title>] [<out>]",
            "\nThis generates an XSLT stylesheet from a DTD.  The stylesheet transforms " +
            "instance XML documents into JSON format."
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
    
        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver());
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

            // Get the debug option, if given, and pass that in.
            boolean debug = app.getDebug();
            xslt.setParameter("debug", debug);

            // Get the jxml-out option, if given, and pass that in.
            boolean jxmlOut = app.getJxmlOut();
            xslt.setParameter("jxml-out", jxmlOut);


            // Use this constructor because Saxon always 
            // looks for a system id even when a reader is used as the source  
            // If no string is provided for the sysId, we get a null pointer exception
            Source xmlSource = new StreamSource(reader, "");
            xslt.transform(xmlSource, app.getOutput());
        }

        catch (Exception e){ 
            System.err.println("Could not run the transformation: " + e.getMessage());
            e.printStackTrace(System.out);
        }     
    }

    /**
     * Initialize any application-specific command line options here.  These can also
     * override the common options, if, for example, you want to change the usage
     * message.  You can even override the usage message, but still let the App class
     * handle the option.
     */
    private static HashMap initCustomOpts() {
        HashMap _customOpts = new HashMap();
        
        return _customOpts;
    }
}
