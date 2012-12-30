<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0"
                xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
                xmlns:str="http://exslt.org/strings"
                xmlns:f="http://exslt.org/functions"
                xmlns:c="http://exslt.org/common"
                extension-element-prefixes="c np str f">
  
  
  <!-- Turn off pretty-printing by setting this to false() -->
  <xsl:param name='pretty' select='true()'/>
  
  <!-- By default, do not convert all names to lowercase -->
  <xsl:param name='lcnames' select='false()'/>

  <!-- $nl == the newline character -->
  <xsl:variable name='nl' select='"&#10;"'/>

  <!-- $nlp == newline when pretty-printing; otherwise empty string  -->
  <xsl:variable name='nlp'>
    <xsl:choose>
      <xsl:when test='$pretty'>
        <xsl:value-of select='$nl'/>
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
  
  
  <!--================================================
    Utility templates and functions
  -->
  
  <!-- 
    Convert a string to lowercase
  -->
  
  <xsl:variable name="lo" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="hi" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  
  <f:function name='np:lower-case'>
    <xsl:param name='s'/>
    <f:result>
      <xsl:value-of select="translate($s, $hi, $lo)"/>
    </f:result>
  </f:function>
  
  <!-- 
    Converts the name of the current context element or attribute
    into lowercase, only if the $lcnames param is true.
  -->
  <xsl:template name="np:translate-name">
    <xsl:param name="s" select='name(.)'/>
    <xsl:choose>
      <xsl:when test='$lcnames'>
        <xsl:value-of select="np:lower-case($s)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='$s'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <f:function name="np:translate-name">
    <xsl:param name="s" select='name(.)'/>
    <f:result>
      <xsl:call-template name="np:translate-name">
        <xsl:with-param name="s" select="$s"/>
      </xsl:call-template>
    </f:result>
  </f:function>
  
  <!--
    Quote a string to prepare it for insertion into a JSON literal value.
  -->
  <f:function name="np:json-escape">
    <xsl:param name="s"/>
    <xsl:variable name="quot">"</xsl:variable>
    <xsl:variable name="bs">\</xsl:variable>
    <xsl:variable name='nl' select='"&#10;"'/>
    <xsl:variable name='cr' select='"&#13;"'/>
    <xsl:variable name='tab' select='"&#9;"'/>
    <xsl:variable name="result" 
      select="str:replace(
                str:replace(
                  str:replace(
                    str:replace(
                      str:replace($s, 
                        $bs, concat($bs, $bs) 
                      ),
                      $quot, concat($bs, $quot) 
                    ),
                    $nl, concat($bs, 'n')
                  ),
                  $cr, concat($bs, 'r')
                ),
                $tab, concat($bs, 't')
              )"/> 
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
    comma.  If false, it returns the empty string; if true, a comma.  It's like
    the ternary-operator expression ($trailing-comma ? "," : "").
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
    There are five main utility functions for outputing stuff, as illustrated here.
    Trailing commas are included only when the trailing-comma parameter is true.
    Each of these is designed to be invoked at the start of a new line, so each
    first outputs an indent, if that's given.

      Function name            Output
      =============            ======
      simple(i, v, tc)         value,\n
      key-simple(i, k, v, tc)  "key": value,\n
      start-object(i)          {\n
      key-start-object(i, k)   "key": {\n
      end-object(i, tc)         },\n
      start-array(i)           [\n
      key-start-array(i, k)    "key": [\n
      end-array(i, tc)          ],\n
  -->
  <f:function name='np:simple'>
    <xsl:param name='indent'/>
    <xsl:param name='value'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, $value, np:tc($trailing-comma), $nlp)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:key-simple'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <xsl:param name='value'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), $value, np:tc($trailing-comma), $nlp)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:start-object'>
    <xsl:param name='indent'/>
    <f:result>
      <xsl:value-of select='concat($indent, "{", $nlp)'/>
    </f:result>
  </f:function>

  <f:function name='np:key-start-object'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), "{", $nlp)'/>
    </f:result>
  </f:function>

  <f:function name='np:end-object'>
    <xsl:param name='indent'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, "}", np:tc($trailing-comma), $nlp)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:start-array'>
    <xsl:param name='indent'/>
    <f:result>
      <xsl:value-of select='concat($indent, "[", $nlp)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:key-start-array'>
    <xsl:param name='indent'/>
    <xsl:param name='key'/>
    <f:result>
      <xsl:value-of select='concat($indent, np:mkey($key), "[", $nlp)'/>
    </f:result>
  </f:function>
  
  <f:function name='np:end-array'>
    <xsl:param name='indent'/>
    <xsl:param name='trailing-comma'/>
    <f:result>
      <xsl:value-of select='concat($indent, "]", np:tc($trailing-comma), $nlp)'/>
    </f:result>
  </f:function>
  
  <!-- 
    The following three return the json-escaped values for simple types 
  -->
  <f:function name='np:string-value'>
    <xsl:param name='v'/>
    <f:result>
      <xsl:value-of select='np:dq(np:json-escape($v))'/>
    </f:result>
  </f:function>

  <f:function name='np:number-value'>
    <xsl:param name='v'/>
    <f:result>
      <xsl:value-of select='normalize-space($v)'/>
    </f:result>
  </f:function>

  <f:function name='np:boolean-value'>
    <xsl:param name='v'/>
    <xsl:variable name='nv' select='np:lower-case(normalize-space($v))'/>
    <f:result>
      <xsl:choose>
        <xsl:when test='$nv = "0" or $nv = "no" or $nv = "n" or $nv = "false" or $nv = ""'>
          <xsl:text>false</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>true</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </f:result>
  </f:function>
  
  <!--============================================================
    Generic templates
  -->

  <!-- 
    Default template for the document root node.  This generates the outermost
    JSON object and the header.
  -->

  <xsl:template match="/">
    <xsl:variable name='jxml'>
      <xsl:call-template name='root'/>
    </xsl:variable>

    <xsl:variable name='jxml-ns' select='c:node-set($jxml)'/>
    <xsl:apply-templates select='$jxml-ns/*' 
      mode='serialize-jxml-array'/>
  </xsl:template>


  <xsl:template name='root'>
    <xsl:param name='header-strings'
      select='c:node-set($dtd-annotation)/json'/>

    <o>
      <xsl:call-template name='header'>
        <xsl:with-param name='header-strings' select='$header-strings'/>
      </xsl:call-template>
      <xsl:apply-templates select='*'>
        <xsl:with-param name="context" select="'object'"/>
      </xsl:apply-templates>
    </o>
  </xsl:template>
  
  <xsl:template name='header'>
    <xsl:param name='header-strings'/>
    
    <o name='header'>
      <xsl:for-each select='$header-strings/@*'>
        <s name='{name(.)}'>
          <xsl:value-of select='.'/>
        </s>
      </xsl:for-each>
    </o>
  </xsl:template>


  

  <!--
    string
    There are separate template here for when we don't know the context
    ("string") or when we do ("string-in-object", "string-in-array").
  -->
  <xsl:template name='string'>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object"'>
        <s name='{$key}'>
          <xsl:value-of select='$value'/>
        </s>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <s>
          <xsl:value-of select='$value'/>
        </s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
          <xsl:text> ($context = "</xsl:text>
          <xsl:value-of select='$context'/>
          <xsl:text>", $key = "</xsl:text>
          <xsl:value-of select='$key'/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    string-in-object
    This translates the node into a key:value pair.  If it's a text node, then, by 
    default, the key will be "value".  If it's an attribute or element node, then, 
    by default, the key will be the name converted to lowercase (it's up to you
    to make sure they are unique within the object).
  -->
  <xsl:template name='string-in-object'>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <s name='{$key}'>
      <xsl:value-of select='$value'/>
    </s>
  </xsl:template>
  
  <!-- 
    string-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
  -->
  <xsl:template name='string-in-array'>
    <xsl:param name='value' select='.'/>
    <s>
      <xsl:value-of select='$value'/>
    </s>
  </xsl:template>
  
  





  <!--
    number
    Delegates either to number-in-object or number-in-array.
  -->
  <xsl:template name='number'>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object"'>
        <n name='{$key}'>
          <xsl:value-of select='$value'/>
        </n>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <n>
          <xsl:value-of select='$value'/>
        </n>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
          <xsl:text> ($context = "</xsl:text>
          <xsl:value-of select='$context'/>
          <xsl:text>", $key = "</xsl:text>
          <xsl:value-of select='$key'/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <!--
    number-in-object
    For text nodes, attributes, or elements that have simple 
    content, when in the context of a JSON object.  
  -->
  <xsl:template name='number-in-object'>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <n name='{$key}'>
      <xsl:value-of select='$value'/>
    </n>
  </xsl:template>
  
  <!-- 
    number-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
  -->
  <xsl:template name='number-in-array'>
    <xsl:param name='value' select='.'/>
    <n>
      <xsl:value-of select='$value'/>
    </n>
  </xsl:template>
  
  
  <!--
    boolean
    Delegates either to boolean-in-object or boolean-in-array.
  -->
  <xsl:template name='boolean'>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object"'>
        <b name='{$key}'>
          <xsl:value-of select='np:boolean-value($value)'/>
        </b>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <b>
          <xsl:value-of select='np:boolean-value($value)'/>
        </b>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
          <xsl:text> ($context = "</xsl:text>
          <xsl:value-of select='$context'/>
          <xsl:text>", $key = "</xsl:text>
          <xsl:value-of select='$key'/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    boolean-in-object
    For text nodes, attributes, or elements that have simple 
    content, when in the context of a JSON object.  
  -->
  <xsl:template name='boolean-in-object'>
    <xsl:param name='key'>
      <xsl:choose>
        <xsl:when test='self::text()'>
          <xsl:text>value</xsl:text>
        </xsl:when>
        <xsl:otherwise>  <!-- This is an attribute or element node -->
          <xsl:value-of select='np:translate-name()'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:param name='value' select='.'/>
    
    <b name='{$key}'>
      <xsl:value-of select='np:boolean-value($value)'/>
    </b>
  </xsl:template>
  
  <!-- 
    boolean-in-array
    For text nodes, attributes, or elements that have simple content, when
    in the context of a JSON array.  This discards the attribute or element name,
    and produces a quoted string from the content.
  -->
  <xsl:template name='boolean-in-array'>
    <xsl:param name='value' select='.'/>
    
    <b>
      <xsl:value-of select='np:boolean-value($value)'/>
    </b>
  </xsl:template>
  
  
  
  
  
  
  
  
  <!--
    array 
    Delegates either to array-in-object or array-in-array.
  -->
  <xsl:template name='array'>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='""'/>
    <xsl:param name='kids' select='*'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object" and $key = ""'>
        <xsl:call-template name='array-in-object'>
          <xsl:with-param name='kids' select='$kids'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "object" and $key != ""'>
        <xsl:call-template name='array-in-object'>
          <xsl:with-param name='key' select='$key'/>
          <xsl:with-param name='kids' select='$kids'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name="array-in-array">
          <xsl:with-param name='kids' select='$kids'/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='$context = "object"'>
        <xsl:message>
          <xsl:text>Error:  bad key passed in for element </xsl:text>
          <xsl:value-of select='name(.)'/>
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
          <xsl:text> ($context = "</xsl:text>
          <xsl:value-of select='$context'/>
          <xsl:text>", $key = "</xsl:text>
          <xsl:value-of select='$key'/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  



  
  
  <!--
    array-in-object
    Call this template for array-type elements.  That is, usually, elements
    whose content is a list of child elements with the same name.
    By default, the key will be the name converted to lowercase.
    This produces a JSON array.  The "kids" are the set of child elements only,
    so attributes and text node children are discarded.
  -->
  <xsl:template name='array-in-object'>
    <xsl:param name='key' select='np:translate-name()'/>
    <xsl:param name='kids' select='*'/>
    
    <a name='{$key}'>
      <xsl:apply-templates select='$kids'>
        <xsl:with-param name='context' select='"array"'/>
      </xsl:apply-templates>
    </a>
  </xsl:template>
  
  <!--
    array-in-array
    Array-type elements that occur inside other arrays.
  -->
  <xsl:template name='array-in-array'>
    <xsl:param name='key' select='np:translate-name()'/>
    <xsl:param name='kids' select='*'/>
    
    <a>
      <xsl:apply-templates select='$kids'>
        <xsl:with-param name='context' select='"array"'/>
      </xsl:apply-templates>
    </a>
  </xsl:template>
  
  
  <!--
    object 
    Delegates either to object-in-object or object-in-array.
  -->
  <xsl:template name='object'>
    <xsl:param name='context' select='"unknown"'/>
    <xsl:param name='key' select='np:translate-name()'/>
    <xsl:param name='kids' select='@*|*'/>
    
    <xsl:choose>
      <xsl:when test='$context = "object"'>
        <o name='{$key}'>
          <xsl:apply-templates select='$kids'>
            <xsl:with-param name='context' select='"object"'/>
          </xsl:apply-templates>
        </o>
      </xsl:when>
      <xsl:when test='$context = "array"'>
        <o>
          <xsl:apply-templates select='$kids'>
            <xsl:with-param name='context' select='"object"'/>
          </xsl:apply-templates>
        </o>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Error:  context is not defined for element </xsl:text>
          <xsl:value-of select='name(.)'/>
          <xsl:text> ($context = "</xsl:text>
          <xsl:value-of select='$context'/>
          <xsl:text>", $key = "</xsl:text>
          <xsl:value-of select='$key'/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
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
    <xsl:param name='key' select='np:translate-name()'/>
    <xsl:param name='kids' select='@*|*'/>
    
    <o name='{$key}'>
      <xsl:apply-templates select='$kids'>
        <xsl:with-param name='context' select='"object"'/>
      </xsl:apply-templates>
    </o>
  </xsl:template>

  <!-- 
    object-in-array
    For elements that contain heterogenous content.  These are converted
    into JSON objects.  
  -->
  <xsl:template name='object-in-array'>
    <xsl:param name='kids' select='@*|*'/>
    <o>
      <xsl:apply-templates select='$kids'>
        <xsl:with-param name='context' select='"object"'/>
      </xsl:apply-templates>
    </o>
  </xsl:template>
  
  
  

  <!-- 
    Default template for an element or attribute. 
    Reports a problem.
  -->
  <xsl:template match='@*|*'>
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
      <xsl:value-of select='concat(" (context = ", $context, ")")'/>
    </xsl:message>
    
    <xsl:choose>
      <xsl:when test='$context = "array"'>
        <xsl:call-template name='string-in-array'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='string-in-object'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Default template for text nodes.  Throw them away if they
    are all blanks.  Report a problem otherwise.    -->
  <xsl:template match="text()" >
    <xsl:param name='context' select='"object"'/>
    
    <xsl:if test='normalize-space(.) != ""'>
      <xsl:message>
        <xsl:text>FIXME:  non-blank text node with no template match.  Parent element: </xsl:text>
        <xsl:value-of select='name(..)'/>
      </xsl:message>
      <xsl:choose>
        <xsl:when test='$context = "array"'>
          <xsl:call-template name='string-in-array'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name='string-in-object'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!--=====================================================
    The following templates serialize jxml into JSON.
    These use mode to also encode the context:  either -object
    or -array.  I think this will probably give better 
    performance than passing it down as a parameter.
  -->
  <xsl:template match='o' mode='serialize-jxml-array'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of select='np:start-object($indent)'/>
    <xsl:apply-templates select='*' mode='serialize-jxml-object'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
    </xsl:apply-templates>
    <xsl:value-of select='np:end-object($indent, position() != last())'/>    
  </xsl:template>
  
  <xsl:template match='o' mode='serialize-jxml-object'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of select='np:key-start-object($indent, @name)'/>
    <xsl:apply-templates select='*' mode='serialize-jxml-object'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
    </xsl:apply-templates>
    <xsl:value-of select='np:end-object($indent, position() != last())'/>    
  </xsl:template>
  
  <xsl:template match='a' mode='serialize-jxml-array'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of select='np:start-array($indent)'/>
    <xsl:apply-templates select='*' mode='serialize-jxml-array'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
    </xsl:apply-templates>
    <xsl:value-of select='np:end-array($indent, position() != last())'/>    
  </xsl:template>
  
  <xsl:template match='a' mode='serialize-jxml-object'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:value-of select='np:key-start-array($indent, @name)'/>
    <xsl:apply-templates select='*' mode='serialize-jxml-array'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
    </xsl:apply-templates>
    <xsl:value-of select='np:end-array($indent, position() != last())'/>    
  </xsl:template>
  
  <xsl:template match='s|n|b' mode='serialize-jxml-array'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:variable name='v'>
      <xsl:choose>
        <xsl:when test='name(.) = "n" or name(.) = "b"'>
          <xsl:value-of select='.'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='np:dq(np:json-escape(.))'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select='np:simple($indent, $v, position() != last())'/>
  </xsl:template>

  <xsl:template match='s|n|b' mode='serialize-jxml-object'>
    <xsl:param name='indent' select='""'/>
    
    <xsl:variable name='v'>
      <xsl:choose>
        <xsl:when test='name(.) = "n" or name(.) = "b"'>
          <xsl:value-of select='.'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='np:dq(np:json-escape(.))'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select='np:key-simple($indent, @name, $v, position() != last())'/>
  </xsl:template>
  
  
</xsl:stylesheet>