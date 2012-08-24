/*
 * EndOfDTDException.java
 *
 * Created on November 14, 2005, 1:55 PM
 */

package gov.pubmedcentral.dtd.documentation;

/**
 * Signals that the parser has reached the end of the DTD
 *
 * @author  Demian Hess
 */
public class EndOfDTDException extends org.xml.sax.SAXException {
    
    /** Creates a new instance of EndOfDTDException */
    public EndOfDTDException() {
        super("Finished processing DTD");
    }    
}
