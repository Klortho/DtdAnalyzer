<?xml version="1.0" encoding="UTF-8"?>
<!--
  This stylesheet flattens a DTD into a single file.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                version="2.0">
  
  <xsl:output method='text'/>
  
  <xsl:template match='/'>
    This will be the flattened version of the DTD.
  </xsl:template>
  
</xsl:stylesheet>