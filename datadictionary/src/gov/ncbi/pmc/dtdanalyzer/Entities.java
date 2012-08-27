/*
 * Entities.java
 *
 * Created on November 14, 2005, 12:48 PM
 */

package gov.pubmedcentral.dtd.documentation;

import java.util.*;

/**
 * Holds a collection of Entity objects and provides accessor methods
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
    public Entity getEntity(String name, int type) throws Exception{
        Entity entity;
        
        switch (type){
            case Entity.PARAMETER_ENTITY:
                entity = (Entity)parameterEntities.get(makeKey(name, type));
                break;
            
            case Entity.GENERAL_ENTITY:
                 entity = (Entity)generalEntities.get(makeKey(name, type));
                break;
                
            default:
                throw new Exception( "Invalid Entity type");
        }                
        return entity;
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
    private String makeKey(Entity entity){
        String key;
        
        switch ( entity.getType() ){
            case Entity.PARAMETER_ENTITY:
                key = "%" + entity.getName();
                break;
            default:
                key = entity.getName();
        }        
        return key;              
    }

    /**
     * Creates the value that will serve as a key under which the Entity will be stored
     *
     * @param name Entity name
     * @param int Indicates whether a parameter or general entity
     */    
    private String makeKey(String name, int type ){
        String key;
        
        switch ( type ){
            case Entity.PARAMETER_ENTITY:
                key = "%" + name;
                break;
            default:
                key = name;
        }        
        return key;              
    }
}
