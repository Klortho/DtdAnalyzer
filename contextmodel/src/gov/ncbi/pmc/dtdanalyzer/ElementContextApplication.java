/*
 * ElementContextApplication.java
 *
 * Created on January 17, 2005, 5:58 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 *
 * @author  Demian Hess
 */
public class ElementContextApplication {
 
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
    try {
      if (args.length < 2) {
        System.err.println("Need two arguments. Usage: java ElementContextApplication [xml instance] [xml catalog]");
        System.exit(1);
      }
      
      XMLReader parser = XMLReaderFactory.createXMLReader();
      PMCResolver resolver = new PMCResolver(args[1]); // Command line argument points to catalog location
      parser.setEntityResolver(resolver); // Tell parser to use the resolver to look-up public and system ids
      gov.ncbi.pmc.dtdanalyzer.ElementModelManager mgr = new gov.ncbi.pmc.dtdanalyzer.ElementModelManager(parser);
      mgr.processDocument(args[0]);
      mgr.getInfo(System.out); // Dump the XML instance of entities to standard out
    } // try
    catch (Exception e) {
      System.err.println(e);
    } // catch
    } // Main
} // ElementContextApplication
