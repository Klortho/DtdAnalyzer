/*
 * Dtd2Xml2Json.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import java.util.ArrayList;
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
        "help", "version", "system", "doc", "public", 
        "basexslt", "default-minimized",
        "catalog", "docproc", "markdown", "param",
        "debug", "jxml-out", "check-json"
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
            String optName = opt.getLongOpt();

            if (optName.equals("basexslt")) {
                basexslt = opt.getValue("basexslt");
                return true;
            }
            
            if (optName.equals("default-minimized")) {
                defaultMinimized = true;
                return true;
            }
          
            if (optName.equals("jxml-out")) {
                jxmlOut = true;
                return true;
            }

            if (optName.equals("check-json")) {
                checkJson = true;
                return true;
            }

            return false;
        }
    };

    // Dtd2Xml2Json-specific command line option values

    private static String basexslt = null;
    private static boolean defaultMinimized = false;
    private static boolean jxmlOut = false;
    private static boolean checkJson = false;

    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * This application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {


        app = new App(args, optList, optHandler, customOpts, true,
            "dtd2xml2json {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[<options>] [<out>]",
            "\nThis generates an XSLT stylesheet from a DTD.  The stylesheet transforms " +
            "instance XML documents into JSON format."
        );
        app.initialize();

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
            ArrayList xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.size() / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter((String) xsltParams.get(2*i), (String) xsltParams.get(2*i+1));
                }
            }

            // Get the basexslt option, if given, and pass those it in as a param
            if (basexslt != null) xslt.setParameter("basexslt", basexslt);
            
            // Get the defaultpretty option, if given, and pass that in.
            xslt.setParameter("default-minimized", defaultMinimized);

            // Get the debug option, if given, and pass that in.
            boolean debug = app.getDebug();
            xslt.setParameter("debug", debug);

            // Get the jxml-out option, if given, and pass that in.
            xslt.setParameter("jxml-out", jxmlOut);

            // Get the check-json option, if given, and pass that in.
            xslt.setParameter("check-json", checkJson);


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
        HashMap _opts = new HashMap();

        _opts.put("basexslt",
            OptionBuilder
                .withLongOpt("basexslt")
                .withDescription("Path to the XSLT which will be imported by the output XSLT. " +
                    "Defaults to \"xml2json.xsl\".")
                .hasArg()
                .withArgName("basexslt")
                .create('b')
        );
        _opts.put("default-minimized",
            OptionBuilder
                .withLongOpt("default-minimized")
                .withDescription("If this option is given, then the default output from " +
                    "the generated stylesheet will minimized, and not pretty.")
                .create('u')
        );
        _opts.put("jxml-out",
            OptionBuilder
                .withLongOpt("jxml-out")
                .withDescription("Causes the generated stylesheet to output the JXML " +
                    "intermediate format instead of JSON. This is used for debugging.")
                .create()
        );
        _opts.put("check-json",
            OptionBuilder
                .withLongOpt("check-json")
                .withDescription("Causes the generated stylesheet do some additional " +
                    "quality checks on the generated JSON, at runtime.  This should not be " +
                    "used to generate your final, production-ready XSLTs! " +
                    "Specifically, this looks for empty or duplicate object keys, and " +
                    "causes the XSLT to terminate with an error message, if it finds any." )
                .create()
        );
        
        return _opts;
    }
}
