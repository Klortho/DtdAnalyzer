/*
 * ElementModelManager.java
 *
 * Created on February 5, 2005, 4:06 PM
 */

package pmctools;

import org.xml.sax.*;
import org.xml.sax.ext.*;
import org.xml.sax.helpers.XMLReaderFactory;
import java.io.*;
import java.util.*;

/**
 *
 * @author  Demian Hess
 */
public class ElementModelManager implements DeclHandler, LexicalHandler, ErrorHandler {
    private HashMap elements;
    private XMLReader parser;
    private int counter;
    private boolean finishedDTD;

    /**
     Creates a new instance of ElementModelManager

     *
     */
    public ElementModelManager(XMLReader p) throws SAXException {
        elements = new HashMap( 256 );
        parser = p;
        parser.setProperty("http://xml.org/sax/properties/declaration-handler", this);
        parser.setProperty("http://xml.org/sax/properties/lexical-handler", this);
    } // constructor

     /**
     * Parses supplied document and makes a list of all PMC entities
     */
    public void processDocument(String uri) {
       try{
		  finishedDTD = false;
		  counter = 0; // Reset the element counter
		  parser.setErrorHandler(this);
          parser.parse(uri);
          parser.setErrorHandler(null); // Clean up after self so parser can be reused by caller
       } // try
       catch (NullPointerException npe ) {
		   ; // ignore - normal error when handler set to null
       }
       catch (Exception e) {
           System.err.println("Could not process document: " + e);
           e.printStackTrace();
       } // catch
   } // processDocument

    /** Report an attribute type declaration.
     *
     * Method will capture attribute information and store it inside
     * a collection under the element name.
     *
     * <p>Only the effective (first) declaration for an attribute will
     * be reported.  The type will be one of the strings "CDATA",
     * "ID", "IDREF", "IDREFS", "NMTOKEN", "NMTOKENS", "ENTITY",
     * "ENTITIES", a parenthesized token group with
     * the separator "|" and all whitespace removed, or the word
     * "NOTATION" followed by a space followed by a parenthesized
     * token group with all whitespace removed.</p>
     *
     * <p>Any parameter entities in the attribute value will be
     * expanded, but general entities will not.</p>
     *
     * @param eName The name of the associated element.
     * @param aName The name of the attribute.
     * @param type A string representing the attribute type.
     * @param valueDefault A string representing the attribute default
     *        ("#IMPLIED", "#REQUIRED", or "#FIXED") or null if
     *        none of these applies.
     * @param value A string representing the attribute's default value,
     *        or null if there is none.
     * @exception SAXException The application may raise an exception.
     */
    public void attributeDecl(String eName, String aName, String type, String valueDefault,
       String value) throws SAXException {
       pmctools.Element e;
       pmctools.Attribute att = new pmctools.Attribute();
       att.setName(aName);
       att.setElementName(eName);
       att.setType(type);

       if ( valueDefault != null ) {
          att.setMode(valueDefault);
       }

       if ( value != null ) {
          att.setDefaultValue(value);
       }

        if ( elements.containsKey(eName)) {
           e = (pmctools.Element)elements.get(eName);
       }
       else {
           e = new pmctools.Element( eName );
           elements.put(eName, e);
       }

       e.addAttribute(att);

    } // attributeDecl

    /** Report an element type declaration.
     *
     * Captures element information and stores it. Includes:
     * element name, context, model. Note that in order to
     * get context information, method must scan the model
     * for names of child elements. The name of this element
     * then is entered in the context collection for each
     * of the children.
     *
     * Ignore #PCDATA and EMPTY
     * separators: , |
     * repetition: + ? *
     * groupers: ) (
     * delimiters should be " \n\t\r,|+?*()"
     *
     * <p>The content model will consist of the string "EMPTY", the
     * string "ANY", or a parenthesised group, optionally followed
     * by an occurrence indicator.  The model will be normalized so
     * that all parameter entities are fully resolved and all whitespace
     * is removed,and will include the enclosing parentheses.  Other
     * normalization (such as removing redundant parentheses or
     * simplifying occurrence indicators) is at the discretion of the
     * parser.</p>
     *
     * @param name The element type name.
     * @param model The content model as a normalized string.
     * @exception SAXException The application may raise an exception.
     */
    public void elementDecl(String name, String model) throws SAXException {
        pmctools.Element e;

        counter++; // Count how many elements there are so we know the order
                   // in which they are declared.

        if ( elements.containsKey( name ) ) {
           e = (pmctools.Element)elements.get( name );
        } // if
        else {
           e = new pmctools.Element( name );
           elements.put( name, e );
        } // else

        e.setModel(model);
        e.setDTDOrder( String.valueOf( counter ) );

        //  We're done if this has no children
        if ( model.equals("(#PCDATA)") || model.equals("EMPTY") ) {
           return; // we're done!!
        }

        // Otherwise, the hard part--need to tokenize the model!
        // Every element name needs to be added as an element and this
        // element needs to be added to the context
        StringTokenizer tokens = new StringTokenizer( model, " \n\t\r,|+?*()");
        pmctools.Element newElement;

        while ( tokens.hasMoreTokens() ) {
           String elName = tokens.nextToken();
           // Make sure this is really a token
           if ( (elName != "") && (! elName.equals("#PCDATA"))) {
              // Check if this element already exists
              if ( elements.containsKey( elName )) {
                  newElement = (pmctools.Element)elements.get( elName );
              } //if
              else {
                  // make a new element and add it since we need to store info
                  newElement = new pmctools.Element( elName );
                  elements.put( elName, newElement);
              } // else

              // Finally, add this parent element to the context of the element
              // identified in the model
              newElement.addContext(name);
           } // if
        } // while
    } // elementDecl

    /** Report a parsed external entity declaration.
     *
     * <p>Only the effective (first) declaration for each entity
     * will be reported.</p>
     *
     * @param name The name of the entity.  If it is a parameter
     *        entity, the name will begin with '%'.
     * @param publicId The declared public identifier of the entity, or
     *        null if none was declared.
     * @param systemId The declared system identifier of the entity.
     * @exception SAXException The application may raise an exception.
     * @see #internalEntityDecl
     * @see org.xml.sax.DTDHandler#unparsedEntityDecl
     */
    public void externalEntityDecl(String name, String publicId, String systemId) throws SAXException {
       // do nothing
    }

    /** Report an internal entity declaration.
     *
     * <p>Only the effective (first) declaration for each entity
     * will be reported.  All parameter entities in the value
     * will be expanded, but general entities will not.</p>
     *
     * @param name The name of the entity.  If it is a parameter
     *        entity, the name will begin with '%'.
     * @param value The replacement text of the entity.
     * @exception SAXException The application may raise an exception.
     * @see #externalEntityDecl
     * @see org.xml.sax.DTDHandler#unparsedEntityDecl
     */
    public void internalEntityDecl(String name, String value) throws SAXException {
        // do nothing
    }

    public void getInfo(java.io.OutputStream out) {
        Iterator iter = elements.values().iterator();
        pmctools.Element e;
        OutputStreamWriter writer;
        BufferedOutputStream bufferedOut;

        try {
           bufferedOut = new BufferedOutputStream(out);
           writer = new OutputStreamWriter(bufferedOut, "UTF8");
           writer.write("<?xml version='1.0' encoding='UTF-8' ?><elements>");

           while (iter.hasNext() ) {
              e = (pmctools.Element)iter.next();
              writer.write("<element ");
              writer.write("name='" + e.getName() + "' ");
              writer.write("dtdOrder='" + e.getDTDOrder() + "' ");
              writer.write("model='" + escape(e.getModel()) + "'");

              if ( e.getNote() != "" ) {
                 writer.write(" note='" + escape(e.getNote()) + "'");
			  } // if

			  if (e.getModelNote() != "" ){
                 writer.write(" modelNote='" + escape(e.getModelNote()) + "'");
			  }

			  if (e.getGroup() != "") {
                 writer.write(" group='" + escape(e.getGroup()) + "'");
			  }

              writer.write(">");

              HashMap attributes = e.getAttributes();

              // Write out the attributes, if any
              if ( ! attributes.isEmpty() ) {
                 writer.write("\n<attributes>\n");
                 Iterator i = attributes.values().iterator();
                 pmctools.Attribute a;
                 while (i.hasNext()){
                     a = (pmctools.Attribute)i.next();
                     writer.write("<attribute ");
                     writer.write("attName='");
                     writer.write(a.getName() + "' mode='" + escape(a.getMode()) + "' type='" + escape(a.getType()) + "'>");
                     if (a.getValue() != ""){
                        writer.write(escape(a.getValue()));
                     } // if
                     writer.write("</attribute>\n");
                 } // while
                 writer.write("</attributes>\n");
              } // if

              HashSet context = e.getContext();
              // Now write out the context
              writer.write("<context>\n");
              if ( ! context.isEmpty()) {
                 Iterator i = context.iterator();
                 String p;
                 while (i.hasNext()){
                     p = (String)i.next();
                     writer.write("<parent>" + p);
                     writer.write("</parent>\n");
                 } // while
              } // if
              else {
                 writer.write("<parent>DOCUMENT ROOT</parent>");
              } // else
              writer.write("</context>\n");

              writer.write("</element>\n");
           } // while
           writer.write("</elements>");
           writer.flush();
           writer.close();
        } // try
        catch (Exception ex) {
           System.err.println("Could not write to output");
        } // catch
    } // getInfo


    // ERROR HANDLER METHODS: only interested in fatal
    // errors as these may indicate that the DTD was
    // invalid and the information should be discarded.
    public void warning(SAXParseException exception) {
	  ; // do nothing
    }

    public void error(SAXParseException exception) {
      ; // do nothing
    }

    public void fatalError(SAXParseException exception) {
       // Clear out all elements because the information is probably incomplete
       if ( ! finishedDTD ) {
          elements.clear();
          System.err.println("Fatal Error: " + exception.getMessage());
          System.err.println(" at line " + exception.getLineNumber() + ", column " + exception.getColumnNumber());
          System.err.println(" in entity " + exception.getSystemId());
       }
    }


    // LEXICAL HANDLER METHODS
   public void startDTD(String name, String publicId, String systemId) throws SAXException {}

    /** Set a flag at the end of the DTD so we know to ignore any fatal exceptions  */
    public void endDTD() throws SAXException {
       finishedDTD = true;
    }

    public void startEntity(String name) throws SAXException {}
    public void endEntity(String name) throws SAXException {}
    public void startCDATA() throws SAXException {}
    public void endCDATA() throws SAXException {}

    /**
     Capture "pmc" comments. These will start with ~Name~. The elementName identifies
     which element the comment pertains to. The element name must be spelled correctly. Additionally, the
     comment MUST follow the element declaration to ensure that it has already been identified by the
     parser and stored in the hash table (this is to prevent bogus elements from appearing in the
     context table.

     Inside the comment, you must delimit your text as follows:
     ~note:text~  note text to be attached to the element
     ~modelNote:text~ text to be attached to the model note attribute
     ~group: text~ which group this should be identified with

     So start with ~keyword: and end with another ~

     All non delimited text will be ignored.
    */
    public void comment (char[] text, int start, int length) throws SAXException {

       String fullComment = new String(text, start, length).trim();
       String elementName;
       StringTokenizer tokens;
       pmctools.Element element;

       // Make sure this is a "pmc" comment
       if ( fullComment.trim().startsWith("~")) {
          // Make sure this is a known element name
          int nextTilde = fullComment.indexOf('~', 1);
          elementName = fullComment.substring(1, nextTilde).trim();

          if (elements.containsKey(elementName)) {
			 element = (pmctools.Element)elements.get(elementName);
             tokens = new StringTokenizer( fullComment.substring(nextTilde + 1), "~" );

             while ( tokens.hasMoreTokens() ) {
                String nextComment = tokens.nextToken().trim();

                if ( nextComment.startsWith("note:") ) {
                    element.setNote(nextComment.substring("note:".length()).trim());
				}

                if ( nextComment.startsWith("modelNote:") ) {
                    element.setModelNote(nextComment.substring("modelNote:".length()).trim());
				}

                if ( nextComment.startsWith("group:") ) {
                    element.setGroup(nextComment.substring("group:".length()).trim());
				}

			 } // while

		  } // if

	   } // if
    }

   // Private class methods

   /**
    * Escapes protected XML characters in content
    */
    private String escape(String str) {
       return str.replaceAll("&", "&amp;").replaceAll(">", "&gt;").replaceAll("<", "&lt;").replaceAll("\"", "&quot;").replaceAll("'","&apos;");
    } // escape

} // ElementModelManager
