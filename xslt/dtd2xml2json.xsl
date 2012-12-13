<?xml version="1.0" encoding="UTF-8"?>
<x:stylesheet xmlns:x="http://www.w3.org/1999/XSL/Transform"
              xmlns:xsl="dummy-namespace-for-the-generated-xslt"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
              xmlns:c="http://exslt.org/common"
              exclude-result-prefixes="xsl xd c"
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
      xml2json template.  -->
    <x:variable name='json-name' select='$json-annotation/@name'/>
    <!--<x:message>json-name is <x:value-of select='$json-name'/></x:message>-->

    <!-- 
      $type-override is from the DTD json annotation top-level
      element name, and overrides the default type that we compute for a
      particular element in the DTD.  For example, if the json annotation 
      contains
          <object/>
      then $type-override will be "object".  The element
      <json> acts as a placeholder, and does not override the type.  So,
      if the json annotation is
          <json name='FOO'/>
      then $type-override will be the empty string.
    -->
    <x:variable name='type-override'>
      <x:if test='name($json-annotation) != "json"'>
        <x:value-of select='name($json-annotation)'/>
      </x:if>
    </x:variable>
    
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
          When an element can have only one type of child (homogenous content),
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
          FIXME:  need to take attributes into account as well.
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
    <x:value-of select='concat($nl, $nl, "   ")'/>
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
    <x:value-of select='concat($nl, "   ")'/>
    
    
    <x:choose>
      <x:when test='$type = "root"'>
        <xsl:template match='{@name}'>
          <xsl:call-template name='result-start'>
            <xsl:with-param name='resulttype' select='"{$json-annotation/@resulttype}"'/>
            <xsl:with-param name='version' select='"{$json-annotation/@version}"'/>
          </xsl:call-template>
          <xsl:apply-templates select='@*|*'>
            <xsl:with-param name='indent' select='$iu'/>
            <xsl:with-param name='context' select='"object"'/>
          </xsl:apply-templates>
          <xsl:value-of select='np:end-object("", false())'/>
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

      <!-- number -->
      <x:when test='$type = "number"'>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='number'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='context' select='$context'/>
            <x:if test='$json-name != ""'>
              <xsl:with-param name='key' select='{$json-name}'/>
            </x:if>
          </xsl:call-template>
        </xsl:template>
      </x:when>

      <!-- boolean -->
      <x:when test='$type = "boolean"'>
        <xsl:template match='{@name}'>
          <xsl:param name='indent' select='""'/>
          <xsl:param name='context' select='"unknown"'/>
          <xsl:call-template name='boolean'>
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
      
      <!-- 
        If type is 'ignore', ignore it; otherwise print out a message.
      -->
      <x:when test='$type != "ignore"'>
        <x:message>
          <x:text>Need to tell me what to do with </x:text> 
          <x:value-of select='@name'/>
        </x:message>
      </x:when>
    </x:choose>
  </x:template>
  
  <!--
    This is the template that gets matched for each element within the json-annotation
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