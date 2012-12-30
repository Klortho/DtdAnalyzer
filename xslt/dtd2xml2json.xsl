<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
              xmlns:x="dummy-namespace-for-the-generated-xslt"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
              xmlns:c="http://exslt.org/common"
              xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
              xmlns:f="http://exslt.org/functions"
              exclude-result-prefixes="x xd c f"
              version="2.0">

  <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
  <xsl:output encoding="UTF-8" method="xml" indent="yes" />
  
  <!-- The path to the base stylesheet.  This is used in the <x:import> of the
    generated XSLT. -->
  <xsl:param name='basexslt' select='"xml2json.xsl"'/>
  
  <!-- This controls whether or not JSON pretty-printing is enabled by default in
    the generated stylesheet. Note that you can always turn on or off pretty-printing;
    this controls the default. The default default is to pretty-print. -->
  <xsl:param name='default-minimized' select='false()'/>

  <!-- This specifies whether or not to ignore unreachable elements in the DTD.
    The default is to ignore them. -->
  <xsl:param name='ignore-unreachable' select='true()'/>

  <!-- Set this to true to write some interesting stuff to debug.xml.  -->
  <xsl:param name='debug' select='false()'/>
  
  <!-- Set this to true to cause the generated stylesheet to output
    JXML instead of JSON. -->
  <xsl:param name='jxml-out' select='false()'/>
  
  <xsl:variable name='nl' select='"&#10;"'/>
  
  <!-- Create a variable pointing to the root of the input document. -->
  <xsl:variable name='daz' select='/'/>

  <!--=================================================================================
    Preliminaries - set a bunch of variables
  -->
  
  <!--
    The dtd-level json annotation, if it exists
  -->
  <xsl:variable name='dtdJA' select='/declarations/dtd/annotations/annotation[@type="json"]/*'/>

  <!-- 
    This tells us whether or not to convert all names into lowercase.  By default, this 
    is false.
  -->
  <xsl:variable name='lcnames' as="xs:boolean">
    <xsl:choose>
      <xsl:when test='$dtdJA/config/@lcnames = "true"'>
        <xsl:value-of select='true()'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='false()'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <!-- 
    First we make a pass through all the element and attribute declarations in the DTD, 
    and determine what we will do with them.
    This will merge the annotations provided by the user with the default
    types computed here.
  -->
  <xsl:variable name='allItems'>
    <xsl:for-each select='/declarations/elements/element[
        not($ignore-unreachable) or not(@reachable = "false")]'>
      <xsl:variable name='elemName' select='@name'/>
      
      <!-- Attribute declarations associated with this element -->
      <xsl:variable name='attrDecls' select='//attribute/attributeDeclaration[@element=$elemName]'/>

      <!-- The json annotation -->
      <xsl:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
      
      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <xsl:variable name='jaName' select='name($ja)'/>
      
      <!-- $typeOverride - one of the valid types, or "custom", or "".  
        If the json-annotation has a valid type name (or "custom"), then we'll use
        that for the new type.  Here we'll also check for valid json annotation
        values. -->
      <xsl:variable name='typeOverride'>
        <xsl:choose>
          <xsl:when test='$jaName = "member"'>
            <xsl:text>members</xsl:text>
          </xsl:when>
          <xsl:when test='$jaName = "string" or $jaName = "number" or $jaName = "boolean" or
                        $jaName = "members" or
                        $jaName = "object" or $jaName = "array" or $jaName = "custom"'>
            <xsl:value-of select='$jaName'/>
          </xsl:when>
          <xsl:when test='$jaName != "" and $jaName != "json"'>
            <xsl:message>
              <xsl:text>Error:  invalid json annotation for element </xsl:text>
              <xsl:value-of select='$elemName'/>
              <xsl:text>; don't understand "</xsl:text>
              <xsl:value-of select='$jaName'/>
              <xsl:text>".</xsl:text>
            </xsl:message>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <!-- $cmSpec - content model spec; one of 'any', 'empty',
        'text', 'mixed', or 'element'. -->
      <xsl:variable name='cmSpec' select='content-model/@spec'/>
      
      <!--
        $type will be the name of the child element here.  If there is a type
        override, then use that.  Otherwise, we'll have to compute it.
        Valid values:  'root', 'string', 'number', 'boolean', 'object', or 'array'.
        If we can't figure out what to map it to, 'unknown'.
      -->
      <xsl:variable name='type'>
        <xsl:choose>
          <xsl:when test='$typeOverride != ""'>
            <xsl:value-of select='$typeOverride'/>
          </xsl:when>
          
          <!-- 
            If an element has no attributes, and has text content, then it will be
            a string type
          -->
          <xsl:when test='count($attrDecls) = 0 and content-model/@spec = "text"'>
            <xsl:text>string</xsl:text>
          </xsl:when>
          
          <!-- 
            If an element has no attributes, and only one type of child (homogenous
            content), then convert it to a json array.
          -->
          <xsl:when test='count($attrDecls) = 0 and 
                        content-model/@spec = "element" and  
                        count(content-model/choice/child) = 1'>
            <xsl:text>array</xsl:text>
          </xsl:when>
          
          <!-- 
            Preliminary check for 'unknown':  if the content model is 'any' or
            'mixed' ...
          -->
          <xsl:when test='$cmSpec = "any" or $cmSpec = "mixed"'>
            <xsl:text>unknown</xsl:text>
          </xsl:when>
          <!-- 
            ... or if the content model is 'element', but any of the kids 
            has a quantifier '+' or '*'
          -->
          <xsl:when test='content-model//child[@q="+" or @q="*"] or
                        content-model//choice[@q="+" or @q="*"] or
                        content-model//seq[@q="+" or @q="*"]'>
            <xsl:text>unknown</xsl:text>
          </xsl:when>
          
          <xsl:otherwise>
            <!-- Need to do a little more work to see if this can be an object.
              First create a list of all it's potential child names. -->
            
            <!-- $kidElemNames - the complete unadulterated list of all the names of all
              possible child elements, possibly with duplicates. -->
            <xsl:variable name='kidElemNames' as='xs:string*' select='content-model//child/text()'/>
            
            <!-- $attrNames - names of all possible attributes -->
            <xsl:variable name='attrNames' as='xs:string*' select='$attrDecls/parent::attribute/@name'/>
            
            <!-- $kidNames - combined list, possibly with duplicates -->
            <!--
              <xsl:variable name='kidNames' select='$kidElemNames | $attrNames'/>-->
            <xsl:variable name='kidNames' as='xs:string*'>
              <xsl:copy-of select='$kidElemNames'/>
              <xsl:copy-of select='$attrNames'/>
            </xsl:variable>
            
            <!-- The same list, converted to lowercase if appropriate ("converted names").
              Possibly with (even more) duplicates.  -->
            <xsl:variable name='kidCNames' as='xs:string*'>
              <xsl:for-each select="$kidNames">
                <xsl:choose>
                  <xsl:when test='$lcnames'>
                    <xsl:value-of select='lower-case(.)'/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select='.'/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:variable>
            
            <xsl:choose>
              <xsl:when test='count($kidCNames) = count(distinct-values($kidCNames))'>
                <xsl:text>object</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>unknown</xsl:text>
              </xsl:otherwise>
            </xsl:choose>

          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- 
        This will be true if an element can have a text node child
      -->
      <xsl:variable name='textKid' as='xs:boolean'>
        <xsl:value-of select='($type = "object" or $type = "array") and
                            content-model/@spec = "text"'/>
      </xsl:variable>
      
      <!-- 
        The "spec" for this element; like <object name='@uid'/>
      -->
      <xsl:variable name='spec'>
        <xsl:element name='{$type}'>
          <xsl:if test='$ja/@name'>
            <xsl:attribute name='name' select='$ja/@name'/>
          </xsl:if>
          <xsl:if test='$textKid'>
            <xsl:attribute name='textKid' select='$textKid'/>
          </xsl:if>
          <xsl:copy-of select='$ja/@*[name(.) != "name"]'/>
          <xsl:copy-of select='$ja/*'/>
        </xsl:element>
      </xsl:variable>
      
      <!-- 
        groupByKey.  This is a string that controls how the elements and 
        attributes are grouped together in the end.  This will basically be
        a serialization of the itemspec.
      -->
      <xsl:variable name="groupByKey">
        <xsl:apply-templates select='$spec/*' mode='groupbykey'/>
      </xsl:variable>
      
      <!-- Finally, create the itemSpec for this element.  For example, something like
        <item type='element' name="DocumentSummary">
          <object name="@uid"/>
        </item>
      -->
      <item type='element' name='{$elemName}' groupByKey='{$groupByKey}'>
        <xsl:copy-of select='$spec'/>
      </item>
    </xsl:for-each>

    <xsl:for-each select='/declarations/attributes/attribute'>
      <xsl:variable name='attrName' select='@name'/>
      
      <!-- The json annotation -->
      <xsl:variable name='ja' select='annotations/annotation[@type="json"]/*'/>
      
      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <xsl:variable name='jaName' select='name($ja)'/>
      
      <!-- $typeOverride - one of the valid types, or "custom", or "".  
        If the json-annotation has a valid type name (or "custom"), then we'll use
        that for the new type.  Here we'll also check for valid json annotation
        values. -->
      <xsl:variable name='typeOverride'>
        <xsl:choose>
          <xsl:when test='$jaName = "string" or $jaName = "number" or $jaName = "boolean" or
                        $jaName = "custom"'>
            <xsl:value-of select='$jaName'/>
          </xsl:when>
          <xsl:when test='$jaName != "" and $jaName != "json"'>
            <xsl:message>
              <xsl:text>Error:  invalid json annotation for attribute </xsl:text>
              <xsl:value-of select='$attrName'/>
              <xsl:text>; don't understand "</xsl:text>
              <xsl:value-of select='$jaName'/>
              <xsl:text>".</xsl:text>
            </xsl:message>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <!--
        $type will be the name of the child element here.  If there is a type
        override, then use that.  Otherwise, we'll have to compute it.
        Valid values:  'string', 'number', 'boolean'.
        If we can't figure out what to map it to, 'unknown'.
      -->
      <xsl:variable name='type'>
        <xsl:choose>
          <xsl:when test='$typeOverride != ""'>
            <xsl:value-of select='$typeOverride'/>
          </xsl:when>
          
          <xsl:otherwise>
            <xsl:text>string</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- 
        The "spec" for this attribute; like <number name='"fleegle"'/>
      -->
      <xsl:variable name="spec">
        <xsl:element name='{$type}'>
          <xsl:if test='$ja/@name'>
            <xsl:attribute name='name' select='$ja/@name'/>
          </xsl:if>
          <xsl:copy-of select='$ja/@*[name(.) != "name"]'/>
          <xsl:copy-of select='$ja/*'/>
        </xsl:element>
      </xsl:variable>
      

      <!-- 
        groupByKey.  This is a string that controls how the elements and 
        attributes are grouped together in the end.  This will basically be
        a serialization of the itemspec.
      -->
      <xsl:variable name="groupByKey">
        <xsl:apply-templates select='$spec/*' mode='groupbykey'/>
      </xsl:variable>
      
      <!-- Finally, create the itemSpec for this attribute.  -->
      <item type='attribute' name='{$attrName}' groupByKey='{$groupByKey}'>
        <xsl:copy-of select='$spec'/>
      </item>
    </xsl:for-each>
  </xsl:variable>

  <!-- 
    This generates the groupByKey used above.  Make sure it is unique for each itemspec,
    and also that if two itemspec's are equivalent from an XML point of view, they have
    the same groupByKey (so sort attributes, for example).
  -->
  <xsl:template match='@*|*' mode='groupbykey'>
    <xsl:choose>
      <xsl:when test='self::*'>
        <xsl:value-of select='concat("[", name(.))'/>
        <xsl:apply-templates select='@*' mode='groupbykey'>
          <xsl:sort select='name(.)'/>
        </xsl:apply-templates>
        <xsl:apply-templates select='*' mode='groupbykey'>
          <xsl:sort select='name(.)'/>
        </xsl:apply-templates>
        <xsl:value-of select='"]"'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='concat(" @", name(.), "=&apos;", ., "&apos;")'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--=================================================================================
    Main template
  -->
  <xsl:template match="/">
    <xsl:if test='$debug'>
      <xsl:result-document href='debug.xml'>
        <debug>
          <xsl:copy-of select='$allItems'/>
        </debug>
      </xsl:result-document>
    </xsl:if>

    <!-- Generate the structure of the XSL stylesheet -->
    <x:stylesheet version="1.0" 
      xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
      exclude-result-prefixes='np xs'>

      <x:import href='{$basexslt}'/>
      <xsl:if test='$dtdJA/config/@import'>
        <x:import href='{$dtdJA/config/@import}'/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test='$jxml-out'>
          <x:output method="xml" version="1.0" encoding="UTF-8" 
            indent="yes" omit-xml-declaration="yes"/>
        </xsl:when>
        <xsl:otherwise>
          <x:output method="text" encoding="UTF-8"/>
        </xsl:otherwise>
      </xsl:choose>
      
      <x:param name='pretty' select='{not($default-minimized)}()'/>

      <!-- 
        Pass the same value of lcnames that we're using down into the generated stylesheet.
      -->
      <x:param name='lcnames' select='{$lcnames}()'/>
      
      <!-- 
        Recapitulation the dtd-annotation as a parameter in the generated stylesheet
      -->
      <x:param name='dtd-annotation'>
        <xsl:copy-of select='$dtdJA'/>
      </x:param>
      
      <!-- 
        If we're supposed to put out JXML instead of JSON, override the
        root template to prevent serialization.
      -->
      <xsl:if test='$jxml-out'>
        <x:template match='/'>
          <x:call-template name='root'/>
        </x:template>
      </xsl:if>
      
      <xsl:for-each-group select="$allItems//item"
                        group-by='@groupByKey'>
        <xsl:variable name='itemSpec' select='current-group()[1]/*'/>
        <!--<xsl:message>itemSpec is <xsl:value-of select='name($itemSpec)'/></xsl:message>-->
        <!-- The variable 'jsonName', if not empty, will be passed to the 'key' param of the
          xml2json template.  -->
        <xsl:variable name='jsonName' select='$itemSpec/@name'/>
        <!-- 
          The type for this element, will be either 
          'unknown', 'root', 'string', 'number', 'boolean', 'object', or 'array'.
        -->
        <xsl:variable name='type' select='name($itemSpec)'/>
        
        <!-- Compute the string that will be used for the "match" attribute of the
          xsl:template that we are generating.  This will be a concatenation of all
          of the names of items in this group. -->
        <xsl:variable name='matchStringSeq' as='xs:string*'>
          <xsl:for-each select='current-group()'>
            <xsl:choose>
              <xsl:when test='@type = "attribute"'>
                <xsl:value-of select='concat("@", @name)'/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select='@name'/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name='matchString'
                    select='string-join($matchStringSeq, " | ")'/>

        <xsl:choose>
          <!-- FIXME:  Do we still need this one for "root"? --> 
          <xsl:when test='$type = "root"'>
            <x:template match='{$matchString}'>
              <x:call-template name='result-start'>
                <xsl:if test='$dtdJA'>
                  <x:with-param name='dtd-annotation'>
                    <xsl:copy-of select='$dtdJA'/>
                  </x:with-param>
                </xsl:if>
              </x:call-template>

              <x:variable name='context' select='"object"'/>
              <xsl:choose>
                <xsl:when test='$itemSpec/*'>
                  <xsl:apply-templates select='$itemSpec' mode='itemspec'/>
                </xsl:when>
                <xsl:otherwise>
                  <x:call-template name='object'>
                    <x:with-param name='context' select='$context'/>
                    <xsl:choose>
                      <xsl:when test='$itemSpec/@textKid = "true"'>
                        <x:with-param name='kids' select='@*|node()'/>
                      </xsl:when>
                      <xsl:when test='$itemSpec/@select'>
                        <x:with-param name='kids' select='{$itemSpec/@select}'/>
                      </xsl:when>
                    </xsl:choose>
                  </x:call-template>
                </xsl:otherwise>
              </xsl:choose>

              <x:value-of select='np:end-object("", false())'/>
            </x:template>
          </xsl:when>
          
          <xsl:when test='$type = "string" or $type = "number" or $type = "boolean"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='{$type}'>
                <x:with-param name='context' select='$context'/>
                <xsl:if test='$jsonName != ""'>
                  <x:with-param name='key' select='{$jsonName}'/>
                </xsl:if>
              </x:call-template>
            </x:template>
          </xsl:when>

          <!-- Very special: an array or object that has specified kids -->
          <xsl:when test='( ($type = "array" or $type = "object") and $itemSpec/* ) or
                        $type = "members"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>
              <xsl:apply-templates select='$itemSpec' mode='itemspec'/>
            </x:template>
          </xsl:when>
          
          <xsl:when test='$type = "array"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='array'>
                <x:with-param name='context' select='$context'/>
                <xsl:if test='$jsonName != ""'>
                  <x:with-param name='key' select='{$jsonName}'/>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test='$itemSpec/@textKid = "true"'>
                    <x:with-param name='kids' select='node()'/>
                  </xsl:when>
                  <xsl:when test='$itemSpec/@select'>
                    <x:with-param name='kids' select='{$itemSpec/@select}'/>
                  </xsl:when>
                </xsl:choose>
              </x:call-template>
            </x:template>
          </xsl:when>
          
          <xsl:when test='$type = "object"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='object'>
                <x:with-param name='context' select='$context'/>
                <xsl:if test='$jsonName != ""'>
                  <x:with-param name='key' select='{$jsonName}'/>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test='$itemSpec/@textKid = "true"'>
                    <x:with-param name='kids' select='@*|node()'/>
                  </xsl:when>
                  <xsl:when test='$itemSpec/@select'>
                    <x:with-param name='kids' select='{$itemSpec/@select}'/>
                  </xsl:when>
                </xsl:choose>
              </x:call-template>
            </x:template>
          </xsl:when>
          
          <!-- 
            If type is 'custom', ignore it; otherwise print out a message.
          -->
          <xsl:when test='$type = "unknown"'>
            <xsl:for-each select='current-group()'>
              <xsl:message>
                <xsl:text>Need to tell me what to do with </xsl:text> 
                <xsl:value-of select='concat(@type, " ", @name)'/>
              </xsl:message>
            </xsl:for-each>
          </xsl:when>
          
          <xsl:when test='$type = "custom"'>
            <!-- do nothing. -->
          </xsl:when>
          
          <xsl:otherwise>  <!-- This should never happen; sanity check.  -->
            <xsl:message>
              <xsl:text>Error:  unknown item group, key = '</xsl:text>
              <xsl:value-of select='current-grouping-key()'/>
              <xsl:text>'; this should never happen.</xsl:text>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>

        <!-- 
          If the type of this element is array or object, and it has text content, then
          also generate a template to match that text.
        -->
        <xsl:if test='$itemSpec/@textKid = "true"'>
          <xsl:for-each select='current-group()'>
            <x:template match="{@name}/text()">
              <x:param name="context" select='"unknown"'/>
              <x:call-template name="string">
                <x:with-param name="context" select="$context"/>
              </x:call-template>
            </x:template>
          </xsl:for-each>
        </xsl:if>
        
      </xsl:for-each-group>

    </x:stylesheet>
  </xsl:template>


  <!--=================================================================================
    Templates that get matched for each element within the json-annotation
    of the DTD.  It gives the author a way to override specific defaults of the automatic
    generation of JSON from the XML.
  -->
  
  <xsl:template match='object|array' mode='itemspec'>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either object or array.  -->
    <xsl:param name='metacontext' select='""'/>
    
    <xsl:comment> 
      <xsl:text>Handling itemspec &lt;</xsl:text>
      <xsl:value-of select='name(.)'/>
      <xsl:text>></xsl:text> 
    </xsl:comment>
    
    <xsl:variable name='jsontype'>
      <xsl:choose>
        <xsl:when test='name(.) = "object"'>
          <xsl:value-of select='"o"'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='"a"'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- The resultant JSON entity, either <o> or <a> -->
    <xsl:element name='{$jsontype}'>  
      <!-- Add either the 'name' attribute, or a conditional that 
        causes the name to be generated from the document-instance -->
      <xsl:call-template name='itemspec-nodename'>
        <xsl:with-param name='metacontext' select='$metacontext'/>
      </xsl:call-template>
      
      <xsl:variable name='nextmetacontext' select='name(.)'/>
      
      <xsl:choose>
        <xsl:when test='*'>
          <xsl:apply-templates select='*' mode='itemspec'>
            <xsl:with-param name='metacontext' select='$nextmetacontext'/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <x:apply-templates select='{@select}'>
            <x:with-param name='context' select='"{$nextmetacontext}"'/>
          </x:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>
  

  <!-- 
    This template either generates a "name" attribute node that gets
    affixed to the JSON entity, or a generated-XSLT if statement that
    causes the name to be computed when the instance document is 
    transformed.
    Determine if this node needs a @name attribute, based on 
    the value of $metacontext:
      - "object" - yes.
      - "array" - no.  
      - "" - this itemspec has no parent, so we need to rely on the
        $context when the stylesheet is run on the instance document,
        and not the $metacontext.
  -->
  <xsl:template name='itemspec-nodename'>
    <xsl:param name='metacontext' select='""'/>

    <xsl:choose>
      <xsl:when test='$metacontext = "object"'>
        <xsl:attribute name='name'>
          <xsl:value-of select='concat("{", @name, "}")'/>
        </xsl:attribute>
      </xsl:when>
      <xsl:when test='$metacontext = ""'>
        <x:if test='$context = "object"'>
          <x:attribute name='name'>
            <x:value-of>
              <xsl:attribute name='select'>
                <xsl:choose>
                  <xsl:when test='@name'>
                    <xsl:value-of select='@name'/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>np:translate-name()</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </x:value-of>
          </x:attribute>
        </x:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  


  <xsl:template match='string|number|boolean' mode='itemspec'>
    <xsl:param name='metacontext' select='""'/>    
    
    <xsl:comment> 
      <xsl:text>Handling itemspec &lt;</xsl:text>
      <xsl:value-of select='name(.)'/>
      <xsl:text>></xsl:text> 
    </xsl:comment>

    <xsl:variable name='jsontype'>
      <xsl:choose>
        <xsl:when test='name(.) = "string"'>
          <xsl:value-of select='"s"'/>
        </xsl:when>
        <xsl:when test='name(.) = "number"'>
          <xsl:value-of select='"n"'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='"b"'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- The resultant JSON entity, either <s>, <n>, or <b> -->
    <xsl:element name='{$jsontype}'>  
      <!-- Add either the 'name' attribute, or a conditional that 
        causes the name to be generated from the document-instance -->
      <xsl:call-template name='itemspec-nodename'>
        <xsl:with-param name='metacontext' select='$metacontext'/>
      </xsl:call-template>
      
      <!-- $value-expr is the XPath expression that will be used to get the 
        content for this -->
      <xsl:variable name='value-expr'>
        <xsl:choose>
          <xsl:when test='@value'>
            <xsl:value-of select='@value'/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <x:value-of select='{$value-expr}'/>
    </xsl:element>
  </xsl:template>



  <xsl:template match='member|members' mode='itemspec'>
    <xsl:param name='metacontext' select='""'/>
    
    <xsl:comment> 
      <xsl:text>Handling itemspec &lt;member> or &lt;members></xsl:text> 
    </xsl:comment>
    
    <!-- Figure out the value to use in the select attribute of the apply-templates.
      If @select is given in the itemspec, use that.  If metacontext is given, then
      use the appropriate default for either array or object.  Otherwise, just use
      "@*|*". -->
    <xsl:variable name='select'>
      <xsl:choose>
        <xsl:when test='@select'>
          <xsl:value-of select='@select'/>
        </xsl:when>
        <xsl:when test='$metacontext = "array"'>
          <xsl:value-of select='"*"'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='"@*|*"'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- Figure out the value to use in the context parameter.  If metacontext
      is given, use that (wrapped in quotes).  Otherwise, use the value 
      "$context", causing the 
      generated stylesheet to pass it's context along. -->
    <xsl:variable name='context-param'>
      <xsl:choose>
        <xsl:when test='$metacontext != ""'>
          <xsl:value-of select='concat("&apos;", $metacontext, "&apos;")'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>$context</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <x:apply-templates select='{$select}'>
      <x:with-param name='context' select='{$context-param}'/>
    </x:apply-templates>
    
  </xsl:template>

  <xsl:template match='*' mode='itemspec'>
    <xsl:message>
      <xsl:text>Error:  unrecognized element in itemspec:  </xsl:text>
      <xsl:value-of select='name(.)'/>
    </xsl:message>
  </xsl:template>

</xsl:stylesheet>