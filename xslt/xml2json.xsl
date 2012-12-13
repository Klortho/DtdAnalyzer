<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0"
                xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
                xmlns:str="http://exslt.org/strings"
                xmlns:f="http://exslt.org/functions"
                extension-element-prefixes="np str f">
  
  
  <!-- Turn off pretty-printing by setting this to false() -->
  <xsl:param name='pretty' select='true()'/>
  

  <!-- $nl == newline when pretty-printing; otherwise empty string  -->
  <xsl:variable name='nl'>
    <xsl:choose>
      <xsl:when test='$pretty'>
        <xsl:value-of select='"&#10;"'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='""'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <!-- $iu = indent unit (four spaces) when pretty-printing; 
    otherwise empty string -->
  <xsl:variable name='iu'>
    <xsl:choose>
      <xsl:when test='$pretty'>
        <xsl:value-of select='"    "'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='""'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='iu0' select='""'/>
  <xsl:variable name='iu1' select='$iu'/>
  <xsl:variable name='iu2' select='concat($iu, $iu)'/>
  <xsl:variable name='iu3' select='concat($iu2, $iu)'/>
  <xsl:variable name='iu4' select='concat($iu3, $iu)'/>
  <xsl:variable name='iu5' select='concat($iu4, $iu)'/>
  <xsl:variable name='iu6' select='concat($iu5, $iu)'/>
  
  
  <!--================================================
    Utility templates and functions
  -->
  
  <!-- Convert a string to lowercase. -->
  
  <xsl:variable name="lo" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="hi" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  
  <xsl:template name="np:to-lower">
    <xsl:param name="s"/>
    <xsl:value-of select="translate($s, $hi, $lo)"/>
  </xsl:template>
  
  <f:function name="np:to-lower">
    <xsl:param name="s"/>
    <f:result>
      <xsl:call-template name="np:to-lower">
        <xsl:with-param name="s" select="$s"/>
      </xsl:call-template>
    </f:result>
  </f:function>
  
  <!--
    Quote a string to prepare it for insertion into a JSON literal value.
    Right now this backslash-escapes double quotes and backslashes.  Probably
    needs to be made more robust.
  -->
  <f:function name="np:q">
    <xsl:param name="_" select="/.."/>
    <xsl:variable name="quot">"</xsl:variable>
    <xsl:variable name="bs">\</xsl:variable>
    <xsl:variable name="result" 
      select="str:replace(
                  str:replace( str:decode-uri($_), $bs, concat($bs, $bs) ), 
                  $quot, concat($bs, $quot) )"/>
    <f:result>
      <xsl:value-of select="$result"/>
    </f:result>
  </f:function>
  
  <!-- 
    Convenience function to wrap any string in double-quotes.  This 
    reduces the need for a lot of XML character escaping.
  -->
  <f:function name='np:dq'>
    <xsl:param name='s'/>
    <f:result>
      <xsl:value-of select="concat('&quot;', $s, '&quot;')"/>
    </f:result>
  </f:function>
  
  <!--
    mkey = member key - this produces a string which is the key in double-quotes, 
    followed by a colon, space.  It is used whenever outputting a member of a JSON 
    object.
  -->
  <f:function name='np:mkey'>
    <xsl:param name='k'/>
    <f:result>
      <xsl:value-of select='concat(np:dq($k), ": ")'/>
    </f:result>
  </f:function>
  
  <!-- 
    This function takes a boolean indicating whether or not we want a trailing
    comma.  If false, it returns the empty string; if true, a comma.
  -->
  <f:function name='np:tc'>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:if test='$trailing-comma'>
        <xsl:text>,</xsl:text>
      </xsl:if>
    </f:result>
  </f:function>
  
  <!-- 
    There are five main utility functions for output stuff, as illustrated here.
    Trailing commas are included only when the trailing-comma parameter is true.
    Each of these is designed to be invoked at the start of a new line, so each
    first outputs an indent, if that's given.

      Function name      Output
      =============      ======
      simple             value,\n
      key-simple         "key": value,\n
      start-object       {\n
      key-start-object   "key": {\n
      end-object         },\n
      start-array        [\n
      key-start-array    "key": [\n
      end-array          ],\n
  -->
  <f:function name='np:simple'>
    <xsl:param name='indent'/>
    <xsl:param name='value'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, $value, np:tc($trailing-comma), $nl)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:key-simple'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <xsl:param name='value'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), $value, np:tc($trailing-comma), $nl)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:start-object'>
    <xsl:param name='indent'/>
    <f:result>
      <xsl:value-of select='concat($indent, "{", $nl)'/>
    </f:result>
  </f:function>

  <f:function name='np:key-start-object'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), "{", $nl)'/>
    </f:result>
  </f:function>

  <f:function name='np:end-object'>
    <xsl:param name='indent'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, "}", np:tc($trailing-comma), $nl)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:start-array'>
    <xsl:param name='indent'/>
    <f:result>
      <xsl:value-of select='concat($indent, "[", $nl)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:key-start-array'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), "[", $nl)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:end-array'>
    <xsl:param name='indent'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, "]", np:tc($trailing-comma), $nl)'/>
    </f:result>
  </f:function>
  
  <!-- 
    The following three return the json-escaped values for simple types 
  -->
  <f:function name='np:string-value'>
    <xsl:param name='v'/>
    <f:result>
      <xsl:value-of select='np:dq(normalize-space(np:q($v)))'/>
    </f:result>
  </f:function>

  <f:function name='np:number-value'>
    <xsl:param name='v'/>
    <f:result>
      <xsl:value-of select='normalize-space($v)'/>
    </f:result>
  </f:function>

  <!-- 
    FIXME:  for booleans, we should do a little processing on the value to see
    if it is "falsy" or not, then convert it into either "true" or "false".
  -->
  <f:function name='np:boolean-value'>
    <xsl:param name='v'/>
    <f:result>
      <xsl:value-of select='normalize-space($v)'/>
    </f:result>
  </f:function>
  
  <!--============================================================
    Generic templates
  -->
  
  <!-- Start-of-output boilerplate -->
  <xsl:template name='result-start'>
    <xsl:param name='resulttype' select='""'/>
    <xsl:param name='version' select='""'/>
    
    <xsl:value-of select='concat("{", $nl)'/>
    <xsl:if test='$resulttype != ""'>
      <xsl:value-of select='np:key-simple($iu, "resulttype", np:dq($resulttype), true())'/>
    </xsl:if>
    <xsl:if test='$version != ""'>
      <xsl:value-of select='np:key-simple($iu, "version", np:dq($version), true())'/>
    </xsl:if>
  </xsl:template>

  <!--
    simple
    Delegates either to simple-in-object or simple-in-array.
    
    FIXME:  This should change to "string".
  -->
  <xsl:template name='simple'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='simple-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='simple-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='key' select='$key'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="simple-in-array">
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    number
    Delegates either to number-in-object or number-in-array.
  -->
  <xsl:template name='number'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='number-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='number-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='key' select='$key'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="number-in-array">
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    boolean
    Delegates either to boolean-in-object or boolean-in-array.
  -->
  <xsl:template name='boolean'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='boolean-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='boolean-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='key' select='$key'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="boolean-in-array">
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <!--
    array 
    Delegates either to array-in-object or array-in-array.
  -->
  <xsl:template name='array'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='array-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='array-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='key' select='$key'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="array-in-array">
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    object 
    Delegates either to object-in-object or object-in-array.
  -->
  <xsl:template name='object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='object-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='object-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='key' select='$key'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="object-in-array">
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <!--
    simple-in-object
    For text nodes, attributes, or elements that have simple 
    content, when in the context of a JSON object.  
    This translates the node into a key:value pair.  If it's a text node, then, by 
    default, the key will be "value".  If it's an attribute or element node, then, 
    by default, the key will be the name converted to lowercase (it's up to you
    to make sure they are unique within the object).
    
    FIXME:  I don't think we always want to normalize-space on the content.
  -->
  <xsl:template name='simple-in-object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:to-lower(name(.))'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    
    <xsl:value-of 
      select='np:key-simple($indent, $key, np:string-value(.), position() != last())'/>
  </xsl:template>
  
  <!-- 
    simple-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
    
    FIXME:  I don't think we always want to normalize-space on the content.
  -->
  <xsl:template name='simple-in-array'>
    <xsl:param name='indent' select='""'/>

    <xsl:value-of 
      select='np:simple($indent, np:string-value(.), position() != last())'/>
  </xsl:template>

  <!--
    number-in-object
    For text nodes, attributes, or elements that have simple 
    content, when in the context of a JSON object.  
  -->
  <xsl:template name='number-in-object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:to-lower(name(.))'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    
    <xsl:value-of 
      select='np:key-simple($indent, $key, np:number-value(.), position() != last())'/>
  </xsl:template>
  
  <!-- 
    number-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
  -->
  <xsl:template name='number-in-array'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of 
      select='np:simple($indent, np:number-value(.), position() != last())'/>
  </xsl:template>


  <!--
    boolean-in-object
    For text nodes, attributes, or elements that have simple 
    content, when in the context of a JSON object.  
  -->
  <xsl:template name='boolean-in-object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:to-lower(name(.))'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    
    <xsl:value-of 
      select='np:key-simple($indent, $key, np:boolean-value(.), position() != last())'/>
  </xsl:template>
  
  <!-- 
    boolean-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
  -->
  <xsl:template name='boolean-in-array'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of 
      select='np:simple($indent, np:boolean-value(.), position() != last())'/>
  </xsl:template>
  
  
  
  <!--
    array-in-object
    Call this template for array-type elements.  That is, usually, elements
    whose content is a list of child elements with the same name.
    By default, the key will be the name converted to lowercase.
    This produces a JSON array.  The "kids" are the set of child elements only,
    so attributes and text node children are discarded.
    
    FIXME [here and in all the templates below]:  
    Can't I use
      <xsl:param name='trailing-comma' select='position() != last()'/>
    instead of the kludgy force-comma that I have here now?  If not, won't I also
    need a no-comma param?
    
    
    FIXME:  Do we still need kids-param?
  -->
  <xsl:template name='array-in-object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key' select='np:to-lower(name(.))'/>
    <!-- 
      kids-param says whether or not kids is given.  It is needed (unless I don't 
      know something) because we might be calling this with a kids parameter that
      evaluates to an empty node-set.  It seems that XSLT 1.0 uses the default 
      in that case (which would be "*"), which is no good:  we want it to mean "no kids". 
    -->      
    <xsl:param name='kids-param' select='false()'/>
    <xsl:param name='kids'/>
    <xsl:param name='force-comma' select='false()'/>
    <xsl:variable name='trailing-comma' select='$force-comma or position() != last()'/>
    
    <xsl:value-of select='np:key-start-array($indent, $key)'/>

    <xsl:choose>
      <xsl:when test='$kids-param'>
        <xsl:apply-templates select='$kids'>
          <xsl:with-param name='indent' select='concat($indent, $iu)'/>
          <xsl:with-param name='context' select='"array"'/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select='*'>
          <xsl:with-param name='indent' select='concat($indent, $iu)'/>
          <xsl:with-param name='context' select='"array"'/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:value-of select='np:end-array($indent, $trailing-comma)'/>
  </xsl:template>
  
  <!--
    array-in-array
    Array-type elements that occur inside other arrays.
  -->
  <xsl:template name='array-in-array'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key' select='np:to-lower(name(.))'/>
    <xsl:param name='force-comma' select='false()'/>
    <xsl:variable name='trailing-comma' select='$force-comma or position() != last()'/>
    
    <xsl:value-of select='np:start-array($indent)'/>

    <xsl:apply-templates select='*'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
      <xsl:with-param name='context' select='"array"'/>
    </xsl:apply-templates>
    
    <xsl:value-of select='np:end-array($indent, $trailing-comma)'/>
  </xsl:template>
  
  <!-- 
    object-in-object
    For elements that have attributes and/or heterogenous content.  These are 
    converted into JSON objects.  
    The key, by default, is taken from this element's name, converted to lowercase.
    By default, this recurses by calling apply-templates on all attributes and
    element children.  So text-node children are discarded.  You can override that
    by passing the $kids param.
  -->
  <xsl:template name='object-in-object'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key' select='np:to-lower(name(.))'/>
    <xsl:param name='kids' select='@*|*'/>
    <xsl:param name='force-comma' select='false()'/>
    <xsl:variable name='trailing-comma' select='$force-comma or position() != last()'/>
    
    <xsl:value-of select='np:key-start-object($indent, $key)'/>
    
    <xsl:apply-templates select='$kids'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
      <xsl:with-param name='context' select='"object"'/>
    </xsl:apply-templates>

    <xsl:value-of select='np:end-object($indent, $trailing-comma)'/>
  </xsl:template>

  <!-- 
    object-in-array
    For elements that contain heterogenous content.  These are converted
    into JSON objects.  
  -->
  <xsl:template name='object-in-array'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='kids' select='@*|*'/>
    <xsl:param name='force-comma' select='false()'/>
    <xsl:variable name='trailing-comma' select='$force-comma or position() != last()'/>
    
    <xsl:value-of select='np:start-object($indent)'/>
    
    <xsl:apply-templates select='$kids'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
      <xsl:with-param name='context' select='"object"'/>
    </xsl:apply-templates>

    <xsl:value-of select='np:end-object($indent, $trailing-comma)'/>
  </xsl:template>
  
  <!-- 
    simple-obj-in-array
    This is for simple-type XML attributes or elements, but we want to convert
    them into mini JSON objects.  For example,
      <PhraseNotFound>fleegle</PhraseNotFound>
    will be converted to
      { "phrasenotfound": "fleegle" }
    This is for elements that appear in an array context, but the content is
    not strictly homogenous.
  -->
  <xsl:template name='simple-obj-in-array'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='key' select='np:to-lower(name(.))'/>

    <xsl:value-of select='np:start-object($indent)'/>
    <xsl:value-of select='np:key-simple(
      concat($indent, $iu), $key, np:string-value(.), false()
    )'/>
    <xsl:value-of select='np:end-object($indent, position() != last())'/>
  </xsl:template>
  
  <!-- 
    Default template for an element or attribute. 
    Reports a problem.
  -->
  <xsl:template match='@*|*'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"object"'/>
    
    <xsl:message>
      <xsl:text>FIXME:  No template defined for </xsl:text>
      <xsl:choose>
        <xsl:when test='self::*'>
          <xsl:text>element </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>attribute </xsl:text>
          <xsl:value-of select='concat(name(..), "/@")'/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select='name(.)'/>
    </xsl:message>
    
    <xsl:choose>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name='simple-in-array'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='simple-in-object'>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Default template for text nodes.  Throw them away if they
    are all blanks.  Report a problem otherwise.    -->
  <xsl:template match="text()" >
    <xsl:param name='indent' select='""'/>
    <xsl:param name='context' select='"object"'/>
    
    <xsl:if test='normalize-space(.) != ""'>
      <xsl:message>
        <xsl:text>FIXME:  non-blank text node with no template match.  Parent element: </xsl:text>
        <xsl:value-of select='name(..)'/>
      </xsl:message>
      <xsl:choose>
        <xsl:when test='$context = "array"'>
          <xsl:call-template name='simple-in-array'>
            <xsl:with-param name='indent' select='$indent'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name='simple-in-object'>
            <xsl:with-param name='indent' select='$indent'/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>