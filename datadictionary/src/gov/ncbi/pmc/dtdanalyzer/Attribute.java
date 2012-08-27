/*
 * Attribute.java
 *
 * Created on November 9, 2005, 4:47 PM
 */

package gov.pubmedcentral.dtd.documentation;

/**
 * Holds attribute declaration information
 *
 * @author  Demian Hess
 */
public class Attribute {
    
    private String parent = null;         // Element name
    private String name = null;           // Attribute name
    private String mode = null;           // Attribute mode (#IMPLIED, etc)
    private String type = null;           // Content model (CDATA, etc)
    private String defaultValue = null;   // Default value 
    private Location location = null;     // Where declaration occured
    
    /**
     * Creates a new instance of Attribute
     *
     * @param eName Element name
     * @param aName Attribute name
     * @param type  Type or content model of attribute (CDATA, enumeration, etc)
     */
    public Attribute(String eName, String aName, String type) {
        parent = eName;
        name = aName;
        this.type = type;
    }
    
    /**
     * Default value for attribute if declared; null otherwise
     *
     * @return  Declared default for attribute or null 
     */    
    public String getDefaultValue() {
        return defaultValue;
    }
    
    /**
     * Returns location of the attribute declaration
     *
     * @return  Declaration location */    
    public Location getLocation(){
        return location;
    }
    
    /**
     * Attribute mode (eg, #IMPLIED or #REQUIRED) or null if none declared
     *
     * @return Declared mode, such as #IMPLIED, or null if none declared
     */
    public String getMode() {
        return mode;
    }
    
    /**
     * Attribute name
     *
     * @return Name of attribute 
     */    
    public String getName() {
        return name;
    }
    
    /**
     * Name of the attribute's parent element. Although an element name
     * is required in every attribute declaration, the element itself
     * does not need to be declared in the DTD.
     *
     * @return Element name
     */    
    public String getParent() {
        return parent;
    }
    
    /**
     * Type of the attribute, which is essentially the content model (CDATA, 
     * enumerated list, etc).
     *
     * @return Attribute type
     */    
    public String getType() {
        return type;
    }
    
    /**
     *  Assign a default value to the attribute
     *
     * @param value  Default value 
     */    
    public void setDefaultValue( String value ){
        defaultValue = value;    
    }
    
    /**
     * Sets location of the attribute declaration
     *
     * @param l  Declaration location
     */    
    public void setLocation(Location l) {
        location = l;
    }
    
    /**
     * Sets the mode (such as #IMPLIED) of the attribute
     *
     * @param m  Attribute mode
     */    
    public void setMode( String m ){
        mode = m;
    }
        
    /**
     * String value of the attribute will be xpath expression for reaching
     * the attribute--namely the element name plus the axis step to reach the
     * attribute.
     *
     * @return Element name and attribute name
     */    
    public String toString(){       
        return getParent() + "/@" + getName();       
    }
} //Attribute
