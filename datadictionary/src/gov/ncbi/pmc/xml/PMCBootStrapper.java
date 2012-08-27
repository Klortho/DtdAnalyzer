/*
 * PMCBootStrapper.java
 *
 * Created on November 23, 2005, 9:04 AM
 */

package gov.ncbi.pmc.xml;

import java.util.HashMap;
import org.xml.sax.InputSource;

/**
 *
 * Identifies location of the DTD needed to parse an OASIS catalog. Do
 * to a quirk in the implementation org.apache.xml.resolver.helpers.BootstrapResolver,
 * the Public ID used for the oasis DTD does not actually match the Public Id 
 * used at PubMedCentral (or, indeed, most other places). As a result, the BootStrapper 
 * does not know how to parse the catalog. This is a custom implementation that allows
 * a calling application to map the OASIS DTD location to additional PUBLIC or SYSTEM
 * ids. Instantiate this in your code, add the correct mappings, and then set your
 * CatalogManager to use this implementation rather than the default BootstrapResolver.
 * When you create your CatalogResolver, you can then provide the properly customized
 * CatalogManager.
 *
 * @author  Demian Hess
 */
public class PMCBootStrapper extends org.apache.xml.resolver.helpers.BootstrapResolver {
    private HashMap entries = new HashMap(32);
    
    /** Creates a new instance of PMCBootStrapper */
    public PMCBootStrapper() {
    }
    
    /**
     * Maps a specific PUBLIC or System ID to the specifed location.
     * The mapping should be a complete path (and should probably point
     * to the location of the OASIS DTD provided in the resolver.jar file).
     *
     * @param value Public or System Id to map
     * @param mapping Location of the DTD
     */    
    public void addMapping(String value, String mapping){
        if ( value != null && mapping != null ){
            entries.put(value, mapping);
        }//if
    }    
    
    /**
     * Resolves entity by first checking for any customized mappings, and then
     * by handing off to the base class.
     *
     * @param publicId Public Id to resolve
     * @param systemId System id to resolve
     * @return The entity wrapped in an InputSource
     */    
    public InputSource resolveEntity(String publicId, String systemId){
        InputSource returnValue = null;
        
        // For bootstrapping, we prefer the public id
        if ( publicId != null && entries.containsKey(publicId)){
            returnValue = new InputSource((String)entries.get(publicId));
        } //if
        // Next try the system id
        else if ( systemId != null && entries.containsKey(systemId) ){
            returnValue = new InputSource((String)entries.get(systemId));
        }//else if
        // Hand off to the super class
        else {
            returnValue = super.resolveEntity( publicId, systemId );
        } // else
           
        return returnValue;
    }
}
