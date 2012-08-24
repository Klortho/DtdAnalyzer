/*
 * Attribute.java
 *
 * Created on February 5, 2005, 4:44 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

/**
 *
 * @author  Demian Hess
 */
public class Attribute {
    
    private String name="";
    
    private String elementName="";
    
    private String mode="#IMPLIED";
    
    private String defaultValue="";
    
    private String type="";
    
    String getName() {
        return name;
    }
    
    String getElementName() {
        return elementName;
    }
    
    String getType() {
        return type;
    }
    
    String getMode() {
       return mode;
    }
    
    String getValue() {
       return defaultValue;
    }
    
    void setName(java.lang.String name) {
       this.name = name; 
    }
    
    void setElementName(java.lang.String name) {
       elementName = name;
    }
    
    void setType(java.lang.String type) {
       this.type = type;
    }
    
    void setMode(java.lang.String mode) {
       this.mode = mode;
    }
    
    void setDefaultValue(java.lang.String value) {
       defaultValue = value;
    }
}
