/*
 * DtdCompare.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;

/**
 * Compares two DTDs
 */
public class DtdCompare {

    private static App app;

    /**
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.
     */
    private static String[] optList = {
        "help", "version", "system", "doc", "public", "catalog", "title",
        "param"
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
     * Main execution point.
     */
    public static void main (String[] args) {


        app = new App(args, optList, optHandler, customOpts, true, 2,  /* this "2" means we want two dtds */
            "dtdcompare 2 X {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[<options>] [<out>]",
            "\nThis utility compares two DTDs and writes an HTML report. " +
            "Exactly two DTDs should be specified on the command line, with any " +
            "combination of the --system, --doc, and --public options.\n\n"
        );
        app.initialize();

        // Parse DTD 2 and save the results in a temporary file.
        File f = null;

        // Write the results for DTD 2 to a temporary file
        try {
            ModelBuilder model = new ModelBuilder(app.getDtdSpec(1), app.getRoots(), app.getResolver());
            XMLWriter writer = new XMLWriter(model);

            f = File.createTempFile("dtdcompare-", ".xml");
            FileOutputStream fos = new FileOutputStream(f);
            OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
            //FileWriter fw = new FileWriter(f);
            StringWriter sw = writer.getBuffer();
            osw.write(sw.toString());
            osw.close();
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

            ArrayList xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.size() / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter((String) xsltParams.get(2*i), (String) xsltParams.get(2*i+1));
                }
            }

            // Pass in the dtd2-loc as a parameter
            xslt.setParameter("dtd2-loc", f.toURI().toString());

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

        // Re-specifying title here, so we can change the description.
        _opts.put("title",
            OptionBuilder
                .withLongOpt( "title" )
                .withDescription("Specify the title of one of the DTDs. If this option " +
                    "is given once, the title will apply to the first DTD.  Give the " +
                    "option twice to specify titles for both DTDs.")
                .hasArg()
                .withArgName("dtd-title")
                .create('t')
        );

        return _opts;
    }
}
