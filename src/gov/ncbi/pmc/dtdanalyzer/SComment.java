/*
 * SComments.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Holds a single instance of a structured comment ("scomment") from the DTD.
 */
public class SComment {
    /**
     * Marks a comment that applies to a parameter entity definition.
     * For consistency, make sure this matches the definition in Entity.java.
     */
    public static final int PARAMETER_ENTITY = 1;
    /**
     * Marks a comment that applies to a general entity definition.
     * For consistency, make sure this matches the definition in Entity.java.
     */
    public static final int GENERAL_ENTITY = 2;
    /**
     * Marks a comment as belonging to the dtd as a whole.
     */
    public static final int DTD = 3;
    /**
     * Marks a comment as belonging to an individual module.
     */
    public static final int MODULE = 4;
    /**
     * Marks a comment as belonging to an element
     */
    public static final int ELEMENT = 5;
    /**
     * Marks a comment as belonging to an attribute.
     */
    public static final int ATTRIBUTE = 6;

    /**
     * My type, one of the above integer constants.
     */
    private int type;
    
    /**
     * My name.  This is from the identifier after the special characters are
     * stripped away.  E.g. if the identifier is "<element>", the name is "element". 
     */
    private String name;
    
    
    /**
     * Creates a new instance of an SComment.  The argument is the identifer
     * such as "<split>" or "!dtd".  It is parsed first to determine the target type.
     */
    public SComment(String identifier) {
        if (identifier.startsWith("%") && identifier.endsWith(";")) {
            type = PARAMETER_ENTITY;
        }
        else if (identifier.startsWith("&") && identifier.endsWith(";")) {
            type = GENERAL_ENTITY;
        }
        else if (identifier.equals("!dtd")) {
            type = DTD;
        }
        else if (identifier.equals("!module")) {
            type = MODULE;
        }
        else if (identifier.startsWith("<") && identifier.endsWith(">")) {
            type = ELEMENT;
        }
        else if (identifier.startsWith("@")) {
            type = ATTRIBUTE;
        }
        else {
            // FIXME:  Throw an exception here.
        }
        
    }
    

}
