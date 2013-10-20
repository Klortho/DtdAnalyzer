<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
              xmlns:x="dummy-namespace-for-the-generated-xslt"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
              xmlns:c="http://exslt.org/common"
              xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
              exclude-result-prefixes="xsl xs x xd c"
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

  <!-- Set this to true to cause the generated stylesheet to do some additional
    quality checks on the JSON before outputting it. -->
  <xsl:param name='check-json' select='false()'/>


  <xsl:variable name='nl' select='"&#10;"'/>

  <!-- Create a variable pointing to the root of the input document. -->
  <xsl:variable name='daz' select='/'/>


  <!--=================================================================================
    Some utility functions copied from xml2json.xsl.
    FIXME:  we should import xml2json.xsl, so we don't have to copy this.  But that's
    an XSLT 1.0 stylesheet, and the EXSLT function extension doesn't work right.  But,
    the functions could both be rewritten to invoke a shared template.
  -->
  <xsl:function name='np:boolean-value'>
    <xsl:param name='v'/>
    <xsl:variable name='nv' select='lower-case(normalize-space($v))'/>

    <xsl:choose>
      <xsl:when test='$nv = "0" or $nv = "no" or $nv = "n" or $nv = "false" or
                      $nv = "f" or $nv = "off" or $nv = ""'>
        <xsl:text>false</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>true</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

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
    This template does some basic validation of the JSON annotations.

    FIXME:  Need more validation.  I think one of the barriers to people using this
    will be that their annotations don't work like they expect.  So this is important,
    and useful error messages will help.  Things to check:
      - don't use both @k and @n in the same element
      - simple types don't have non-text kids
      - no unrecognized element or attribute names anywhere
      - simple types don't have both a @s attribute and a text node kid.
    See test/xml2json/itemspec.dtd for some documentation on the annotation schema.

    FIXME:  Can't be done here, but if there's more than one json annotation for an
    element or attribute, complain about that too.
  -->
  <xsl:template name='validate-json-annotation'>
    <xsl:param name='ja'/>
    <xsl:param name='itemName'/>
    <xsl:param name='elemOrAttr'/>

    <xsl:variable name='jaName' select='name($ja)'/>

    <xsl:if test='$ja'>
      <xsl:if test='$elemOrAttr = "elem" and
                    ( $jaName != "json" and
                      $jaName != "s" and $jaName != "n" and $jaName != "b" and
                      $jaName != "m" and
                      $jaName != "o" and $jaName != "a" and $jaName != "c" )'>
        <xsl:message>
          <xsl:text>Error:  invalid json annotation for element </xsl:text>
          <xsl:value-of select='$itemName'/>
          <xsl:text>; I don't understand "</xsl:text>
          <xsl:value-of select='$jaName'/>
          <xsl:text>".</xsl:text>
        </xsl:message>
      </xsl:if>

      <xsl:if test='$elemOrAttr = "attr" and
                    ( $jaName != "json" and
                      $jaName != "s" and $jaName != "n" and $jaName != "b" and
                      $jaName != "c" )'>
        <xsl:message>
          <xsl:text>Error:  invalid json annotation for attribute </xsl:text>
          <xsl:value-of select='$itemName'/>
          <xsl:text>; don't understand "</xsl:text>
          <xsl:value-of select='$jaName'/>
          <xsl:text>".</xsl:text>
        </xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--
    First we make a pass through all the element and attribute declarations in the DTD,
    and determine what we will do with them.
    This will merge the annotations provided by the user with the default
    types computed here.
  -->
  <xsl:variable name='allItems'>

    <!-- For each element defined in the DTD -->
    <xsl:for-each select='/declarations/elements/element[
                            not($ignore-unreachable) or not(@reachable = "false")]'>
      <xsl:variable name='itemName' select='@name'/>

      <!-- Attribute declarations associated with this element -->
      <xsl:variable name='attrDecls' select='//attribute/attributeDeclaration[@element=$itemName]'/>

      <!-- The normalized json annotation.  This resolves all element and attribute synonyms
        to their canonical values -->
      <xsl:variable name='jaWrapper'>
        <xsl:apply-templates select='annotations/annotation[@type="json"]/*'
          mode='normalize-ja'/>
      </xsl:variable>
      <xsl:variable name='ja' select='$jaWrapper/*'/>

      <xsl:call-template name='validate-json-annotation'>
        <xsl:with-param name='ja' select='$ja'/>
        <xsl:with-param name='itemName' select='$itemName'/>
        <xsl:with-param name='elemOrAttr' select='"elem"'/>
      </xsl:call-template>

      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <xsl:variable name='jaName' select='name($ja)'/>

      <!-- $cmSpec - content model spec; one of 'any', 'empty',
        'text', 'mixed', or 'element'. -->
      <xsl:variable name='cmSpec' select='content-model/@spec'/>

      <!--
        $type will used for the name of top-level element of the itemspec for this
        element.  If the the DTD annotation is one of the valid type names (and not
        "json") then use that.  If there is no DTD annotation, or if it's value is
        "json", then we'll have to
        compute the type based on the allowed attributes and the content model, and
        a set of heuristics.

        Valid values:
          - One of the types:  "o", "a", "s", "n", "b", "m", or
          - Custom:  "c" - will cause this element to be ignored.
          - Unknown:  "u" - this will result in a warning message.
      -->
      <xsl:variable name='type'>
        <xsl:choose>
          <xsl:when test='$jaName = "s" or $jaName = "n" or $jaName = "b" or
                          $jaName = "m" or
                          $jaName = "o" or $jaName = "a" or $jaName = "c"'>
            <xsl:value-of select='$jaName'/>
          </xsl:when>

          <!--
            If an element has no attributes, and has text content, then it will be
            a string type
          -->
          <xsl:when test='count($attrDecls) = 0 and content-model/@spec = "text"'>
            <xsl:text>s</xsl:text>
          </xsl:when>

          <!--
            If an element has no attributes, and only one type of child (homogenous
            content), then convert it to a json array.
          -->
          <xsl:when test='count($attrDecls) = 0 and
                          content-model/@spec = "element" and
                          count(content-model/choice/child) = 1'>
            <xsl:text>a</xsl:text>
          </xsl:when>

          <!--
            Preliminary check for 'unknown':  if the content model is 'any' or
            'mixed' ...
          -->
          <xsl:when test='$cmSpec = "any" or $cmSpec = "mixed"'>
            <xsl:text>u</xsl:text>
          </xsl:when>

          <!--
            ... or if the content model is 'element', but any of the kids
            has a quantifier '+' or '*'
          -->
          <xsl:when test='content-model//child[@q="+" or @q="*"] or
                          content-model//choice[@q="+" or @q="*"] or
                          content-model//seq[@q="+" or @q="*"]'>
            <xsl:text>u</xsl:text>
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
                <xsl:text>o</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>u</xsl:text>
              </xsl:otherwise>
            </xsl:choose>

          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!--
        This will be true if an element can have a text node child,
        but not mixed content.  (That is, text and only text, no element children).
        This whole scheme doesn't handle mixed content well.  Mixed content is
        still best handled by custom templates. But, see sample5.dtd, test45,
        for one example.
      -->
      <xsl:variable name='textKid' as='xs:boolean'>
        <xsl:value-of select='($type = "o" or $type = "a") and
                              content-model/@spec = "text"'/>
      </xsl:variable>

      <!--
        The "spec" for this element; like <o n='@uid'/>
      -->
      <xsl:variable name='spec'>
        <xsl:element name='{$type}'>
          <xsl:if test='$textKid'>
            <xsl:attribute name='textKid' select='$textKid'/>
          </xsl:if>
          <xsl:copy-of select='$ja/@*'/>
          <xsl:copy-of select='$ja/*'/>
        </xsl:element>
      </xsl:variable>

      <!--
        groupByKey.  This is a string that controls how the elements and
        attributes are grouped together in the end.  This is a stylized
        serialization of the itemspec.
      -->
      <xsl:variable name="groupByKey">
        <xsl:apply-templates select='$spec/*' mode='groupbykey'/>
      </xsl:variable>

      <!-- Finally, create the itemSpec for this element.  For example, something like
        <item type='element' name="DocumentSummary">
          <o n="@uid"/>
        </item>
      -->
      <item type='element' name='{$itemName}' groupByKey='{$groupByKey}'>
        <xsl:copy-of select='$spec'/>
      </item>
    </xsl:for-each>

    <!-- Now, for each attribute in the DTD -->
    <xsl:for-each select='/declarations/attributes/attribute'>
      <xsl:variable name='itemName' select='@name'/>

      <!-- The normalized json annotation.  This resolves all element and attribute synonyms
        to their canonical values -->
      <xsl:variable name='jaWrapper'>
        <xsl:apply-templates select='annotations/annotation[@type="json"]/*'
          mode='normalize-ja'/>
      </xsl:variable>
      <xsl:variable name='ja' select='$jaWrapper/*'/>

      <xsl:call-template name='validate-json-annotation'>
        <xsl:with-param name='ja' select='$ja'/>
        <xsl:with-param name='itemName' select='$itemName'/>
        <xsl:with-param name='elemOrAttr' select='"attr"'/>
      </xsl:call-template>

      <!-- The name of the top-level element in the json annotation, or "" if there isn't any -->
      <xsl:variable name='jaName' select='name($ja)'/>

      <!--
        $type will used for the name of top-level element of the itemspec for this
        attribute.

        Valid values (for attributes):
          - One of the simple types:  "s", "n", or "b", or
          - Custom:  "c", or
          - Unknown"  "u".
      -->
      <xsl:variable name='type'>
        <xsl:choose>
          <xsl:when test='$jaName = "s" or $jaName = "n" or $jaName = "b" or
                          $jaName = "c"'>
            <xsl:value-of select='$jaName'/>
          </xsl:when>

          <xsl:otherwise>
            <xsl:text>s</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!--
        The "spec" for this attribute; like <n k='fleegle'/>
      -->
      <xsl:variable name="spec">
        <xsl:element name='{$type}'>
          <xsl:copy-of select='$ja/@*'/>
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
      <item type='attribute' name='{$itemName}' groupByKey='{$groupByKey}'>
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
        <xsl:apply-templates select='node()' mode='groupbykey'>
          <xsl:sort select='name(.)'/>
        </xsl:apply-templates>
        <xsl:value-of select='"]"'/>
      </xsl:when>
      <xsl:when test='self::text()'>
        <xsl:value-of select='concat(" text=&apos;", ., "&apos;")'/>
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

    <!-- If $debug is true, then we'll generate a file debug.xml that has all the
      itemspecs. -->
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
      exclude-result-prefixes='np'>

      <x:import href='{$basexslt}'/>

      <xsl:if test='$dtdJA/config/@import'>
        <x:import href='{$dtdJA/config/@import}'/>
      </xsl:if>

      <!-- Specify the output method of the generated stylesheet.  This depends on whether
        we are outputting JXML or JSON. -->
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

      <xsl:choose>
        <!--
          If we're supposed to put out JXML instead of JSON, override the
          root template to prevent serialization.
        -->
        <xsl:when test='$jxml-out'>
          <x:template match='/'>
            <x:call-template name='root'/>
          </x:template>
        </xsl:when>
        <!--
          If, on the other hand, we're instructed to do additional quality checks
          on the output, then override the root template in a different way.
        -->
        <xsl:when test='$check-json'>
          <x:template match="/">
            <x:call-template name='check-json'/>
          </x:template>
        </xsl:when>
      </xsl:choose>

      <!-- Now generate the templates for each element and attribute. -->
      <xsl:for-each-group select="$allItems//item"
                          group-by='@groupByKey'>
        <xsl:variable name='itemSpec' select='current-group()[1]/*'/>

        <!-- The variable 'jsonName' holds the value of the @n (name) attribute of the
          json annotation, which is an XPath expression used to get the key.  -->
        <xsl:variable name='jsonName' select='$itemSpec/@n'/>

        <!-- 'jsonKey' holds the value of the @k (key) attribute.  -->
        <xsl:variable name='jsonKey' select='$itemSpec/@k'/>

        <!--
          The type for this element.
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

          <xsl:when test='$type = "s" or $type = "n" or $type = "b"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='{$type}'>
                <x:with-param name='context' select='$context'/>
                <xsl:choose>
                  <xsl:when test='$jsonName != ""'>
                    <x:with-param name='k' select='{$jsonName}'/>
                  </xsl:when>
                  <xsl:when test='$jsonKey != ""'>
                    <x:with-param name='k' select='"{$jsonKey}"'/>
                  </xsl:when>
                </xsl:choose>
                <xsl:if test='$itemSpec/@s'>
                  <x:with-param name='value' select='{$itemSpec/@s}'/>
                </xsl:if>
              </x:call-template>
            </x:template>
          </xsl:when>

          <!-- Very special: an array or object that has specified kids -->
          <xsl:when test='( ($type = "a" or $type = "o") and $itemSpec/* ) or
                          $type = "m"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>
              <xsl:apply-templates select='$itemSpec' mode='itemspec'/>
            </x:template>
          </xsl:when>

          <xsl:when test='$type = "a"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='a'>
                <x:with-param name='context' select='$context'/>
                <xsl:choose>
                  <xsl:when test='$jsonName != ""'>
                    <x:with-param name='k' select='{$jsonName}'/>
                  </xsl:when>
                  <xsl:when test='$jsonKey != ""'>
                    <x:with-param name='k' select='"{$jsonKey}"'/>
                  </xsl:when>
                </xsl:choose>
                <xsl:choose>
                  <xsl:when test='$itemSpec/@s'>
                    <x:with-param name='kids' select='{$itemSpec/@s}'/>
                  </xsl:when>
                  <xsl:when test='$itemSpec/@textKid = "true"'>
                    <x:with-param name='kids' select='node()'/>
                  </xsl:when>
                </xsl:choose>
              </x:call-template>
            </x:template>
          </xsl:when>

          <xsl:when test='$type = "o"'>
            <x:template match='{$matchString}'>
              <x:param name='context' select='"unknown"'/>

              <x:call-template name='o'>
                <x:with-param name='context' select='$context'/>
                <xsl:choose>
                  <xsl:when test='$jsonName != ""'>
                    <x:with-param name='k' select='{$jsonName}'/>
                  </xsl:when>
                  <xsl:when test='$jsonKey != ""'>
                    <x:with-param name='k' select='"{$jsonKey}"'/>
                  </xsl:when>
                </xsl:choose>
                <xsl:choose>
                  <xsl:when test='$itemSpec/@s'>
                    <x:with-param name='kids' select='{$itemSpec/@s}'/>
                  </xsl:when>
                  <xsl:when test='$itemSpec/@textKid = "true"'>
                    <x:with-param name='kids' select='@*|node()'/>
                  </xsl:when>
                </xsl:choose>
              </x:call-template>
            </x:template>
          </xsl:when>

          <!--
            If type is 'custom', ignore it; otherwise print out a message.
          -->
          <xsl:when test='$type = "u"'>
            <xsl:for-each select='current-group()'>
              <xsl:message>
                <xsl:text>Need to tell me what to do with </xsl:text>
                <xsl:value-of select='concat(@type, " ", @name)'/>
              </xsl:message>
            </xsl:for-each>
          </xsl:when>

          <xsl:when test='$type = "c"'>
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
              <x:call-template name="s">
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

  <xsl:template match='o|a' mode='itemspec'>
    <!-- If we are here from recursing within the json annotation, then this
      will be the name of our parent, either o or a.  -->
    <xsl:param name='metacontext' select='""'/>

    <xsl:comment>
      <xsl:text>Handling itemspec &lt;</xsl:text>
      <xsl:value-of select='name(.)'/>
      <xsl:text>></xsl:text>
    </xsl:comment>
    <xsl:value-of select='$nl'/>

    <xsl:variable name='jsontype' select='name(.)'/>

    <!-- The resultant JSON entity, either <o> or <a> -->
    <xsl:element name='{$jsontype}'>
      <!-- Add either the 'n' attribute, or a conditional that
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
          <x:apply-templates select='{@s}'>
            <x:with-param name='context' select='"{$nextmetacontext}"'/>
          </x:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <!--
    This template either generates a "k" attribute node that gets
    affixed to the JSON entity, or a generated-XSLT if statement that
    causes the key to be computed when the instance document is
    transformed.
    Determine if this node needs a @k attribute, based on
    the value of $metacontext:
      - "o" - yes.
      - "a" - no.
      - "" - this itemspec has no parent, so we need to rely on the
        $context when the stylesheet is run on the instance document,
        and not the $metacontext.
  -->
  <xsl:template name='itemspec-nodename'>
    <xsl:param name='metacontext' select='""'/>

    <xsl:choose>
      <xsl:when test='$metacontext = "o"'>
        <xsl:attribute name='k'>
          <xsl:choose>
            <xsl:when test='@n'>
              <xsl:value-of select='concat("{", @n, "}")'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='@k'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:when>
      <!--
        For reference, in the following, we're generating something in the target
        XSLT that looks like this:
            <xsl:if test='$context = "o"'>
              <xsl:attribute name='k'>
                <xsl:value-of select='np:translate-name()'/>
              </xsl:attribute>
            </xsl:if>
      -->
      <xsl:when test='$metacontext = ""'>
        <x:if test='$context = "o"'>
          <x:attribute name='k'>
            <xsl:choose>
              <xsl:when test='@n'>
                <x:value-of select='{@n}'/>
              </xsl:when>
              <xsl:when test='@k'>
                <xsl:value-of select='@k'/>
              </xsl:when>
              <xsl:otherwise>
                <x:value-of select='np:translate-name()'/>
              </xsl:otherwise>
            </xsl:choose>
          </x:attribute>
        </x:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='s|n|b' mode='itemspec'>
    <xsl:param name='metacontext' select='""'/>

    <xsl:comment>
      <xsl:text>Handling itemspec &lt;</xsl:text>
      <xsl:value-of select='name(.)'/>
      <xsl:text>></xsl:text>
    </xsl:comment>
    <xsl:value-of select='$nl'/>

    <xsl:variable name='jsontype' select='name(.)'/>

    <!-- The resultant JSON entity, either <s>, <n>, or <b> -->
    <xsl:element name='{$jsontype}'>
      <!-- Add either the 'name' attribute, or a conditional that
        causes the name to be generated from the document-instance -->
      <xsl:call-template name='itemspec-nodename'>
        <xsl:with-param name='metacontext' select='$metacontext'/>
      </xsl:call-template>

      <!--
        The value for this simple JSON node will be one of:
        * If there's a text node child, then use that literal value
        * If there's a @s attribute, use that as an XPath expression
        * Neither, then use "." as the XPath expression
      -->
      <xsl:choose>
        <xsl:when test='normalize-space(.) != ""'>
          <xsl:choose>
            <xsl:when test='$jsontype = "s"'>
              <xsl:value-of select='.'/>
            </xsl:when>
            <xsl:when test='$jsontype = "n"'>
              <xsl:value-of select='normalize-space(.)'/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='np:boolean-value(.)'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test='@s'>
          <xsl:choose>
            <xsl:when test='$jsontype = "s"'>
              <x:value-of select='{@s}'/>
            </xsl:when>
            <xsl:when test='$jsontype = "n"'>
              <x:value-of select='normalize-space({@s})'/>
            </xsl:when>
            <xsl:otherwise>
              <x:value-of select='np:boolean-value({@s})'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test='$jsontype = "s"'>
              <x:value-of select='.'/>
            </xsl:when>
            <xsl:when test='$jsontype = "n"'>
              <x:value-of select='normalize-space(.)'/>
            </xsl:when>
            <xsl:otherwise>
              <x:value-of select='np:boolean-value(.)'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match='m' mode='itemspec'>
    <xsl:param name='metacontext' select='""'/>

    <xsl:comment>
      <xsl:text>Handling itemspec &lt;m></xsl:text>
    </xsl:comment>
    <xsl:value-of select='$nl'/>

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

    <!--
      FIXME:  I think I also need to take @textKid into account here.
    -->

    <!-- Figure out the value to use in the select attribute of the apply-templates.
      If @s is given in the itemspec, use that.  If metacontext is given, then
      use the appropriate default for either array or object.  Otherwise, just use
      "@*|*". -->
    <xsl:choose>
      <xsl:when test='@s or $metacontext != ""'>
        <xsl:variable name='select'>
          <xsl:choose>
            <xsl:when test='@s'>
              <xsl:value-of select='@s'/>
            </xsl:when>
            <xsl:when test='$metacontext = "a"'>
              <xsl:text>*</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>@*|*</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <x:apply-templates select='{$select}'>
          <x:with-param name='context' select='{$context-param}'/>
        </x:apply-templates>
      </xsl:when>

      <!-- Otherwise we have to resolve the context at runtime -->
      <xsl:otherwise>
        <x:choose>
          <x:when test='$context = "a"'>
            <x:apply-templates select='*'>
              <x:with-param name='context' select='{$context-param}'/>
            </x:apply-templates>
          </x:when>
          <x:otherwise>
            <x:apply-templates select='@*|*'>
              <x:with-param name='context' select='{$context-param}'/>
            </x:apply-templates>
          </x:otherwise>
        </x:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template match='*' mode='itemspec'>
    <xsl:message>
      <xsl:text>Error:  unrecognized element in itemspec:  </xsl:text>
      <xsl:value-of select='name(.)'/>
    </xsl:message>
  </xsl:template>


  <!--=================================================================================
    These templates are applied to the json annotations, and just normalize
    the element and attribute names to their canonical values.
    E.g. "object" -> "o".
  -->
  <xsl:template match='@*|node()' mode='normalize-ja'>
    <xsl:copy>
      <xsl:apply-templates select='@*|*' mode='normalize-ja'/>
    </xsl:copy>
  </xsl:template>

  <!-- These are allowed to have a text node child -->
  <xsl:template match='s|n|b'>
    <xsl:copy>
      <xsl:apply-templates select='@*|text()'/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match='object' mode='normalize-ja'>
    <o>
      <xsl:apply-templates select='@*|*' mode='normalize-ja'/>
    </o>
  </xsl:template>

  <xsl:template match='array' mode='normalize-ja'>
    <a>
      <xsl:apply-templates select='@*|*' mode='normalize-ja'/>
    </a>
  </xsl:template>

  <xsl:template match='string' mode='normalize-ja'>
    <s>
      <xsl:apply-templates select='@*|text()' mode='normalize-ja'/>
    </s>
  </xsl:template>

  <xsl:template match='number' mode='normalize-ja'>
    <n>
      <xsl:apply-templates select='@*|text()' mode='normalize-ja'/>
    </n>
  </xsl:template>

  <xsl:template match='boolean' mode='normalize-ja'>
    <b>
      <xsl:apply-templates select='@*|text()' mode='normalize-ja'/>
    </b>
  </xsl:template>

  <xsl:template match='member|members' mode='normalize-ja'>
    <m>
      <xsl:apply-templates select='@*|*' mode='normalize-ja'/>
    </m>
  </xsl:template>

  <xsl:template match='custom' mode='normalize-ja'>
    <c>
      <xsl:apply-templates select='@*|*' mode='normalize-ja'/>
    </c>
  </xsl:template>

  <xsl:template match='@select' mode='normalize-ja'>
    <xsl:attribute name='s'>
      <xsl:value-of select='.'/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match='@key' mode='normalize-ja'>
    <xsl:attribute name='k'>
      <xsl:value-of select='.'/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match='@name' mode='normalize-ja'>
    <xsl:attribute name='n'>
      <xsl:value-of select='.'/>
    </xsl:attribute>
  </xsl:template>



</xsl:stylesheet>