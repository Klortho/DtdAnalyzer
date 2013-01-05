/*
 * DtdAnalyzer.java
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
public class DtdAnalyzer {
    
    private static App app;

    /**
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.
     */
    private static String[] optList = {
        "help", "version", "system", "doc", "public", "catalog", "xslt", "title", 
        "roots", "docproc", "markdown", "param", "debug"
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

            // Check for, and handle, the --xsl option
            if ( optName.equals("xslt") ) {
                try {
                    TransformerFactory f = TransformerFactory.newInstance();
                    File xslFile = new File(opt.getValue());
                    if ( ! xslFile.exists() || ! xslFile.isFile() ) {
                        System.err.println("Error: Specified xsl " + xslFile.toString() + 
                            " is not a file" );
                        System.exit(1);
                    }
                    app.setXslt( f.newTransformer(new StreamSource(xslFile)) );
                }
                catch (TransformerConfigurationException e) {
                    System.err.println("Error configuring xslt transformer: " + e.getMessage());
                    System.exit(1);
                }
                return true;
            }


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
            "dtdanalyzer {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[<options>] [<out>]",
            "\nThis utility analyzes a DTD and writes an XML output file."
        );
        app.initialize();

        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = 
            new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver(), app.getDebug());

        XMLWriter writer = new XMLWriter(model);


        // Now run the XSLT transformation.  This defaults to the identity transform, if
        // no XSLT was specified.

        try {
            InputStreamReader reader = writer.getXML();
            
            Transformer xslt = app.getXslt();
            
            ArrayList xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.size() / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter((String) xsltParams.get(2*i), (String) xsltParams.get(2*i+1));
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

        _opts.put("xslt",
            OptionBuilder
                .withLongOpt( "xslt" )
                .withDescription("An XSLT script to run to post-process the output.")
                .hasArg()
                .withArgName("xslt")
                .create('x')
        );
        /* 
          The 'q' here is a hack to get around some weird behavior that I can't figure out.
          If the 'q' is omitted, this option just doesn't work.
        */
        _opts.put("debug",
            OptionBuilder
                .withLongOpt("debug")
                .withDescription("Turns on debugging messages.")
                .create('q')
        );

        return _opts;
    }
}
