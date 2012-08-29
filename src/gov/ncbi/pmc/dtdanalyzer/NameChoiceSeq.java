/*
 * NameChoiceSeq.java
 *
 * Created on November 9, 2005, 3:36 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * Stores one occurrence of either a name, choice, or sequence in the content
 * model.  Each comes with an optional quantifier.  
 * If this is a name, then type == 0, name will be non-empty, and kids will be null.
 * If it is a choice (type == 1) or seq (type == 2) then name will be empty and
 * kids will have a valid Vector object.
 */
public class NameChoiceSeq {
    
    private int type;           // One of 0 = name; 1 = choice; 2 = seq.
    private String name = "";   // Only non-empty if type == 0.
    private String q = "";      // One of "" = none; "?", "*", or "+"
    
    // Only choice or seq can have kids, so don't instantiate this automatically.
    private Vector kids;
    
    /** 
     * Creates a new instance of NameChoiceSeq.  Since this doesn't have a String
     * argument, we'll assume it is a choice. 
     */
    public NameChoiceSeq() {
        type = 1;
        kids = new Vector();
    }
    
    /**
     * Construct with a name String.
     */
    public NameChoiceSeq(String n) {  
        type = 0;      
        name = n;
    }
    
    /**
     * Returns the name for name types; empty string otherwise.
     */
    public String getName() {
        return name;
    }
    
    /**
     * Set the type.  You can only change from a choice to seq or vice versa;
     * not allowed to change from name to one of the others.
     */
    public void setType(int t) throws Exception {
        if (type == 0 && t != 0 || t < 0 || t > 2) {
            throw new Exception("Bad type change!");
        }
        type = t;
    }
    
    /**
     * Get the type
     */
    public int getType() {
        return type;
    }

    /**
     * Set the quantifier string.  You can only set this once, and it must be to one
     * of the non-empty values "?", "*", or "+".
     */
    public void setQ(char newQ) throws Exception {
        if ( !q.equals("") || 
             !( newQ == '?' || newQ == '+' || newQ == '*' ) ) 
        {
            throw new Exception("Bad quantifier change!");
        } 
        q = Character.toString(newQ);
    }
    
    /**
     * Get the quantifier string
     */
    public String getQ() {
        return q;
    }
    
    /**
     * Add a new child name/choice/seq to this one.
     */
    public void addKid(NameChoiceSeq k) {
        kids.addElement(k);
    }

    /**
     * Get the kids; this should only be called if type is 1 or 2 (choice or seq)
     */
    public Vector getKids() {
        return kids;
    }
}
