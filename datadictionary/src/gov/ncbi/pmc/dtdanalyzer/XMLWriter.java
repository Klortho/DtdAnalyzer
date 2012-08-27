/*
 * XMLWriter.java
 *
 * Created on November 14, 2005, 5:25 PM
 */

package gov.pubmedcentral.dtd.documentation;

import java.util.*;
import java.net.*;
import java.io.*;

/**
 * Creates UTF-8 XML representation of the DTD content model. Class
 * depends on the {@see ModelBuilder} class, which provides all information
 * about the DTD content model.
 *
 * @author  Demian Hess
 */
public class XMLWriter {
    /**
     * Location of the DTD used for declarations. This will be written into
     * each instance as an internal DTD.
     */
    public final static String DTD_LOCATION="/gov/pubmedcentral/etc/dtd-information.dtd";
    
    private ModelBuilder model;          // Holds all the model information
    private Elements elements;           // All element declarations
    private Attributes attributes;       // All attribute declarations
    private Entities entities;           // All entity declarations
    private StringWriter buffer;         // Buffer to hold XML instance as its written
    private String internalDTD = null;   // Holds the internal DTD
    
    /**
     * Creates a new instance of XMLWriter 
     *
     * @param mb Contains all model information
     */
    public XMLWriter(ModelBuilder mb) {
        // Retrieve the internal DTD
        try{
            InputStream is = this.getClass().getResourceAsStream(DTD_LOCATION);
            InputStreamReader isr = new InputStreamReader(is);
            BufferedReader br = new BufferedReader(isr);
            StringWriter sw = new StringWriter();
            String line;
            while (  (line = br.readLine()) != null ){                
                sw.write(line + "\r\n");   
            }//while   
            internalDTD = sw.toString();
        }//try
        catch (Exception e){
            //Couldn't read the dtd; report but otherwise continue
            System.err.println("Could not process the DTD. The XML will not have an internal DTD declared.");
        }//catch
        model = mb;
        buildXML();
    }
   
    /**
     * Creates an XML instance based on the information supplied by the ModelBuilder
     */
    private void buildXML(){ 
        buffer = new StringWriter();
        buffer.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        // Write out a DOCTYPE and internal DTD if one is available
        if ( internalDTD != null ){
            writeDOCTYPE();
        }//if
        buffer.write("<declarations>");       
        if ( model != null ){
            elements = model.getElements();
            attributes = model.getAttributes();
            entities = model.getEntities();
            
            // Make elements
            processAllElements();
            
            // Make attributes
            processAllAttributes();
            
            // Make entities
            processAllEntities();
        }//if        
        buffer.write("</declarations>");
        buffer.flush();    
    }
    
    /**
     * Helper method closes the start tag
     */
    private void closeStartTag(){
        buffer.write(">");        
    }
    
   /**
    * Escapes protected XML characters in content
    */
    private String escape(String str) {
       return str.replaceAll("&", "&amp;").replaceAll(">", "&gt;").replaceAll("<", "&lt;").replaceAll("\"", "&quot;").replaceAll("'","&apos;");
    } // escape
    
    /**
     * Returns an XML representation of the DTD content model. XML is returned 
     * as an InputStreamReader so that the caller can, if needed, extract the
     * original encoding, which is UTF-8.
     *
     * @return UTF-8 encoded reader
     */    
    public InputStreamReader getXML(){
        ByteArrayInputStream bais = null;
        InputStreamReader isr = null;
        
        // Create InputStreamReader using encoding that matches the encoding 
        // declaration in the XML instance
        try{
            bais = new ByteArrayInputStream( buffer.toString().getBytes("UTF8") ); 
            isr = new InputStreamReader( bais, "UTF8" );
        }
        catch (UnsupportedEncodingException e){
            //should never happen (hint)
        }      
        return isr;
    }
    
    /**
     * Helper methods writes an attribute to the buffer
     *
     * @param name Attribute name
     * @param value Attribute value
     */
    private void makeAttribute(String name, String value){
        buffer.write( " " + name + "=\"" + escape(value) + "\"");
    }
    
    /**
     * Helper methods writes an end tag to the buffer
     *
     * @param name Tag name
     */
    private void makeEndTag(String name){
        buffer.write( "</" + name + ">");       
    }
    
    /**
     * Helper method starts writing an start tag to the buffer. Note
     * that the start tag does not have a closing angle bracket because 
     * the user may want to write attributes.
     *
     * @param name Tag name
     */
    private void openStartTag(String name){
        buffer.write("<" + name);        
    }

    /**
     * Iterates over all attribute declarations to create the "attributes"
     * element.
     */
    private void processAllAttributes(){
        String [] attNames = attributes.getAllAtttributeNames();   
       
        if ( attNames.length > 0){
           buffer.write("<attributes>");
           for (int i = 0; i < attNames.length; i++){
                openStartTag("attribute");
                makeAttribute("name", attNames[i]);
                closeStartTag();
                AttributeIterator atts = attributes.getAttributesByName(attNames[i]);
                while (atts.hasNext()){               
                    writeDeclarationInfo(atts.next());
                }//while
                makeEndTag("attribute");
           }//for
           buffer.write("</attributes>");
        }//if
    }
     
    /**
     * Iterates over all entity declarations to creates the "entities" element
     */
    private void processAllEntities(){
        EntityIterator entit = entities.getParameterEntities();
        
        if ( entit.hasNext()){
            buffer.write("<parameterEntities>");
                while (entit.hasNext()){
                    writeEntityInfo(entit.next());
                }//while
            buffer.write("</parameterEntities>");
        }
        
        // It's unlikely that any general entities have been declared
        entit = entities.getGeneralEntities();        
        if ( entit.hasNext() ){
            buffer.write("<generalEntities>");
                while (entit.hasNext()){
                    writeEntityInfo(entit.next());
                }//while
            buffer.write("</generalEntities>");            
        }
    }
    
    /**
     * Iterates over all element declarations to create the "elements" element
     */
    private void processAllElements(){
        ElementIterator iter = elements.getElementIterator();
        
        if ( iter.hasNext() ){
            buffer.write("<elements>");
            
            while(iter.hasNext()){
                writeElementInfo(iter.next());
            } //while
            
            buffer.write("</elements>");
        }//if 
    }
   
    /**
     * Helper  creates a "attribute" element
     */
    private void writeAttributeInfo( Attribute att ){
        openStartTag("attribute");
        makeAttribute("name", att.getName());
        makeAttribute("type", att.getType());
        if ( att.getMode() != null ){
            makeAttribute("mode", att.getMode());
        }//if
        
        if ( att.getDefaultValue() != null){
            makeAttribute("defaultValue", att.getDefaultValue());
        }//if        
        
        closeStartTag();        
        writeDeclaredInInfo( att.getLocation() );        
        makeEndTag("attribute");
    }
    
    /**
     * Helper creates a "contextInfo" element
     */
    private void writeContextInfo( String[] context ){
        if (context.length > 0){
            buffer.write("<context>");
            for (int i = 0; i < context.length; i++ ){
                writeParentInfo( context[i] );
            }//for
            buffer.write("</context>");
        }//if
    }
    
    /**
     * Creates a "declarationInfo" element
     */
    private void writeDeclarationInfo(Attribute att){
        openStartTag("attributeDeclaration");
        makeAttribute("element", att.getParent());
        makeAttribute("type", att.getType());
        if ( att.getDefaultValue() != null ){
            makeAttribute("defaultValue", att.getDefaultValue());
        }//if
        if ( att.getMode() != null ){
            makeAttribute("mode", att.getMode());
        }//if               
        closeStartTag();
        writeDeclaredInInfo(att.getLocation());
        makeEndTag("attributeDeclaration");
    }
    
    /**
     * Creates a "declaredIn" element 
     */
    private void writeDeclaredInInfo( Location loc ){
        openStartTag("declaredIn");
        makeAttribute("systemId", loc.getSystemId());
                
        if ( loc.getPublicId() != null ){
            makeAttribute("publicId", loc.getPublicId());
        }//if
                
        if ( loc.getLineNumber() > 0 ){
            makeAttribute("lineNumber", Integer.toString(loc.getLineNumber()));
        }//if
                
        closeStartTag();               
        makeEndTag("declaredIn");        
    }
    
    /**
     * Outputs the DOCTYPE
     */
    private void writeDOCTYPE(){
        buffer.write("<!DOCTYPE declarations [\n");
        buffer.write(internalDTD);
        buffer.write("\n]>\n");
    }
    
    /**
     * Create "element" element
     */
    private void writeElementInfo( Element e ){               
        openStartTag("element");
        makeAttribute("name", e.getName());
        makeAttribute("model", e.getModel());
        makeAttribute("dtdOrder", Integer.toString(e.getDTDOrder()));
        closeStartTag();                
        writeDeclaredInInfo( e.getLocation() );  
        writeContextInfo(model.getContext(e.getName()));        
        makeEndTag("element");                
    }

    /**
     * Creates "parent" element
     */
    private void writeParentInfo(String name){
        openStartTag("parent");
        makeAttribute("name", name);
        closeStartTag();
        makeEndTag("parent");
    }
    
    /**
     * Creates "entity" element
     */
    private void writeEntityInfo(Entity ent){
        openStartTag("entity");
        
        makeAttribute("name", ent.getName());
        
        if (ent.getSystemId() != null){
            makeAttribute("systemId", ent.getSystemId());
        }
        
        if (ent.getPublicId() != null){
            makeAttribute("publicId", ent.getPublicId());
        }
        
        closeStartTag();        
 
        if (ent.getLocation() != null){
            writeDeclaredInInfo(ent.getLocation());
        }
        
        writeValueInfo(ent);
        
        makeEndTag("entity");
    }        
    
    /**
     * Creates "value" element for an entity if the value
     * is not null.
     *
     * @param ent Entity
     */
    private void writeValueInfo(Entity ent){
         if (ent.getValue() != null){
            openStartTag("value");
            closeStartTag();
            buffer.write(escape(ent.getValue()));
            makeEndTag("value");
        }//if   
    }
}
