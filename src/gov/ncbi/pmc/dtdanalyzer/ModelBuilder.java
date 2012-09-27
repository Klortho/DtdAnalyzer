/*
 * ModelBuilder.java
 *
 * Created on November 14, 2005, 2:45 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import java.io.*;

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

    /**
     * Creates a new instance of ModelBuilder.  
     *
     * @param _dtdInfo Provides all the information about the DTD, that was gathered during
     * parsing.
     * @param _dtdTitle If not null, this will override any title that was given in the
     * top-level DTD structured comment.
     */
    public ModelBuilder(DTDEventHandler _dtdInfo, String _dtdTitle) {
        dtdInfo = _dtdInfo;
        elements = _dtdInfo.getAllElements();
        attributes = _dtdInfo.getAllAttributes();
        entities = _dtdInfo.getAllEntities();
        scomments = _dtdInfo.getAllSComments();

        // The DTD title will either come from the parsed content (from _dtdInfo) or else 
        // from the command-line param (from _dtdTitle).
        if (_dtdTitle != null) {
            dtdTitle = _dtdTitle;
        }
        else {
            SComment dtdSComment = scomments.getSComment(SComment.MODULE, getDtdModule().getRelSysId());
            if (dtdSComment != null) {
                dtdTitle = dtdSComment.getTitle();
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
                  }//if
                  //Doesn't exist yet, so create a collection for it
                  else{
                     parents = new HashMap(256);
                     contexts.put(elName, parents);
                  }//else
                  
                  // Now update the context for this element
                  if ( parents.containsKey( name )) {
                      // do nothing since we already know about it
                  } //if
                  else {
                      parents.put(name, name);
                  } // else
               } // if
            } // while            
        } //else
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
        } // while        
    }
}
