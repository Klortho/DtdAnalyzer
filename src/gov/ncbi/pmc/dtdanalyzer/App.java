/*
 * App.java
 * This class provides a set of top-level defaults, including a superset of all of the
 * command-line options used by all of the individual applications.
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.util.HashMap;
import java.io.*;
import java.net.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import org.xml.sax.*;
import org.apache.xml.resolver.tools.*;
import gov.ncbi.pmc.xml.PMCBootStrapper;
import org.apache.xml.resolver.*;

/*
import java.io.*;
import java.net.*;
import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import gov.ncbi.pmc.xml.PMCBootStrapper;
import org.apache.xml.resolver.*;
import org.apache.xml.resolver.tools.*;
import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;
*/

/**
 * Creates XML representation of an XML DTD and then transforms it using
 * a provided stylesheet. This is a bare-bones application intended for
 * demonstration and debugging.
 */
public class App {
    
    // CONSTANTS
    
    // ID for SAX driver
    public static final String SAX_DRIVER_PROPERTY = "org.xml.sax.driver";
                                   
    // SAX driver implementation
    public static final String SAX_DRIVER_DEFAULT = "org.apache.xerces.parsers.SAXParser";
                   
    // ID for transformer
    public static final String TRANSFORMER_FACTORY_PROPERTY = "javax.xml.transform.TransformerFactory";
      
    // Transformer implementation - default to Saxon 9, per this documentation page:
    // http://www.saxonica.com/documentation/using-xsl/embedding/jaxp-transformation.xml
    public static final String TRANSFORMER_FACTORY_DEFAULT = "net.sf.saxon.TransformerFactoryImpl";
         
    // Path to reach OASIS dtd
    public static final String OASIS_DTD = "/org/apache/xml/resolver/etc/catalog.dtd";
                       
    // Public id of Oasis DTD
    public static final String OASIS_PUBLIC_ID = "-//OASIS/DTD Entity Resolution XML Catalog V1.0//EN";  
    
    // Stores the actual command line arguments used, this should be passed in directly from main()
    String[] args;
    
    // This is the Options object that gives the list of all of the command-line options
    // that are in effect for this particular invokation.  (The list will differ depending on the
    // driver class; i.e. DtdAnalyzer, DtdDocumentor, etc.)
    private Options activeOpts = new Options();
    
    // This holds the superset of all possible options for any applications here.  Each
    // driver class will pick and choose from this set.  Use the long option name for the 
    // key of this hash.
    private HashMap allOpts = new HashMap();
    
    // This is used to sort the options
    private OptionComparator oc;
    
    // Usage into, passed to the HelpFormatter
    private String cmdLineSyntax;
    private String usageHeader;

    // Parsed command line
    private CommandLine line;

    // If -s or -p was given, this is the dummy input XML file:
    private InputSource dummyXmlFile;   

    // If --catalog was given, this will be the CatalogResolver
    private CatalogResolver resolver = null;
    
    // If --xslt was given, this will be the transformer
    private Transformer xslt = null;
    
    // If --title was given, this holds the value
    private String dtdTitle = null;

    // If --roots was given, this holds the values as an array.
    String[] roots = null;

    // If --params was given, this holds the keys and values in an array.  Even
    // indeces are keys, odd indeces are values.
    String[] xsltParams = new String[0];
    
    /**
     * Constructor.  The list of options should be in the same order that you want them
     * to be output in the usage message.
     */
    public App(String[] args, String[] optList, String _cmdLineSyntax, String _usageHeader) {
        initAllOpts();
        oc = new OptionComparator(optList);
        cmdLineSyntax = _cmdLineSyntax;
        usageHeader = _usageHeader;

        for (int i = 0; i < optList.length; ++i) {
            activeOpts.addOption( (Option) allOpts.get(optList[i]) );
        }

        // Set System properties for parsing and transforming
        if ( System.getProperty(App.SAX_DRIVER_PROPERTY) == null )
            System.setProperty(App.SAX_DRIVER_PROPERTY, App.SAX_DRIVER_DEFAULT);     
        
        if ( System.getProperty(App.TRANSFORMER_FACTORY_PROPERTY) == null )
            System.setProperty(App.TRANSFORMER_FACTORY_PROPERTY, App.TRANSFORMER_FACTORY_DEFAULT);


        // create the command line parser
        CommandLineParser clp = new PosixParser();
        try {
            // parse the command line arguments
            line = clp.parse( activeOpts, args );
        
            // Handle --help:
            if ( line.hasOption( "h" ) ) {
                printUsage();
                System.exit(0);
            }
            
            // Validate options
            
            // Only one of -s, -d, or -p can be given
            if ( (line.hasOption("d") ? 1:0) + (line.hasOption("s") ? 1:0) + 
                 (line.hasOption("p") ? 1:0) > 1) {
                 usageError("Only one of -d, -s, or -p is allowed!");
            }
            
            // Check that, if given, the argument to -d is a valid file
            if (line.hasOption("d")) {
                File xml = new File(line.getOptionValue("d"));
                if ( ! xml.exists() || ! xml.isFile() ) {
                    System.err.println("Error: " + xml.toString() + " is not a file" );
                    System.exit(1);
                }
            }

            // Otherwise, construct the dummy XML file
            else {
                String xmlFileStr = "<!DOCTYPE root ";
                if (line.hasOption("s")) {
                    xmlFileStr += "SYSTEM \"" + line.getOptionValue("s") + "\">";
                }
                else {
                    xmlFileStr += "PUBLIC \"" + line.getOptionValue("p") + "\" \"\">";
                }
                String publicId = line.getOptionValue("p");
                xmlFileStr += "\n\n<root/>\n";
                
                dummyXmlFile = new InputSource(new StringReader(xmlFileStr));
            }


            // Check for, and handle, the --catalog option
            if (line.hasOption("c")) {
                File catalog = new File(line.getOptionValue("c"));
                if ( ! catalog.exists() || ! catalog.isFile() ) {
                    System.err.println("Error: Specified catalog " + catalog.toString() + " is not a file" );
                    System.exit(1);
                }
                
                // Set up catalog resolution
                PMCBootStrapper bootstrapper = new PMCBootStrapper();
                CatalogManager catalogManager = new CatalogManager(); 
                URL oasisCatalog = catalogManager.getClass().getResource(App.OASIS_DTD);
                bootstrapper.addMapping(App.OASIS_PUBLIC_ID, oasisCatalog.toString());
                catalogManager.setBootstrapResolver(bootstrapper);
                catalogManager.setCatalogFiles(catalog.toString());
                resolver = new CatalogResolver(catalogManager); 
            }

            // Check for, and handle, the --xsl option
            try {
                TransformerFactory f = TransformerFactory.newInstance();
                if (line.hasOption("x")) {
                    File xslFile = new File(line.getOptionValue("x"));
                    if ( ! xslFile.exists() || ! xslFile.isFile() ) {
                        System.err.println("Error: Specified xsl " + xslFile.toString() + " is not a file" );
                        System.exit(1);
                    }
                    xslt = f.newTransformer(new StreamSource(xslFile));
                }
                else {
                    // If no xsl was specified, use the identity transformer
                    xslt = f.newTransformer();
                }
            }
            catch (TransformerConfigurationException e) {
                System.err.println("Error configuring xslt transformer: " + e.getMessage());
                System.exit(1);
            }

            // Check for and store the --title option
            if (line.hasOption("t")) dtdTitle = line.getOptionValue("t");

            // Check for and store --roots
            if (line.hasOption("r")) {
                roots = line.getOptionValue("r").split("\\s");
            }

            // Check for and deal with the comment processor options
            if (line.hasOption("m")) {
                SComment.setCommentProcessor("pandoc");            
            }
            else if (line.hasOption("docproc")) {
                SComment.setCommentProcessor(line.getOptionValue("docproc"));
            }

            // Check for and deal with the --param option(s)
            if (line.hasOption("P")) {
                xsltParams = line.getOptionValues("P");
                int numXsltParams = xsltParams.length / 2;
                //System.err.println("num of params: " + num);
                for (int i = 0; i < numXsltParams; ++i) {
                    // parameter name can't be empty
                    if (xsltParams[i*2].length() == 0) {
                        System.err.println("XSLT parameter name can't be empty");
                        System.exit(1);
                    }
                }
            }

        }
        catch( ParseException exp ) {
            usageError(exp.getMessage());
        }
    }

    /**
     * Get the parsed command line.
     */
    public CommandLine getLine() {
        return line;
    }

    /**
     * Get the currently active Options
     */
    public Options getActiveOpts() {
        return activeOpts;
    }
    
    /**
     * If -s or -p were used, this should hold the dummy XML file
     */
    public InputSource getDummyXmlFile() {
        return dummyXmlFile;
    }

    /**
     * If --catalog was given, this will return a valid object, otherwise null.
     */
    public CatalogResolver getResolver() {
        return resolver;
    }
    
    /**
     * If --xslt was given, this will return a Transformer object.  Even if not, this
     * will return a Transformer that does the identity transformation.
     */
    public Transformer getXslt() {
        return xslt;
    }

    /**
     * If --title was given, this returns the value, otherwise null.
     */
    public String getDtdTitle() {
        return dtdTitle;
    }

    /** 
     * If --roots was given, this returns the value as an array
     */
    public String[] getRoots() {
        return roots;
    }
    
    /**
     * If --params was given, this returns the keys and values in an alternating array.
     */
    public String[] getXsltParams() {
        return xsltParams;
    }




    /**
     * This initializes the allOpts hash.
     */
    private void initAllOpts() {
        allOpts.put("help", new Option("h", "help", false, "Get help"));
        allOpts.put("doc", 
            OptionBuilder
                .withLongOpt( "doc" )
                .withDescription("Specify an XML document used to find the DTD. This could be just a \"stub\" " +
                    "file, that contains nothing other than the doctype declaration and a root element. " +
                    "This file doesn't need to be valid according to the DTD.")
                .hasArg()
                .withArgName("xml-file")
                .create('d')
        );
        allOpts.put("system",
            OptionBuilder
                .withLongOpt( "system" )
                .withDescription("Use the given system identifier to find the DTD. This could be a relative " +
                    "pathname, if the DTD exists in a file on your system, or an HTTP URL.")
                .hasArg()
                .withArgName("system-id")
                .create('s') 
        );
        allOpts.put("public",
            OptionBuilder
                .withLongOpt( "public" )
                .withDescription("Use the given public identifier to find the DTD. This would be used in " +
                    "conjunction with an OASIS catalog file.")
                .hasArg()
                .withArgName("public-id")
                .create('p') 
        );
        allOpts.put("catalog",
            OptionBuilder
                .withLongOpt( "catalog" )
                .withDescription("Specify a file to use as the OASIS catalog, to resolve public identifiers.")
                .hasArg()
                .withArgName("catalog-file")
                .create('c') 
        );
        allOpts.put("xslt",
            OptionBuilder
                .withLongOpt( "xslt" )
                .withDescription("An XSLT script to run to post-process the output. This is optional.")
                .hasArg()
                .withArgName("xslt")
                .create('x') 
        );
        allOpts.put("title",
            OptionBuilder
                .withLongOpt( "title" )
                .withDescription("Specify the title of this DTD. This will be output within a <title> " +
                    "element under the root <declarations> element of the output XML.")
                .hasArg()
                .withArgName("dtd-title")
                .create('t') 
        );
        allOpts.put("roots",
            OptionBuilder
                .withLongOpt("roots")
                .withDescription("Specify the set of possible root elements for documents conforming " + 
                    "to this DTD.  These elements will be tagged with a 'root=true' attribute in " +
                    "the output.  This will also cause the program to find those elements that " +
                    "are not reachable from this set of possible root elements, and to tag those " +
                    "with a 'reachable=false' attribute.  The argument to this " +
                    "should be a space-delimited list of element names. ")
                .hasArg()
                .withArgName("roots")
                .create('r')
        );
        allOpts.put("docproc",
            OptionBuilder
                .withLongOpt("docproc")
                .withDescription("Command to use to process structured comments.  This command should " +
                    "take its input on stdin, and produce valid XHTML on stdout.")
                .hasArg()
                .withArgName("cmd")
                .create()
        );
        allOpts.put("markdown",
            OptionBuilder
                .withLongOpt("markdown")
                .withDescription("Causes structured comments to be processed as Markdown. " +
                    "Requires pandoc to be installed on the system, and accessible to this process. " +
                    "Same as \"--docproc 'pandoc'\".")
                .create('m')
        );
        allOpts.put("param",
            OptionBuilder
                .withLongOpt("param")
                .hasArgs(2)
                .withValueSeparator()
                .withDescription("Parameter name & value to pass to the XSLT.  You can use multiple " +
                    "instances of this option.")
                .withArgName( "param=value" )
                .create("P")
        );
    }
    
   /**
    * Outputs usage message to standard output
    */
    public void printUsage() {
        printUsage(System.out);
    }
    /**
     * Outputs the usage message to an output stream (System.out or System.err).
     */
    public void printUsage(OutputStream os) {
        // automatically generate the help statement
        HelpFormatter formatter = new HelpFormatter();
        formatter.setSyntaxPrefix("Usage:  ");
        formatter.setOptionComparator(oc);
        formatter.printHelp(new PrintWriter(os, true), 80, cmdLineSyntax, usageHeader, activeOpts,
            2, 2, "");
    }
    
    /**
     * Use this when there's a serious error in the command line
     */
    public void usageError(String msg) {
        System.err.println("Usage error:  " + msg + "\n");
        printUsage(System.err);
        System.exit(1);
    }
}
