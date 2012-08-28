/*
 * DTDEventHandler.java
 *
 * Created on November 9, 2005, 2:03 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.ext.*;
import java.util.*;

/**
 * Collects and stores information about elements, attributes, and entities
 * declared in a DTD. Class can then be queried for this information.
 * Class should only be used with a parser that supports the LexicalHandler and
 * DeclHandler interfaces. This has been tested using Xerces, which is the preferred
 * XML reader implementation.
 *
 * @author Demian Hess
 * @version 1.0 2005-11-09
 */
public class DTDEventHandler implements org.xml.sax.ContentHandler, org.xml.sax.ErrorHandler, org.xml.sax.ext.DeclHandler, org.xml.sax.ext.LexicalHandler {
        
    private Locator locator = null;                       // Receives location information from XML reader
    private Attributes allAttributes = new Attributes();  // Contains all declared attributes
    private Elements allElements = new Elements();        // Contains all declared elements
    private int numOfElements = 0;                        // Element counter
    private Entities allEntities = new Entities();        // Contains all declared entities
        
    /**
     * Returns all declared Attributes 
     *
     * @return  Collection containing all declared attributes
     */    
    public Attributes getAllAttributes(){
        return allAttributes;
    }
    
    /**
     * Returns all declared Elements
     *
     * @return  Collection containing all declared elements
     */    
    public Elements getAllElements(){
        return allElements;
    }
    
    /**
     * Returns all declared Entities 
     *
     * @return  Collection containing all declared entities
     */    
    public Entities getAllEntities(){
        return allEntities;
    }
      
    /**
     * Returns location of the last declaration. This is a convenience method for
     * internal use.
     *
     * @return  Location of last declaration
     */  
    private Location getLocation() throws SAXException{
        if ( locator == null ){
            throw new SAXException("No locator provided by the parser. The DTD cannot be processed without location information.");
        } // if
        
        return new Location(locator.getSystemId(), locator.getPublicId(), locator.getLineNumber());
    }
    
    // *********************** ContentHandler methods ***********************
        
    /**
     * Sets locator that identifies the DTD file in which a declaration occurs.
     * The locator must be set in order to process a DTD. If the locator remains
     * null, the class methods will generate a SAXException.
     *
     * @param locator Reports location information from the DTD during parsing
     */    
    public void setDocumentLocator(org.xml.sax.Locator locator) {
            this.locator = locator;
    }

    /**
     * Reinitializes all values so that declaration information can be collected
     *
     * @throws SAXException Indicates problem occurred during processing */    
    public void startDocument() throws org.xml.sax.SAXException {
        allAttributes = new Attributes();
        allElements = new Elements();  
        allEntities = new Entities();
        numOfElements = 0;        
    }

    /**
     * Ends DTD processing because the parser has reached content. This method
     * should never be encountered if the document has a DTD because processing
     * will end when endDTD is called. Some documents, however, may not have a 
     * DTD.
     *
     * @param str         Uri of namespace
     * @param str1        localName of element
     * @param str2        Full name of element, including prefix
     * @param attributes  Element attributes
     * @throws EndOfDTDException Indicates that processing should end
     */
    public void startElement(String str, String str1, String str2, 
        org.xml.sax.Attributes attributes) throws org.xml.sax.SAXException {
        throw new EndOfDTDException();
    }
    
    // ++++ NOT IMPLEMENTED ++++
    public void characters(char[] values, int param, int param2) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void endDocument() throws org.xml.sax.SAXException {
        //do nothing
    }
    public void endElement(String str, String str1, String str2) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void endPrefixMapping(String str) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void ignorableWhitespace(char[] values, int param, int param2) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void processingInstruction(String str, String str1) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void skippedEntity(String str) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void startPrefixMapping(String str, String str1) throws org.xml.sax.SAXException {
        //do nothing
    }
        
    // *********************** DeclHandler methods *********************** 
    
    /**
     * Creates a new Attribute using the declaration information provided
     * by the XML Reader
     *
     * @param eName          Element name
     * @param aName          Attribute name
     * @param type           Type of content of the attribute (eg, CDATA)
     * @param valueDefault   The mode, such as "#IMPLIED"; null if not specified
     * @param value          Default value or null if none
     * @throws SAXException  Thrown if the XML Reader did not supply a Locator or some other problem occurred
     */    
    public void attributeDecl(String eName, String aName, String type, 
        String valueDefault, String value) throws org.xml.sax.SAXException {
        
        // Build the attribute: note that some values may be null and shouldn't
        // be set. Also note that building the location may throw an exception
        // if no locator was provided.
        Attribute att = new Attribute( eName, aName, type );
        
        if ( valueDefault != null ){
           att.setMode( valueDefault );
        }//if
        
        if ( value != null ){
           att.setDefaultValue( value );   
        }//if
       
        att.setLocation( getLocation() );
        
        // Add this to the master set of attributes
        allAttributes.addAttribute(att);
    }
    
    /**
     * Builds Element from the declaration information provided by the parser
     *
     * @param name          Element name 
     * @param model         Content model
     * @throws SAXException Thrown if the XML Reader did not supply a Locator or some other problem occurred
     */    
    public void elementDecl(String name, String model) throws org.xml.sax.SAXException {
        // Count how many elements there are so that we know the order in which they were
        // declared
        numOfElements++;

        // Create the element        
        Element el = new Element( name, model, numOfElements);
        el.setLocation( getLocation() );
        allElements.addElement(el);      
    }
    
    /**
     * Builds Entity from the declaration information provided by the parser
     *
     * @param name           Enity name
     * @param publicId       Public id (if supplied)
     * @param systemId       System id 
     * @throws SAXException  Thrown if an Entity object cannot be instantiated (such as due to an invalid "type")  
     */    
    public void externalEntityDecl(String name, String publicId, String systemId) throws org.xml.sax.SAXException {
        int type;
        Entity entity;
        
        try{
            if ( name.trim().startsWith("%") ){
                entity = new Entity(name.trim().substring(1), Entity.PARAMETER_ENTITY);
            }
            else{
                entity = new Entity(name.trim(), Entity.GENERAL_ENTITY);
            }
        }
        catch (Exception e){
           throw new SAXException( e.getMessage() );    
        }
        
        entity.setSystemId(systemId);       
        entity.setLocation(getLocation());
        
        if ( publicId != null ){
            entity.setPublicId(publicId);
        }
        
        allEntities.addEntity(entity);
    }
    
    /**
     * Builds Entity from declaration information provided by the parser
     *
     * @param name           Entity name
     * @param value          Entity value
     * @throws SAXException  Thrown if Entity object cannot be instantiated (such as due to an invalid "type") 
     */    
    public void internalEntityDecl(String name, String value) throws org.xml.sax.SAXException {
        int type;
        Entity entity;
        
        try{
            if ( name.trim().startsWith("%") ){
                entity = new Entity(name.trim().substring(1), Entity.PARAMETER_ENTITY);
            }
            else{
                entity = new Entity(name.trim(), Entity.GENERAL_ENTITY);
            }
        }
        catch (Exception e){
            throw new SAXException( e.getMessage() );
        }
        
        entity.setValue(value);       
        entity.setLocation(getLocation());
               
        allEntities.addEntity(entity);        
    }

    // *********************** ErrorHandler methods ***********************
    
    /**
     * Stops processing of the DTD because a fatal error occured. 
     *
     * @param sAXParseException The fatal error that stopped processing
     * @throws SAXException  This will probably never be thrown */    
    public void fatalError(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        throw sAXParseException;
    }
    
    // ++++ NOT IMPLEMENTED ++++ 
    public void error(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void warning(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        //do nothing
    }
    
    // *********************** LexicalHandler methods ***********************
    
    /**
     * Signals that the DTD has been fully processed
     *
     * @throws SAXException Subclass indicates that the DTD has been processed  */    
    public void endDTD() throws org.xml.sax.SAXException {
        throw new EndOfDTDException();
    }
    
    // ++++ NOT IMPLEMENTED ++++
    public void comment(char[] values, int param, int param2) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void endCDATA() throws org.xml.sax.SAXException {
        //do nothing
    }
    public void endEntity(String str) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void startCDATA() throws org.xml.sax.SAXException {
        //do nothing
    }
    public void startDTD(String str, String str1, String str2) throws org.xml.sax.SAXException {
        //do nothing
    }
    public void startEntity(String str) throws org.xml.sax.SAXException {
        //do nothing
    }
    
} //DTDEventHandler
