/*
 * ElementIterator.java
 *
 * Created on November 10, 2005, 5:09 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Allows user to iterate over a collection of Element objects
 *
 * @author  Demian Hess
 */
public class ElementIterator {
    private Iterator iterator;  // Iterator containing all the elements
    
    /** Creates a new instance of ElementIterator */
    public ElementIterator(Iterator it) {
        iterator = it;
    }
    
    /**
     * Indicates whether there are more Elements in the collection
     *
     * @return True if more Elements; false otherwise
     */    
    public boolean hasNext(){
        return iterator.hasNext();
    }
    
    /**
     * Returns the next available Element in the collection
     *
     * @return Next Element in the collection */    
    public Element next(){
        return (Element)iterator.next();
    }
}
