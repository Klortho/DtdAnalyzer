/*
 * Entities.java
 *
 * Created on November 14, 2005, 12:48 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Holds a collection of Entity objects and provides accessor methods.
 *
 * @author  Demian Hess
 */
public class Entities {
    private HashMap generalEntities = new HashMap(256);    // All "general" entities
    private HashMap parameterEntities = new HashMap(256);  // All parameter entities
    
    /**
     * Adds an entity to the collection 
     *
     * @param entity  Entity to add
     */    
    public void addEntity(Entity entity){
        switch (entity.getType()){
            case Entity.PARAMETER_ENTITY:
                parameterEntities.put(makeKey(entity), entity);
                break;
                
            default:
                generalEntities.put(makeKey(entity), entity);
                break;
        }
    }
    
    /**
     * @param name
     * @param type
     * @throws Exception
     * @return  */    
    public Entity getEntity(String name, int type) throws Exception 
    {
        if (type == Entity.PARAMETER_ENTITY) {
            return (Entity) parameterEntities.get(makeKey(name, type));
        }
        else if (type == Entity.GENERAL_ENTITY) {
            return (Entity) generalEntities.get(makeKey(name, type));
        }
        else throw new Exception( "Invalid Entity type");
    }
    
    /**
     * Returns all the non-parameter Entities declared in the DTD
     *
     * @return Iterator containing all non-parameter Entities 
     */    
    public EntityIterator getGeneralEntities(){
        return new EntityIterator(generalEntities.values().iterator());
    }    
    
    /**
     * Returns all parameter Entities declared in the DTD
     *
     * @return Iterator containing all parameter entities
     */    
    public EntityIterator getParameterEntities(){
        return new EntityIterator(parameterEntities.values().iterator());
    }

    /**
     * Creates the value that will serve as a key under which the Entity will be stored
     *
     * @param entity Entity for which a key is needed
     */
    private String makeKey(Entity entity) {
        return makeKey(entity.getName(), entity.getType());
    }

    /**
     * Creates the value that will serve as a key under which the Entity will be stored
     *
     * @param name Entity name
     * @param int Indicates whether a parameter or general entity
     */    
    private String makeKey(String name, int type ) {
        return type == Entity.PARAMETER_ENTITY ? "%" + name : name;
    }
}
