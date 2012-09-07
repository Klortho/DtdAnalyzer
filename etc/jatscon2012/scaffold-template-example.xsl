<!-- **************************************************************************** -->
<!-- Template for: article -->
<!-- ============================================================================ -->
<!-- Content model:
  ( front, body?, back?, floats-group?, ( sub-article* | response* ) )

  Attributes:
  -article-type (Type: CDATA; Mode: #IMPLIED)
  -dtd-version (Type: CDATA; Default Value: 3.0; Mode: #FIXED)
  -xml:lang (Type: NMTOKEN; Default Value: en)
  -xmlns:mml (Type: CDATA; Default Value: http://www.w3.org/1998/Math/MathML; Mode:
  #FIXED)
  -xmlns:xlink (Type: CDATA; Default Value: http://www.w3.org/1999/xlink; Mode:
  #FIXED)
  -xmlns:xsi (Type: CDATA; Default Value: http://www.w3.org/2001/XMLSchema-instance;
  Mode: #FIXED)
-->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<xsl:template match="article">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>
