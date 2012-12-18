/*
 * DtdSpecifier.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.io.File;
import java.io.StringReader;
import org.xml.sax.InputSource;

/**
 * Holds information about a DTD, taken from command-line arguments.
 * This is a helper class for App.  For each DTD, in addition to the type and
 * the identifier itself, this holds:
 *   - title
 * But not the list of roots or the document processor - those are too
 * application-specific.
 */
public class DtdSpecifier {
    
    public int idType;     // either 'd', 's', or 'p'
    public String idValue;  // filename, system identifer, or public identifier.
    public String title;
    
    public InputSource dummyXml;
    
    /**
     * Create a new instance.
     */
    public DtdSpecifier() {
    }
    
    /**
     * Validate, and where appropriate, create a dummy XML document.
     * At this point, idType and idValue should be valid values.
     */
    public void validate() {
    
        // If the type is "d", verify that it is a valid file
        if (idType == 'd') {
            File xml = new File(idValue);
            if ( ! xml.exists() || ! xml.isFile() ) {
                System.err.println("Error: " + xml.toString() + " is not a file" );
                System.exit(1);
            }
        }
        
        // Otherwise, construct a dummy XML document
        else {
            String xmlFileStr = "<!DOCTYPE root ";
            if (idType == 's') {
                xmlFileStr += "SYSTEM \"" + idValue + "\">";
            }
            else {
                xmlFileStr += "PUBLIC \"" + idValue + "\" \"\">";
            }
            xmlFileStr += "\n\n<root/>\n";

            dummyXml = new InputSource(new StringReader(xmlFileStr));
        }
    }
}
