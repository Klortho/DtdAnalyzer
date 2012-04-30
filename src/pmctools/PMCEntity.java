/*
 * PMCEntity.java
 *
 * Created on January 17, 2005, 2:23 PM
 */

package pmctools;

/**
 * Holds PMC Entity information and provides getter and setter methods.
 * @author  Demian Hess
 */
public class PMCEntity {
    
    private String name,
                   decimalValue,
                   hexValue,
                   description,
                   type;
    /** Creates a new instance of PMCEntity */
    public PMCEntity() {
       name = "";
       decimalValue = "";
       hexValue = "";
       description = "";
       type = "";
    } // constructor
    
    // SETTER METHODS
    public void setName( String value ) {
        if (value != null)
           name = value;
    } // setName
    
    public void setDecimalValue( String value ) {
       if (value != null)
           decimalValue = value;
    } // setDecimalValue
    
    public void setHexValue( String value ) {
        if (value != null)
            hexValue = value;
    } // setHexValue
    
    public void setDescription( String value ) {
        if (value != null)
            description = value;
    } // setDescription
    
    public void setType( String value ) {
        if (value != null)
            type = value;
    } // setType
    
    // GETTER METHODS
    public String getName() {
        return name;
    } // getName
    
    public String getDecimalValue() {
        return decimalValue;
    } // getDecimalValue
    
    public String getHexValue() {
        return hexValue;
    } // getHexValue
    
    public String getDescription() {
        return description;
    } // getDescription
    
    public String getType() {
        return type;
    } // getType
} // PMCEntity
