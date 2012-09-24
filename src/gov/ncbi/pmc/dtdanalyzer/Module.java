/*
 * Module.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.xml.sax.Locator;

/**
 * Holds a collection of information about the modules in the DTD.
 */
public class Module {
    private String publicId;
    private String systemId;
    private String name;
        
    /**
     * Construcor
     */    
    public Module( Locator locator ) {
        publicId = locator.getPublicId();
        systemId = locator.getSystemId();
    }

    /**
     * Set the name
     */
    public void setName(String n) {
        name = n;
    }
    
    /**
     * Get the name
     */
    public String getName() {
        return name;
    }
    /**
     * Get the public ID
     */
    public String getPublicId() {
        return publicId;
    }
    /**
     * Get the system ID
     */
    public String getSystemId() {
        return systemId;
    }
}
