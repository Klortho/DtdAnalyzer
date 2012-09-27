/*
 * XMLWriter.java
 *
 * Created on November 14, 2005, 5:25 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

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
    /* * cfm, removed this.
     * Location of the DTD used for declarations. This will be written into
     * each instance as an internal DTD.
     */
    //public final static String DTD_LOCATION="/gov/pubmedcentral/etc/dtd-information.dtd";
    
    private ModelBuilder model;          // Holds all the model information
    private Elements elements;           // All element declarations
    private Attributes attributes;       // All attribute declarations
    private Entities entities;           // All entity declarations
    private SComments scomments;         // All structured comments
    private StringWriter buffer;         // Buffer to hold XML instance as its written
    private String internalDTD = null;   // Holds the internal DTD
    
    /**
     * Creates a new instance of XMLWriter 
     *
     * @param mb Contains all model information
     */
    public XMLWriter(ModelBuilder mb) {
        // Retrieve the internal DTD
      /* cfm, removed this - I hate DTDs!
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
      */
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
        if ( internalDTD != null ) {
            writeDOCTYPE();
        }
        
        buffer.write("<declarations>");       
        if ( model != null ){
            elements = model.getElements();
            attributes = model.getAttributes();
            entities = model.getEntities();
            scomments = model.getSComments();
            
            processDtdModule();
            
            // Process modules
            //processModules();
            
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
     * Output the top-level <dtd> element, with information and annoations about the 
     * main DTD module
     */
    private void processDtdModule() {
        DtdModule dtd = model.getDtdModule();
        openStartTag("dtd");
          makeAttribute("relSysId", dtd.getRelSysId());
          makeAttribute("systemId", dtd.getSystemId());
          makeAttribute("publicId", dtd.getPublicId());
        closeStartTag();
          // Process any dtd-level annotations, if there are any
          SComment dtdAnnotations = scomments.getSComment(SComment.MODULE, dtd.getRelSysId());
          if (dtdAnnotations != null) {
              processSComment(dtdAnnotations);
          }
        makeEndTag("dtd");
    }
    
   /**
    * Escapes protected XML characters in content
    */
    private String escape(String str) {
       return str.replaceAll("&", "&amp;")
                 .replaceAll(">", "&gt;")
                 .replaceAll("<", "&lt;")
                 .replaceAll("\"", "&quot;")
                 .replaceAll("'","&apos;");
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
     * Helper method to write a complete start tag, for an element that
     * won't get any attributes
     */
    private void makeStartTag(String name) {
        buffer.write("<" + name + ">");
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
     * Helper method closes the start tag
     */
    private void closeStartTag(){
        buffer.write(">");        
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
                }
                
                // Write the annotations for this attribute
                processSComment(scomments.getSComment(SComment.ATTRIBUTE, attNames[i]));
                
                makeEndTag("attribute");
           }//for
           buffer.write("</attributes>");
        }//if
    }
    
    /**
     * This outputs the <annotations> element corresponding to a SComment object.
     * If the sc argument is null, then this outputs nothing.
     */
    private void processSComment(SComment sc) {
        processSComment(sc, "");
    }
    
    /**
     * This version of processSComment puts a @level attribute on the <annotations> element,
     * if it is not an empty string.
     */
    private void processSComment(SComment sc, String level) {
        if (sc == null) return;

        openStartTag("annotations");
        if (!level.equals("")) {
            makeAttribute("level", level);
        }
        closeStartTag();
        
        Iterator secNames = sc.getSectionNameIterator();
        while ( secNames.hasNext() ) {
            String secName = (String) secNames.next();
            openStartTag("annotation");
            makeAttribute("type", secName);
            closeStartTag();
            buffer.write(sc.getSection(secName));
            makeEndTag("annotation");
        }
        makeEndTag("annotations");
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
    private void processAllElements() {
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
          makeAttribute("dtdOrder", Integer.toString(e.getDTDOrder()));
        closeStartTag();
          writeDeclaredInInfo( e.getLocation() );  
          writeContentModel( e.getContentModel() );
          writeContextInfo(model.getContext(e.getName()));
          processSComment(scomments.getSComment(SComment.ELEMENT, e.getName()));
        makeEndTag("element");                
    }
    
    /**
     * Creates the "content-model" element
     */
    private void writeContentModel(ContentModel cm) {
        openStartTag("content-model");
          makeAttribute("spec", cm.getSpec());
          makeAttribute("minified", cm.getMinifiedModel());
          makeAttribute("spaced", makeSpacedModel(cm));
        closeStartTag();

        String spec = cm.getSpec();
        if (spec.equals("mixed")) {
            Iterator kids = cm.getKids().iterator();
            while (kids.hasNext()) {
                String kid = (String) kids.next();
                buffer.write("<child>" + kid + "</child>");
            }
        }
        else if (spec.equals("element")) {
            NameChoiceSeq cs = cm.getChoiceOrSeq();
            writeNameChoiceSeq(cs);
        }
        makeEndTag("content-model");
    }

    /**
     * Constructs the @spaced version of the content model, for pretty-printing.
     */
    private String makeSpacedModel(ContentModel cm) {
        String spec = cm.getSpec();
        
        String sm;
        if (spec.equals("any") || spec.equals("empty")) {
            sm = cm.getMinifiedModel();
        }
        else if (spec.equals("text")) {
            sm = "( #PCDATA )";
        }
        else if (spec.equals("mixed")) {
            sm = "( #PCDATA | ";
            Iterator kids = cm.getKids().iterator();
            while (kids.hasNext()) {
                String kid = (String) kids.next();
                sm += kid + " ";
                if (kids.hasNext()) sm += "| ";
            }
            sm += ")";
        }
        else {  // element content
            sm = makeSpacedModel(cm.getChoiceOrSeq());
        }
        return sm;
    }
    
    /**
     * Constructs the spaced-model version specifically for a name, choice, or sequence,
     * within 'element' type content models.
     */
    private String makeSpacedModel(NameChoiceSeq cs) {
        String sm;
        int type = cs.getType();
        if (type == 0) {   // name
            sm = cs.getName();
        }
        else {
            sm = "( ";
            Iterator kids = cs.getKids().iterator();
            while (kids.hasNext()) {
                NameChoiceSeq kid = (NameChoiceSeq) kids.next();
                sm += makeSpacedModel(kid);
                if (kids.hasNext()) {
                    if (type == 1) sm += " | ";
                    else sm += ", ";
                }
            }
            sm += " )";
        }
        
        // Add the qualifier if there is one.
        sm += cs.getQ();
        return sm;
    }
    
    /**
     * Creates either an <element>, <choice>, or <seq>, in the detailed
     * content-model section.  Recurses through the children.
     */
    private void writeNameChoiceSeq(NameChoiceSeq cs) {
        int type = cs.getType();
        String q = cs.getQ();
        String tagName = (type == 0) ? "child" :
                         (type == 1) ? "choice" :
                                       "seq";
        openStartTag(tagName);
          if (!q.equals("")) {
              makeAttribute("q", q);
          }
        closeStartTag();
        if (type == 0) {
            buffer.write(cs.getName());
        }
        else {
            Iterator kids = cs.getKids().iterator();
            while (kids.hasNext()) {
                NameChoiceSeq kid = (NameChoiceSeq) kids.next();
                writeNameChoiceSeq(kid);
            }
        }
        makeEndTag(tagName);
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
        
        if (ent.getSystemId() != null) {
            makeAttribute("systemId", ent.getSystemId());
            makeAttribute("relSysId", ent.getRelSysId());
            if (ent.getType() == Entity.PARAMETER_ENTITY) {
                makeAttribute("included", Boolean.toString(ent.getIncluded()));
            }
        }
        if (ent.getPublicId() != null) {
            makeAttribute("publicId", ent.getPublicId());
        }
        
        closeStartTag();        
 
        if (ent.getLocation() != null) {
            writeDeclaredInInfo(ent.getLocation());
        }
        writeValueInfo(ent);
        
        // Only for parameter entities will we output the level="reference" attribute
        int type = ent.getType();
        String level = type == Entity.PARAMETER_ENTITY ? "reference" : "";
        processSComment(scomments.getSComment(ent.getType(), ent.getName()), level);
        
        // Again, only for parameter entities, if it's external, then also put out the
        // module-level annotations
        if (type == Entity.PARAMETER_ENTITY && ent.isExternal()) {
            processSComment(scomments.getSComment(SComment.MODULE, ent.getRelSysId()), "module");
        }

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
    
    /**
     * Outputs the <modules> section at the top-level.
     */
    private void processModules() {
      /*
        Iterator iter = modules.getIterator();
        
        if ( iter.hasNext() ){
            makeStartTag("modules");
            
            while(iter.hasNext()) {
                Module m = (Module) iter.next();
                openStartTag("module");
                  makeAttribute("name", m.getName());
                  makeAttribute("systemId", m.getSystemId());
                  makeAttribute("publicId", m.getPublicId());
                closeStartTag();
                // Write any annotations for this module, if there are any
                processSComment(scomments.getSComment(SComment.MODULE, m.getName()));
                makeEndTag("module");
            }
            
            makeEndTag("modules");
        }//if 
      */
    }
     
}
