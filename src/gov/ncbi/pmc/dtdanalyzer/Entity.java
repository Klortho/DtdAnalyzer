/*
 * Class.java
 *
 * Created on November 14, 2005, 11:58 AM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.net.*;

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
    
    /**
     * A static value for the base URI, from which all relSysId's are computed.
     */
    private static URI baseUri;
    
    private String name = null;        // Entity name
    private int type;                  // Whether is a parameter or general entity
    private Location location = null;  // Declaration location
    private String systemId = null;    // System id specified in the declaration (for external entities)
    private String relSysId = null;    // System id relative to the system id of the main DTD (for
                                       // external entities)
    private String publicId = null;    // Public id specified in the declaration (for external entities)
    private String value = null;       // "Replacement text" of the entity
    private boolean included = false;  // Only for external parameter entities; this is set to true when
                                       // we know that the entity has been included in the DTD (as
                                       // opposed to just being declared).  For other types of
                                       // entities, this is not used.
    
    /**
     * Set the baseUri, used in computing relSysId.
     */
    public static void setBaseUri(URI base) {
        baseUri = base;
    }
    
    /**
     * Creates an instances of the class
     *
     * @throws Exception thrown if the entity type is not valid
     */
    public Entity(String n, int t) throws Exception{
        name = n;
        type = t;

        // Make sure type is valid
        if (t != GENERAL_ENTITY && t != PARAMETER_ENTITY) {
            throw new Exception("Invalid Entity declaration: unknown type value: " + t);
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
     * Get the value of the relative system identifier.
     */
    public String getRelSysId() {
        return relSysId;
    }
    
    /**
     * Returns type, which will be either be Entity.PARAMETER_ENTITY (1) or
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
     * Returns true if this is an external entity
     */
    public boolean isExternal() {
        return systemId != null;
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
     * Sets the system id and relSysId.
     *
     * @param sysId System id 
     */    
    public void setSystemId(String sysId){
        systemId = sysId;
        if (baseUri != null) {
            try {
                relSysId = baseUri.relativize(new URI(sysId)).toString();
            }
            catch (URISyntaxException e) {
                // FIXME: what to do here?
            }
        }
    }
    
    /**
     * Sets the value
     *
     * @param v Entity value
     */    
    public void setValue(String v){
       value = v;   
    }
    
    /**
     * Set the included flag.  For external parameter entities only, this will be called 
     * with an argument of 'true' when we actually see it (in the startEntity handler).
     */
    public void setIncluded(boolean i) {
        included = i;
    }
    
    /**
     * Get the value of the included flag.  This should only be considered to be valid for
     * external parameter entities.
     */
    public boolean getIncluded() {
        return included;
    }
}
