/*
 * Class.java
 *
 * Created on November 14, 2005, 11:58 AM
 */

package gov.ncbi.pmc.dtdanalyzer;

/**
 * Holds all the information associated with an entity declaration in the DTD. Class
 * includes constants to indicate whether an entity is a parameter or a general
 * entity.
 *
 * @author  Demian Hess
 */
public class Entity {
    /**
     * An entity with this "type" is a parameter entity
     */
    public static final int PARAMETER_ENTITY = 1;
    
    /**
     * An entity with this "type" is a general entity
     */
    public static final int GENERAL_ENTITY = 2;
    
    private String name = null;           // Entity name
    private Location location = null;     // Declaration location
    private String systemId = null;       // System id specified in the declaration (for external entities)
    private String publicId = null;       // Public id specified in the declaration (for external entities)
    private String value = null;          // "Replacement text" of the entity
    private int type;                     // Whether is a parameter or general entity
        
    /**
     * Creates an instances of the class
     *
     * @throws Exception thrown if the entity type is not valid
     */
    public Entity(String n, int t) throws Exception{
        name = n;
        type = t;
        
        // Make sure type is valid
        switch (t){
            case GENERAL_ENTITY:
            case PARAMETER_ENTITY:
                break;
            default:
                throw new Exception("Invalid Entity declaration: unknown type value");
        }        
    }
        
    /**
     * Returns location of the declaration
     *
     * @return  Declaration location
     */    
    public Location getLocation(){
        return location;
    }
    
    /**
     * Returns entity name
     *
     * @return Name of entity */    
    public String getName(){
        return name;
    }
    
    /**
     * Returns public id or null if none available
     *
     * @return Public id or null
     */    
    public String getPublicId(){
        return publicId;
    }
    
    /**
     * Returns system id or null if none available
     *
     * @return System id or null 
     */    
    public String getSystemId(){
        return systemId;
    }
    
    /**
     * Returns type, which will be either Entity.PARAMETER_ENTITY (1) or
     * Entity.GENERAL_ENTITY (2)
     *
     * @return Entity type */    
    public int getType(){
        return type;
    }
    
    /**
     * Returns entity value or null if none available
     *
     * @return Entity value or null
     */    
    public String getValue(){
        return value;
    }
    
    /**
     * @param loc  */    
    public void setLocation(Location loc){
        location = loc;
    }
    
    /**
     * @param pubId  */    
    public void setPublicId(String pubId){
        publicId = pubId;
    }
    
    /**
     * Sets the system id
     *
     * @param sysId System id */    
    public void setSystemId(String sysId){
        systemId = sysId;
    }
    
    /**
     * Sets the value
     *
     * @param v Entity value
     */    
    public void setValue(String v){
       value = v;   
    }
}
