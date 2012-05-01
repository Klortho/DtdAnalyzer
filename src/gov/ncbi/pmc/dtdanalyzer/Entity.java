/*
 * Entity.java
 *
 * Created on January 17, 2005, 2:23 PM
 */

package pmctools;

/**
 * Holds  Entity information and provides getter and setter methods.
 * @author  Demian Hess
 */
public class Entity {
    
    private String name,
                   entValue;
    /** Creates a new instance of Entity */
    public Entity() {
       name = "";
       entValue = "";
    } // constructor
    
    // SETTER METHODS
    public void setName( String value ) {
        if (value != null)
           name = value;
    } // setName
    
    public void setValue( String value ) {
       if (value != null)
           entValue = value;
    } // setDecimalValue
    
    
    // GETTER METHODS
    public String getName() {
        return name;
    } // getName
    
    public String getValue() {
        return entValue;
    } // getValue
    
} // Entity
