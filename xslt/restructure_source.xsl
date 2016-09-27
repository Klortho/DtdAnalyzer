<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0">
    
    <!-- ============================================================================== -->
    <!-- OUTPUT                                                                         -->
    <!-- ============================================================================== -->
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <!-- ============================================================================== -->
    <!-- WHITESPACE CONTROL                                                             -->
    <!-- ============================================================================== -->
    <xsl:strip-space elements=" declarations element "/>
    
    <!-- ============================================================================== -->
    <!-- PARAMETERS                                                                     -->
    <!-- ============================================================================== -->
    <xsl:param name="nlm1arch" />
    <xsl:param name="nlm11arch" />
    <xsl:param name="nlm2arch" />
    <xsl:param name="nlm21arch" />
    <xsl:param name="nlm22arch" />
    <xsl:param name="nlm23arch" />
    <xsl:param name="nlm3arch" />
    <xsl:param name="jats1arch" />
    <xsl:param name="jats1d1arch" />
    <xsl:param name="jats1d2arch" />
    <xsl:param name="jats1d3arch" />
    <xsl:param name="jats11arch" />
    
    <xsl:param name="nlm1pub" />
    <xsl:param name="nlm11pub" />
    <xsl:param name="nlm2pub" />
    <xsl:param name="nlm21pub" />
    <xsl:param name="nlm22pub" />
    <xsl:param name="nlm23pub" />
    <xsl:param name="nlm3pub" />
    <xsl:param name="jats1pub" />
    <xsl:param name="jats1d1pub" />
    <xsl:param name="jats1d2pub" />
    <xsl:param name="jats1d3pub" />
    <xsl:param name="jats11pub" />
    
    <xsl:param name="nlm21auth" />
    <xsl:param name="nlm22auth" />
    <xsl:param name="nlm23auth" />
    <xsl:param name="nlm3auth" />
    <xsl:param name="jats1auth" />
    <xsl:param name="jats1d1auth" />
    <xsl:param name="jats1d2auth" />
    <xsl:param name="jats1d3auth" />
    <xsl:param name="jats11auth" />   
    
    <xsl:param name="bits01"/>
    <xsl:param name="bits02"/>
    <xsl:param name="bits10"/>
    <xsl:param name="bits20"/>
    
    <!-- ============================================================================== -->
    <!-- Start building new XML here                                                    -->
    <!-- ============================================================================== -->
    <xsl:template match="final-list">
       
        <final-list>
            
            <xsl:for-each select="declarations">
                
                <declarations>
                    <xsl:attribute name="relsysid" select="dtd/@relSysId"/>
                    <xsl:attribute name="systemid" select="dtd/@systemId"/>
                    
                    <xsl:apply-templates select="dtd"/>
                    
                    <xsl:apply-templates select="elements/element">
                        <xsl:sort select="@name"/>
                    </xsl:apply-templates>
                    
                </declarations>
                
            </xsl:for-each>
        </final-list>
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- ELEMENTS/ELEMENT                                                               -->
    <!-- ============================================================================== -->
    <xsl:template match="element">
        <xsl:variable name="nm" select="@name"/>
        <element>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="spec" select="content-model/@spec"/>
            <xsl:attribute name="mini-model" select="content-model/@minified"/>
            <xsl:attribute name="sp-model" select="content-model/@spaced"/>
            <attribute-model>
                <xsl:apply-templates select="parent::elements/following-sibling::attributes/attribute/attributeDeclaration[@element=$nm]">
                   <xsl:sort select="parent::attribute/@name"/>
                </xsl:apply-templates>
            </attribute-model>
        </element>
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- ATTRIBUTES/ATTRIBUTE                                                           -->
    <!-- ============================================================================== -->
    <xsl:template match="attribute/attributeDeclaration">
        <xsl:value-of select="concat('&#x0040;',parent::attribute/@name,'&#x00A0;',@type,'&#x00A0;',@mode,'  ')"/>
        <attribute name="{parent::attribute/@name}" type="{@type}" mode="{@mode}"/>
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- DTD                                                                            -->
    <!-- ============================================================================== -->
    <xsl:template match="dtd">
        
        <xsl:variable name="dtd" select="@systemId"/>
        
        <xsl:variable name="ver">
            <xsl:choose>
                <xsl:when test="$dtd = $nlm1arch or $dtd = $nlm1pub">
                    <xsl:value-of select="'NLM 1.0'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm11arch or $dtd = $nlm11pub">
                    <xsl:value-of select="'NLM 1.1'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm2arch or $dtd = $nlm2pub">
                    <xsl:value-of select="'NLM 2.0'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm21arch or $dtd = $nlm21pub or $dtd = $nlm21auth">
                    <xsl:value-of select="'NLM 2.1'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm22arch or $dtd = $nlm22pub or $dtd = $nlm22auth">
                    <xsl:value-of select="'NLM 2.2'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm23arch or $dtd = $nlm23pub or $dtd = $nlm23auth">
                    <xsl:value-of select="'NLM 2.3'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm3arch or $dtd = $nlm3pub or $dtd = $nlm3auth">
                    <xsl:value-of select="'NLM 3.0'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1arch or $dtd = $jats1pub or $dtd = $jats1auth">
                    <xsl:value-of select="'JATS 1.0'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1d1arch or $dtd = $jats1d1pub or $dtd = $jats1d1auth">
                    <xsl:value-of select="'JATS 1.1d1'"/>
                </xsl:when>   
                <xsl:when test="$dtd = $jats1d2arch or $dtd = $jats1d2pub or $dtd = $jats1d2auth">
                    <xsl:value-of select="'JATS 1.1d2'"/>
                </xsl:when>           
                <xsl:when test="$dtd = $jats1d3arch or $dtd = $jats1d3pub or $dtd = $jats1d3auth">
                    <xsl:value-of select="'JATS 1.1d3'"/>
                </xsl:when>       
                <xsl:when test="$dtd = $jats11arch or $dtd = $jats11pub or $dtd = $jats11auth">
                    <xsl:value-of select="'JATS 1.1'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits01">
                    <xsl:value-of select="'BITS 0.1'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits02">
                    <xsl:value-of select="'BITS 0.2'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits10">
                    <xsl:value-of select="'BITS 1.0'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits20">
                    <xsl:value-of select="'BITS 2.0'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="vdate">
            <xsl:choose>
                <xsl:when test="$dtd = $nlm1arch or $dtd = $nlm1pub">
                    <xsl:value-of select="'20021201'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm11arch or $dtd = $nlm11pub">
                    <xsl:value-of select="'20031101'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm2arch or $dtd = $nlm2pub">
                    <xsl:value-of select="'20040830'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm21arch or $dtd = $nlm21pub or $dtd = $nlm21auth">
                    <xsl:value-of select="'20050630'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm22arch or $dtd = $nlm22pub or $dtd = $nlm22auth">
                    <xsl:value-of select="'20060430'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm23arch or $dtd = $nlm23pub or $dtd = $nlm23auth">
                    <xsl:value-of select="'20070202'"/>
                </xsl:when>
                <xsl:when test="$dtd = $nlm3arch or $dtd = $nlm3pub or $dtd = $nlm3auth">
                    <xsl:value-of select="'20080202'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1arch or $dtd = $jats1pub or $dtd = $jats1auth">
                    <xsl:value-of select="'20120330'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1d1arch or $dtd = $jats1d1pub or $dtd = $jats1d1auth">
                    <xsl:value-of select="'20130915'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1d2arch or $dtd = $jats1d2pub or $dtd = $jats1d2auth">
                    <xsl:value-of select="'20140930'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats1d3arch or $dtd = $jats1d3pub or $dtd = $jats1d3auth">
                    <xsl:value-of select="'20150301'"/>
                </xsl:when>
                <xsl:when test="$dtd = $jats11arch or $dtd = $jats11pub or $dtd = $jats11auth">
                    <xsl:value-of select="'20151215'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits01">
                    <xsl:value-of select="'20120710'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits02">
                    <xsl:value-of select="'20121015'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits10">
                    <xsl:value-of select="'20131225'"/>
                </xsl:when>
                <xsl:when test="$dtd = $bits20">
                    <xsl:value-of select="'20151225'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <dtd-info>
            <xsl:attribute name="version" select="$ver"/>
            <xsl:attribute name="version-date" select="$vdate"/>
        </dtd-info>
    </xsl:template>
    
</xsl:stylesheet>
