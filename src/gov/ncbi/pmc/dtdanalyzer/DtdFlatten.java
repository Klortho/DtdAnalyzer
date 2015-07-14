/*
 * DtdFlatten.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import java.io.File;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import org.apache.xml.resolver.tools.*;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * Creates a flattened version of a DTD.
 */
public class DtdFlatten {
    
    private static App app;

    /**
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.
     */
    private static String[] optList = {
        "help", "version", "system", "doc", "public",
        "catalog", "title", "roots", "docproc", "markdown", "param"
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
          
            if (optName.equals("full")) {
                full = true;
                return true;
            }

            return false;
        }
    };


    // DtdFlatten-specific command line option values
    private static boolean full = false;


    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * This application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {


        app = new App(args, optList, optHandler, customOpts, true,
            "dtdflatten {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[-c <catalog>] [-t <title>] [<out>]",
            "\nThis generates a flattened version of a DTD."
        );
        app.initialize();
    
        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = 
            new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver());
        XMLWriter writer = new XMLWriter(model);

        // Now run the XSLT transformation. 

        try {
            InputStreamReader reader = writer.getXML();

            File xslFile = new File(app.getHome(), "xslt/dtdflatten.xsl");
            Transformer xslt = 
                TransformerFactory.newInstance().newTransformer(new StreamSource(xslFile));
            ArrayList xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.size() / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter((String) xsltParams.get(2*i), (String) xsltParams.get(2*i+1));
                }
            }
            
            // Get the full option, if given, and pass that in.
            xslt.setParameter("complete", full ? "yes" : "no");

            // Use this constructor because Saxon always 
            // looks for a system id even when a reader is used as the source  
            // If no string is provided for the sysId, we get a null pointer exception
            Source xmlSource = new StreamSource(reader, "");
            xslt.transform(xmlSource, app.getOutput());
        }

        catch (Exception e) { 
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
        
        return _opts;
    }
}
