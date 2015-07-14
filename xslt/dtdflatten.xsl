<?xml version="1.0"?>

<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:f="http://www.ncbi.nlm.nih.gov/ns/dtdanalyzer">


  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="yes"
              encoding='UTF-8'/>

  <xsl:param name="write-ents" select='"yes"'/>

  <xsl:template match="declarations">
    <xsl:apply-templates select="elements"/>
    <xsl:if test="$write-ents='yes'">
      <xsl:apply-templates select="generalEntities"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="elements">
    <xsl:text>&lt;!-- ========================= --&gt;&#xA;&lt;!-- ELEMENT DECLARATIONS HERE --&gt;&#xA;&lt;!-- ========================= --&gt;&#xA;&#xA;</xsl:text>
    <xsl:apply-templates select="element"/>
  </xsl:template>

  <xsl:template match="element">
    <xsl:variable name="elname" select="@name"/>
    <xsl:text>&lt;!ELEMENT </xsl:text>
    <xsl:value-of select="$elname"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="content-model/@minified"/>
    <xsl:text> &gt;&#xA;</xsl:text>
    <xsl:if test="//attributeDeclaration[@element=$elname]">
      <xsl:text>&lt;!ATTLIST </xsl:text>
      <xsl:value-of select="$elname"/>
      <xsl:apply-templates select="//attributeDeclaration[@element=$elname]"/>
      <xsl:text> &gt;&#xA;</xsl:text>
    </xsl:if>
    <xsl:text>&#xA;&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="attributeDeclaration">
    <xsl:text>&#xA;&#x9;&#x9;</xsl:text>
    <xsl:value-of select="parent::attribute/@name"/>
    <xsl:text>&#x9;&#x9;</xsl:text>
    <xsl:apply-templates select="@type"/>
    <xsl:text>&#x9;&#x9;</xsl:text>
    <xsl:choose>
      <xsl:when test="normalize-space(@mode) or normalize-space(@defaultValue)">
        <xsl:if test="normalize-space(@mode)">
          <xsl:value-of select="@mode"/>
        </xsl:if>
        <xsl:if test="normalize-space(@defaultValue)">
          <xsl:text>&#x9;'</xsl:text>
          <xsl:value-of select="@defaultValue"/>
          <xsl:text>'</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>#IMPLIED</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@type">
    <xsl:choose>
      <!-- NOTATIONS DIDN'T SURVIVE DTDANALYZER -->
      <xsl:when test="starts-with(.,'NOTATION')">
        <xsl:text>CDATA</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template match="generalEntities">
    <xsl:text>&lt;!-- ========================= --&gt;&#xA;&lt;!-- ENTITY DECLARATIONS HERE --&gt;&#xA;&lt;!-- ========================= --&gt;&#xA;&#xA;</xsl:text>
    <xsl:apply-templates select="entity"/>
  </xsl:template>


  <xsl:template match="entity">
    <xsl:value-of select="concat(
      '&lt;!ENTITY ', 
      @name,
      ' &quot;',
      f:str-to-ncrs(value),
      '&quot; &gt;&#xA;'
    )"/>
  </xsl:template>


  <!-- =========== Helper functions ============= -->
  
  <!--
    Take a string and replace each character with a numeric character reference. This returns another string
    which has all the NCRs concatenated together.
  -->
  <xsl:function name='f:str-to-ncrs' as='xs:string'>
    <xsl:param name='s' as='xs:string'/>
    <xsl:value-of select="string-join(
      for $i in string-to-codepoints($s) return concat('&amp;#x', f:int-to-hex($i), ';'),
      ''
      )" />
  </xsl:function>
  
  <!--
    Convert an integer to a hex string.
  -->
  <xsl:function name='f:int-to-hex' as='xs:string'>
    <xsl:param name='i' as='xs:integer'/>
    <xsl:sequence select='
      if ($i lt 16)
      then substring("0123456789ABCDEF", $i + 1, 1)
      else concat(f:int-to-hex($i idiv 16), f:int-to-hex($i mod 16))
      '/>
  </xsl:function>
  
</xsl:stylesheet>
