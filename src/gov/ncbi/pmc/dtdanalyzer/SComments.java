/*
 * SComments.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Holds a collection of SComment objects and provides accessor methods.
 */
public class SComments {
    /**
     */
    private HashMap[] scomments;
    
    /**
     * Constructor
     */
    public SComments() {
        scomments = new HashMap[6];
        for (int i = 0; i < 6; ++i) {
            scomments[i] = new HashMap();
        }
    }
     
    /**
     * Adds an SComment to the collection
     *
     * @param scomment SComment to be added
     */
    public void addSComment( SComment sc ) {
        //System.err.println("type is " + sc.getType() +
        //    "scomments[0] is " + scomments[0]);
        scomments[sc.getType()].put(sc.getName(), sc);
    }

    /**
     * Get an SComment by its type and name
     */
    public SComment getSComment(int type, String name) {
        return (SComment) scomments[type].get(name);
    }

}
