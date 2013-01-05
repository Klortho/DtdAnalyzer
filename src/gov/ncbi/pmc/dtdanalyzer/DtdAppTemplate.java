/*
 * DtdAppTemplate.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import java.io.InputStreamReader;
import java.util.HashMap;
import javax.xml.transform.Transformer;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * Description of this application.
 */
public class DtdAppTemplate {
    
    private static App app;

    /**
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.  
     * The strings in this list are the long names of the options, and those options
     * can either be common ones, defined in App.java, or application-specific ones,
     * defined in initCustomOpts() below.  If the same option name appears in both
     * places, the custom option takes precedence.
     */
    private static String[] optList = {
        "help", "version", "system", "doc", "public", "catalog", "title", 
        "roots", "docproc", "markdown", "param"
    };
    
    /**
     * The set of options that are unique to this application.
     */
    private static HashMap customOpts = initCustomOpts();

    /**
     * This inner class will be invoked for each of the options that was 
     * actually given on the command line.
     * If it is a custom option, handle it here and return true.  Otherwise, 
     * return false.
     */
    private static OptionHandler optHandler = new OptionHandler() {
        public boolean handleOption(Option opt) {
            String optName = opt.getLongOpt();
          /*
            if (optName.equals("...")) {
                ... = opt.getValue();
                return true;
            }
          */
            return false;
        }
    };

    /**
     * Main execution entry-point. 
     */
    public static void main (String[] args) {

        app = new App(args, optList, optHandler, customOpts, true,
            "dtdapptemplate {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[<options>] [<out>]",
            "\nThis utility ...."
        );
        app.initialize();

        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver());
        XMLWriter writer = new XMLWriter(model);

        // Now run the XSLT transformation.  This defaults to the identity transform, if
        // no XSLT was specified.

        try {
            InputStreamReader reader = writer.getXML();
            Transformer xslt = app.getXslt();
            
            // Get XSLT parameters, these are from the --params option.
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
      /*
        _opts.put("my-option",
            OptionBuilder
                .withLongOpt( "my-option" )
                .withDescription("A description of this option that will go into the " +
                    "usage message.")
                .hasArg()
                .withArgName("opt-arg-name")
                .create('m')
        );
      */
        return _opts;
    }
}
