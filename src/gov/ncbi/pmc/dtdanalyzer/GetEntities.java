/*
 * GetEntities.java
 *
 * Created on January 17, 2005, 5:58 PM
 */

package gov.ncbi.pmc.dtdanalyzer;

import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;
import java.io.IOException;

/**
 *
 * @author  Demian Hess
 */
public class GetEntities {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
       // Need to pass in catalog and fake instance
       if (!(args.length == 2)){
	      System.err.println("Wrong number of arguments. Usage:\n   GetEntities arg1 arg2\n   Where: arg1=catalog arg2=instance");
	      System.exit(0);
	   } // if

       XMLReader parser = null;
    try {
      parser = XMLReaderFactory.createXMLReader();
      PMCResolver resolver = new PMCResolver(args[0]);
      parser.setEntityResolver(resolver);
      PMCEntityCollector collector = new PMCEntityCollector(parser);
      collector.processDocument(args[1]);
      collector.getEntities(System.out); // Dump the XML instance of entities to standard out
    } // try
    catch (Exception e) {
      System.err.println(e);
      e.printStackTrace(System.err);
    } // catch
    } // Main
} // Test
