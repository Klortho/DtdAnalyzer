/*
 * Modules.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.xml.sax.Locator;
import java.net.*;

/**
 * Holds a collection of information about the modules in the DTD.
 */
public class Modules {
    Locator locator;
    private HashMap modules = new HashMap();
    
    // top-level module, which is the main external subset.
    Module dtd;
    
    // The URI of the "directory" in which the DTD is.  This is used to relativize all
    // of the other system IDs, in order to create the names of each module.
    URI baseUri;
    
    // This is the last Module object that we created
    Module current;

    /**
     * Constructor.
     */
    public Modules(Locator loc) {
        locator = loc;
    }

    /**
     * Called when the locator points at the main external subset.  This is used to set
     * the dtd and baseUri members above.
     */
    public void setDtd() {
        String key = locator.getSystemId();
        dtd = new Module(locator);
        current = dtd;
        modules.put(key, dtd);
        
        int lastSlash = key.lastIndexOf("/");
        String parentDir = key.substring(0, lastSlash);
        dtd.setName(key.substring(lastSlash + 1));
        //System.err.println("parentDir is " + parentDir);
        try {
            baseUri = new URI(parentDir);
        }
        catch (URISyntaxException e) {
            System.err.println("ERROR trying to make a URI from dtd system id: " + e.getMessage());
            // FIXME:  what to do here?
        }
    }

    /**
     * Checks to see if we already have a module corresponding to the locator at
     * this point.  If not, a new one is created and added.
     */    
    public void checkModule() {
        String key = locator.getSystemId();
        if (modules.containsKey(key)) return;
        
        //System.err.println("*** new module:  " + key);
        Module m = new Module(locator);
        current = m;
        
        try {
            URI uri = new URI(key);
            URI name = baseUri.relativize(uri);
            //System.err.println("  baseUri = " + baseUri + "\n  uri = " + uri + "\n  name = " + name);
            m.setName(name.toString());
            
        }
        catch (URISyntaxException e) {
            // FIXME:  what to do here?
        }

        modules.put(key, m);
    }

    /**
     * Get an iterator over the Module objects.
     */
    public Iterator getIterator() {
        return modules.values().iterator();
    }
    
    /**
     * Get the current Module (the last one that we created)
     */
    public Module getCurrent() {
        return current;
    }
}
