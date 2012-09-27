/*
 * Element.java
 *
 * Created on November 9, 2005, 5:18 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Holds all the information associated with an element declaration in the DTD.
 * Class does not hold any attribute information, but this can be accessed through
 * the {@link Attribute} and {@link Attributes} classes. <code>Element</code>
 * also provides no "context" information (ie, the
 * places where a given element can occur), but this information is available
 * through the {@link ModelBuilder} class. 
 *
 * @author  Demian Hess
 */
public class Element {
    
    private String name = null;     // Element name
    private ContentModel cmodel;    // Content model
    private int dtdOrder = 0;       // Order declared in the DTD
    private Location location;      // Location inside the DTD
    
    private boolean isRoot = false;  // True if this is one of a set of possible roots
    private boolean reachable = true;
    
    /**
     * Creates a new instance of the class
     *
     * @param eName Element name
     * @param eModel Content model
     * @param order  Order in which this declaration appeared in the DTD 
     */    
    public Element( String eName, String eModel, int order ){
       name = eName;
       cmodel = new ContentModel(eModel);
       dtdOrder = order;
    }
    
    /**
     * Returns the number indicating the order of this element declaration
     * relative to other elements in the DTD
     *
     * @return  Declaration order 
     */    
    public int getDTDOrder(){
        return dtdOrder;
    }
    
    /**
     * Returns the location of the element declaration in the DTD (file name and line number)
     *
     * @return  Declaration location 
     */    
    public Location getLocation(){
        return location;
    }      
    
    /**
     * Returns the ContentModel object associated with this element definition.
     *
     * @return Content model object
     */
    public ContentModel getContentModel() {
        return cmodel;
    }

    /**
     * Returns the minified content model string for the element declaration
     *
     * @return  Content model string */    
    public String getMinifiedModel(){
        return cmodel.getMinifiedModel();
    }
    
    /**
     * Returns the name of the element
     *
     * @return  Element name 
     */    
    public String getName(){
        return name;
    }    
        
    /**
     * Sets the location for this element declaration inside the DTD.
     *
     * @param loc  Location information 
     */    
    public void setLocation( Location loc ){
        location = loc;
    }
    
    /**
     * Sets the value of the isRoot flag to true.
     */
    public void setIsRoot() {
        isRoot = true;
    }
    
    /**
     * Returns the value of the isRoot flag.
     */
    public boolean isRoot() {
        return isRoot;
    }
    
    /**
     * Sets the reachable flag to false.
     */
    public void setUnreachable() {
        reachable = false;
    }
    
    /**
     * Returns the value of the reachable flag.
     */
    public boolean isReachable() {
        return reachable;
    }
}

