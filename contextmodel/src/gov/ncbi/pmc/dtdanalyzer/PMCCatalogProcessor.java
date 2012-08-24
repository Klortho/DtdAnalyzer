package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.helpers.*;
import java.util.*;

/**
PMCCatalogProcessor is responsible for reading an XML catalog of PUBLIC/SYSTEM ids and
returning a hashmap of all the key/value pairs. The catalog must conform to
the OASIS XML catalog model, but MUST NOT contain a DOCTYPE unless the DTD is
located in the same directory as the catalog.
*/
public class PMCCatalogProcessor extends DefaultHandler implements ErrorHandler {

   private String base;        // Base directory added to all URIs so that the system id is fully qualified
   private XMLReader parser;   // SAX parser used to read the catalog
   private HashMap ents;       // Holds all key/value pairs

   /**
   Default constructor creates a SAX parser and registers class to handle all content.
   If a parser cannot be created, an error message is output, but otherwise
   the class is unaffected. All attempts to resolve entities will result in a
   null value being returned, thus forcing the calling XMLReader to fallback to
   default entity processing.
   */
   public PMCCatalogProcessor() {
      try {
	     parser = XMLReaderFactory.createXMLReader();
	     parser.setContentHandler(this);
	     parser.setErrorHandler(this);
	  } // try
	  catch (SAXException e){
	     System.err.println("Could not create instance of SAX parser: " + e);
	  } // catch
      ents =  new HashMap(64); // Set size to 64 as this is expected to be the max number of ids
      base = "";
   } // constructor

   // ------------------- DefaultHandler METHODS -------------------

   /**
   Handle elements--for each type of element, calls appropriate helper method to
   add information to the hash map.
   */
   public void startElement(String namespaceURI, String localName,
      String qualifiedName, Attributes atts) {

      if (localName.equals("group")) {
         processGroup(atts);
      } //if

      if (localName.equals("public")) {
	     processPublicId(atts);
      } // if

      if (localName.equals("system")) {
         processSystemId(atts);
      } // if
   } // startElement

   // -------------------- ErrorHandler METHODS ---------------------

   public void warning(SAXParseException exception) {
      System.err.println("Warning while processing catalog: " + exception);
   } //	warning

   public void error(SAXParseException exception) {
      System.err.println("Validity errors while processing catalog: " + exception);
   } // error

   public void fatalError(SAXParseException exception) throws SAXParseException {
      throw exception;
   } // fatalError

   // -------------------- PUBLIC METHODS ---------------------------

   /**
   Extracts information from the catalog at the specified systemId and returns
   all info in the form of a hashmap. Note that all parsing errors are ignored.
   */
   public HashMap processCatalog(String systemId) {
      ents.clear(); // Empty hashtable for new processing

      try {
         parser.parse(systemId);
 	  } // try
 	  catch (Exception e) {
         // If a problem occurs parsing document, report the exception do nothing else --
         // let the parser try to use the default resolver
         System.err.println("Could not process catalog at " + systemId + ": " + e );
      } // catch

      return ents;

   } // processCatalog

   // -------------------- PRIVATE HELPER METHODS -------------------

   /**
   When group element is found, retrieve the "base" attribute
   */
   private void processGroup(Attributes atts) {
      String b;

      b = atts.getValue("xml:base");
      if (b != null)
         base = b;
      else
         base = "";

   } // processGroup

   /**
   For each public element, retrieve the id and the uri and add to the hashmap
   */
   private void processPublicId(Attributes atts) {
      String id, uri;

      id = atts.getValue("publicId");
      uri = atts.getValue("uri");

      if (id != null)
         ents.put(id, base + uri);

   } // processPublicId

   /**
   For each system element, retrieve the id and the uri and add to the hashmap
   */
   private void processSystemId(Attributes atts) {
      String id, uri;

      id = atts.getValue("systemId");
      uri = atts.getValue("uri");

      if (id != null)
         ents.put(id, base + uri);
   } // processSystemId


} // PMCCatalogProcessor
