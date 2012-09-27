/*
 * ContentModel.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;

/**
 * This holds the content model from an element, and parses it.
 */
public class ContentModel {
    
    private String minModel = null;   // Minified string version of the content model
    private String spec;              // Either "any", "empty", "text", "mixed", or "element".
    private Vector kids;              // If the spec is "mixed", this holds the list of child elements
    private NameChoiceSeq choiceOrSeq;  // If the spec is "element", this holds the parsed model. 

    // If spec is "mixed" or "element", this contains pointers to all this child Element names.
    // In the case of "mixed", this is the same as kids, except unordered.  In the case of
    // "element", this is like choiceOrSeq, but flattened, so that each kid appears only once.
    private HashSet allKids;
    
    // Used in parsing the model string
    private int _tp;                      // token pointer, index of the *next* character in minModel
    private char _token;                  // Results of last _getToken(): "(", "+", ..., "n", or "e".
    private String _tokenName;            // If _token is 'n', this stores the name.
    private boolean _debugMode = false;   // Set to true to turn on debug messages
    private int _debugIndent = 0;         // Used for indenting the parser debug messages.

    /**
     * Creates a new instance of the class
     *
     * @param m Content model, minified version (whitespace removed)
     */    
    public ContentModel( String m ) {
        try {
            minModel = m;
            _printDebug("\nParsing '" + m + "'");
            _debugIndent++;
            
            if (m.equals("ANY")) {
                spec = "any";
            }
            else if (m.equals("EMPTY")) {
                spec = "empty";
            }
            else if (m.equals("(#PCDATA)")) {
                spec = "text";
            }
            else if (m.startsWith("(#PCDATA")) {
                spec = "mixed";
                kids = new Vector();
                allKids = new HashSet();

                // Need to parse mixed content
                _tp = 9;
                _getToken();
                while (_token != 'e') {
                    if (_token == 'n') {
                        kids.addElement(_tokenName);
                        allKids.add(_tokenName);
                    }
                    _getToken();
                }
            }
            else {
                spec = "element";
                allKids = new HashSet();

                // Initialize the parser
                _tp = 0;
                // The first token must be an '('
                _getToken();
                choiceOrSeq = _makeChoiceOrSeq();
              /*
                while (t != 'e') {
                    System.out.println("  _token is " + t + ", '" + _tokenName + "'");
                    t = _getToken();
                }
                System.out.println("  _token is " + t + ", '" + _tokenName + "'");
              */
            }
        }
        catch (Exception e) {
            System.err.println("Error parsing the content model:  " + e.getMessage());
            System.exit(1);
        }
    }
    
    /**
     * Returns the minified model string 
     *
     * @return  Minified content model string (whitespace removed) 
     */    
    public String getMinifiedModel(){
        return minModel;
    }
    
    /**
     * Returns the spec; one of "any", "empty", "text", "mixed", or "element".
     */
    public String getSpec() {
        return spec;
    }

    /**
     * Returns the Vector of allowed child elements; only meaningful when spec is "mixed".
     */
    public Vector getKids() {
        return kids;
    }
    
    /**
     * Returns the choice-or-sequence child.  This is only meaningful when spec is "element".
     */
    public NameChoiceSeq getChoiceOrSeq() {
        return choiceOrSeq;
    }
    
    /**
     * If spec is "mixed" or "element", this returns an iterator over all of the child
     * element names (not Element objects).
     */
    public Iterator getKidsIter() {
        return (spec.equals("mixed") || spec.equals("element")) ? allKids.iterator() : null;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    // All of the rest of the methods are private, and used for parsing the content model.
    
    // _makeChoiceOrSeq() is invoked when we just saw an opening parens.  It instantiates 
    // and construct a choice-or-sequence.
    // When this returns, the current token will be the one after the close parens
    // (if no quantifier was present) or after the quantifier.
    private NameChoiceSeq _makeChoiceOrSeq() throws Exception {
        _printDebug("In _makeChoiceOrSeq");
        _debugIndent++;
        NameChoiceSeq self = new NameChoiceSeq();
        _getToken();
        while (_token != ')' && _token != 'e') {
            if (_token == '(') {
                _printDebug("Creating a new choice-or-seq child");
                self.addKid(_makeChoiceOrSeq());
            }
            else if (_token == 'n') {
                allKids.add(_tokenName);
                // We just found a name, create a new kid from it.
                _printDebug("Creating a new name child");
                NameChoiceSeq kName = new NameChoiceSeq(_tokenName);
                self.addKid(kName);
                _getToken();
                // If the next thing is a quantifier, add it to this kid
                if (_token == '?' || _token == '*' || _token == '+') {
                    _printDebug("Adding quantifier to name child");
                    kName.setQ(_token);
                    _getToken();
                }
            }
            
            // The next thing will either be ',', '|', or ')'
            if (_token == ',') {
                _printDebug("Setting choice-or-sequence type to sequence");
                self.setType(2);   // we are a sequence, not a choice
                _getToken();
            }
            else if (_token == '|') {
                _printDebug("I see this is a choice; no problem");
                _getToken();
            }
        }
        
        // If the next thing is a quantifier, add it to ourself
        _getToken();
        if (_token == '?' || _token == '*' || _token == '+') {
            _printDebug("Adding quantifier to myself");
            self.setQ(_token);
            _getToken();
        }
        _debugIndent--;
        _printDebug("Exiting _makeChoiceOrSeq");
        return self;
    }
    
    // _getToken() puts a character into _token that identifies what the next token is:
    //   '(', ')', '?', '+', '*', '|', ','  = themselves
    //   'n'  = name; in this case, the name found is stored into _tokenName.
    //   'e'  = end of string
    
    private void _getToken() {
        if (_tp >= minModel.length()) { 
            _token = 'e';
            _debugGetToken();
            return;
        } 
        char c = minModel.charAt(_tp);
        if ( _isTokenChar(c) ) 
        {
            _token = c;
            _tp++;
            _debugGetToken();
            return;
        }
        else {
            _tokenName = "";
            boolean isNameChar = true;                
            while (isNameChar) {
                _tokenName += c;
                _tp++;
                isNameChar = false;
                if (_tp < minModel.length()) {
                    c = minModel.charAt(_tp);
                    isNameChar = !_isTokenChar(c); 
                }
            }
            _token = 'n';
            _debugGetToken();
            return;
        }
    }

    // Returns true if the character is one of the fixed set of token characters.  If not,
    // then it must be a name character.
    private boolean _isTokenChar(char c) {
        return c == '(' || c == ')' || c == '?' || c == '+' || 
               c == '*' || c == '|' || c == ',';
    }
    
    // This prints out a debug message for every token we get
    private void _debugGetToken() {
        if (!_debugMode) { return; }
        String s = "Got token " + _token;
        if (_token == 'n') {
            s += ", \"" + _tokenName + "\""; 
        }
        s += ", _tp is now " + _tp;
        if (_tp < minModel.length()) {
            s += ", points at '" + minModel.charAt(_tp) + "'";
        }
        _printDebug(s);
    }
    
    // Print out a generic debug message
    private void _printDebug(String s) {
        if (!_debugMode) { return; }
        
        String indentStr = "";
        for (int i = 0; i < _debugIndent; ++i) {
            indentStr += "  ";
        }
        System.out.println(indentStr + s); 
    }
    
    
    
}
