/*
 * PMCParser.java
 *
 * Created on November 14, 2005, 3:01 PM
 */

package pmctools;

import org.xml.sax.*;
import org.xml.sax.helpers.XMLReaderFactory;
import java.net.URL;
import java.io.*;

/**
 *
 * @author  hessd
 */
public class PMCParser implements org.xml.sax.ErrorHandler {
    private int fatalErrorCount = 0;
     private int errorCount = 0;
    
    public void error(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        errorCount++;
        System.err.println("Error at line " + sAXParseException.getLineNumber() + " in " + sAXParseException.getSystemId() + ": " + sAXParseException.getMessage());
    }
    
    public void fatalError(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        fatalErrorCount++;
        System.err.println("Fatal errorat line " + sAXParseException.getLineNumber() + " in " + sAXParseException.getSystemId() + ": " + sAXParseException.getMessage());
    }
    
    public void warning(org.xml.sax.SAXParseException sAXParseException) throws org.xml.sax.SAXException {
        // ignore these
    }
    
   public static void main (String[] args){
        String catalogSysId = null; 
        String xmlSysId = null;
    
    if ( (args.length < 1) || (args.length > 2) ){
        System.err.println("Usage: java pmctools.PMCParser [xml file] {catalog}");
        System.exit(1);
    }
            
    if ( args.length == 2 ){
        try{
            File file = new File(args[0]);
            URL url = file.toURL();
            xmlSysId = url.toExternalForm();
            
            file = new File(args[1]);
            url = file.toURL();
            catalogSysId = url.toExternalForm();
        }
        catch (Exception e){
            System.err.println("Could not access file.  " + e.getMessage());
            System.exit(1);
        }
    }
        
    if ( args.length == 1){
       try{
            File file = new File(args[0]);
            URL url = file.toURL();
            xmlSysId = url.toExternalForm();            
        }
        catch (Exception e){
            System.err.println("Could not access file. " + e.getMessage());
            System.exit(1);
        }        
    }
     
    PMCParser errorReporter = new PMCParser();
    
    try {
      System.setProperty( "org.xml.sax.driver", "org.apache.xerces.parsers.SAXParser");        
      XMLReader parser = XMLReaderFactory.createXMLReader();
      parser.setFeature("http://xml.org/sax/features/validation", true);
      parser.setErrorHandler(errorReporter);
      
      if ( catalogSysId != null ){
         PMCResolver resolver = new PMCResolver(catalogSysId);
         parser.setEntityResolver(resolver);
      }
      
      parser.parse(xmlSysId);
      if ( errorReporter.errorCount == 0){
          System.out.println( "No errors");
          
      }
      else{
          System.out.println( Integer.toString(errorReporter.errorCount) + " errors");
      }      
      
      if ( errorReporter.fatalErrorCount == 0){
          System.out.println( "No fatal errors");
          
      }
      else{
          System.out.println( Integer.toString(errorReporter.fatalErrorCount) + " fatal errors");
      }

    } // try
    catch (Exception e) {
      System.out.println(e.getMessage());
      e.printStackTrace();
      System.exit(1);
    } 
    }
}
