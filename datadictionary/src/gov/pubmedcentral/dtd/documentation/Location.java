/*
 * Location.java
 *
 * Created on November 9, 2005, 3:36 PM
 */

package gov.pubmedcentral.dtd.documentation;

/**
 * Records where a declaration appears inside a DTD file. The public id
 * refers to the file's public id (if any); the system id refers to the file
 * name. Line number indicates the line number in the file where the 
 * declaration occurs.
 *
 * @author  Demian Hess
 */
public class Location {
    
    private String systemId = null;    
    private String publicId = null;    
    private int lineNumber = -1;
    
    /** Creates a new instance of Location */
    public Location() {
    }
    
    /**
     * Constructs instance using all supplied values. 
     *
     * @param sysId Filename of DTD; can be null if not known
     * @param pubId Public identifier of DTD; can be null
     * @param line Linenumber of declaration in DTD; should be -1 if unknown
     */
    public Location(String sysId, String pubId, int line){        
        setSystemId(sysId);
        setPublicId(pubId);
        setLineNumber(line);       
    }
    
    /**
     * Returns public identifier for the file containing the declaration. If no
     * id is available, returns null.
     *
     * @return Public identifier of the file.
     */
    public String getPublicId() {
        return publicId;        
    }

    /**
     * Returns the line number where the declaration occured within the DTD file.
     * Returns -1 if no number is available.
     *
     * @return Line number of declaration
     */
    public int getLineNumber() {
        return lineNumber;
    }
    
    /**
     * Returns the system name of the file containing the declaration.
     *
     * @return File name or null if none
     */
    public String getSystemId() {
        return systemId;
    } 
        
    /**
     * Sets line number of the declaration in the DTD file. Any value less
     * than 0 is normalized to -1.
     *
     * @param line Line number of the declaration
     */
    public void setLineNumber(int line) {
        if ( line < 0 ) 
            lineNumber = -1;
        else
            lineNumber = line;
    }
    
    /**
     * Sets public identifier of the DTD file containing the declaration.
     * 
     * @param pubId Public id of the dtd file
     */
    public void setPublicId(String pubId) {
        publicId = pubId;
    }
    
    /**
     * Sets value of the filename
     *
     * @param sysId Filename of the file containing the declaration
     */
    public void setSystemId(String sysId) {
        systemId = sysId;
    }
        
} // Location
