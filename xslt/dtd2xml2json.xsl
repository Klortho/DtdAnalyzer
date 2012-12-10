<?xml version="1.0" encoding="UTF-8"?>
<x:stylesheet xmlns:x="http://www.w3.org/1999/XSL/Transform"
              xmlns:xsl="dummy-namespace-for-the-generated-xslt"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
              xmlns:c="http://exslt.org/common"
              exclude-result-prefixes="xsl xd c"
              version="2.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 6, 2012</xd:p>
    </xd:desc>
  </xd:doc>
  
  <x:namespace-alias stylesheet-prefix="xsl" result-prefix="x"/>
  <x:output encoding="UTF-8" method="xml" indent="yes" />
  
  <x:variable name='nl' select='"&#10;"'/>
  <x:param name='basexslt' select='"../../xslt/xml2json.xsl"'/>
  
  <x:template match="/">
    <!-- Generate the structure of the XSL stylesheet -->
    <xsl:stylesheet version="1.0" xmlns:np="http://ncbi.gov/portal/XSLT/namespace">

      <xsl:import href='{$basexslt}'/>
      <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

      <x:apply-templates select='declarations/elements/element'>
        <x:sort select='@name'/>
      </x:apply-templates>
    </xsl:stylesheet>
  </x:template>

  <x:template match='element'>
    <x:variable name='json-annotation' select='annotations/annotation[@type="json"]/*'/>
    
    <!-- The variable 'json-name', if not empty, will be passed to the 'key' param of the
      XML2JSON template.  -->
    <x:variable name='json-name' select='$json-annotation/@name'/>

    <!-- The variable 'type-override' is from the DTD json annotations.
      If not empty, it will override the default type that is
      derived from this node's content model.
    -->
    <x:variable name='type-override' select='name($json-annotation)'/>
    
    <!-- 
      Compute the type for this node.
      Valid values:  'root', 'simple', 'object', or 'array'.
      
      FIXME:  Need to change 'simple' to 'string', and add 'number' and 'boolean'.
        All three of those are simple types, but 'number' and 'boolean' should not
        be quoted.
    -->
    <x:variable name='type'>
      <x:choose>
        <x:when test='$type-override != ""'>
          <x:choose>
            <x:when test='$json-annotation/*'>
              <x:value-of select='"special"'/>
            </x:when>
            <x:otherwise>
              <x:value-of select='$type-override'/>
            </x:otherwise>
          </x:choose>
        </x:when>
        <x:when test='@root="true"'>
          <x:value-of select='"root"'/>
        </x:when>
        
        <!-- 
          Elements with text-only content are converted to simple JSON objects.
          FIXME:  Need to be able to specify number or boolean.
          FIXME:  Also deal with attributes and text nodes here.
        -->
        <x:when test='content-model/@spec = "text"'>
          <x:value-of select='"simple"'/>
        </x:when>
        
        <!-- 
          When an element can have only type of child (homogenous content),
          convert it to a JSON array.
          FIXME:  need to check quantifier; if it's absent or '?', then this 
          *could* be simple content.
        -->        
        <x:when test='( content-model/@spec = "element" and  
                        count(content-model/choice/child) = 1 )'>
          <x:value-of select='"array"'/>
        </x:when>
        
        <!--
          Element content with more than one child, and each child can
          appear at most once.
        -->
        <x:when test='( content-model/@spec = "element" and
                        not( content-model//child[@q="+" or @q="*"] |
                             content-model//choice[@q="+" or @q="*"] |
                             content-model//seq[@q="+" or @q="*"] )
                      )'>
          <x:value-of select='"object"'/>
        </x:when>
      </x:choose>
    </x:variable>
<!--    <x:message>type is '<x:value-of select='$type'/>'.</x:message> -->

    <!-- 
      Write a comment into the destination stylesheet for help to see where
      the type came from. 
    -->
    <x:value-of select='concat($nl, $nl, "  ")'/>
    <x:comment> 
      <x:text> Element </x:text>
      <x:value-of select='@name'/>
      <x:choose>
        <x:when test='$type-override != ""'>
          <x:text>, type override:  </x:text>
          <x:value-of select='$type-override'/> 
        </x:when>
        <x:otherwise>
          <x:text>, type: </x:text>
          <x:value-of select='$type'/>
        </x:otherwise>
      </x:choose>
      <x:text> </x:text>
    </x:comment>
    <x:value-of select='$nl'/>
    
    
    <x:choose>
      <x:when test='$type = "root"'>
        <xsl:template match='{@name}'>
          <xsl:call-template name='result-start'/>
          <xsl:apply-templates select='*'>
            <xsl:with-param name='indent' select='$iu'/>
            <xsl:with-param name='context' select='"object"'/>
          </xsl:apply-templates>
          <xsl:value-of select='concat("}}", $nl)'/>
        </xsl:template>
      </x:when>

      <!-- simple -->
      <x:when test='$type = "simple"'>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='simple'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$json-name != ""'>
              <xsl:with-param name='key' select='{$json-name}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- array -->
      <x:when test='$type = "array"'>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='array'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$json-name != ""'>
              <xsl:with-param name='key' select='{$json-name}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- object -->
      <x:when test='$type = "object"'>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='object'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$json-name != ""'>
              <xsl:with-param name='key' select='{$json-name}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>
      
      <!-- special -->
      <x:when test='$type = "special"'>
        <!-- Get the XML thing that specifies the JSON content -->
        <x:variable name='jcon' select='$json-annotation'/>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <x:apply-templates select='$jcon'/>
        </xsl:template>
      </x:when>
      
      <x:otherwise>
        <x:message>
          <x:text>Need to implement a template for </x:text> 
          <x:value-of select='@name'/>
        </x:message>
      </x:otherwise>
    </x:choose>
  </x:template>
  
  <!--
    This is the template that gets matched for each element within the json-annotation
    of the DTD.  It gives the author a way to override specific defaults of the automatic
    generation of JSON from the XML.
  -->
  <x:template match='object|array|simple|string|number|boolean'>
    <x:param name='metaindent' select='0'/>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either object or array.  -->
    <x:param name='metacontext' select='""'/>

    <x:variable name='currentmeta' select='name(.)'/>
    <x:value-of select='$nl'/>
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text>json annotation for content model: '</x:text> 
        <x:value-of select='$currentmeta'/>
      <x:text>'</x:text>
    </x:comment>
    
    <!-- Output the indent for this level -->
    <xsl:value-of select='$indent'/>
    <x:if test='$metaindent > 0'>
      <xsl:value-of select='$iu{$metaindent}'/>
    </x:if>
    
    <xsl:if test='$context = "object"'>
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
      <xsl:value-of select='concat(np:dq($key), ": ")'/>
    </xsl:if>
    
    <x:choose>
      <x:when test='$currentmeta = "object"'>
        <xsl:value-of select='concat("{{", $nl)'/>
        <x:apply-templates select='*'>
          <x:with-param name='metaindent' select='$metaindent + 1'/>
          <x:with-param name='metacontext' select='$currentmeta'/>
        </x:apply-templates>
        <xsl:value-of select='concat($indent, "}}")'/>
        <xsl:if test='position() != last()'>,</xsl:if>
      </x:when>
      <x:when test='$currentmeta = "array"'>
        <xsl:value-of select='concat("[", $nl )'/>
        <x:apply-templates select='*'>
          <x:with-param name='metaindent' select='$metaindent + 1'/>
          <x:with-param name='metacontext' select='$currentmeta'/>
        </x:apply-templates>
        <xsl:value-of select='concat($indent, "]")'/>
        <xsl:if test='position() != last()'>,</xsl:if>
      </x:when>
    </x:choose>
    <xsl:value-of select='$nl'/>
    
    <x:value-of select='$nl'/>
    <x:comment> 
      <x:text>done: '</x:text> 
      <x:value-of select='name(.)'/>
      <x:text>'</x:text>
    </x:comment>
  </x:template>
</x:stylesheet>