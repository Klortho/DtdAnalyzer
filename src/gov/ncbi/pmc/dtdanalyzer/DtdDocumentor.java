/*
 * DtdDocumentor.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import org.apache.xml.resolver.tools.*;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.output.NullOutputStream;
import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * Creates XML representation of an XML DTD and then transforms it using
 * a provided stylesheet. This is a bare-bones application intended for
 * demonstration and debugging.
 */

public class DtdDocumentor implements OptionHandler {
    
    private static App app;
    
    /**
     * Main execution point. Checks arguments, then converts the DTD into XML.
     * Once it has the XML, it transforms it using the specified XSL. The output
     * is placed in the specified location. Application currently uses Xerces and
     * Saxon because these are known to work well and will be bundled with this
     * distribution. However, other implementations can be specified through the
     * System properties.
     */
    public static void main (String[] args) {
        String[] optList = {
            "help", "version", "doc", "system", "public", "dir",
            "catalog", "title", "roots", "docproc", "markdown", "param",
            "css", "js", "include", "nosuffixes", "exclude", "exclude-except"
        };
        app = new App(args, optList, false,
            "dtddocumentor [-h] [-d <xml-file> | -s <system-id> | -p <public-id>] " +
            "[-dir <dir>] [-c <catalog>] [-t <title>] [-r <roots>] [-m]",
            "\nThis utility generates HTML documentation from a DTD.  The above " +
            "is a summary of arguments; the complete list is below."
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
    
        // This parses the DTD, and corrals the data into a model:
        ModelBuilder model = new ModelBuilder(app.getDtdSpec(), app.getRoots(), app.getResolver());

        XMLWriter writer = new XMLWriter(model);


        // Now run the XSLT transformation.  This will be the dtddocumentor.xsl
        // stylesheet

        try {
            InputStreamReader reader = writer.getXML();
            
            File xslFile = new File(app.getHome(), "xslt/dtddocumentor.xsl");
            Transformer xslt = 
                TransformerFactory.newInstance().newTransformer(new StreamSource(xslFile));
            String[] xsltParams = app.getXsltParams();
            int numXsltParams = xsltParams.length / 2;
            if (numXsltParams > 0) {
                for (int i = 0; i < numXsltParams; ++i) {
                    xslt.setParameter(xsltParams[2*i], xsltParams[2*i+1]);
                }
            }
            
            // Now get the dir, css, etc. options and pass those in as params
            String dir = app.getDir();
            if (dir == null) dir = "doc";
            xslt.setParameter("dir", dir);
            
            // We set the defaults for css and js here, which should match the default in the 
            // stylesheet.  The reason is that the Java code needs to know what the filename is, so
            // that it can copy it into the destination directory
            String css = app.getCss();
            if (css == null) css = "dtddoc.css";
            xslt.setParameter("css", css);
            
            String js = app.getJs();
            if (js == null) js = "expand.js";
            xslt.setParameter("js", js);
            
            String include = app.getInclude();
            if (include != null) xslt.setParameter("include-files", include);
            
            boolean suffixes = app.getSuffixes();
            xslt.setParameter("filesuffixes", suffixes);
            
            String excludeElems = app.getExcludeElems();
            if (excludeElems != null) xslt.setParameter("exclude-elems", excludeElems);
            
            String excludeExcept = app.getExcludeExcept();
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
     * This method will be invoked for each of the command-line options that was given.
     * If it is a custom option, handle it here, otherwise, kick it back to App.
     */
    public void handleOption(Option opt) {
        app.handleOption(opt);
    }
}
