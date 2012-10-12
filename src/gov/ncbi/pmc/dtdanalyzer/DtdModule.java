/*
 * DtdModule.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.xml.sax.Locator;
import java.net.*;

/**
 * Holds information (the public and system identifier) of the main DTD module
 */
public class DtdModule {
    private String publicId;
    private String systemId;
    private String relSysId;
    private URI baseUri;
        
    /**
     * Constructor.
     */    
    public DtdModule( Locator locator ) {
        publicId = locator.getPublicId();
        systemId = locator.getSystemId();
        
        int lastSlash = systemId.lastIndexOf("/");
        relSysId = systemId.substring(lastSlash + 1);
        String parentDir = systemId.substring(0, lastSlash);
        
        try {
            baseUri = new URI(parentDir);
        }
        catch (URISyntaxException e) {
            // I don't think this should ever happen, so let's just report it and keep going.
            System.err.println("ERROR trying to make a URI from dtd system id: " + e.getMessage());
        }
        
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
    
    /**
     * Get the relative system ID of the DTD module itself.  In other words, just the
     * filename portion of it's URI.
     */
    public String getRelSysId() {
        return relSysId;
    }
    
    /**
     * Get the base URI.  This is the "directory" in which the DTD module resides.
     */
    public URI getBaseUri() {
        return baseUri;
    }
    
    /**
     * Relativize some other URI to the baseUri here.
     */
    public String relativize(String uri) {
        if (baseUri == null) {
            return uri;
        }
        else {
            try {
                return baseUri.relativize(new URI(uri)).toString();
            }
            catch (URISyntaxException e) {
                // If there's any problem here, just return the original string
                return uri;
            }
        }
    }
}
