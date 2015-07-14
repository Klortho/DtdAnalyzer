<?xml version="1.0"?>

<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:mml="http://www.w3.org/1998/Math/MathML">


  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="yes"/>

  <xsl:param name="write-ents"/>

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
      <!-- NOTATIONS DIDN't SURVIVE DTDANALYZER -->
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
    <xsl:text>&lt;!ENTITY </xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text> "</xsl:text>
    <xsl:value-of select="value"/>
    <xsl:text>" &gt;&#xA;</xsl:text>
  </xsl:template>


</xsl:stylesheet>
