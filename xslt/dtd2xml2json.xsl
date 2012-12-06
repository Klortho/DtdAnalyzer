<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:x="dummy-namespace-for-the-generated-xslt"
                exclude-result-prefixes="xs xd"
                version="2.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Dec 6, 2012</xd:p>
    </xd:desc>
  </xd:doc>

  <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
  <xsl:output byte-order-mark="yes" encoding="UTF-8" indent="yes" method="xml"/>
  
  
  <xsl:template match='/'>
    <x:stylesheet version="1.0">
      <xsl:apply-templates/>
    </x:stylesheet>
  </xsl:template>
  
  <xsl:template match='elements'>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match='element'>
    <x:template match='{@name}'>
      
    </x:template>
  </xsl:template>


  <xsl:template match='@*|node()'>
    <xsl:copy>
      <xsl:apply-templates select='@*|node()'/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>