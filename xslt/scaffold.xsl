<!-- ************************************************************************************************ -->
<!-- Stylesheet will convert DtdAnalyzer output into a scaffolded XSLT script that contains a template
     for every element in the original DTD. These templates can be changed to convert content to
	 a new schema. Each template header contains the content model of the element to aid in analysys.
	 
	 Note that if the DTD declares xmlns namespace declarations as attributes, we must redeclare
	 the same namespace and prefix bindings on the root element. We assume that the namespace URIs are
	 probably declared as the default value of the pseudo-attribute. If no default value is found,
	 we output a fake URI. You will need to manually change these values to the correct namespace
	 URI. 
	 
	 Author: Demian Hess, Avalon Consulting, LLC
	 Date: August 30, 2012 -->
<!-- ************************************************************************************************ -->
<xsl:stylesheet version="2.0"  
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:x="urn:xslt:alias">
   
   <xsl:output method="xml" indent="yes"/>
   <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
   <xsl:strip-space elements="*"/>
   <xsl:variable name="crlf" select="'&#10;   '" />
   
   <!-- ************************************************************************************************ -->
   <!-- Template for: / -->
   <!-- ================================================================================================ -->
   <!-- Create stylesheet -->
   <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
   <xsl:template match="/">
      <x:stylesheet version="2.0">
	    <!-- Search for attributes that are actually namespace declarations and add to document element -->
		<xsl:for-each select="/declarations/attributes/attribute[starts-with(@name, 'xmlns:')]">
			<xsl:choose>
				<xsl:when test="attributeDeclaration/@defaultValue">
					<xsl:namespace name="{substring-after(@name, ':')}" select="attributeDeclaration[@defaultValue][1]/@defaultValue" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:namespace name="{substring-after(@name, ':')}" select="'urn:unknown:namespace:uri'"/>
				</xsl:otherwise>
			</xsl:choose>			
		</xsl:for-each>
	  
         <x:output method="xml" indent="yes"/>         
         <xsl:apply-templates select="/declarations/elements/element">
			<xsl:sort select="@name"/>
         </xsl:apply-templates>         
      </x:stylesheet>
   </xsl:template>
   
   <!-- ************************************************************************************************ -->
   <!-- Template for: element -->
   <!-- ================================================================================================ -->
   <!-- Create template for each element -->
   <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
   <xsl:template match="element">
   
      <xsl:variable name="curr-element" select="@name"/>
      <xsl:variable name="attributes" select="/declarations/attributes/attribute/attributeDeclaration[@element eq $curr-element]"/>
	  
      <xsl:value-of select="$crlf"/>
      <xsl:comment> ************************************************************************************************ </xsl:comment>
      <xsl:value-of select="$crlf"/>     
	  <xsl:comment> Template for: <xsl:value-of select="@name"/> <xsl:text> </xsl:text></xsl:comment>
	  <xsl:value-of select="$crlf"/>
      <xsl:comment> ================================================================================================ </xsl:comment>
      <xsl:value-of select="$crlf"/>	  
      <xsl:comment> 
         <xsl:text> Content model for element:</xsl:text>
		 <xsl:value-of select="$crlf"/>
		 <xsl:call-template name="line-wrap">
		    <xsl:with-param name="str" select="content-model/@spaced"/>
		 </xsl:call-template>
         <xsl:if test="$attributes">
		    <xsl:value-of select="$crlf"/>
			<xsl:value-of select="$crlf"/>
            <xsl:text>Attributes:</xsl:text>  
            <xsl:value-of select="$crlf"/>
         </xsl:if>         
         <xsl:for-each select="$attributes">
			<xsl:sort select="parent::attribute/@name"/>
            <xsl:text>   -</xsl:text>
            <xsl:value-of select="parent::attribute/@name"/>
            <xsl:if test="@type | @mode | @defaultValue">
               <xsl:text> (</xsl:text>
               <xsl:for-each select="@type | @mode | @defaultValue">
                  <xsl:choose>
                     <xsl:when test="local-name() eq 'type'">
                        <xsl:text>Type: </xsl:text>
                        <xsl:value-of select="."/>
                     </xsl:when>
                     
                     <xsl:when test="local-name() eq 'mode'">
                        <xsl:text>Mode: </xsl:text>
                        <xsl:value-of select="."/>
                     </xsl:when>
                     
                     <xsl:when test="local-name() eq 'defaultValue'">
                        <xsl:text>Default Value: </xsl:text>
                        <xsl:value-of select="."/>                     
                     </xsl:when>
                  </xsl:choose>                  
                  <xsl:if test="position() ne last()">; </xsl:if>                  
               </xsl:for-each>
               <xsl:text>)</xsl:text>
			   <xsl:value-of select="$crlf"/>
            </xsl:if>
         </xsl:for-each>
      </xsl:comment>
	  <xsl:value-of select="$crlf"/>
      <xsl:comment> ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ </xsl:comment>
      <xsl:value-of select="$crlf"/>	  
	  <x:template match="{@name}"> 
         <x:copy>   
            <xsl:if test="$attributes">
               <x:copy-of select="@*"/>
            </xsl:if>
            
            <x:apply-templates/>
         </x:copy>
      </x:template>  
      <xsl:value-of select="$crlf"/>	  
   </xsl:template>
   
   <!-- ************************************************************************************************ -->
   <!-- Named template: line-wrap -->
   <!-- ================================================================================================ -->
   <!-- Wrap lines every 80 chars (approximately) -->
   <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
   <xsl:template name="line-wrap">
      <xsl:param name="str" select="''"/>
	  <xsl:param name="counter" select="1"/>
	  
	  <xsl:variable name="first-char" select="substring($str, 1, 1)"/>
	  <xsl:choose>
		<xsl:when test="string-length($str) eq 0"/>
		<xsl:when test="$counter ge 80 and $first-char eq ' '">
		   <xsl:value-of select="$crlf"/>
		   <xsl:call-template name="line-wrap">
				<xsl:with-param name="str" select="substring($str, 2)"/>
				<xsl:with-param name="counter" select="1"/>
		   </xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$first-char"/>
		   <xsl:call-template name="line-wrap">
				<xsl:with-param name="str" select="substring($str, 2)"/>
				<xsl:with-param name="counter" select="$counter + 1"/>
		   </xsl:call-template>			
		</xsl:otherwise>
	  </xsl:choose>
   </xsl:template>
   
</xsl:stylesheet>
