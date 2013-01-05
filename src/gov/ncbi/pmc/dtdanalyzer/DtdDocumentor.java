/*
 * DtdDocumentor.java
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
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.output.NullOutputStream;
import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 */

public class DtdDocumentor {
    
    private static App app;

    /**
     * The list of all of the options that this application can take, in the order
     * that they will appear in the usage message.
     */
    private static String[] optList = {
        "help", "version", "system", "doc", "public", "dir",
        "catalog", "title", "roots", "docproc", "markdown", "param",
        "css", "js", "include", "entities", "nosuffixes", "exclude", "exclude-except",
        "debug"
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

            if (optName.equals("dir")) {
                dir = opt.getValue();
                return true;
            }
            if (optName.equals("css")) {
                css = opt.getValue();
                return true;
            }
            if (optName.equals("js")) {
                js = opt.getValue();
                return true;
            }
            if (optName.equals("include")) {
                include = opt.getValue();
                return true;
            }
            if (optName.equals("entities")) {
                entities = true;
                return true;
            }
            if (optName.equals("nosuffixes")) {
                suffixes = false;
                return true;
            }
            if (optName.equals("exclude")) {
                excludeElems = opt.getValue();
                return true;
            }
            if (optName.equals("exclude-except")) {
                excludeExcept = opt.getValue();
                return true;
            }
            
            return false;
        }
    };

    // DtdDocumentor-specific command line option values
    private static String dir = null;
    private static String css = null;
    private static String js = null;
    private static String include = null;
    private static boolean entities = false;
    private static boolean suffixes = true;
    private static String excludeElems = null;
    private static String excludeExcept = null;

    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * Once it has the XML, it transforms it using the specified XSL. The output
     * is placed in the specified location. Application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {

        app = new App(args, optList, optHandler, customOpts, false,
            "dtddocumentor {[-s] <system-id> | -d <xml-file> | -p <public-id>} " +
            "[<options>]",
            "\nThis utility generates HTML documentation from a DTD.  The above " +
            "is a summary of arguments; the complete list is below."
        );
        app.initialize();
    
        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = 
            new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver(), app.getDebug());

        XMLWriter writer = new XMLWriter(model);


        // Now run the XSLT transformation.  This will be the dtddocumentor.xsl
        // stylesheet

        try {
            InputStreamReader reader = writer.getXML();
            
            File xslFile = new File(app.getHome(), "xslt/dtddocumentor.xsl");
            Transformer xslt = 
                TransformerFactory.newInstance().newTransformer(new StreamSource(xslFile));
            ArrayList xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.size() / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter((String) xsltParams.get(2*i), (String) xsltParams.get(2*i+1));
                }
            }
            
            // Now get the dir, css, etc. options and pass those in as params
            if (dir == null) dir = "doc";
            xslt.setParameter("dir", dir);
            
            // We set the defaults for css and js here, which should match the default in the 
            // stylesheet.  The reason is that the Java code needs to know what the filename is, so
            // that it can copy it into the destination directory
            if (css == null) css = "dtddoc.css";
            xslt.setParameter("css", css);
            
            if (js == null) js = "expand.js";
            xslt.setParameter("js", js);
            
            if (include != null) xslt.setParameter("include-files", include);
            
            if (entities) xslt.setParameter("entities", "on");
            xslt.setParameter("filesuffixes", suffixes);
            
            if (excludeElems != null) xslt.setParameter("exclude-elems", excludeElems);
            
            if (excludeExcept != null) xslt.setParameter("exclude-except", excludeExcept);
            
            // Use this constructor because Saxon always 
            // looks for a system id even when a reader is used as the source  
            // If no string is provided for the sysId, we get a null pointer exception
            Source xmlSource = new StreamSource(reader, "");
            Result r = new StreamResult(new NullOutputStream());
            xslt.transform(xmlSource, r);
            
            // Copy the css and js files in, if they exist in our etc/dtddoc directory,
            // and don't exist already in the target directory.
            File destDir = new File(dir);
            File srcFile;
            File destFile;
            srcFile = new File(app.getHome(), "etc/dtddoc/" + css);
            destFile = new File(destDir, css);
            if (srcFile.exists() && !destFile.exists()) {
                FileUtils.copyFile(srcFile, destFile);
            }
            srcFile = new File(app.getHome(), "etc/dtddoc/" + js);
            destFile = new File(destDir, js);
            if (srcFile.exists() && !destFile.exists()) {
                FileUtils.copyFile(srcFile, destFile);
            }
            

            System.out.println("Done, documention is in the " + dir + " directory.");
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

        _opts.put("dir",
            OptionBuilder
                .withLongOpt("dir")
                .withDescription("Specify the directory to which to write the output files. " +
                    "Defaults to \"doc\".")
                .hasArg()
                .withArgName("dir")
                .create()
        );
        _opts.put("css",
            OptionBuilder
                .withLongOpt("css")
                .withDescription("Specify a CSS file that is included in a <link> element within " +
                    " each HTML output page.  Defaults to dtddoc.css.")
                .hasArg()
                .withArgName("file")
                .create()
        );
        _opts.put("js",
            OptionBuilder
                .withLongOpt("js")
                .withDescription("Specify a Javascript file that is invoked from each HTML " +
                    "output page.  Defaults to expand.js.")
                .hasArg()
                .withArgName("file")
                .create()
        );
        _opts.put("include",
            OptionBuilder
                .withLongOpt("include")
                .withDescription("Allows you to specify any number of additional " +
                    "CSS and/or JS files.  This should be a space-delimited list.")
                .hasArg()
                .withArgName("files")
                .create()
        );
        _opts.put("entities",
            OptionBuilder
                .withLongOpt("entities")
                .withDescription("Causes parameter and general entities to be " +
                    "included in the documentation.  By default they are not.")
                .create('e')
        );

        _opts.put("nosuffixes",
            OptionBuilder
                .withLongOpt("nosuffixes")
                .withDescription("If this option is given, it prevents the documentor " +
                    "from adding suffixes to output filenames.  By default, these are " +
                    "added to prevent problems on Windows machines when filenames differ " +
                    "only by case (for example, \"leftarrow.html\" and \"LeftArrow\".html). ")
                .create()
        );
        _opts.put("exclude",
            OptionBuilder
                .withLongOpt("exclude")
                .withDescription("List of elements that should be excluded from the " +
                    "documentation.  This is a regular expression.")
                .hasArg()
                .withArgName("elems")
                .create()
        );
        _opts.put("exclude-except",
            OptionBuilder
                .withLongOpt("exclude-except")
                .withDescription("List of exceptions to the elements that should " +
                    "be excluded.  This is also a regular expression.")
                .hasArg()
                .withArgName("elems")
                .create()
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
