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
     * Marks a comment as belonging to the dtd as a whole.
     */
    public static final int DTD = 0;
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
     * Marks a comment as belonging to an individual module.
     */
    public static final int MODULE = 3;
    /**
     * Marks a comment as belonging to an element
     */
    public static final int ELEMENT = 4;
    /**
     * Marks a comment as belonging to an attribute.
     */
    public static final int ATTRIBUTE = 5;

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
     * List of sections, indexed by section name.
     */
    private HashMap sections = new HashMap();
    
    /**
     * Creates a new instance of an SComment.  The argument is the identifer
     * such as "<split>" or "!dtd".  It is parsed first to determine the target type.
     */
    public SComment(String identifier) {
        if (identifier.startsWith("%") && identifier.endsWith(";")) {
            type = PARAMETER_ENTITY;
            name = identifier.substring(1, identifier.length() - 1);
            //System.err.println("Adding parameter entity " + name);
        }
        else if (identifier.startsWith("&") && identifier.endsWith(";")) {
            type = GENERAL_ENTITY;
            name = identifier.substring(1, identifier.length() - 1);
        }
        else if (identifier.equals("!dtd")) {
            type = DTD;
            name = "";   // There can be only one.
        }
        else if (identifier.equals("!module")) {
            type = MODULE;
        }
        else if (identifier.startsWith("<") && identifier.endsWith(">")) {
            type = ELEMENT;
            name = identifier.substring(1, identifier.length() - 1);
        }
        else if (identifier.startsWith("@")) {
            type = ATTRIBUTE;
            name = identifier.substring(1);
        }
        else {
            // FIXME:  Throw an exception here.
        }
    }
    
    public int getType() {
        return type;
    }
    public void setName(String n) {
        name = n;
    }
    
    public String getName() {
        return name;
    }
    
    public void addSection(String name, String text) {
        sections.put(name, text);
    }
    
    public String getSection(String name) {
        return (String) sections.get(name);
    }

    /**
     * Returns an iterator of all the names of the sections in this structured 
     * comment
     */    
    public Iterator getSectionNameIterator() {
        return sections.keySet().iterator();
    }
}
