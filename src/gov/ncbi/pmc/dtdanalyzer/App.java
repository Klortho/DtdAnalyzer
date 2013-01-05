/*
 * App.java
 * This class provides a set of top-level defaults, including a superset of all of the
 * command-line options used by all of the individual applications.
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.apache.commons.cli.*;
import java.io.*;
import java.net.*;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.HashMap;
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
    private HashMap commonOpts = initCommonOpts();



    // This is the list of long names of the options, as passed into the constructor
    private String[] optList;
    
    // This is passed in from the application class, and provides a function that will handle
    // any custom command-line options for that application.
    private OptionHandler optHandler;

    // True if the application takes a final command-line argument that specifies the
    // output.
    private boolean wantOutput;

    // The number of DTDs that this application wants.  Usually this is one, but 
    // DtdCompare, for example, requires two.
    private int numDtds;




    // The set of custom options that is passed to use from the application class.
    private HashMap customOpts;

    // Usage info, these are passed in as constructor arguments from the application class,
    // and passed along to the HelpFormatter.
    private String cmdLineSyntax;
    private String usageHeader;

    // Parsed command line
    private CommandLine line;

    // List of DTD specifiers.  This list is constructed from the -d/-s/-p options, plus
    // the other options that are DTD-specific.  Usually, there is only one, but at least
    // one tool (dtdcompare) requires two DTDs.
    private DtdSpecifier[] dtdSpecifiers;

    // Used when parsing the command line:  number of DTDs we've seen so far.
    private int numDtdsFound;
    
    // Used when parsing: the number of titles we've seen so far.  Each DTD can have
    // its own title
    private int numTitlesFound;

    // If --catalog was given, this will be the CatalogResolver
    private CatalogResolver resolver = null;

    // If --xslt was given, this will be the transformer
    private Transformer xslt = null;

    // If --roots was given, this holds the values as an array.
    private String[] roots = null;

    // If --params was given, this holds the keys and values in an array.  Even
    // indeces are keys, odd indeces are values.
    private ArrayList xsltParams = new ArrayList();

    private StreamResult output = null;

    // If --debug were given, this would be true.
    private boolean debug = false;



    /**
     * Constructor.  The list of options should be in the same order that you want them
     * to be output in the usage message.
     */
    public App(String[] _args, String[] _optList, OptionHandler _optHandler, 
               HashMap _customOpts,
               boolean _wantOutput, String _cmdLineSyntax, String _usageHeader) 
    {
        _init(_args, _optList, _optHandler, _customOpts, _wantOutput, 1, _cmdLineSyntax, _usageHeader);
    }
    
    /**
     * Constructor.  Use this form when the command will accept more than one DTD argument;
     * for example, dtdcompare.
     */
    public App(String[] _args, String[] _optList, OptionHandler _optHandler, 
               HashMap _customOpts,
               boolean _wantOutput, int _numDtds, String _cmdLineSyntax, String _usageHeader) 
    {
        _init(_args, _optList, _optHandler, _customOpts, _wantOutput, _numDtds, _cmdLineSyntax, _usageHeader);
    }
    
    /**
     * Invoked by the constructors to initialize member variables.
     */
    private void _init(String[] _args, String[] _optList, OptionHandler _optHandler, 
                             HashMap _customOpts,
                             boolean _wantOutput, int _numDtds, String _cmdLineSyntax, 
                             String _usageHeader) 
    {
        args = _args;
        optList = _optList;
        optHandler = _optHandler;
        customOpts = _customOpts;
        wantOutput = _wantOutput;
        numDtds = _numDtds;
        cmdLineSyntax = _cmdLineSyntax;
        usageHeader = _usageHeader;
    }
    
    /**
     * This function does all the work, after the App object has been instantiated.
     * This must be a separate instance method, rather than being invoked from the 
     * constructor, because it calls the application class, which might call back to
     * us.  The easiest way for it to call back to us is via other instance methods.
     */
    public void initialize() {
        // Get our home directory
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
            System.err.println(
                "Warning:  failed to read app.properties file.  This should exist in " +
                "the DtdAnalyzer installation directory."
            );
        }

        // Merge the common and custom options into activeOpts.  Custom ones with the same
        // name will override the common ones.
        for (int i = 0; i < optList.length; ++i) {
            String optName = optList[i];
            //System.err.println("    option " + optName);
            Option opt = (Option) customOpts.get(optName);
            if (opt == null) opt = (Option) commonOpts.get(optList[i]);
            if (opt == null) {
                System.err.println("Strange, undefined command line option '" + optName +
                    "'.  This should never " +
                    "happen; please create an issue on GitHub.");
                System.exit(1);
            }
            
            activeOpts.addOption(opt);
        }

        // Set System properties for parsing and transforming
        if ( System.getProperty(App.SAX_DRIVER_PROPERTY) == null )
            System.setProperty(App.SAX_DRIVER_PROPERTY, App.SAX_DRIVER_DEFAULT);

        if ( System.getProperty(App.TRANSFORMER_FACTORY_PROPERTY) == null )
            System.setProperty(App.TRANSFORMER_FACTORY_PROPERTY, App.TRANSFORMER_FACTORY_DEFAULT);

        // Initialize all of the dtd specifiers
        dtdSpecifiers = new DtdSpecifier[numDtds];
        for (int i = 0; i < numDtds; ++i) {
            dtdSpecifiers[i] = new DtdSpecifier();
        }
        numDtdsFound = 0;
        numTitlesFound = 0;
        
        // Parse the command line arguments
        CommandLineParser clp = new PosixParser();
        try {
            line = clp.parse( activeOpts, args );

            // Loop through the given command-line options, in the order they were given.
            Option[] lineOpts = line.getOptions();
            for (int i = 0; i < lineOpts.length; ++i) {
                Option opt = lineOpts[i];
                String optName = opt.getLongOpt();

                if (!optHandler.handleOption(opt)) {
                    // The application didn't know what to do with it, so it
                    // must be a common opt, for us to handle.
                    handleOption(opt);
                }
            }

          
            // Now loop through any left-over arguments, and if we still
            // expect dtd specifiers, then use them up.  If there's one extra, and 
            // wantOutput is true, then we'll use that for the output filename.
            String[] rest = line.getArgs();
            for (int i = 0; i < rest.length; ++i) {
                //System.err.println("looking at " + rest[i] + ", numDtdsFound is " + numDtdsFound +
                //    ", numDtds is " + numDtds + ", wantOutput is " + wantOutput);
                if (numDtdsFound < numDtds) {
                    // Use this to initialize a dtd; assume it is a system id.
                    dtdSpecifiers[numDtdsFound].idType = 's';
                    dtdSpecifiers[numDtdsFound].idValue = rest[i];
                    numDtdsFound++;
                }
                else if (wantOutput && output == null) {
                    // Use this to initialize the output
                    output = new StreamResult(new File(rest[i]));
                }
                else {
                    usageError("Too many arguments");
                }
            }

            // If we still don't have all the input dtds specified, complain.
            if (numDtdsFound < numDtds) {
                usageError("Expected at least " + numDtds + " DTD specifier" + 
                           (numDtds > 1 ? "s" : "") + "!");
            }

            // Default output is to write to standard out
            if (wantOutput && output == null) {
                output = new StreamResult(System.out);
            }

            // Validate each dtd specifier object.  This also causes dummy XML documents
            // to be created for -s or -p specifiers.
            for (int i = 0; i < numDtds; ++i) {
                dtdSpecifiers[i].validate();
            }

            // If no --xslt option was specified, then set the transformer to the
            // identity transformer
            if (xslt == null) {
                try {
                    // If no xslt was specified, use the identity transformer
                    TransformerFactory f = TransformerFactory.newInstance();
                    xslt = f.newTransformer();
                    xslt.setOutputProperty(OutputKeys.INDENT, "yes");
                }
                catch (TransformerConfigurationException e) {
                    System.err.println("Error configuring xslt transformer: " + e.getMessage());
                    System.exit(1);
                }
            }
            

        }
        catch( ParseException exp ) {
            usageError(exp.getMessage());
        }
    }

    /**
     * Here is where we handle any of the common command-line options.  This will
     * be invoked when the application class doesn't know what to do with a given
     * option.
     */
    public boolean handleOption(Option opt) {
        String optName = opt.getLongOpt();
        
        // Handle --help:
        if ( optName.equals("help") ) {
            printUsage();
            System.exit(0);
        }
        
        // Handle --version
        if ( optName.equals("version") ) {
            System.out.println(
                "DtdAnalyzer utility, version " + version + "\n" +
                "Built " + buildtime + "\n" +
                "See http://dtd.nlm.nih.gov/ncbi/dtdanalyzer/"
            );
            System.exit(0);
        }

        // Handle the DTD specifiers
        if (optName.equals("doc") || optName.equals("system") || optName.equals("public")) {
            //System.err.println("Found a DTD specifier option, number " + numDtdsFound);
            if (numDtdsFound + 1 > numDtds) {
                usageError("Expected at most " + numDtds + " DTD specifier" +
                           (numDtds > 1 ? "s" : "") + "!");
            }
            dtdSpecifiers[numDtdsFound].idType = opt.getId();
            dtdSpecifiers[numDtdsFound].idValue = opt.getValue();
            numDtdsFound++;
            return true;
        }
        
        // Handle the title option(s)
        if (optName.equals("title")) {
            //System.err.println("Found title #" + numTitlesFound + ": '" + opt.getValue() + "'");
            if (numTitlesFound + 1 > numDtds) {
                usageError("Too many titles!");
            }
            dtdSpecifiers[numTitlesFound++].title = opt.getValue();
            return true;
        }

        // Handle the --catalog option
        if (optName.equals("catalog")) {
            File catalog = new File(opt.getValue());
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
            return true;
        }
        
        // Handle the --roots option.  This option should only be used when there's
        // one and only one DTD specified on the command line (i.e. not for dtdcompare).
        if (optName.equals("roots")) {
            roots = opt.getValue().split("\\s");
            return true;
        }

        // Check for and deal with the comment processor options.  
        // These are here under common options, because right now they are required
        // for all commands -- see issue #36.  Even after that gets resolved, they
        // will still be needed for both dtdanalyzer and dtddocumentor, so they
        // should stay in the common list.
        if (optName.equals("markdown")) {
            SComment.setCommentProcessor("pandoc");
            return true;
        }
        if (optName.equals("docproc")) {
            SComment.setCommentProcessor(opt.getValue());
            return true;
        }
        if (optName.equals("debug")) {
            debug = true;
            return true;
        }

        // Check for and deal with the --param option
        if (optName.equals("param")) {
            String[] values = opt.getValues();
            if (values[0].length() == 0) {
                System.err.println("XSLT parameter name can't be empty");
                System.exit(1);
            }
            xsltParams.addAll(Arrays.asList(values));
            return true;
        }

        System.err.println("Strange, unhandled command line option.  This should never " +
            "happen; please create an issue on GitHub.");
        System.exit(1);
        
        return false;
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
     * Allows an application class to set the XSLT transformer object.
     */
    public void setXslt(Transformer _xslt) {
        xslt = _xslt;
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
    public ArrayList getXsltParams() {
        return xsltParams;
    }

    /**
     * If --debug was given, this returns true, otherwise false.
     */
    public boolean getDebug() {
        return debug;
    }

    /**
     * Get the output file/stream.  This will only be initialized if wantOutput was
     * true when you called the constructor.
     */
    public StreamResult getOutput() {
        return output;
    }


    /**
     * This initializes the commonOpts hash.  Note that we're using the long option
     * name as the key to this hash.  That's required, because the array of names that
     * each driver class passes into the constructor here as optList is used for two
     * different things:  1, to pull the Option object out of the commonOpts hash; and
     * 2, in OptionComparator to sort the options for the usage message.  The OptionComparator
     * requires those values to match the long option names.
     *
     * What this means is that any two driver classes (for example, dtdanalyzer and dtddocumentor)
     * can't have options that have the same long option name but mean different things.
     */
    private HashMap initCommonOpts() {
        HashMap _opts = new HashMap();
        
        _opts.put("help", 
            new Option("h", "help", false, "Get help.")
        );
        _opts.put("version",
            new Option("v", "version", false, "Print version number and exit.")
        );
        _opts.put("system",
            OptionBuilder
                .withLongOpt( "system" )
                .withDescription("Use the given filename or system identifier to find the DTD. " +
                    "This could be a relative " +
                    "pathname, if the DTD exists in a file on your system, or an HTTP URL. " +
                    "The '-s' switch is optional. " +
                    "Note that if a catalog is in use, what looks like a filename might " +
                    "resolve to something else entirely.")
                .hasArg()
                .withArgName("system-id")
                .create('s')
        );
        _opts.put("doc",
            OptionBuilder
                .withLongOpt( "doc" )
                .withDescription("Specify an XML document used to find the DTD. This could be just a \"stub\" " +
                    "file, that contains nothing other than the doctype declaration and a root element. " +
                    "This file doesn't need to be valid according to the DTD.")
                .hasArg()
                .withArgName("xml-file")
                .create('d')
        );
        _opts.put("public",
            OptionBuilder
                .withLongOpt( "public" )
                .withDescription("Use the given public identifier to find the DTD. This would be used in " +
                    "conjunction with an OASIS catalog file.")
                .hasArg()
                .withArgName("public-id")
                .create('p')
        );
        _opts.put("catalog",
            OptionBuilder
                .withLongOpt( "catalog" )
                .withDescription("Specify a file to use as the OASIS catalog, to resolve system and " +
                    "public identifiers.")
                .hasArg()
                .withArgName("catalog-file")
                .create('c')
        );
        _opts.put("title",
            OptionBuilder
                .withLongOpt( "title" )
                .withDescription("Specify the title of this DTD.")
                .hasArg()
                .withArgName("dtd-title")
                .create('t')
        );
        _opts.put("roots",
            OptionBuilder
                .withLongOpt("roots")
                .withDescription("Specify the set of possible root elements for documents conforming " +
                    "to this DTD.")
                .hasArg()
                .withArgName("roots")
                .create('r')
        );
        _opts.put("docproc",
            OptionBuilder
                .withLongOpt("docproc")
                .withDescription("Command to use to process structured comments.  This command should " +
                    "take its input on stdin, and produce valid XHTML on stdout.")
                .hasArg()
                .withArgName("cmd")
                .create()
        );
        _opts.put("markdown",
            OptionBuilder
                .withLongOpt("markdown")
                .withDescription("Causes structured comments to be processed as Markdown. " +
                    "Requires pandoc to be installed on the system, and accessible to this process. " +
                    "Same as \"--docproc pandoc\".  If you want to supply your own Markdown " +
                    "processor, or any other processor, use the --docproc option.")
                .create('m')
        );
        _opts.put("param",
            OptionBuilder
                .withLongOpt("param")
                .hasArgs(2)
                .withValueSeparator()
                .withDescription("Parameter name & value to pass to the XSLT.  You can use multiple " +
                    "instances of this option.")
                .withArgName( "param=value" )
                .create('P')
        );

        /* 
          The 'q' here is a hack to get around some weird behavior that I can't figure out.
          If the 'q' is omitted, this option just doesn't work.
        */
        _opts.put("debug",
            OptionBuilder
                .withLongOpt("debug")
                .withDescription("Turns on debugging.")
                .create('q')
        );

        return _opts;
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
        formatter.setOptionComparator(new OptionComparator(optList));
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
