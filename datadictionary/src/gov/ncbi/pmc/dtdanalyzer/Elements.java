/*
 * Elements.java
 *
 * Created on November 10, 2005, 5:11 PM
 */

package gov.pubmedcentral.dtd.documentation;

import java.util.*;

/**
 * Holds a collection of Element objects and provides accessor methods
 *
 * @author  Demian Hess
 */
public class Elements {
    private HashMap elements = new HashMap(256);  // Collection holds all elements
    
    /**
     * Adds an Element to the collection. A null value can be added.
     *
     * @param element  Element to add
     */    
    public void addElement(Element element){
        elements.put(element.getName(), element);
    }
    
    /**
     * Returns an element with the specified name; returns null if nothing available.
     *
     * @param name Name of the requested element
     * @return  Element or null if nothing available 
     */    
    public Element getElement(String name){
       return (Element)elements.get(name);   
    }
    
    /**
     * Returns an iterator containing all elements in the collection
     *
     * @return Iterator of all elements
     */    
    public ElementIterator getElementIterator(){
       return new ElementIterator(elements.values().iterator());   
    }
    
    /**
     * Indicates wether an element with the specified name is present in the 
     * collection.
     *
     * @param name Element name
     * @return Whether or not element is present
     */    
    public boolean hasElement( String name ){
       return elements.containsKey(name);   
    }  
}
