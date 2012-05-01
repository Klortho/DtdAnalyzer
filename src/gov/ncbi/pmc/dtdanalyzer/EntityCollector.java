/*
 * EntityCollector.java
 *
 * Created on January 17, 2005, 2:16 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.ext.*;
import java.io.*;
import java.util.*;

/**
 * Responsible for processing an XML instance and returning all the 
 * entities in a new XML instance.
 *
 * @author  Demian Hess
 */
public class EntityCollector implements DeclHandler {
    private HashMap entities;
    private gov.ncbi.pmc.dtdanalyzer.Entity currentEntity;
    private XMLReader parser;
    private boolean grabNextComment;
    
    /** Creates a new instance of EntityCollector. User must supply an appropriate parser. */
    public EntityCollector(XMLReader p) throws SAXException {
        parser = p;
        grabNextComment = false;
        entities = new HashMap();
        parser.setProperty("http://xml.org/sax/properties/declaration-handler", this);
    } // constructor

    // Public Class methods
    
    /**
     * Returns all the entities in the previously processed document
     * as an XML instance. Caller must supply an OutputStream to which
     * the instance will be written.
     */
    public void getEntities(OutputStream os) {
        Iterator iter = entities.values().iterator();
        gov.ncbi.pmc.dtdanalyzer.Entity ent;
        OutputStreamWriter out;
        BufferedOutputStream bufferedOut;
        
        try {
           bufferedOut = new BufferedOutputStream(os);
           out = new OutputStreamWriter(bufferedOut, "UTF8");
           out.write("<?xml version='1.0' encoding='UTF-8' ?><entities>");
        
           while (iter.hasNext() ) {
              ent = (gov.ncbi.pmc.dtdanalyzer.Entity)iter.next();
              out.write("<entity ");
              out.write("name='" + escape(ent.getName()) + "' ");
              out.write("value='" + escape(ent.getValue()) + "'/>");
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
     * Parses supplied document and makes a list of all entities
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
    * Grab internal entities and convert these into Entities and store in a hashtable for later processing.
    */
    public void internalEntityDecl(String name, String value) throws SAXException {

     try {
        // Ignore parameter entities 
        if (!name.startsWith("%")) { 

        Entity ent = new Entity();
        ent.setName(name);
        ent.setValue(value);
	entities.put(name, ent);
	} //if
     } // try
     catch (Exception e ) {System.err.print(e);};
    } // internalEntityDecl
    

  
    // do-nothing methods not needed in this example
    public void attributeDecl(String eName, String aName, String type, String valueDefault, String value) throws SAXException {}  
    public void elementDecl(String name, String model) throws SAXException {}
    public void externalEntityDecl(String name, String publicId, String systemId) throws SAXException {}

} // EntityCollector
