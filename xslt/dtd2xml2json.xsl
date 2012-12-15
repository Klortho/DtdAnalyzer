<?xml version="1.0" encoding="UTF-8"?>
<x:stylesheet xmlns:x="http://www.w3.org/1999/XSL/Transform"
              xmlns:xsl="dummy-namespace-for-the-generated-xslt"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
              xmlns:c="http://exslt.org/common"
              xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
              xmlns:f="http://exslt.org/functions"
              exclude-result-prefixes="xsl xd c f"
              version="2.0">



  <!-- 
    FIXME:  
    * Converting elements and attribute names to lowercase when using them as
      member names should be optional.  In fact, I think the default should be off.
    * For the default operation of converting to an object, need to check that 
      there are no name clashes between attributes and element kids, and also
      none when names are converted to lowercase (case-insensitive compare).
  -->
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 6, 2012</xd:p>
    </xd:desc>
  </xd:doc>
  
  <x:namespace-alias stylesheet-prefix="xsl" result-prefix="x"/>
  <x:output encoding="UTF-8" method="xml" indent="yes" />
  
  
  <x:param name='basexslt' select='"../../xslt/xml2json.xsl"'/>
  <x:param name='lowercase-names' select='false()'/>
  
  <x:variable name='nl' select='"&#10;"'/>
  <x:variable name='debug' select='false()'/>


  <!--=================================================================================
    Preliminaries - set a bunch of variables
  -->
  
  <!--
    The dtd-level json annotation, if it exists
  -->
  <x:variable name='dtdJA' select='/declarations/dtd/annotations/annotation[@type="json"]/*'/>
  
  <!-- 
    First we make a pass through all the element declarations in the DTD, and determine
    their type.  This will merge the annotations provided by the user with the default
    types computed here.
  -->
  <x:variable name='elemSpecs'>
    <x:for-each select='//element'>
      <x:variable name='elemName' select='@name'/>
      <x:if test='$debug'>
        <x:message>============================================</x:message>
        <x:message>
          <x:value-of select='concat("Looking at element ", $elemName)'/>
        </x:message>
      </x:if>
      
      <!-- Attribute declarations associated with this element -->
      <x:variable name='attrDecls' select='//attribute/attributeDeclaration[@element=$elemName]'/>
      <x:if test='$debug'>
        <x:message>
          <x:value-of select='concat("Number of attr decls: ", count($attrDecls))'/>
        </x:message>
      </x:if>

      <!-- The json annotation -->
      <x:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
      <x:if test='$debug'>
        <x:message>
          <x:text>ja is </x:text>
          <x:copy-of select='$ja'/>
        </x:message>
      </x:if>
      
      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <x:variable name='jaName' select='name($ja)'/>
      <x:if test='$debug'>
        <x:message>
          <x:value-of select='concat("$jaName is ", $jaName)'/>
        </x:message>
      </x:if>
      
      <!-- $typeOverride - one of the valid types, or "custom", or "".  
        If the json-annotation has a valid type name (or "custom"), then we'll use
        that for the new type.  Here we'll also check for valid json annotation
        values. -->
      <x:variable name='typeOverride'>
        <x:choose>
          <x:when test='$jaName = "string" or $jaName = "number" or $jaName = "boolean" or
                        $jaName = "object" or $jaName = "array" or $jaName = "custom"'>
            <x:value-of select='$jaName'/>
          </x:when>
          <x:when test='$jaName != "" and $jaName != "json"'>
            <x:message>
              <x:text>Error:  invalid json annotation for element </x:text>
              <x:value-of select='$elemName'/>
              <x:text>; don't understand "</x:text>
              <x:value-of select='$jaName'/>
              <x:text>".</x:text>
            </x:message>
          </x:when>
        </x:choose>
      </x:variable>
      <x:if test='$debug'>
        <x:message>
          <x:value-of select='concat("$typeOverride is ", $typeOverride)'/>
        </x:message>
      </x:if>
      
      <!-- $cmSpec - content model spec; one of 'any', 'empty',
        'text', 'mixed', or 'element'. -->
      <x:variable name='cmSpec' select='content-model/@spec'/>
      
      <!--
        $type will be the name of the child element here.  If there is a type
        override, then use that.  Otherwise, we'll have to compute it.
        Valid values:  'root', 'string', 'number', 'boolean', 'object', or 'array'.
        If we can't figure out what to map it to, 'unknown'.
      -->
      <x:variable name='type'>
        <x:choose>
          <x:when test='$typeOverride != ""'>
            <x:if test='$debug'><x:message>Setting type to typeOverride</x:message></x:if>
            <x:value-of select='$typeOverride'/>
          </x:when>
          
          <x:when test='@root="true"'>
            <x:if test='$debug'><x:message>Setting type to "root".</x:message></x:if>
            <x:text>root</x:text>
          </x:when>
          
          <!-- 
            If an element has no attributes, and has text content, then it will be
            a string type
          -->
          <x:when test='count($attrDecls) = 0 and content-model/@spec = "text"'>
            <x:if test='$debug'>
              <x:message>No attributes and text content:  "string".</x:message>
            </x:if>
            <x:text>string</x:text>
          </x:when>
          
          <!-- 
            If an element has no attributes, and only one type of child (homogenous
            content), then convert it to a json array.
          -->
          <x:when test='count($attrDecls) = 0 and 
                        content-model/@spec = "element" and  
                        count(content-model/choice/child) = 1'>
            <x:if test='$debug'><x:message>Setting type to "array".</x:message></x:if>
            <x:text>array</x:text>
          </x:when>
          
          <!-- 
            Preliminary check for 'unknown':  if the content model is 'any' or
            'mixed' ...
          -->
          <x:when test='$cmSpec = "any" or $cmSpec = "mixed"'>
            <x:if test='$debug'>
              <x:message>Content model is 'any' or 'mixed':  setting type to "unknown".</x:message>
            </x:if>
            <x:text>unknown</x:text>
          </x:when>
          <!-- 
            ... or if the content model is 'element', but any of the kids 
            has a quantifier '+' or '*'
          -->
          <x:when test='content-model//child[@q="+" or @q="*"] or
                        content-model//choice[@q="+" or @q="*"] or
                        content-model//seq[@q="+" or @q="*"]'>
            <x:if test='$debug'>
              <x:message>Content model has + or * quantifiers:  setting type to "unknown"</x:message>
            </x:if>
            <x:text>unknown</x:text>
          </x:when>
          
          <x:otherwise>
            <!-- Need to do a little more work to see if this can be an object.
              First create a list of all it's potential child names. -->
            
            <!-- $kidElemNames - the complete unadulterated list of all the names of all
              possible child elements, possibly with duplicates. -->
            <x:variable name='kidElemNames' as='xs:string*' select='content-model//child/text()'/>
            <x:if test='$debug'>
              <x:message>
                <x:text>kidElemNames is </x:text>
                <x:value-of select='$kidElemNames'/>
                <x:text>&#10;  count: </x:text>
                <x:value-of select='count($kidElemNames)'/>
              </x:message>
            </x:if>
            
            <!-- $attrNames - names of all possible attributes -->
            <x:variable name='attrNames' as='xs:string*' select='$attrDecls/parent::attribute/@name'/>
            <x:if test='$debug'>
              <x:message>
                <x:text>attrNames is </x:text>
                <x:value-of select='$attrNames'/>
                <x:text>&#10;  count: </x:text>
                <x:value-of select='count($attrNames)'/>
              </x:message>
            </x:if>
            
            <!-- $kidNames - combined list, possibly with duplicates -->
            <!--
              <x:variable name='kidNames' select='$kidElemNames | $attrNames'/>-->
            <x:variable name='kidNames' as='xs:string*'>
              <x:copy-of select='$kidElemNames'/>
              <x:copy-of select='$attrNames'/>
            </x:variable>
            <x:if test='$debug'>
              <x:message>
                <x:text>kidNames is </x:text>
                <x:value-of select='$kidNames'/>
                <x:text>&#10;  count: </x:text>
                <x:value-of select='count($kidNames)'/>
              </x:message>
            </x:if>
            
            <!-- The same list, converted to lowercase if appropriate ("converted names").
              Possibly with (even more) duplicates.  -->
            <x:variable name='kidCNames' as='xs:string*'>
              <x:for-each select="$kidNames">
                <x:choose>
                  <x:when test='$lowercase-names'>
                    <x:value-of select='lower-case(.)'/>
                  </x:when>
                  <x:otherwise>
                    <x:value-of select='.'/>
                  </x:otherwise>
                </x:choose>
              </x:for-each>
            </x:variable>
            <x:if test='$debug'>
              <x:message>
                <x:text>kidCNames is </x:text>
                <x:value-of select='$kidCNames'/>
                <x:text>&#10;  count: </x:text>
                <x:value-of select='count($kidCNames)'/>
              </x:message>
            </x:if>
            
            <x:choose>
              <x:when test='count($kidCNames) = count(distinct-values($kidCNames))'>
                <x:if test='$debug'><x:message>Setting type to "object".</x:message></x:if>
                <x:text>object</x:text>
              </x:when>
              <x:otherwise>
                <x:if test='$debug'><x:message>Setting type to "unknown".</x:message></x:if>
                <x:text>unknown</x:text>
              </x:otherwise>
            </x:choose>

          </x:otherwise>
        </x:choose>
      </x:variable>
      
      <!-- Finally, create the elemSpec for this element.  For example, something like
        <element name="DocumentSummary">
          <object name="@uid"/>
        </element>
      -->
      <element name='{$elemName}'>
        <x:element name='{$type}'>
          <x:if test='$ja/@name'>
            <x:attribute name='name' select='$ja/@name'/>
          </x:if>
          <x:copy-of select='$ja/@*[name(.) != "name"]'/>
          <x:copy-of select='$ja/*'/>
        </x:element>
      </element>
    </x:for-each>
  </x:variable>

  <!--=================================================================================
    Main template
  -->
  <x:template match="/">
    <!-- Generate the structure of the XSL stylesheet -->
    <xsl:stylesheet version="1.0" xmlns:np="http://ncbi.gov/portal/XSLT/namespace">

      <xsl:import href='{$basexslt}'/>
      <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

      <!--<x:copy-of select='$elemSpecs'/>-->

      <x:apply-templates select='declarations/elements/element'/>
      <x:apply-templates select='declarations/attributes/attribute'/>
    </xsl:stylesheet>
  </x:template>


  <!--=================================================================================
    Generate a template to handle each element 
  -->
  <x:template match='element'>
    <x:variable name='elemName' select='@name'/>
    <x:variable name='elemSpec' select='$elemSpecs/element[@name=$elemName]/*'/>

    <!-- The variable 'json-name', if not empty, will be passed to the 'key' param of the
      xml2json template.  -->
    <x:variable name='jsonName' select='$elemSpec/@name'/>
    <!--<x:message>json-name is <x:value-of select='$json-name'/></x:message>-->

    <!-- 
      The type for this element, will be either 
      'unknown', 'root', 'string', 'number', 'boolean', 'object', or 'array'.
    -->
    <x:variable name='type' select='name($elemSpec)'/>
<!--    <x:message>type is '<x:value-of select='$type'/>'.</x:message> -->

    <!-- 
      Write a comment into the destination stylesheet.
    -->
    <x:value-of select='concat($nl, $nl, "   ")'/>
    <x:comment> 
      <x:text> Element </x:text>
      <x:value-of select='$elemName'/>
      <x:text>, type:  </x:text>
      <x:value-of select='$type'/> 
    </x:comment>
    <x:value-of select='concat($nl, "   ")'/>
    
    
    <x:choose>
      <x:when test='$type = "root"'>
        <xsl:template match='{$elemName}'>
          <xsl:call-template name='result-start'>
            <x:if test='$dtdJA'>
              <xsl:with-param name='dtd-annotation'>
                <x:copy-of select='$dtdJA'/>
              </xsl:with-param>
            </x:if>
          </xsl:call-template>
          <xsl:apply-templates select='@*|*'>
            <xsl:with-param name='indent' select='$iu'/>
            <xsl:with-param name='context' select='"object"'/>
          </xsl:apply-templates>
          <xsl:value-of select='np:end-object("", false())'/>
        </xsl:template>
      </x:when>

      <!-- string -->
      <x:when test='$type = "string"'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='string'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>

      <!-- number -->
      <x:when test='$type = "number"'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='number'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>

      <!-- boolean -->
      <x:when test='$type = "boolean"'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='boolean'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>


      <!-- Special: an array or object that has specified kids -->
      <x:when test='($type = "array" or $type = "object") and
                    $elemSpec/*'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <x:apply-templates select='$elemSpec'/>
        </xsl:template>
      </x:when>
      
      <!-- array -->
      <x:when test='$type = "array"'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='array'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- object -->
      <x:when test='$type = "object"'>
        <xsl:template match='{$elemName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='object'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- 
        If type is 'custom', ignore it; otherwise print out a message.
      -->
      <x:when test='$type != "custom"'>
        <x:message>
          <x:text>Need to tell me what to do with element </x:text> 
          <x:value-of select='$elemName'/>
        </x:message>
      </x:when>
    </x:choose>
    
    <!-- 
      If the type of this element is array or object, and it has text content, then
      also generate a template to match that text.
    -->
    <x:if test='($type = "object" or $type = "array") and
                content-model/@spec = "text"'>
      <xsl:template match="{$elemName}/text()">
        <xsl:param name="indent" select='""'/>
        <xsl:param name="context" select='"unknown"'/>
        <xsl:call-template name="string">
          <xsl:with-param name="indent" select="$indent"/>
          <xsl:with-param name="context" select="$context"/>
        </xsl:call-template>
      </xsl:template>
    </x:if>
  </x:template>
  

  <!--=================================================================================
    Generate a template to handle each attribute 
  -->
  <x:template match='attribute'>
    <x:variable name='attrName' select='@name'/>
    <x:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
    <x:variable name='jaName' select='name($ja)'/>
    <!-- 
      Compute the type. This will be one of "custom", "number", "boolean", "string".
    -->
    <x:variable name='type'>
      <x:choose>
        <x:when test='$jaName = "string" or $jaName = "number" or $jaName = "boolean" or
                      $jaName = "custom"'>
          <x:value-of select='$jaName'/>
        </x:when>
        <x:when test='$jaName != "" and $jaName != "json"'>
          <x:message>
            <x:text>Error:  invalid json annotation for attribute </x:text>
            <x:value-of select='$attrName'/>
            <x:text>; don't understand "</x:text>
            <x:value-of select='$jaName'/>
            <x:text>".</x:text>
          </x:message>
        </x:when>
        <x:otherwise>
          <x:text>string</x:text>
        </x:otherwise>
      </x:choose>
    </x:variable>
    
    <!-- The variable 'jsonName', if not empty, will be passed to the 'key' param of the
      xml2json template.  -->
    <x:variable name='jsonName' select='$ja/@name'/>
    <!--<x:message>json-name is <x:value-of select='$json-name'/></x:message>-->
    
    <!-- 
      Write a comment into the destination stylesheet.
    -->
    <x:value-of select='concat($nl, $nl, "   ")'/>
    <x:comment> 
      <x:text> Attribute </x:text>
      <x:value-of select='$attrName'/>
      <x:text>, type:  </x:text>
      <x:value-of select='$type'/> 
    </x:comment>
    <x:value-of select='concat($nl, "   ")'/>
    
    <x:choose>
      <!-- string -->
      <x:when test='$type = "string"'>
        <xsl:template match='@{$attrName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='string'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- number -->
      <x:when test='$type = "number"'>
        <xsl:template match='@{$attrName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='number'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- boolean -->
      <x:when test='$type = "boolean"'>
        <xsl:template match='@{$attrName}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='boolean'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$jsonName != ""'>
              <xsl:with-param name='key' select='{$jsonName}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- 
        If type is 'custom', ignore it; otherwise print out a message.
      -->
      <x:when test='$type != "custom"'>
        <x:message>
          <x:text>Need to tell me what to do with attribute </x:text> 
          <x:value-of select='$attrName'/>
        </x:message>
      </x:when>
      
    </x:choose>
  </x:template>
  
  <!--=================================================================================
    Templates that get matched for each element within the json-annotation
    of the DTD.  It gives the author a way to override specific defaults of the automatic
    generation of JSON from the XML.
  -->
  <x:template match='object'>
    <x:param name='metaindentlevel' select='0'/>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either object or array.  -->
    <x:param name='metacontext' select='""'/>
    <x:variable name='metaindent' select='concat("$iu", $metaindentlevel)'/>
    <x:variable name='trailing-comma'>
      <x:choose>
        <x:when test='$metacontext = ""'>
          <x:text>position() != last()</x:text>
        </x:when>
        <x:when test='position() != last()'>
          <x:text>true()</x:text>
        </x:when>
        <x:otherwise>
          <x:text>false()</x:text>
        </x:otherwise>
      </x:choose>
    </x:variable>
    
    <x:value-of select='$nl'/>
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text>json annotation for content model: object</x:text> 
    </x:comment>
    <x:value-of select='concat($nl, "      ")'/>
    
    <!-- Now output the start, which will depend on context.
      If $metacontext is "object", then definitely output key.  Otherwise,
      if $metacontext is blank, then we have to use $context. -->
    <x:choose>
      <x:when test='$metacontext = "array"'>
        <xsl:value-of select='np:start-object(concat($indent, {$metaindent}))'/>
      </x:when>
      <x:when test='$metacontext = "object"'>
        <xsl:value-of 
          select='np:key-start-object(concat($indent, {$metaindent}), {@name})'/>
      </x:when>
      <x:when test='$metacontext = ""'>
        <xsl:choose>
          <xsl:when test='$context = "array"'>
            <xsl:value-of select='np:start-object(concat($indent, {$metaindent}))'/>
          </xsl:when>
          <xsl:otherwise> <!-- $context = "object" -->
            <xsl:variable name='key'>
              <x:attribute name='select'>
                <x:choose>
                  <x:when test='@name'>
                    <x:value-of select='@name'/>
                  </x:when>
                  <x:otherwise>
                    <x:text>np:to-lower(name(.))</x:text>
                  </x:otherwise>
                </x:choose>
              </x:attribute>
            </xsl:variable>
            
            <xsl:value-of 
              select='np:key-start-object(concat($indent, {$metaindent}), $key)'/>
          </xsl:otherwise>
        </xsl:choose>
      </x:when>
    </x:choose>
    
    <x:choose>
      <x:when test='*'>
        <x:apply-templates select='*'>
          <x:with-param name='metaindentlevel' select='$metaindentlevel + 1'/>
          <x:with-param name='metacontext' select='"object"'/>
        </x:apply-templates>
      </x:when>
      <x:otherwise>
        <xsl:apply-templates select='{@content}'>
          <xsl:with-param name='indent' 
            select='concat($indent, {$metaindent}, $iu)'/>
          <xsl:with-param name='context' select='"object"'/>
        </xsl:apply-templates>
      </x:otherwise>
    </x:choose>

    <xsl:value-of 
      select='np:end-object(concat($indent, {$metaindent}),  {$trailing-comma})'/>

    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text> done: '</x:text> 
      <x:value-of select='name(.)'/>
      <x:text>' </x:text>
    </x:comment>
  </x:template>
  
  <x:template match='array'>
    <x:param name='metaindentlevel' select='0'/>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either object or array.  -->
    <x:param name='metacontext' select='""'/>
    <x:variable name='metaindent' select='concat("$iu", $metaindentlevel)'/>
    <x:variable name='trailing-comma'>
      <x:choose>
        <x:when test='$metacontext = ""'>
          <x:text>position() != last()</x:text>
        </x:when>
        <x:when test='position() != last()'>
          <x:text>true()</x:text>
        </x:when>
        <x:otherwise>
          <x:text>false()</x:text>
        </x:otherwise>
      </x:choose>
    </x:variable>
    
    <x:value-of select='$nl'/>
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text>json annotation for content model: 'array'</x:text> 
    </x:comment>
    <x:value-of select='concat($nl, "      ")'/>

    <!-- Now output the start, which will depend on context.
      If $metacontext is "object", then definitely output key.  Otherwise,
      if $metacontext is blank, then we have to use $context. -->
    <x:choose>
      <x:when test='$metacontext = "array"'>
        <xsl:value-of select='np:start-array(concat($indent, {$metaindent}))'/>
      </x:when>
      <x:when test='$metacontext = "object"'>
        <xsl:value-of 
          select='np:key-start-array(concat($indent, {$metaindent}), {@name})'/>
      </x:when>
      <x:when test='$metacontext = ""'>
        <xsl:choose>
          <xsl:when test='$context = "array"'>
            <xsl:value-of select='np:start-array(concat($indent, {$metaindent}))'/>
          </xsl:when>
          <xsl:otherwise> <!-- $context = "object" -->
            <xsl:variable name='key'>
              <x:attribute name='select'>
                <x:choose>
                  <x:when test='@name'>
                    <x:value-of select='@name'/>
                  </x:when>
                  <x:otherwise>
                    <x:text>np:to-lower(name(.))</x:text>
                  </x:otherwise>
                </x:choose>
              </x:attribute>
            </xsl:variable>
            
            <xsl:value-of 
              select='np:key-start-array(concat($indent, {$metaindent}), $key)'/>
          </xsl:otherwise>
        </xsl:choose>
      </x:when>
    </x:choose>
    
    <x:choose>
      <x:when test='*'>
        <x:apply-templates select='*'>
          <x:with-param name='metaindentlevel' select='$metaindentlevel + 1'/>
          <x:with-param name='metacontext' select='"array"'/>
        </x:apply-templates>
      </x:when>
      <x:otherwise>
        <xsl:apply-templates select='{@content}'>
          <xsl:with-param name='indent' 
            select='concat($indent, {$metaindent}, $iu)'/>
          <xsl:with-param name='context' select='"array"'/>
        </xsl:apply-templates>
      </x:otherwise>
    </x:choose>

    <xsl:value-of 
      select='np:end-array(concat($indent, {$metaindent}), {$trailing-comma})'/>
    
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text> done: '</x:text> 
      <x:value-of select='name(.)'/>
      <x:text>' </x:text>
    </x:comment>
  </x:template>

  <!-- FIXME: Needs more testing. -->
  <x:template match='string|number|boolean'>
    <x:param name='metaindentlevel' select='0'/>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either object or array.  -->
    <x:param name='metacontext' select='""'/>    
    <x:variable name='metaindent' select='concat("$iu", $metaindentlevel)'/>
    <x:variable name='trailing-comma'>
      <x:choose>
        <x:when test='position() != last()'>
          <x:text>true()</x:text>
        </x:when>
        <x:otherwise>
          <x:text>false()</x:text>
        </x:otherwise>
      </x:choose>
    </x:variable>
    
    <x:value-of select='$nl'/>
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text>json annotation for content model: '</x:text> 
      <x:value-of select='name(.)'/>
      <x:text>'</x:text>
    </x:comment>
    <x:value-of select='concat($nl, "      ")'/>
    
    <!-- $value-expr is the XPath expression that will be used to get the content
      for this -->
    <x:variable name='value-expr'>
      <x:choose>
        <x:when test='@value'>
          <x:value-of select='@value'/>
        </x:when>
        <x:otherwise>
          <x:text>.</x:text>
        </x:otherwise>
      </x:choose>
    </x:variable>
    <!-- Next we wrap that XPath expression in a function call that converts
      it into the proper JSON type.  E.g.  "np:number-value(.)" -->
    <x:variable name='v' select='concat(
      "np:", name(.), "-value(", $value-expr, ")")'/>
    
    <!-- Now output the stuff, which will depend on context.
      If $metacontext is "object", then definitely output key.  
      Note that metacontext is never "" for simple types.
    -->
    <x:choose>
      <x:when test='$metacontext = "array"'>
        <xsl:value-of 
          select='np:simple(
            concat($indent, {$metaindent}), {$v}, {$trailing-comma}
          )'/>
      </x:when>
      <x:when test='$metacontext = "object"'>
        <xsl:value-of 
          select='np:key-simple(
            concat($indent, {$metaindent}), "{@name}", {$v}, {$trailing-comma}
          )'/>
      </x:when>
    </x:choose>
    
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text> done: '</x:text> 
      <x:value-of select='name(.)'/>
      <x:text>' </x:text>
    </x:comment>
  </x:template>
</x:stylesheet>