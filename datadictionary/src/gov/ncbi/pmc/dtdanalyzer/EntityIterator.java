/*
 * EntityIterator.java
 *
 * Created on November 14, 2005, 12:48 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.Iterator;

/**
 *  Allows user to iterate over a collection of Entity objects
 *
 * @author  Demian Hess
 */
public class EntityIterator {
    
    private Iterator iterator; // Iterator to hold all entities
    
    /** 
     * Creates a new instance of EntityIterator 
     *
     * @param iter Iterator containing all entities
     */
    public EntityIterator(Iterator iter) {
        iterator = iter;
    }
    
    /**
     * Returns true if another Entity is available, false otherwise
     *
     * @return Flag indicating whether another Entity is available
     */    
    public boolean hasNext(){
        return iterator.hasNext();
    }
   
    /**
     * Returns the next available entity
     *
     * @return Next entity
     */    
    public Entity next(){
        return (Entity)iterator.next();
    }
    
}
