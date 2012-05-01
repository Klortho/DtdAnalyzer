package gov.ncbi.pmc.dtdanalyzer;

import javax.xml.transform.*;
import javax.xml.transform.sax.*;
import javax.xml.transform.stream.*;
import java.io.*;
import org.xml.sax.*;
import org.xml.sax.helpers.*;
import java.util.*;

/**
PMCTransformer is responsible for applying an XSL stylesheet to an XML
instance and sending the result tree to standard out.

If the XML instance has a DOCTYPE, then the calling application should
provide the location of a suitable XML catalog so that all PUBLIC and
SYSTEM identifiers can be resolved.

   NOTE: You MUST set two required system properties and have the option of setting 2 others, as follows:
         -gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xsl = (required) fully-qualified path to stylesheet
         -gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xml = (required) fully-qualified path to XML instance
         -gov.ncbi.pmc.dtdanalyzer.PMCTransformer.catalog = (optional) fully-qualified path to XML catalog to resolve PUBLIC identifiers
         -gov.ncbi.pmc.dtdanalyzer.PMCTransformer.params = (optional) string listing name and values of parameters to pass to the stylesheet. Format must be
	                                    name1::value1;name2::value2; . . .nameN::valueN

Author: Demian Hess
Date: January 25, 2005
*/

public class PMCTransformer {
   private static String xslName = "", xmlName = "", catalogName = "", params = "";
   private static String XMLKEY = "gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xml",
                               XSLKEY = "gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xsl",
			       CATALOGKEY = "gov.ncbi.pmc.dtdanalyzer.PMCTransformer.catalog",
			       PARAMSKEY = "gov.ncbi.pmc.dtdanalyzer.PMCTransformer.params";

   public static void main ( String args [] ) {
      Source xml, xsl;
      
      // Retrieve the system properties
      retrieveProperties();

      // Xsl and xml locations must have been set as system properties
      if ( xslName.length() == 0 || xmlName.length() == 0 ) {
         System.err.println("The system properties gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xml and/or gov.ncbi.pmc.dtdanalyzer.PMCTransformer.xsl are not set.");
	 System.err.println("Typical invocation:");
	 System.err.println("   java -Dgov.ncbi.pmc.dtdanalyzer.PMCTransformer.xml=file.xml -Dgov.ncbi.pmc.dtdanalyzer.PMCTransformer.xsl=file.xsl [-Dgov.ncbi.pmc.dtdanalyzer.PMCTransformer.catalog=catolog.xml -Dgov.ncbi.pmc.dtdanalyzer.PMCTransformer.params=name1::value1;name2::value2] gov.ncbi.pmc.dtdanalyzer.PMCTransformer");
	 System.exit(1);
      } // if

      try {
         TransformerFactory f = TransformerFactory.newInstance();
	 xsl = new StreamSource(xslName); // Command line arg points to XSL location

	 // If a catalog is being supplied must create a SAX source in order to process any PUBLIC identifiers
	 if (catalogName.length() > 0) {
	    XMLReader parser = XMLReaderFactory.createXMLReader();
            PMCResolver resolver = new PMCResolver(catalogName); // Command line argument points to catalog location
            parser.setEntityResolver(resolver); // Tell parser to use the resolver to look-up public and system ids
            xml = new SAXSource(parser, new InputSource(xmlName)); // Command line arg points to XML location
            f.setURIResolver(resolver); // Transformer can use resolver to return SAX streams from the document() function
         } // if
         else {
            xml = new StreamSource(xmlName);
         } // else

	 Result out = new StreamResult(System.out);
	 Transformer stylesheet = f.newTransformer(xsl);
	 
	 // Set any parameters being passed in via system properties
	 setParameters( stylesheet );
	 
	 stylesheet.transform(xml, out);
      } // try
      catch ( Exception e ) {
         System.err.println(e);
      } // catch
   } // main
   
   /**
    Retrieve all system properties (if any).
   */
   private static void retrieveProperties(){
      Properties p = System.getProperties();
      
      if (p.containsKey(XMLKEY)){
         xmlName = (String)p.getProperty(XMLKEY);
      } //if
      
      if (p.containsKey(XSLKEY)){
         xslName = (String)p.getProperty(XSLKEY);
      } //if
      
      if (p.containsKey(CATALOGKEY)){
         catalogName = (String)p.getProperty(CATALOGKEY);
      } //if
      
      if (p.containsKey(PARAMSKEY)){
         params = (String)p.getProperty(PARAMSKEY);
      } //if
   } // retrieveProperties
   
   /**
    Sets the parameters (if any) for the stylesheet.
   */
   private static void setParameters( Transformer transformer ) {
      if ( params.length() > 0 ) {
         // Get name and value pairs--these are separated by semi-colons
         StringTokenizer pairs = new StringTokenizer( params, ";" );
         while ( pairs.hasMoreTokens() ) {
	    
	    // Break the pair on the '::'-- first token is the name, second is the value
	    StringTokenizer nameAndValue = new StringTokenizer( pairs.nextToken(), "::" );
	    
	    // Must be two--otherwise, no good
	    if ( nameAndValue.countTokens() == 2 ) {
	       transformer.setParameter( nameAndValue.nextToken(), nameAndValue.nextToken() );
	    } // if
	 } // while
      }
   } // setParameters
   

} // PMCTransformer
