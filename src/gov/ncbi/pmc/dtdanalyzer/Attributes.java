/*
 * Attributes.java
 *
 * Created on November 9, 2005, 5:23 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Holds a collection of Attribute objects and provides accessor methods
 *
 * @author  Demian Hess
 */
public class Attributes {
    
    private HashMap atts = new HashMap(256);             // Holds all attributes
    private HashMap attsByElement = new HashMap(256);    // Organizes attributes by element name
    private HashMap attsByName = new HashMap(256);       // Organizes attributes by name
    private HashMap attNames = new HashMap(256);         // Unique set of attribute names
        
    /**
     * Adds Attribute to the collection
     *
     * @param attribute Attribute to be added
     */    
    public void addAttribute( Attribute attribute ){
        atts.put( makeKey(attribute), attribute );     
        
        // Keep a list of all unique names
        if (! attNames.containsKey(attribute.getName())){
            attNames.put(attribute.getName(), attribute.getName());
        }//if
        
        // Store this attribute under the name of the element
        if ( attsByElement.containsKey(attribute.getParent())){
            Collection elementAtts = (Collection)attsByElement.get(attribute.getParent());
            elementAtts.add(attribute);
        }
        // First time this element is seen: need to create container
        else{
            Collection elementAtts = new HashSet();
            elementAtts.add(attribute);
            attsByElement.put(attribute.getParent(), elementAtts);
        }
        
        // Also store this attribute under its name; the value in the
        // collection will be another collection since it is 
        // possible for several attributes to have the same name in different
        // elements
        if (attsByName.containsKey(attribute.getName())){
            Collection namedAtts = (Collection)attsByName.get(attribute.getName());
            namedAtts.add(attribute);          
        }//if
        // First time this attribute name is seen: need to create a container
        else{
            Collection namedAtts = new HashSet();
            namedAtts.add(attribute);
            attsByName.put(attribute.getName(), namedAtts);
        }//else
    }

    /**
     * Returns a list of unique attribute names in the collection
     *
     * @return  List of attribute names 
     */    
    public String[] getAllAtttributeNames(){
        String[] values = new String[0];
        if ( ! attNames.isEmpty()){
            values = (String [])attNames.keySet().toArray(values);
        }//if
        
        return values;
    }

    /**
     * Returns the specified Attribute using the element name and the attribute
     * name; null if no matching attribute is in the collection.
     *
     * @param elementName Element name
     * @param attributeName Attribute name
     * @return Matching attribute or null 
     */    
    public Attribute getAttribute( String elementName, String attributeName ){
        return (Attribute)atts.get( this.makeKey(elementName, attributeName) );
    }    
        
    /**
     * Returns an iterator of all the Attributes in the collection
     *
     * @return All attributes in the collection  
     */    
    public AttributeIterator getAttributeIterator(){
        return new AttributeIterator( atts.values().iterator() );
    }

    /**
     * Returns all attributes declared for a specific element. Attributes will
     * be packaged in an AttributeIterator. If no attributes are available, 
     * the iterator will be empty.
     *
     * @param eName Element name
     * @return  Iterator containing all matching attributes
     */    
    public AttributeIterator getAttributesByElementName( String eName ){
        if ( attsByElement.containsKey( eName ) ){
            Collection attributes = (Collection)attsByElement.get( eName );
            return new AttributeIterator(attributes.iterator());
        }//if
        else {
           return new AttributeIterator( new HashMap().values().iterator());   
        }//if     
    }

    /**
     * Returns all attributes that have the specified name. Note that attributes
     * can be declared with the same name as long as they are located in different
     * elements. Each attribute returned will thus have a different element name. 
     *
     * @param aName Attribute name
     * @return  Iterator containing all matching attributes
     */    
    public AttributeIterator getAttributesByName( String aName ){
        if ( attsByName.containsKey( aName ) ){
            Collection attributes = (Collection)attsByName.get( aName );
            return new AttributeIterator(attributes.iterator());
        }//if
        else{
            return new AttributeIterator( new HashMap().values().iterator()); 
        }//else
    }
           
    /**
     * @param attribute
     * @return  */    
    public boolean hasAttribute( Attribute attribute ){
        return atts.containsKey( makeKey( attribute ) );
    }
    
    /**
     * Indicates whether a specific attribute is in the collection. 
     *
     * @param elementName Name of the parent element
     * @param attributeName Name of the attribute
     * @return  True if in the collection, false otherwise 
     */    
    public boolean hasAttribute( String elementName, String attributeName ){
        return atts.containsKey( makeKey( elementName, attributeName ) );
    }
    
    /**
     * Creates the key used to access an attribute in the underlying
     * HashMap. Key is based on the element name plus the attribute name.
     * The key should match Attribute.toString(), but this method does
     * not rely on that value in case we want to change the way the key is
     * formed. 
     *
     * @param eName Name of the parent element
     * @param aName Name of the attribute
     * @return  Key to access the attribute 
     */    
    private String makeKey( String eName, String aName ){
       return eName + "/@" + aName;   
    }
 
    /**
     * Creates the key used to access an attribute in the underlying
     * HashMap. Key is based on the element name plus the attribute name.
     * The key should match Attribute.toString(), but this method does
     * not rely on that value in case we want to change the way the key is
     * formed. 
     *
     * @param att Attribute for which a key is required
     * @return  Key to access the attribute 
     */        
    private String makeKey( Attribute att ){
       return makeKey( att.getParent(), att.getName() );   
    }
} // Attributes
