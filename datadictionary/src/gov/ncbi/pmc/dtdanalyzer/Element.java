/*
 * Element.java
 *
 * Created on November 9, 2005, 5:18 PM
 */

package gov.pubmedcentral.dtd.documentation;

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
    
    private String name = null;                   // Element name
    private String model = null;                  // Content model
    private int dtdOrder = 0;                     // Order declared in the DTD
    private Location location;                    // Location inside the DTD
    
    /**
     * Creates a new instance of the class
     *
     * @param eName Element name
     * @param eModel Content model
     * @param order  Order in which this declaration appeared in the DTD 
     */    
    public Element( String eName, String eModel, int order ){
       name = eName;
       model = eModel;
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
     * Returns the content model for the element declaration
     *
     * @return  Content model */    
    public String getModel(){
        return model;
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
     * Returns a Location object that indicates the location of the element
     * declaration inside the DTD.
     *
     * @param loc  Location information 
     */    
    public void setLocation( Location loc ){
        location = loc;
    }    
}
