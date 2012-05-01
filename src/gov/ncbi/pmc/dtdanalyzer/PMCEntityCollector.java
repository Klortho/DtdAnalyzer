/*
 * PMCEntityCollector.java
 *
 * Created on January 17, 2005, 2:16 PM
 */

package pmctools;

import org.xml.sax.*;
import org.xml.sax.ext.*;
import java.io.*;
import java.util.*;

/**
 * Responsible for processing an XML instance and returning all the 
 * PMC entities in a new XML instance.
 *
 * @author  Demian Hess
 */
public class PMCEntityCollector implements DeclHandler, LexicalHandler {
    private HashMap entities;
    private PMCEntity currentEntity;
    private XMLReader parser;
    private boolean grabNextComment;
    
    /** Creates a new instance of PMCEntityCollector. User must supply an appropriate parser. */
    public PMCEntityCollector(XMLReader p) throws SAXException {
        parser = p;
        grabNextComment = false;
        entities = new HashMap();
        parser.setProperty("http://xml.org/sax/properties/lexical-handler", this);
        parser.setProperty("http://xml.org/sax/properties/declaration-handler", this);
    } // constructor

    // Public Class methods
    
    /**
     * Returns all the PMC entities in the previously processed document
     * as an XML instance. Caller must supply an OutputStream to which
     * the instance will be written.
     */
    public void getEntities(OutputStream os) {
        Iterator iter = entities.values().iterator();
        PMCEntity ent;
        OutputStreamWriter out;
        BufferedOutputStream bufferedOut;
        
        try {
           bufferedOut = new BufferedOutputStream(os);
           out = new OutputStreamWriter(bufferedOut, "UTF8");
           out.write("<?xml version='1.0' encoding='UTF-8' ?><entities>");
        
           while (iter.hasNext() ) {
              ent = (PMCEntity)iter.next();
              out.write("<entity ");
              out.write("name='" + escape(ent.getName()) + "' ");
              out.write("description='" + escape(ent.getDescription()) + "' ");
              out.write("type='" + escape(ent.getType()) + "' " );
              out.write("decimal-value='" + escape(ent.getDecimalValue()) + "' " );
              out.write("hex-value='" + escape(ent.getHexValue()) + "'/>");
           } // while
        
           out.write("</entities>");
           out.flush();
           out.close();
        } // try
        catch (Exception e) {
           System.err.print("Could not write to output");  
        } // catch
    }// getEntities
    
    /**
     * Parses supplied document and makes a list of all PMC entities
     */
    public void processDocument(String uri) {
       try{
          parser.parse(uri);
       } // try
       catch (Exception e) {
           System.err.println("Could not process document: " + e);
       } // catch
   } // processDocument
    
   // Private class methods
   
   /**
    * Escapes protected XML characters in content
    */
    private String escape(String str) {
       return str.replaceAll("&", "&amp;").replaceAll(">", "&gt;").replaceAll("<", "&lt;").replaceAll("\"", "&quot;").replaceAll("'","&apos;");    
    } // escape
   
    // DeclHandler methods
    
   /**
    * Grab internal entities that define ENTITYSTART and PCSTART strings.
    * Convert these into PMCEntities and store in a hashtable for later processing.
    */
    public void internalEntityDecl(String name, String value) throws SAXException {
     String mode = "UNKNOWN";
     String decValue = "";
     String hexValue = "";
     
     try {
        // Ignore parameter entities and any other entities that are
        // not defining special ent start and pc start values.
        if (!name.startsWith("%") 
           && (value.startsWith("_ENTITYSTART_#") 
              || value.startsWith("_PCSTART_#"))) { 
          StringBuffer temp = new StringBuffer(value);
          int prefix, suffix; // prefix = # chars in start string; suffix = # in end string
          
          if (value.startsWith("_ENTITYSTART_")) {
             prefix = 13; // _ENTITYSTART_
             suffix = 11; // _ENTITYEND_
             mode = "ENTITY";
          } // if
          else { // Must be PCSTART
             prefix = 9; // _PCSTART_
             suffix = 7; // _PCEND_
             mode="PRIVATECHARACTER";
          } // else
          
          temp.delete(0, prefix); // Remove the prefix
          temp.delete(temp.length() - suffix, temp.length()); // Remove the suffix
         
         // If starts with a #x then is already Hex--convert to dec   
         if (temp.toString().startsWith("#x")) {
            hexValue = temp.substring(2);
            decValue = Integer.toString(Integer.parseInt(hexValue, 16));
         } // if
         // Assume is decimal
         else {
            decValue = temp.substring(1);
            hexValue =  Integer.toHexString(Integer.parseInt(decValue));
         } // else
        } // if
        
        PMCEntity ent = new PMCEntity();
        ent.setName(name);
        ent.setDecimalValue(decValue.toString());
        ent.setHexValue(hexValue);
        ent.setType(mode);
        entities.put(name, ent);
        currentEntity = ent;
        grabNextComment = true;
     } // try
     catch (Exception e ) {System.err.print(e);};
    } // internalEntityDecl
    
    // LexicalReader methods
    
    /**
     * Grab comment if have recently visited an entity and are looking for
     * its description. Note: If an entity doesn't have a comment, then
     * this could mistakenly grab the next comment that appears in the
     * DTD.
     */
    public void comment (char[] text, int start, int length) throws SAXException {
      if (grabNextComment){  
         currentEntity.setDescription( new String(text, start, length));
         grabNextComment = false;
      } // if
   } // comment
  
    // do-nothing methods not needed in this example
    public void startDTD(String name, String publicId, String systemId) throws SAXException {}
    public void endDTD() throws SAXException {}
    public void attributeDecl(String eName, String aName, String type, String valueDefault, String value) throws SAXException {}  
    public void elementDecl(String name, String model) throws SAXException {}
    public void externalEntityDecl(String name, String publicId, String systemId) throws SAXException {}
    public void endEntity(String name) throws SAXException {}
    public void startCDATA() throws SAXException {}
    public void endCDATA() throws SAXException {}
    public void startEntity(String name) throws SAXException {} 
    
} // PMCEntityCollector
