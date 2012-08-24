/*
 * Element.java
 *
 * Created on February 5, 2005, 4:55 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import  java.util.*;

/**
 *
 * @author  Demian Hess
 */
public class Element {
    private HashMap attributes;
    private HashSet context;
    private String name;
    private String model;
    private String dtdOrder;
    private String note;
    private String modelNote;
    private String group;

    /** Creates a new instance of Element */
    public Element(String elName) {
        name = elName;
        model = "EMPTY";
        note="";
        modelNote="";
        group="";
        dtdOrder = "";
        context = new HashSet();
        attributes = new HashMap();
    } // constructor

    String getName() {
        return name;
    }

    String getModel() {
        return model;
    }

    String getNote() {
		return note;
	}

	String getModelNote() {
		return modelNote;
	}

	String getGroup() {
		return group;
	}

	String getDTDOrder() {
		return dtdOrder;
	}

    HashMap getAttributes() {
       return attributes;
    }

    HashSet getContext() {
        return context;
    }

    void setName(java.lang.String elementName) {
        name = elementName;
    }

    void setModel(java.lang.String model) {
        this.model = model;
    }

    void setNote( String value) {
		note = value;
	}

	void setModelNote(String value) {
		modelNote = value;;
	}

	void setGroup(String value) {
		group = value;
	}

	void  setDTDOrder(String value) {
		dtdOrder = value;
	}

    void addContext(java.lang.String elementName) {
       context.add( elementName );
    }

    void addAttribute(gov.ncbi.pmc.dtdanalyzer.Attribute attribute) {
        if ( ! attributes.containsKey( attribute.getName() )) {
            attributes.put( attribute.getName(), attribute );
        } // if
    }
}
