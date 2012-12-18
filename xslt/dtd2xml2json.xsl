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

  <x:namespace-alias stylesheet-prefix="xsl" result-prefix="x"/>
  <x:output encoding="UTF-8" method="xml" indent="yes" />
  
  <!-- The path to the base stylesheet.  This is used in the <xsl:import> of the
    generated XSLT. -->
  <x:param name='basexslt' select='"xml2json.xsl"'/>
  
  <!-- This controls whether or not JSON pretty-printing is enabled by default in
    the generated stylesheet. Note that you can always turn on or off pretty-printing;
    this controls the default. The default default is to pretty-print. -->
  <x:param name='default-minimized' select='false()'/>
  
  <x:variable name='nl' select='"&#10;"'/>
  
  <!-- Set this to true to write some interesting stuff to debug.xml.  -->
  <x:variable name='debug' select='false()'/>

  <!-- Create a variable pointing to the root of the input document. -->
  <x:variable name='daz' select='/'/>

  <!--=================================================================================
    Preliminaries - set a bunch of variables
  -->
  
  <!--
    The dtd-level json annotation, if it exists
  -->
  <x:variable name='dtdJA' select='/declarations/dtd/annotations/annotation[@type="json"]/*'/>

  <!-- 
    This tells us whether or not to convert all names into lowercase.  By default, this 
    is false.
  -->
  <x:variable name='lcnames' as="xs:boolean">
    <x:choose>
      <x:when test='$dtdJA/@lcnames = "true"'>
        <x:value-of select='true()'/>
      </x:when>
      <x:otherwise>
        <x:value-of select='false()'/>
      </x:otherwise>
    </x:choose>
  </x:variable>
  
  <!-- 
    First we make a pass through all the element and attribute declarations in the DTD, 
    and determine what we will do with them.
    This will merge the annotations provided by the user with the default
    types computed here.
  -->
  <x:variable name='allItems'>
    <x:for-each select='/declarations/elements/element'>
      <x:variable name='elemName' select='@name'/>
      
      <!-- Attribute declarations associated with this element -->
      <x:variable name='attrDecls' select='//attribute/attributeDeclaration[@element=$elemName]'/>

      <!-- The json annotation -->
      <x:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
      
      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <x:variable name='jaName' select='name($ja)'/>
      
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
            <x:value-of select='$typeOverride'/>
          </x:when>
          
          <x:when test='@root="true"'>
            <x:text>root</x:text>
          </x:when>
          
          <!-- 
            If an element has no attributes, and has text content, then it will be
            a string type
          -->
          <x:when test='count($attrDecls) = 0 and content-model/@spec = "text"'>
            <x:text>string</x:text>
          </x:when>
          
          <!-- 
            If an element has no attributes, and only one type of child (homogenous
            content), then convert it to a json array.
          -->
          <x:when test='count($attrDecls) = 0 and 
                        content-model/@spec = "element" and  
                        count(content-model/choice/child) = 1'>
            <x:text>array</x:text>
          </x:when>
          
          <!-- 
            Preliminary check for 'unknown':  if the content model is 'any' or
            'mixed' ...
          -->
          <x:when test='$cmSpec = "any" or $cmSpec = "mixed"'>
            <x:text>unknown</x:text>
          </x:when>
          <!-- 
            ... or if the content model is 'element', but any of the kids 
            has a quantifier '+' or '*'
          -->
          <x:when test='content-model//child[@q="+" or @q="*"] or
                        content-model//choice[@q="+" or @q="*"] or
                        content-model//seq[@q="+" or @q="*"]'>
            <x:text>unknown</x:text>
          </x:when>
          
          <x:otherwise>
            <!-- Need to do a little more work to see if this can be an object.
              First create a list of all it's potential child names. -->
            
            <!-- $kidElemNames - the complete unadulterated list of all the names of all
              possible child elements, possibly with duplicates. -->
            <x:variable name='kidElemNames' as='xs:string*' select='content-model//child/text()'/>
            
            <!-- $attrNames - names of all possible attributes -->
            <x:variable name='attrNames' as='xs:string*' select='$attrDecls/parent::attribute/@name'/>
            
            <!-- $kidNames - combined list, possibly with duplicates -->
            <!--
              <x:variable name='kidNames' select='$kidElemNames | $attrNames'/>-->
            <x:variable name='kidNames' as='xs:string*'>
              <x:copy-of select='$kidElemNames'/>
              <x:copy-of select='$attrNames'/>
            </x:variable>
            
            <!-- The same list, converted to lowercase if appropriate ("converted names").
              Possibly with (even more) duplicates.  -->
            <x:variable name='kidCNames' as='xs:string*'>
              <x:for-each select="$kidNames">
                <x:choose>
                  <x:when test='$lcnames'>
                    <x:value-of select='lower-case(.)'/>
                  </x:when>
                  <x:otherwise>
                    <x:value-of select='.'/>
                  </x:otherwise>
                </x:choose>
              </x:for-each>
            </x:variable>
            
            <x:choose>
              <x:when test='count($kidCNames) = count(distinct-values($kidCNames))'>
                <x:text>object</x:text>
              </x:when>
              <x:otherwise>
                <x:text>unknown</x:text>
              </x:otherwise>
            </x:choose>

          </x:otherwise>
        </x:choose>
      </x:variable>
      
      <!-- 
        This will be true if an element can have a text node child
      -->
      <x:variable name='textKid' as='xs:boolean'>
        <x:value-of select='($type = "object" or $type = "array") and
                            content-model/@spec = "text"'/>
      </x:variable>
      
      <!-- 
        The "spec" for this element; like <object name='@uid'/>
      -->
      <x:variable name='spec'>
        <x:element name='{$type}'>
          <x:if test='$ja/@name'>
            <x:attribute name='name' select='$ja/@name'/>
          </x:if>
          <x:if test='$textKid'>
            <x:attribute name='textKid' select='$textKid'/>
          </x:if>
          <x:copy-of select='$ja/@*[name(.) != "name"]'/>
          <x:copy-of select='$ja/*'/>
        </x:element>
      </x:variable>
      
      <!-- 
        groupByKey.  This is a string that controls how the elements and 
        attributes are grouped together in the end.  This will basically be
        a serialization of the itemspec.
      -->
      <x:variable name="groupByKey">
        <x:apply-templates select='$spec/*' mode='groupbykey'/>
      </x:variable>
      
      <!-- Finally, create the itemSpec for this element.  For example, something like
        <item type='element' name="DocumentSummary">
          <object name="@uid"/>
        </item>
      -->
      <item type='element' name='{$elemName}' groupByKey='{$groupByKey}'>
        <x:copy-of select='$spec'/>
      </item>
    </x:for-each>

    <x:for-each select='/declarations/attributes/attribute'>
      <x:variable name='attrName' select='@name'/>
      
      <!-- The json annotation -->
      <x:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
      
      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <x:variable name='jaName' select='name($ja)'/>
      
      <!-- $typeOverride - one of the valid types, or "custom", or "".  
        If the json-annotation has a valid type name (or "custom"), then we'll use
        that for the new type.  Here we'll also check for valid json annotation
        values. -->
      <x:variable name='typeOverride'>
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
        </x:choose>
      </x:variable>
      
      <!--
        $type will be the name of the child element here.  If there is a type
        override, then use that.  Otherwise, we'll have to compute it.
        Valid values:  'string', 'number', 'boolean'.
        If we can't figure out what to map it to, 'unknown'.
      -->
      <x:variable name='type'>
        <x:choose>
          <x:when test='$typeOverride != ""'>
            <x:value-of select='$typeOverride'/>
          </x:when>
          
          <x:otherwise>
            <x:text>string</x:text>
          </x:otherwise>
        </x:choose>
      </x:variable>
      
      <!-- 
        The "spec" for this attribute; like <number name='"fleegle"'/>
      -->
      <x:variable name="spec">
        <x:element name='{$type}'>
          <x:if test='$ja/@name'>
            <x:attribute name='name' select='$ja/@name'/>
          </x:if>
          <x:copy-of select='$ja/@*[name(.) != "name"]'/>
          <x:copy-of select='$ja/*'/>
        </x:element>
      </x:variable>
      

      <!-- 
        groupByKey.  This is a string that controls how the elements and 
        attributes are grouped together in the end.  This will basically be
        a serialization of the itemspec.
      -->
      <x:variable name="groupByKey">
        <x:apply-templates select='$spec/*' mode='groupbykey'/>
      </x:variable>
      
      <!-- Finally, create the itemSpec for this attribute.  -->
      <item type='attribute' name='{$attrName}' groupByKey='{$groupByKey}'>
        <x:copy-of select='$spec'/>
      </item>
    </x:for-each>
  </x:variable>

  <!-- 
    This generates the groupByKey used above.  Make sure it is unique for each itemspec,
    and also that if two itemspec's are equivalent from an XML point of view, they have
    the same groupByKey (so sort attributes, for example).
  -->
  <x:template match='@*|*' mode='groupbykey'>
    <x:choose>
      <x:when test='self::*'>
        <x:value-of select='concat("[", name(.))'/>
        <x:apply-templates select='@*' mode='groupbykey'>
          <x:sort select='name(.)'/>
        </x:apply-templates>
        <x:apply-templates select='*' mode='groupbykey'>
          <x:sort select='name(.)'/>
        </x:apply-templates>
        <x:value-of select='"]"'/>
      </x:when>
      <x:otherwise>
        <x:value-of select='concat(" @", name(.), "=&apos;", ., "&apos;")'/>
      </x:otherwise>
    </x:choose>
  </x:template>

  <!--=================================================================================
    Main template
  -->
  <x:template match="/">
    <x:if test='$debug'>
      <x:result-document href='debug.xml'>
        <debug>
          <x:copy-of select='$allItems'/>
        </debug>
      </x:result-document>
    </x:if>

    <!-- Generate the structure of the XSL stylesheet -->
    <xsl:stylesheet version="1.0" xmlns:np="http://ncbi.gov/portal/XSLT/namespace">

      <xsl:import href='{$basexslt}'/>
      <xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
      
      <xsl:param name='pretty' select='{not($default-minimized)}()'/>

      <!-- 
        Pass the same value of lcnames that we're using down into the generated stylesheet.
      -->
      <xsl:param name='lcnames' select='{$lcnames}()'/>
    
      <x:for-each-group select="$allItems//item"
                        group-by='@groupByKey'>
        <x:variable name='itemSpec' select='current-group()[1]/*'/>
        <!--<x:message>itemSpec is <x:value-of select='name($itemSpec)'/></x:message>-->
        <!-- The variable 'jsonName', if not empty, will be passed to the 'key' param of the
          xml2json template.  -->
        <x:variable name='jsonName' select='$itemSpec/@name'/>
        <!-- 
          The type for this element, will be either 
          'unknown', 'root', 'string', 'number', 'boolean', 'object', or 'array'.
        -->
        <x:variable name='type' select='name($itemSpec)'/>
        
        <!-- Compute the string that will be used for the "match" attribute of the
          xsl:template that we are generating.  This will be a concatenation of all
          of the names of items in this group. -->
        <x:variable name='matchStringSeq' as='xs:string*'>
          <x:for-each select='current-group()'>
            <x:choose>
              <x:when test='@type = "attribute"'>
                <x:value-of select='concat("@", @name)'/>
              </x:when>
              <x:otherwise>
                <x:value-of select='@name'/>
              </x:otherwise>
            </x:choose>
          </x:for-each>
        </x:variable>
        <x:variable name='matchString'
                    select='string-join($matchStringSeq, " | ")'/>

        <x:choose>
          <x:when test='$type = "root"'>
            <xsl:template match='{$matchString}'>
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
          
          <x:when test='$type = "string" or $type = "number" or $type = "boolean"'>
            <xsl:template match='{$matchString}'>
              <xsl:param name='indent' select='""'/>
              <xsl:param name='context' select='"unknown"'/>
              <xsl:call-template name='{$type}'>
                <xsl:with-param name='indent' select='$indent'/>
                <xsl:with-param name='context' select='$context'/>
                <x:if test='$jsonName != ""'>
                  <xsl:with-param name='key' select='{$jsonName}'/>
                </x:if>
              </xsl:call-template>
            </xsl:template>
          </x:when>

          <!-- Very special: an array or object that has specified kids -->
          <x:when test='($type = "array" or $type = "object") and
                        $itemSpec/*'>
            <xsl:template match='{$matchString}'>
              <xsl:param name='indent' select='""'/>
              <xsl:param name='context' select='"unknown"'/>
              <x:apply-templates select='$itemSpec'/>
            </xsl:template>
          </x:when>
          
          <x:when test='$type = "array"'>
            <xsl:template match='{$matchString}'>
              <xsl:param name='indent' select='""'/>
              <xsl:param name='context' select='"unknown"'/>
              <xsl:call-template name='array'>
                <xsl:with-param name='indent' select='$indent'/>
                <xsl:with-param name='context' select='$context'/>
                <x:if test='$jsonName != ""'>
                  <xsl:with-param name='key' select='{$jsonName}'/>
                </x:if>
                <x:if test='$itemSpec/@textKid = "true"'>
                  <xsl:with-param name='kids' select='node()'/>
                </x:if>
              </xsl:call-template>
            </xsl:template>
          </x:when>
          
          <x:when test='$type = "object"'>
            <xsl:template match='{$matchString}'>
              <xsl:param name='indent' select='""'/>
              <xsl:param name='context' select='"unknown"'/>
              <xsl:call-template name='object'>
                <xsl:with-param name='indent' select='$indent'/>
                <xsl:with-param name='context' select='$context'/>
                <x:if test='$jsonName != ""'>
                  <xsl:with-param name='key' select='{$jsonName}'/>
                </x:if>
                <x:if test='$itemSpec/@textKid = "true"'>
                  <xsl:with-param name='kids' select='@*|node()'/>
                </x:if>
              </xsl:call-template>
            </xsl:template>
          </x:when>
          
          <!-- 
            If type is 'custom', ignore it; otherwise print out a message.
          -->
          <x:when test='$type = "unknown"'>
            <x:for-each select='current-group()'>
              <x:message>
                <x:text>Need to tell me what to do with </x:text> 
                <x:value-of select='concat(@type, " ", @name)'/>
              </x:message>
            </x:for-each>
          </x:when>
          
          <x:when test='$type = "custom"'>
            <!-- do nothing. -->
          </x:when>
          
          <x:otherwise>  <!-- This should never happen; sanity check.  -->
            <x:message>
              <x:text>Error:  unknown item group, key = '</x:text>
              <x:value-of select='current-grouping-key()'/>
              <x:text>'; this should never happen.</x:text>
            </x:message>
          </x:otherwise>
        </x:choose>

        <!-- 
          If the type of this element is array or object, and it has text content, then
          also generate a template to match that text.
        -->
        <x:if test='$itemSpec/@textKid = "true"'>
          <x:for-each select='current-group()'>
            <xsl:template match="{@name}/text()">
              <xsl:param name="indent" select='""'/>
              <xsl:param name="context" select='"unknown"'/>
              <xsl:call-template name="string">
                <xsl:with-param name="indent" select="$indent"/>
                <xsl:with-param name="context" select="$context"/>
              </xsl:call-template>
            </xsl:template>
          </x:for-each>
        </x:if>
        
      </x:for-each-group>

    </xsl:stylesheet>
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