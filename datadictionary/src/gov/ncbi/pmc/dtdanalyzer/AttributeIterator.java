/*
 * AttributeIterator.java
 *
 * Created on November 10, 2005, 9:23 AM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.Iterator;

/**
 * Allows user to iterate over a collection of Attribute objects
 *
 * @author  Demian Hess
 */
public class AttributeIterator {
    Iterator iterator; // Iterator containing all the attributes
    
    /**
     * Creates a new instance of AttributeIterator
     * 
     * @param it Iterator containing Attribute objects.
     */
    AttributeIterator( Iterator it ) {
        iterator = it;
    }
    
    /**
     * True if there is another Attribute in the collection 
     *
     * @return Indicates if there is another Attribute */    
    public boolean hasNext(){
        return iterator.hasNext();
    }
    
    /**
     * Returns the next Attribute in the collection 
     *
     * @return  Next attribute */    
    public Attribute next(){
        return (Attribute)iterator.next();
    }
}
