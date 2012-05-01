package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.helpers.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import java.util.*;
import java.io.*;
import java.net.*;
import javax.xml.transform.*;

/**
PMCResolver is responsible for resolving PUBLIC and SYSTEM identifiers. Resolution is
accomplished using an XML catalog that is passed in as an argument. The catalog must
conform to the OASIS DTD for XML catalogs. Note, however, that the catalog should not
include a DOCTYPE and should not be validated.

Late addition: Class also can serve as a URIResolver for a TransformationFactory.
If the resolve method is passed a systemId, then this resolver will return a SAXSource.
This is useful when the document() function is used in a stylesheet, since it
will enable the processor to find all DTDs and validate the document.
*/
public class PMCResolver implements EntityResolver, URIResolver {

   private HashMap entities; // Holds all PUBLIC and SYSTEM ids as a key; value is full path to file
   private XMLReader parser;
   private PMCCatalogProcessor catProcessor; // Processes the catalog

   /**
   Create a parser on instantiation; if it cannot be created, report an error
   but do not throw an exception. If a parser could not be created, then
   this class will simply return null for every id, thus allowing the
   calling XMLReader to fallback to its default id resolution process.
   */
   public PMCResolver() {
      try {
         parser = XMLReaderFactory.createXMLReader();
      } // try
      catch (SAXException e){
         System.err.println("Could not create instance of SAX parser: " + e);
	  } // catch
      catProcessor = new PMCCatalogProcessor();
      entities = new HashMap(64);
      parser.setEntityResolver(this);
   } // no args constructor

   /**
   Constructor takes the location of the catalog.
   */
   public PMCResolver(String systemId) {
      try {
         parser = XMLReaderFactory.createXMLReader();
      } // try
      catch (SAXException e){
         System.err.println("Could not create instance of SAX parser: " + e);
	  } // catch
      catProcessor = new PMCCatalogProcessor();
      entities = new HashMap(64);
      setCatalog(systemId);
      parser.setEntityResolver(this);
    } // constructor

    /**
    Sets/resets the current catalog
    */
    public void setCatalog(String systemId) {
       entities = catProcessor.processCatalog(systemId);
    } // setCatalog

    /**
     Required public method to resolve a PUBLIC or SYSTEM id.
    */
    public InputSource resolveEntity(String publicId, String systemId) throws SAXException, IOException {
       InputSource result = null;
       String sysId;

       // Use the public id if available
       if (publicId != null && publicId.length() > 0) {
          sysId = (String)entities.get(publicId);
          if (sysId != null) {

		     result = new InputSource(makeURL(sysId));
		     result.setSystemId(sysId);
		  } // if
	   } // if
       // Otherwise, use the systemId
       else {
	      if (systemId != null) {
             sysId = (String)entities.get(systemId);
             if (sysId != null) {
		        result = new InputSource(makeURL(sysId));
			result.setSystemId(sysId);
		     } // if
	      } //if
	   } // else
       return result;
    } // resolveEntity

    /**
     Required public method for the URIResolver interface. Attempts to parse
     the document at the provided href. This, then assumes, that the href
     is a valid systemId, and that it points to an XML instance that, if it has a doctype, 
     can be validated. If a SAXSource cannot be constructed, then this
     simply returns null, which will cause the XSLT processor to fallback to 
     default resolution.
    */
    public Source resolve(String href, String base) {
       Source result = null;

       try{
          result = new SAXSource(parser, new InputSource(href));
       }
       catch (Exception e){
		   // do nothing
       } //catch

       return result;

    } //resolve

    /**
    Helper method transforms file name to URI so that it is a bit more portable
    */
    private String makeURL(String s) {
		String result;

		try{
           File fileObject = new File(s);
           URL url = fileObject.toURL();
           result = url.toExternalForm();
		} //try
		catch (Exception e){
           result = s; // Just return what was passed in
		} // catch

		return result;

	} // makeURL




} // PMCResolver


