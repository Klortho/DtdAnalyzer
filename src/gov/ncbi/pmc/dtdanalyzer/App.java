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
import java.util.Properties;
import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import org.xml.sax.*;
import org.apache.xml.resolver.tools.*;
import gov.ncbi.pmc.xml.PMCBootStrapper;
import org.apache.xml.resolver.*;

/**
 * The App class consolidates command-line options, configuration information, and other
 * things that are shared across all of the dtdanalyzer tools.
 */
public class App {

    /////////////////////////////////////////
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

    /////////////////////////////////////////
    
    // Application version number, from app.properties
    String version = "unknown";
    // Build time, from app.properties
    String buildtime = "unknown";
    
    // Stores the actual command line arguments used, this should be passed in directly from main()
    String[] args;

    // Value of the DTDANALYZER_HOME system property
    private File home;

    // This is the Options object that gives the list of all of the command-line options
    // that are in effect for this particular invokation.  (The list will differ depending on the
    // driver class; i.e. DtdAnalyzer, DtdDocumentor, etc.)
    private Options activeOpts = new Options();

    // This holds the superset of all possible options for any applications here.  Each
    // driver class will pick and choose from this set.  Use the long option name for the
    // key of this hash.
    private HashMap allOpts = new HashMap();

    // This is used to sort the options, when outputting the usage message.
    private OptionComparator oc;

    // Usage info, these are passed to the HelpFormatter
    private String cmdLineSyntax;
    private String usageHeader;

    // Parsed command line
    private CommandLine line;

    // List of DTD specifiers.  This list is constructed from the -d/-s/-p options, plus
    // the other options that are DTD-specific.  Usually, there is only one, but at least
    // one tool (dtdcompare) requires two DTDs.
    private DtdSpecifier[] dtdSpecifiers;

    // Number of DTDs that we are expecting from the command-line arguments.
    private int numDtds;

    // If --catalog was given, this will be the CatalogResolver
    private CatalogResolver resolver = null;

    // If --xslt was given, this will be the transformer
    private Transformer xslt = null;

    // If --roots was given, this holds the values as an array.
    private String[] roots = null;

    // If --params was given, this holds the keys and values in an array.  Even
    // indeces are keys, odd indeces are values.
    private String[] xsltParams = new String[0];





    // FIXME:
    // If --title was given, this holds the value
    //private String dtdTitle = null;


    // DtdDocumentor options, to be passed in as XSLT params.

    private String dir = null;
    private String css = null;
    private String js = null;
    private String include = null;
    private boolean suffixes = true;
    private String excludeElems = null;
    private String excludeExcept = null;
    private String basexslt = null;
    private boolean defaultMinimized = false;


    /**
     * Constructor.  The list of options should be in the same order that you want them
     * to be output in the usage message.
     */
    public App(String[] args, String[] optList, String _cmdLineSyntax, String _usageHeader) {
        _initialize(args, optList, _cmdLineSyntax, _usageHeader, 1);
    }
    
    public App(String[] args, String[] optList, String _cmdLineSyntax, String _usageHeader,
               int _numDtds) {
        _initialize(args, optList, _cmdLineSyntax, _usageHeader, _numDtds);
    }
    
    
    private void _initialize(String[] args, String[] optList, String _cmdLineSyntax, 
                             String _usageHeader, int _numDtds) 
    {
        String homeStr = System.getProperty("DTDANALYZER_HOME");
        if (homeStr == null) homeStr = ".";
        home = new File(homeStr);

        // Read the package properties file
        Properties props = new Properties();
        try {
            props.load(new FileInputStream( new File(homeStr, "app.properties") ));
            version = props.getProperty("version");
            buildtime = props.getProperty("buildtime");
        } 
        catch (IOException e) {
            System.err.println("Warning:  failed to read app.properties file.");
        }
        
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
            
            // Handle --version:
            if ( line.hasOption("v") ) {
                System.out.println(
                    "DtdAnalyzer utility, version " + version + "\n" +
                    "Built " + buildtime + "\n" +
                    "See http://ncbitools.github.com/DtdAnalyzer/"
                );
                System.exit(0);
            }

            // Initialize all of the dtd specifiers
            numDtds = _numDtds;
            dtdSpecifiers = new DtdSpecifier[numDtds];
            for (int i = 0; i < numDtds; ++i) {
                dtdSpecifiers[i] = new DtdSpecifier();
            }

            // Loop through the dtd-specific options -d/-s/-p, and store the info in the
            // DtdSpecifer objects.
            Option[] lineOpts = line.getOptions();
            int n = 0;
            for (int i = 0; i < lineOpts.length; ++i) {
                Option opt = lineOpts[i];
                //System.out.println("Option " + i + ": " + opt.getArgName() + ", " + (char) opt.getId());
                int optId = opt.getId();
                if (optId == 'd' || optId == 's' || optId == 'p') {
                    if (n + 1 > numDtds) {
                        usageError("Expected at most " + numDtds + " DTD specifier" +
                                   (numDtds > 1 ? "s" : "") + "!");
                    }
                    dtdSpecifiers[n].idType = optId;
                    dtdSpecifiers[n].idValue = opt.getValue();
                    n++;
                }
            }
            // FIXME:  Now we want to loop through any left-over arguments, and if we still
            // expect dtd specifiers, then use them up.  For now, complain
            if (n < numDtds) {
                usageError("Expected at least " + numDtds + " DTD specifier" + 
                           (numDtds > 1 ? "s" : "") + "!");
            }
            
            // Loop through again, and pick up any title options given
            n = 0;
            for (int i = 0; i < lineOpts.length; ++i) {
                Option opt = lineOpts[i];
                int optId = opt.getId();
                if (optId == 't') {
                    if (n + 1 > numDtds) {
                        usageError("Too many titles!");
                    }
                    dtdSpecifiers[n++].title = opt.getValue();
                }
            }
            
            // Validate each dtd specifier object.  This also causes dummy XML documents
            // to be created for -s or -p specifiers.
            for (int i = 0; i < numDtds; ++i) {
                dtdSpecifiers[i].validate();
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
                catalogManager.setIgnoreMissingProperties(true);
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
                    xslt.setOutputProperty(OutputKeys.INDENT, "yes");
                }
            }
            catch (TransformerConfigurationException e) {
                System.err.println("Error configuring xslt transformer: " + e.getMessage());
                System.exit(1);
            }

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

            // Check for and store all of the dtddocumentor options
            if (line.hasOption("dir")) {
                dir = line.getOptionValue("dir");
            }
            if (line.hasOption("css")) {
                css = line.getOptionValue("css");
            }
            if (line.hasOption("js")) {
                js = line.getOptionValue("js");
            }
            if (line.hasOption("include")) {
                include = line.getOptionValue("include");
            }
            if (line.hasOption("nosuffixes")) {
                suffixes = false;
            }
            if (line.hasOption("exclude")) {
                excludeElems = line.getOptionValue("exclude");
            }
            if (line.hasOption("exclude-except")) {
                excludeExcept = line.getOptionValue("exclude-except");
            }
            if (line.hasOption("basexslt")) {
                basexslt = line.getOptionValue("basexslt");
            }
            if (line.hasOption("default-minimized")) {
                defaultMinimized = true;
            }
        }
        catch( ParseException exp ) {
            usageError(exp.getMessage());
        }
    }

    /**
     * Get the home directory.  This is passed in from our startup scripts as the value of
     * the DTDANALYZER_HOME system property.
     */
    public File getHome() {
        return home;
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
     * Get the DtdSpecifier.
     */
    public DtdSpecifier getDtdSpec() {
        return getDtdSpec(0);
    }
    /**
     * Same, but use this when there are multiple dtds allowed.
     * No range checking done here, use responsibly.
     */
    public DtdSpecifier getDtdSpec(int i) {
        return dtdSpecifiers[i];
    }

    /**
     * Gets the DTD specification type, either 'd', 's', or 'p'.
     */
    public int getDtdSpecType() {
        return getDtdSpecType(0);
    }
    
    /**
     * Same, but use this one when there are multiple dtds allowed.
     * No range checking done here, use responsibly.
     */
    public int getDtdSpecType(int i) {
        return dtdSpecifiers[i].idType;
    }

    /**
     * Gets the DTD specification value, either a filename ('d'), a
     * system identifier, or a public identifier.
     */
    public String getDtdSpecValue() {
        return getDtdSpecValue(0);
    }
    
    /**
     * Same, but use this one when there are multiple dtds allowed.
     * No range checking done here, use responsibly.
     */
    public String getDtdSpecValue(int i) {
        return dtdSpecifiers[i].idValue;
    }

    /**
     * If -s or -p were used, this should hold the dummy XML file
     */
    public InputSource getDummyXml() {
        return getDummyXml(0);
    }
    
    /**
     * Same, but use this one when there are multiple dtds allowed.
     * No range checking done here, use responsibly.
     */
    public InputSource getDummyXml(int i) {
        return dtdSpecifiers[i].dummyXml;
    }

    /**
     * If --title was given, this returns the value, otherwise null.
     */
    public String getDtdTitle() {
        return getDtdTitle(0);
    }
    
    /**
     * Same, but use this when there are multiple dtds allowed.
     * No range checking done here, use responsibly.
     */
    public String getDtdTitle(int i) {
        return dtdSpecifiers[i].title;
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
     * If --dir was given, this returns that value, otherwise null.
     */
    public String getDir() {
        return dir;
    }

    /**
     * If --css was given, this returns the value, otherwise null.
     */
    public String getCss() {
        return css;
    }

    /**
     * If --js was given, this returns the value, otherwise null.
     */
    public String getJs() {
        return js;
    }

    /**
     * If --include was given, this returns the value, otherwise null.
     */
    public String getInclude() {
        return include;
    }

    /**
     * If --nosuffixes was given, this returns false, otherwise true.
     */
    public boolean getSuffixes() {
        return suffixes;
    }

    /**
     * If --exclude was given, this returns the value, otherwise null.
     */
    public String getExcludeElems() {
        return excludeElems;
    }

    /**
     * If --exclude-except was given, this returns the value, otherwise null.
     */
    public String getExcludeExcept() {
        return excludeExcept;
    }

    /**
     * If --basexslt was given, this returns the value, otherwise null.
     */
    public String getBaseXslt() {
        return basexslt;
    }

    /**
     * If --default-minimized was given, this returns true, otherwise false.
     */
    public boolean getDefaultMinimized() {
        return defaultMinimized;
    }



    /**
     * This initializes the allOpts hash.  Note that we're using the long option
     * name as the key to this hash.  That's required, because the array of names that
     * each driver class passes into the constructor here as optList is used for two
     * different things:  1, to pull the Option object out of the allOpts hash; and
     * 2, in OptionComparator to sort the options for the usage message.  The OptionComparator
     * requires those values to match the long option names.
     *
     * What this means is that any two driver classes (for example, dtdanalyzer and dtddocumentor)
     * can't have options that have the same long option name but mean different things.
     */
    private void initAllOpts() {
        allOpts.put("help", new Option("h", "help", false, "Get help"));
        allOpts.put("version",
            OptionBuilder
                .withLongOpt( "version" )
                .withDescription("Print version number and exit.")
                .create("v")
        );
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
        allOpts.put("dir",
            OptionBuilder
                .withLongOpt("dir")
                .withDescription("Specify the directory to which to write the output files. " +
                    "Defaults to \"doc\".")
                .hasArg()
                .withArgName("dir")
                .create()
        );
        allOpts.put("css",
            OptionBuilder
                .withLongOpt("css")
                .withDescription("Specify a css file to add to each HTML.  " +
                    "Defaults to dtddoc.css.")
                .hasArg()
                .withArgName("file")
                .create()
        );
        allOpts.put("js",
            OptionBuilder
                .withLongOpt("js")
                .withDescription("Specify a javascript file to add to each HTML.  " +
                    "Defaults to expand.js.")
                .hasArg()
                .withArgName("file")
                .create()
        );
        allOpts.put("include",
            OptionBuilder
                .withLongOpt("include")
                .withDescription("Allows you to specify any number of additional " +
                    "CSS and/or JS files.  This should be a space-delimited list.")
                .hasArg()
                .withArgName("files")
                .create()
        );
        allOpts.put("nosuffixes",
            OptionBuilder
                .withLongOpt("nosuffixes")
                .withDescription("If this option is given, it prevents the documentor " +
                    "from adding suffixes to output filenames.  By default, these are " +
                    "added to prevent problems on Windows machines when filenames differ " +
                    "only by case (for example, \"leftarrow.html\" and \"LeftArrow\".html). ")
                .create()
        );
        allOpts.put("exclude",
            OptionBuilder
                .withLongOpt("exclude")
                .withDescription("List of elements that should be excluded from the " +
                    "documentation.  This should be space-delimited.")
                .hasArg()
                .withArgName("elems")
                .create()
        );
        allOpts.put("exclude-except",
            OptionBuilder
                .withLongOpt("exclude-except")
                .withDescription("List of exceptions to the elements that should " +
                    "be excluded.")
                .hasArg()
                .withArgName("elems")
                .create()
        );
        allOpts.put("basexslt",
            OptionBuilder
                .withLongOpt("basexslt")
                .withDescription("Path to the XSLT which will be imported by the output XSLT. " +
                    "Defaults to \"../../xslt/xml2json.xsl\".")
                .hasArg()
                .withArgName("basexslt")
                .create("b")
        );
        allOpts.put("default-minimized",
            OptionBuilder
                .withLongOpt("default-minimized")
                .withDescription("If this option is given, then the default output from " +
                    "the generated stylesheet will minimized, and not pretty.")
                .create("u")
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
