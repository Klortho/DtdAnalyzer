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

public class DtdDocumentor {
    
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
            "help", "doc", "system", "public", "dir",
            "catalog", "title", "roots", "docproc", "markdown", "param",
            "css", "js", "include", "nosuffixes", "exclude", "exclude-except"
        };
        app = new App(args, optList, 
            "dtddocumentor [-h] [-d <xml-file> | -s <system-id> | -p <public-id>] " +
            "[-dir <dir>] [-c <catalog>] [-t <title>] [-r <roots>] [-m]",
            "\nThis utility generates HTML documentation from a DTD.  The above " +
            "is a summary of arguments; the complete list is below."
        );
        Options options = app.getActiveOpts();

        // Get the parsed command line arguments
        CommandLine line = app.getLine();
    
        // At least one of these must be given
        if (!line.hasOption("d") && !line.hasOption("s") && !line.hasOption("p")) {
            app.usageError("At least one of -d, -s, or -p must be specified!");
        }


        // There should be nothing left on the line.
        String[] rest = line.getArgs();
        if (rest.length > 0) {
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
            
            // Run the parse to capture all events and create an XML representation of the DTD.
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
            System.err.println( "Could not process the DTD. ");
            System.err.println(e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }


        // The next step is to mung the data from the parsed DTD a bit, building derived
        // data structures.  The output of this step is stored in the ModelBuilder object.

        ModelBuilder model = new ModelBuilder(dtdEvents, app.getDtdTitle());
        String[] roots = app.getRoots();
        try {
            if (roots != null) model.findReachable(roots);
        }
        catch (Exception e) {
            // This is not fatal.
            System.err.println("Error trying to find reachable nodes from set of roots: " +
                e.getMessage());
        }
        XMLWriter writer = new XMLWriter(model);


        // Now run the XSLT transformation.  This will be the dtddocumentor.xslt
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
            // stylesheet, so that we can copy it into the destination directory
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
}
