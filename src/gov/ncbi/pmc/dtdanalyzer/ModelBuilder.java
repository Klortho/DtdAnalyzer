/*
 * ModelBuilder.java
 *
 * Created on November 14, 2005, 2:45 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import java.io.*;
import org.apache.xml.resolver.tools.CatalogResolver;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * Processes the declarations for Elements, Attributes and Entities to provide 
 * additional information such as the context of each element. In essense, this
 * class interprets the basic declaration information in order to create a 
 * more complete conceptual model of the XML DTD. This class is dependent on 
 * {@see DTDEventHandler}, which provides access to all the declarations.
 *
 * @author  Demian Hess
 */
public class ModelBuilder {
    private DTDEventHandler dtdInfo;
    private String dtdTitle;                   // Either null or a title value.
    private Elements elements;                 // All element declarations
    private Attributes attributes;             // All attribute declarations
    private Entities entities;                 // All entity declarations
    private Map contexts = new HashMap(1024);  // Collection used to hold context info
    private SComments scomments;               // All structured comments

    private HashSet _roots;                    // A list of all the root Elements
    
    private boolean debug = false;             // True if we should output debugging messages

    /**
     * Constructor.
     */
     
    public ModelBuilder(DtdSpecifier _dtdSpec, String[] _roots, CatalogResolver _resolver)
    {
        _init(_dtdSpec, _roots, _resolver, false);
    }

    /**
     * Constructor; allows you to set the debug flag
     */
    public ModelBuilder(DtdSpecifier _dtdSpec, String[] _roots, CatalogResolver _resolver,
                        boolean _debug) 
    {
        _init(_dtdSpec, _roots, _resolver, _debug);
    }
    
    private void _init(DtdSpecifier _dtdSpec, String[] _roots, CatalogResolver _resolver,
                       boolean _debug)
    {
        debug = _debug;
    
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
            if ( _resolver != null ) parser.setEntityResolver(_resolver); 
            
            // Run the parse to capture all events and create an XML representation of the DTD.
            // XMLReader's parse method either takes a system id as a string, or an InputSource
            if (_dtdSpec.idType == 'd') {
                parser.parse(_dtdSpec.idValue);
            }
            else {
                parser.parse(_dtdSpec.dummyXml);
            }
            
            // After parsing, all of the data has been collected into dtdEvents.
        }

        catch (EndOfDTDException ede) {
            // ignore: this is a normal exception raised to signal the end of processing
        }
        
        catch (Exception e) {
            System.err.println( "Could not process the DTD.  Message from the parser:");
            System.err.println(e.getMessage());
            //e.printStackTrace();
            System.exit(1);
        }


        // The next step is to mung the data from the parsed DTD a bit, building derived
        // data structures.  The output of this step is stored in the ModelBuilder object.
        _initialize(dtdEvents, _dtdSpec.title);

        // If the --roots switch was given, then add those to our list of root elements:
        try {
            if (_roots != null) addRoots(_roots);
        }
        catch (Exception e) {
            // This is not fatal
            System.err.println("Error trying to add specified root elements: " + 
                e.getMessage());
        }
        
        // If there are any known root elements (specified either as annotation tags or with
        // the --roots switch, then find reachable elements.
        try {
            if (hasRoots()) {
                findReachable();
            }
        }
        catch (Exception e) {
            // This is not fatal.
            System.err.println("Error trying to find reachable nodes from set of roots: " +
                e.getMessage());
        }

    }

    /**
     * Creates a new instance of ModelBuilder.  
     *
     * @param _dtdInfo Provides all the information about the DTD, that was gathered during
     * parsing.
     * @param _dtdTitle If not null, this will override any title that was given in the
     * top-level DTD structured comment.
     */
    public ModelBuilder(DTDEventHandler _dtdInfo, String _dtdTitle) {
        _initialize(_dtdInfo, _dtdTitle); 
    }
    
    private void _initialize(DTDEventHandler _dtdInfo, String _dtdTitle) {
        dtdInfo = _dtdInfo;
        elements = _dtdInfo.getAllElements();
        attributes = _dtdInfo.getAllAttributes();
        entities = _dtdInfo.getAllEntities();
        scomments = _dtdInfo.getAllSComments();

        _roots = new HashSet();
        _reachable = new HashSet();
        _toCheck = new LinkedList();


        // The DTD title will either come from the parsed content (from _dtdInfo) or else 
        // from the command-line param (from _dtdTitle).
        if (_dtdTitle != null) {
            dtdTitle = _dtdTitle;
        }
        else if (getDtdModule() != null) {
            SComment dtdSComment = scomments.getSComment(SComment.MODULE, getDtdModule().getRelSysId());
            if (dtdSComment != null) {
                dtdTitle = dtdSComment.getTitle();
            }
        }
        
        // Initialize the set of _roots from the annotation tags.  This might
        // be supplemented later with values from command-line argument
        ElementIterator elit = elements.getElementIterator();        
        while ( elit.hasNext() ){
            Element el = elit.next();
            SComment sc = scomments.getSComment(SComment.ELEMENT, el.getName());
            if (sc != null && sc.isRoot()) {
                el.setIsRoot();
                _putRoot(el);
            }
        }

        processContext();
    }

    /**
     * Returns the DTD title which will either come from the structured annotation within
     * the top-level DTD module, or else the command line.  It will be null if it's not
     * specified in either place.
     */
    public String getDtdTitle() {
        return dtdTitle;
    }
     
    /**
     * Returns all attribute declarations
     *
     * @return All attribute declaractions
     */    
    public Attributes getAttributes(){
        return attributes;
    }
    
    /**
     * Returns the context of a specified element (in other words, the elements
     * in which the specified element may appear)
     *
     * @param elementName Element for which the context is requested
     * @return  Array of parent element names
     */    
    public String[] getContext( String elementName ){

        Map children = (Map)contexts.get(elementName);        
        String[] values = new String[0];
        
        if ( children != null ){
            values = (String[])children.keySet().toArray(new String[children.keySet().size()]);
        }        
        return values;
    }
    
    /**
     * Returns the DtdModule associated with this DTD.
     */
    public DtdModule getDtdModule() {
        return dtdInfo.getDtdModule();
    }
     
    /**
     * Returns all element declarations
     *
     * @return  All element declarations
     */    
    public Elements getElements(){
        return elements;        
    }
    
    /**
     * Returns all entity declarations
     *
     * @return  All entity declarations
     */    
    public Entities getEntities(){
        return entities;        
    }
    
    /**
     * Returns all the structured comments.
     */
    public SComments getSComments() {
        return scomments;
    }
    
    /**
     * Sets debug to true.
     */ 
    public void setDebug() {
        debug = true;
    }
    
    /**
     * Tokenizes the content model for an element and builds the context list. All
     * the element names inside the model represent children of the current element.
     * The current element is thus added as a parent to the "context" list of each 
     * child element. 
     * 
     * @param name Current element name
     * @param model Content model of the current element
     */
    private void parseModel( String name, String model ){    
        // Check whether this has children
        if ( model.equals("EMPTY") || model.equals("ANY") || model.equals("(#PCDATA)")){
            // do nothing (no children)
        }
        // Must have content--either mixed or element only
        else{
            Map parents; // Holds all the potential parents 
            StringTokenizer tokens = new StringTokenizer( model, " \n\t\r,|+?*()"); 
            
            while ( tokens.hasMoreTokens() ) {
               String elName = tokens.nextToken().trim();
               
               // Make sure this is really a token
               if ( (! elName.equals("")) && (! elName.equals("#PCDATA")) ){
                  // Check if this element already exists in context collection
                  if ( contexts.containsKey(elName)){
                     parents = (Map)contexts.get(elName);
                  }
                  //Doesn't exist yet, so create a collection for it
                  else{
                     parents = new HashMap(256);
                     contexts.put(elName, parents);
                  }
                  
                  // Now update the context for this element
                  if ( parents.containsKey( name )) {
                      // do nothing since we already know about it
                  }
                  else {
                      parents.put(name, name);
                  }
               }
            }       
        } 
    }
    
    /**
     * Determines the context for each element declaration
     */
    private void processContext(){
        // Iterate over each element and process the model
        ElementIterator elit = elements.getElementIterator();        
        while ( elit.hasNext() ){
            Element el = elit.next();
            parseModel(el.getName(), el.getMinifiedModel());
        } 
    }
    
    
    /**
     * Add a list of root elements.  This is used by the main routine in response to
     * the "--roots" command-line argument.
     */
    public void addRoots(String[] roots) throws Exception {
        String name;
        
        for (int i = 0; i < roots.length; ++i) {
            name = roots[i];
            //System.err.println("root: " + roots[i]);
            Element r = elements.getElement(name);
            if (r == null) throw new Exception("Specified root \"" + name + "\" not found");
            r.setIsRoot();

            // Add each of these to the list of roots (and of reachable elements)
            _putRoot(r);
        }
    }
    
    /**
     * Returns true if there are any elements known to be specified as root elements
     */
    public boolean hasRoots() {
        return !_roots.isEmpty();
    }
    
    /**
     * Finds all the reachable elements, given a list of roots.  This then will flag the
     * roots with a 'root=true' attribute, and the unreachable elements with a 
     * 'reachable=false' attribute.
     */

    public void findReachable() throws Exception {
        if (debug) System.err.println("Finding reachable elements.");
        Element r;
        
        // Pop a new reachable element off the queue, and check each of its kids, until done.
        while ((r = (Element) _toCheck.poll()) != null) {
            if (debug) System.err.println("* <" + r.getName() + "> is reachable.");
            ContentModel cm = r.getContentModel();
            String spec = cm.getSpec();
            
            // If the spec is "any", then we're done -- all elements are reachable
            if (spec.equals("any")) {
                if (debug) System.err.println("  Allows any content, so we're done: everything is reachable.");
                return;
            }
            if (spec.equals("mixed") || spec.equals("element")) {
                if (debug) System.err.println("  Kids not seen before:");
                Iterator kids = cm.getKidsIter();
                while (kids.hasNext()) {
                    String kn = (String) kids.next();
                    Element k = elements.getElement(kn);
                    
                    // If we can't find one of the kids in the content model, just throw out
                    // a warning and continue.
                    if (k == null) {
                        System.err.println(
                            "Warning:  the content model for element \"" + r.getName() + 
                            "\" includes a child element \"" + kn + "\", but there is " +
                            "no declaration for it.");
                    }
                    else {
                        _putReachable(k);
                    }
                }
            }
        }
        
        // Now mark all those that are not in our set of reachable elements
        ElementIterator ei = elements.getElementIterator();
        while (ei.hasNext()) {
            Element e = ei.next();
            if (!_reachable.contains(e)) {
                e.setUnreachable();
                //System.err.println("Element " + e.getName() + ": unreachable");
            }
            else {
                //System.err.println("Element " + e.getName() + ": reachable");
            }
        }
    }
    
    // Keeps a list of all the elements we've found so far that are reachable
    private HashSet _reachable;

    // Here are the reachable elements whose kids we still need to check.
    private Queue _toCheck;

    // This helper function checks a given element that has just been determined to be
    // reachable.  If it has not been seen before, then it adds it to the queue of those
    // that still need to be checked.
    private void _putReachable(Element r) {
        if (!_reachable.contains(r)) {
            if (debug) System.err.println("    <" + r.getName() + ">");
            _reachable.add(r);
            _toCheck.add(r);
        }
    }
    
    // This helper function adds a given element to the list of root elements.  
    // While doing that, it also adds it to _reachable, since every root is of course
    // reachable.
    private void _putRoot(Element r) {
        if (debug) System.err.print("Root element:");
        if (!_roots.contains(r)) {
            _roots.add(r);
            _putReachable(r);
        }
    }
    
}
