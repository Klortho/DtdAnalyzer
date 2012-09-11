<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:functx="http://www.functx.com" version="2.0" exclude-result-prefixes="#all">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <iso:schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:sch="http://www.ascc.net/xml/schematron" xmlns:dp="http://www.dpawson.co.uk/ns#" queryBinding="xslt2" schemaVersion="ISO19757-3">
            <iso:title>ISO Schematron file created from DTD</iso:title>
            <iso:ns prefix="dp" uri="http://www.dpawson.co.uk/ns#"/>
            <iso:ns prefix="mml" uri="http://www.w3.org/1998/Math/MathML"/>
            <iso:ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
            <iso:ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>

            <iso:pattern id="heading">
                <!--<iso:title>Report for NLM JATS Journal Publishing 3.0 Article</iso:title>-->
                <iso:rule>
                    <xsl:attribute name="context">
                        <xsl:copy-of select="concat('/', //element[@root-element='yes']/@name)"/>
                    </xsl:attribute>
                    <iso:report test="*">Report date: <iso:value-of select="current-dateTime()"/></iso:report>
                </iso:rule>
            </iso:pattern>

            <xsl:apply-templates/>
        </iso:schema>
    </xsl:template>
    
    <xsl:template name="title-case">
        <xsl:param name="str"/>
        <xsl:value-of select="upper-case(substring($str,1,1))"/>
        <xsl:value-of select="lower-case(substring($str,2))"/>
    </xsl:template>

    <xsl:template match="element">
        <xsl:variable name="element" select="concat('&lt;', @name, '&gt;')"/>
        <iso:pattern>
            <iso:title>
                <xsl:call-template name="title-case">
                    <xsl:with-param name="str" select="@name"/>
                </xsl:call-template>
                <xsl:text> Checks</xsl:text>
            </iso:title>
            <xsl:comment><xsl:value-of select="@model"/></xsl:comment>
            <iso:rule>
                <xsl:attribute name="context">
                    <xsl:copy-of select="concat('//',@name)"/>
                </xsl:attribute>
                <xsl:apply-templates select="attributes">
                    <xsl:with-param name="element" select="$element" tunnel="yes"/>
                </xsl:apply-templates>
                <xsl:if test="exists(attributes) = false()">
                    <iso:report test="@*"><xsl:value-of select="$element"/> must not contain any attributes.</iso:report>
                </xsl:if>
                <xsl:call-template name="model-entities">
                    <xsl:with-param name="str" select="substring-after(@model, '(')"/>
                </xsl:call-template>
                <xsl:apply-templates select="@model">
                    <xsl:with-param name="element" select="$element" tunnel="yes"/>
                </xsl:apply-templates>
            </iso:rule>
        </iso:pattern>
    </xsl:template>
    
    
    <!-- ============================== -->
    <!-- Make allowed attributes report-->
    <!-- ============================== -->
    <xsl:template match="attributes">
        <xsl:param name="element" tunnel="yes"/>
        <iso:report>
            <xsl:variable name="allowed-test">
                <xsl:text>@* except (</xsl:text>
                <xsl:variable name="allowed">
                    <xsl:for-each-group select="attribute[not(contains(@attName, 'xmlns'))]" group-by="@attName">
                        <xsl:value-of select="concat('@',current-grouping-key())"/>
                        <xsl:text> | </xsl:text>
                    </xsl:for-each-group>
                    <xsl:text>)</xsl:text>
                </xsl:variable>
                <xsl:value-of select="replace($allowed, ' \| \)', ')')"/>
            </xsl:variable>
            <xsl:attribute name="test" select="$allowed-test"/>
            <xsl:value-of select="$element"/><xsl:text> cannot contain the following attributes: </xsl:text><iso:value-of select="{concat('(', $allowed-test, ')/name()')}"/>
        </iso:report>
        <xsl:apply-templates select="attribute[@mode='#REQUIRED'], attribute[@mode='#FIXED' and not(contains(@attName, 'xmlns'))], attribute[starts-with(@type, '(') and @mode!='#FIXED']"/>
    </xsl:template>

    <!-- ===================================== -->
    <!-- Make attribute assertions and reports -->
    <!-- ===================================== -->
    <xsl:template match="attribute[@mode='#REQUIRED']">
        <xsl:param name="element" tunnel="yes"/>
        <iso:assert test="{concat('@', @attName)}">
            <xsl:value-of select="concat('@',@attName)"/>
            <xsl:text> is a required attribute for </xsl:text>
            <xsl:value-of select="$element"/>
        </iso:assert>
    </xsl:template>
    
    <xsl:template match="attribute[@mode='#FIXED' and not(contains(@attName, 'xmlns'))]">
        <xsl:param name="element" tunnel="yes"/>
        <iso:assert>
            <xsl:attribute name="test">
                <xsl:value-of select="concat('if (@', @attName, ') then @', @attName)"/>
                <xsl:text>='</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>' else not(@</xsl:text>
                <xsl:value-of select="concat(@attName,')')"/>
            </xsl:attribute>
            <xsl:value-of select="concat('@', @attName)"/>
            <xsl:text> is a fixed attribute for </xsl:text>
            <xsl:value-of select="$element"/>
            <xsl:text> and must equal "</xsl:text>
            <xsl:value-of select="(.)"/>
            <xsl:text>"</xsl:text>
        </iso:assert>
    </xsl:template>
    
    <xsl:template match="attribute[starts-with(@type, '(') and @mode!='#FIXED']">
        <xsl:param name="element" tunnel="yes"/>
        <iso:assert>
            <xsl:attribute name="test">
                <xsl:variable name="attName" select="concat('@', @attName)"/>
                <xsl:value-of select="concat('if (@', @attName,') then ')"/>
                <xsl:variable name="values">
                    <xsl:for-each-group select="tokenize(translate(@type, '()', ''), '\|')" group-by=".">
                        <xsl:value-of select="$attName"/>
                        <xsl:text>='</xsl:text>
                        <xsl:value-of select="current-grouping-key()"/>
                        <xsl:text>' or </xsl:text>
                    </xsl:for-each-group>
                </xsl:variable>
                <xsl:value-of select="string-join((tokenize($values, 'or ')[position() != last()]), 'or ')"/>
                <xsl:value-of select="concat('else not(@', @attName, ')')"></xsl:value-of>
            </xsl:attribute>
            <xsl:text>The attribute </xsl:text>
            <xsl:value-of select="concat('@',@attName)"/>
            <xsl:text> can only equal: </xsl:text>
            <xsl:value-of select="string-join((tokenize(translate(string-join((tokenize(@type, '\|')), ', '), '()', ''), ',')[position() != last()]), ',')"></xsl:value-of>
            <xsl:text> or</xsl:text>
            <xsl:value-of select="tokenize(translate(string-join((tokenize(@type, '\|')), ', '), '()', ''), ',')[last()]"/>
        </iso:assert>
    </xsl:template> 
    
    
    <!-- ============================ -->
    <!-- Make allowed elements report -->
    <!-- ============================ -->
    <xsl:template match="@model">
        <xsl:param name="element" tunnel="yes"/>
        <xsl:if test="not(contains(., '#PCDATA'))">
            <iso:report test="child::text()[normalize-space()]">
                <xsl:value-of select="$element"/>
                <xsl:text> should not contain #PCDATA</xsl:text>
            </iso:report>
        </xsl:if>
        <xsl:if test=".='EMPTY'">
            <iso:report test="*">
                <xsl:value-of select="$element"/>
                <xsl:text> should be empty</xsl:text>
            </iso:report>
        </xsl:if>
        <xsl:if test=".!='EMPTY' and not(starts-with(., '(#PCDATA)'))">
            <iso:report>
                <xsl:variable name="allowed-test">
                    <xsl:text>* except (</xsl:text>
                    <xsl:value-of select="replace(string-join((tokenize(translate(translate(substring-after(., '('), '|,', '  '), '?()*+', ''), '\s+')), ' | '), '#PCDATA', 'text()')"/>
                    <xsl:text>)</xsl:text>
                </xsl:variable>
                <xsl:attribute name="test" select="$allowed-test"/>
                <xsl:value-of select="$element"/><xsl:text> cannot contain the following elements: </xsl:text><iso:value-of select="{concat('(', $allowed-test, ')/name()')}"/>
            </iso:report>
            
            <!-- ============================ -->
            <!-- Make element ordering report -->
            <!-- ============================ -->            
            <xsl:if test="not(ends-with(., '*')) and contains(., ',')">
                <iso:report>
                    <xsl:attribute name="test">
                        <xsl:variable name="order-test">
                            <xsl:call-template name="ordering">
                                <xsl:with-param name="str" select="substring-after(., '(')"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="string-join((tokenize($order-test, ' or ')[position() != last()]), ' or ')"/>
                    </xsl:attribute>
                    <xsl:text>Child elements of </xsl:text><xsl:value-of select="$element"/><xsl:text> are out of order. <!--The correct order is: </xsl:text><xsl:value-of select="replace(replace(replace(replace(replace(., '\|', ' or '), ',', ', then: '), '\*', '[0 or more]'), '\+', '[1 or more]'), '\?', '[0 or 1]')"/>-->Element model: </xsl:text><xsl:value-of select="replace(replace(., ',', ', '), '\|', ' | ')"/>
                </iso:report>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    
    <!-- ================================= -->
    <!-- Make model assertions and reports -->
    <!-- ================================= -->
    <xsl:template name="model-entities">
        <xsl:param name="str"/>
        <xsl:param name="output"/>
        <xsl:choose>
            <xsl:when test="$str">
                <xsl:choose>

                    <!-- =============================== -->
                    <!-- Handle parenthetical statements -->
                    <!-- =============================== -->
                    <xsl:when test="starts-with($str, '(')">
                        <xsl:variable name="inside-paren">
                            <xsl:call-template name="paren-nesting">
                                <xsl:with-param name="str" select="$str"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            
                            <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                            <!-- Zero or more of any: no tests -->
                            <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                            <xsl:when test="ends-with($inside-paren, '*')">
                              <xsl:call-template name="model-entities">
                                    <xsl:with-param name="str" select="substring-after(substring($str, string-length($inside-paren)), ',')"/>
                                    <xsl:with-param name="output">
                                        <xsl:copy-of select="$output"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!-- ~~~~~~~~~~~~~~~ -->
                            <!-- Either/Or tests -->
                            <!-- ~~~~~~~~~~~~~~~ -->
                            <xsl:when test="starts-with($inside-paren, '(') and contains(translate($inside-paren, '+?*', ''), ')|') and not(contains($inside-paren, ',('))">
                                <xsl:variable name="or" select="substring-after(substring-after($inside-paren, ')'),'|')"/>
                                <xsl:variable name="either">
                                    <xsl:if test="contains($inside-paren, ')|')">
                                        <xsl:value-of select="concat(substring-before($inside-paren, ')|'), ')')"/>
                                    </xsl:if>
                                    <xsl:if test="contains($inside-paren, ')*|')">
                                        <xsl:value-of select="concat(substring-before($inside-paren, ')*|'), ')*')"/>
                                    </xsl:if>
                                    <xsl:if test="contains($inside-paren, ')+|')">
                                        <xsl:value-of select="concat(substring-before($inside-paren, ')+|'), ')+')"/>
                                    </xsl:if>
                                    <xsl:if test="contains($inside-paren, ')?|')">
                                        <xsl:value-of select="concat(substring-before($inside-paren, ')?|'), ')?')"/>
                                    </xsl:if>
                                    <xsl:value-of select="substring($inside-paren, string-length($inside-paren))"/>
                                </xsl:variable>
                                <xsl:if test="not(matches(translate($either, '()?,+*', ''), translate($or, '()?,+*', ''))) and not(matches(translate($or, '()?,+*', ''), translate($either, '()?,+*', '')))">
                                    <iso:assert>
                                        <xsl:attribute name="test">
                                            <xsl:text>if (</xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($or, '?+*()', ''), ',')),' or ')"/>
                                            <xsl:text>) then not(</xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($either, '?+*()', ''), ',')),' or ')"/>
                                            <xsl:text>) else not(</xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($or, '?+*()', ''), ',')),' or ')"/>
                                            <xsl:text>)</xsl:text>
                                        </xsl:attribute>
                                        <xsl:value-of select="concat('&lt;', @name,'&gt;')"/>
                                        <xsl:text> cannot contain both (&lt;</xsl:text>
                                        <xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($either, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/>
                                        <xsl:text>&gt;) and (&lt;</xsl:text>
                                        <xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($or, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/>
                                        <xsl:text>&gt;)</xsl:text>
                                    </iso:assert>
                                </xsl:if>
                                <xsl:variable name="element" select="concat('&lt;',@name,'&gt;')"/>
                                <xsl:choose>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- No more than one of either side -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with($inside-paren, '?')">            
                                        <xsl:for-each select="tokenize(translate($or, '()?+*', ''), ',')">
                                            <iso:report>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="concat('count(',., ') > 1')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="$element"/>
                                                <xsl:text> cannot have more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',.,'&gt;')"/>
                                            </iso:report>
                                        </xsl:for-each>
                                        <xsl:for-each select="tokenize(translate($either, '()?+*', ''), ',')">
                                            <iso:report>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="concat('count(',., ') > 1')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="$element"/>
                                                <xsl:text> cannot have more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',.,'&gt;')"/>
                                            </iso:report>
                                        </xsl:for-each>
                                    </xsl:when>

                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- Minimum one of either side -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with($inside-paren, '+')">
                                        <xsl:comment>NO TEST HERE YET</xsl:comment>
                                        <xsl:comment><xsl:text>Either/Or: </xsl:text><xsl:copy-of select="$inside-paren"/></xsl:comment>
                                        <xsl:comment><xsl:text>Either: </xsl:text><xsl:copy-of select="$either"/></xsl:comment>
                                        <xsl:comment><xsl:text>Or: </xsl:text><xsl:copy-of select="$or"/></xsl:comment>
                                        <iso:assert>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="concat('(', string-join((tokenize(translate($either, '?+*()', ''), ',')),' or '), ')')"/>
                                                <xsl:text> or </xsl:text>
                                                <xsl:value-of select="concat('(', string-join((tokenize(translate($or, '?+*()', ''), ',')),' or '), ')')"/>
                                              </xsl:attribute>
                                            <xsl:value-of select="$element"/><xsl:text> must contain at least one (&lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($either, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/><xsl:text>&gt;) or (&lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($or, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/><xsl:text>&gt;)</xsl:text>
                                        </iso:assert>
                                    </xsl:when>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~ -->
                                    <!-- Either side tests -->
                                    <!-- ~~~~~~~~~~~~~~~~~ -->
                                    <xsl:otherwise>
                                        
                                        <!-- ,,,,,,,,,,,, -->
                                        <!-- Either tests -->
                                        <!-- '''''''''''' -->
                                        <xsl:for-each-group select="tokenize(translate($either, '()', ''), ',')" group-by=".">
                                            <xsl:variable name="entity-name" select="translate(current-grouping-key(), '+?*~ ', '')"/>
                                            <xsl:choose>
                                                
                                                <!-- No tests -->
                                                <xsl:when test="ends-with(current-grouping-key(), '*')"/>
                                                
                                                <!-- At least one of either -->
                                                <xsl:when test="ends-with(current-grouping-key(), '+')">
                                                     <iso:assert>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="$entity-name"/><xsl:text> or </xsl:text>
                                                            <xsl:choose>
                                                                <xsl:when test="not(contains($or, ',') or contains($or, '|'))">
                                                                    <xsl:if test="contains($or, '+')">
                                                                        <xsl:value-of select="translate($or, '+?*~() ', '')"/>
                                                                    </xsl:if>
                                                                </xsl:when>
                                                                <xsl:otherwise>
                                                                    <xsl:value-of select="concat('(', string-join((tokenize(translate($or, '?+*()', ''), ',')),' or '), ')')"/>
                                                                </xsl:otherwise>
                                                            </xsl:choose>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/><xsl:text> must contain at least one </xsl:text><xsl:value-of select="concat('&lt;', $entity-name, '&gt;')"/><xsl:text> or &lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($or, '?+*()', ''), ',')),'&gt;/&lt;'), '\|')),'&gt;/&lt;')"/><xsl:text>&gt;</xsl:text>
                                                    </iso:assert>
                                                </xsl:when>
                                                
                                                <!-- No more than one -->
                                                <xsl:when test="ends-with(current-grouping-key(), '?')">
                                                    <iso:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/>
                                                        <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </iso:report>
                                                </xsl:when>
                                                
                                                <!-- One of either and no more than one -->
                                                <xsl:otherwise>
                                                    <iso:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/> <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </iso:report>
                                                    <iso:assert>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="$entity-name"/><xsl:text> or </xsl:text>
                                                            <xsl:choose>
                                                                <xsl:when test="not(contains($or, ',') or contains($or, '|'))">
                                                                    <xsl:if test="not(contains($or, '?') or contains($or, '+') or contains($or, '*'))">
                                                                        <xsl:value-of select="translate($or, '~() ', '')"/>
                                                                    </xsl:if>
                                                                </xsl:when>
                                                                <xsl:otherwise>
                                                                    <xsl:value-of select="concat('(', string-join((tokenize(translate($or, '?+*()', ''), ',')),' or '), ')')"/>
                                                                </xsl:otherwise>
                                                            </xsl:choose>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/><xsl:text> must contain at least one </xsl:text><xsl:value-of select="concat('&lt;', $entity-name, '&gt;')"/><xsl:text> or &lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($or, '?+*()', ''), ',')),'&gt;/&lt;'), '\|')),'&gt;/&lt;')"/><xsl:text>&gt;</xsl:text>
                                                    </iso:assert>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:for-each-group>
                                        
                                        <!-- ,,,,,,,, -->
                                        <!-- Or tests -->
                                        <!-- '''''''' -->
                                        <xsl:for-each-group select="tokenize(translate($or, '()', ''), ',')" group-by=".">
                                            <xsl:variable name="entity-name" select="translate(current-grouping-key(), '+?*~ ', '')"/>
                                            <xsl:choose>
                                                
                                                <!-- No tests -->
                                                <xsl:when test="ends-with(current-grouping-key(), '*')"/>
                                                   
                                                <!-- At least one -->
                                                <xsl:when test="ends-with(current-grouping-key(), '+')">
                                                    <xsl:choose>
                                                        <xsl:when test="not(contains($either, '+') or contains($either, '?'))">
                                                            <iso:assert>
                                                                <xsl:attribute name="test">
                                                                    <xsl:value-of select="$entity-name"/><xsl:text> or </xsl:text>
                                                                    <xsl:choose>
                                                                        <xsl:when test="not(contains($either, ',') or contains($either, '|'))">
                                                                            <xsl:value-of select="translate($either, '+?*~() ', '')"/>
                                                                        </xsl:when>
                                                                        <xsl:otherwise>
                                                                            <xsl:value-of select="concat('(', string-join((tokenize(translate($either, '?+*()', ''), ',')),' or '), ')')"/>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                </xsl:attribute>
                                                                <xsl:value-of select="$element"/><xsl:text> must contain at least one </xsl:text><xsl:value-of select="concat('&lt;', $entity-name, '&gt;')"/><xsl:text> or &lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($either, '?+*()', ''), ',')),'&gt;/&lt;'), '\|')),'&gt;/&lt;')"/><xsl:text>&gt;</xsl:text>
                                                            </iso:assert>
                                                        </xsl:when>
                                                    </xsl:choose>                                                    
                                                </xsl:when>
                                                
                                                <!-- No more than one -->
                                                <xsl:when test="ends-with(current-grouping-key(), '?')">
                                                    <iso:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/>
                                                        <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </iso:report>
                                                </xsl:when>
                                                
                                                <!-- One of either and no more than one -->
                                                <xsl:otherwise>
                                                    <xsl:choose>
                                                        <xsl:when test="contains($either, '*')">
                                                            <iso:assert>
                                                                <xsl:attribute name="test">
                                                                    <xsl:value-of select="$entity-name"/><xsl:text> or </xsl:text>
                                                                    <xsl:choose>
                                                                        <xsl:when test="not(contains($either, ',') or contains($either, '|'))">
                                                                            <xsl:value-of select="translate($either, '+?*~() ', '')"/>
                                                                        </xsl:when>
                                                                        <xsl:otherwise>
                                                                            <xsl:value-of select="concat('(', string-join((tokenize(translate($either, '?+*()', ''), ',')),' or '), ')')"/>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                </xsl:attribute>
                                                                <xsl:value-of select="$element"/><xsl:text> must contain at least one </xsl:text><xsl:value-of select="concat('&lt;', $entity-name, '&gt;')"/><xsl:text> or &lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($either, '?+*()', ''), ',')),'&gt;/&lt;'), '\|')),'&gt;/&lt;')"/><xsl:text>&gt;</xsl:text>
                                                            </iso:assert>
                                                            <iso:report>
                                                                <xsl:attribute name="test">
                                                                    <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                                </xsl:attribute>
                                                                <xsl:value-of select="$element"/> <xsl:text> cannot have more than one </xsl:text>
                                                                <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                            </iso:report>
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:for-each-group>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:call-template name="model-entities">
                                    <xsl:with-param name="str" select="substring-after(substring($str, string-length($inside-paren)), ',')"/>
                                    <xsl:with-param name="output">
                                        <xsl:copy-of select="$output"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            
                            <!-- ~~~~~~~~~ -->
                            <!-- Moving on -->
                            <!-- ~~~~~~~~~ -->
                            <xsl:otherwise>
                                <xsl:call-template name="model-entities">
                                    <xsl:with-param name="str" select="substring-after(substring($str, string-length($inside-paren)), ',')"/>
                                    <xsl:with-param name="output">
                                        <xsl:copy-of select="$output"/>
                                        <xsl:call-template name="model-entities">
                                            <xsl:with-param name="str" select="$inside-paren"/>
                                        </xsl:call-template>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- =============== -->
                    <!-- Text only tests -->
                    <!-- =============== -->
                    <xsl:when test="starts-with($str, '#PCDATA)')">
                        <iso:report>
                            <xsl:attribute name="test">
                                <xsl:value-of select="'*'"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                            <xsl:text> may contain only #PCDATA</xsl:text>
                        </iso:report>
                        <xsl:choose>
                            <xsl:when test="$str = '#PCDATA)*'"/>
                            <xsl:when test="$str = '#PCDATA)'">
                                <iso:assert>
                                    <xsl:attribute name="test">
                                        <xsl:value-of select="'child::text()[normalize-space()]'"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                    <xsl:text> must contain #PCDATA</xsl:text>
                                </iso:assert>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- =============== -->
                    <!-- Handle all else -->
                    <!-- =============== -->
                    <xsl:otherwise>
                        <xsl:variable name="entity">
                            <xsl:choose>
                                <xsl:when test="contains($str,',')">
                                    <xsl:value-of select="substring-before($str,',')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$str"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="entity-name" select="translate($entity,'(),*? |+~','')"/>
                        <xsl:choose>
                            
                            <!-- =============== -->
                            <!-- Either/Or tests -->
                            <!-- =============== -->
                            <xsl:when test="contains($entity, '|')">
                                <xsl:choose>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- Zero or more of any: no tests -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with($entity, '*')"/>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- At least one of either -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with(translate($entity, ')', ''), '+')">
                                        <iso:assert>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                            <xsl:text> must have at least one of: </xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                        </iso:assert>
                                    </xsl:when>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- No more than one of either -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with(translate($entity, ')', ''), '?')">
                                        <iso:report>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="concat('count(',string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or '), ') > 1')"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                            <xsl:text> cannot have more than one of: </xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                        </iso:report>
                                    </xsl:when>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- One of either and any number of either -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:otherwise>
                                        <iso:assert>
                                            <xsl:attribute name="test">
                                                <xsl:text>if(</xsl:text>
                                                <xsl:value-of select="translate(substring-before($entity, '|'), '(),*? |+~','')"/>
                                                <xsl:text>) then not(</xsl:text>
                                                <xsl:value-of select="translate(substring-after($entity, '|'), '(),*? |+~','')"/>
                                                <xsl:text>) else not(</xsl:text>
                                                <xsl:value-of select="translate(substring-before($entity, '|'), '(),*? |+~','')"/>
                                                <xsl:text>)</xsl:text>
                                            </xsl:attribute>
                                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                            <xsl:text> cannot have both </xsl:text>
                                            <xsl:value-of select="concat('&lt;',translate(substring-before($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                            <xsl:text> and </xsl:text>
                                            <xsl:value-of select="concat('&lt;',translate(substring-after($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                        </iso:assert>
                                        <xsl:if test="not(contains($entity, '*'))">
                                            <iso:assert>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="translate(substring-before($entity, '|'), '(),*? |+~','')"/>
                                                    <xsl:text> or </xsl:text>
                                                    <xsl:value-of select="translate(substring-after($entity, '|'), '(),*? |+~','')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                <xsl:text> must have one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',translate(substring-before($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                                <xsl:text> or one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',translate(substring-after($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                            </iso:assert>
                                            <iso:report>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="concat('count(', translate(substring-before($entity, '|'), '(),*? |+~',''), ') > 1')"/>
                                                    <xsl:text> or </xsl:text>
                                                    <xsl:value-of select="concat('count(', translate(substring-after($entity, '|'), '(),*? |+~',''), ') > 1')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                <xsl:text> cannot have more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',translate(substring-before($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                                <xsl:text> or more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',translate(substring-after($entity, '|'), '(),*? |+~',''),'&gt;')"/>
                                            </iso:report>
                                        </xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            
                            <!-- ================ -->
                            <!-- Individual tests -->
                            <!-- ================ -->
                            <xsl:otherwise>
                                <xsl:call-template name="model-entities">
                                    <xsl:with-param name="str" select="substring-after($str,',')"/>
                                    <xsl:with-param name="output">
                                        <xsl:copy-of select="$output"/>
                                        <xsl:choose>
                                            
                                            <!-- ~~~~~~~~~~~~~~~~~~~~~~ -->
                                            <!-- Zero or more: no tests -->
                                            <!-- ~~~~~~~~~~~~~~~~~~~~~~ -->
                                            <xsl:when test="ends-with(translate($entity, ')', ''), '*')"/>
                                                
                                            
                                            <!-- ~~~~~~~~~~~~ -->
                                            <!-- At least one -->
                                            <!-- ~~~~~~~~~~~~ -->
                                            <xsl:when test="ends-with(translate($entity, ')', ''), '+')">
                                                <iso:assert>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="$entity-name"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> must have at least one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </iso:assert>
                                            </xsl:when>
                                            
                                            <!-- ~~~~~~~~~~~ -->
                                            <!-- Zero or one -->
                                            <!-- ~~~~~~~~~~~ -->
                                            <xsl:when test="ends-with(translate($entity, ')', ''), '?')">
                                                <iso:report>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> cannot have more than one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </iso:report>
                                            </xsl:when>
                                            
                                            <!-- ~~~~~~~~~~~~~~~~ -->
                                            <!-- One and only one -->
                                            <!-- ~~~~~~~~~~~~~~~~ -->
                                            <xsl:otherwise>
                                                <iso:assert>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="$entity-name"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> must have one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </iso:assert>
                                                <iso:report>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> cannot have more than one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </iso:report>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$output"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="ordering">
        <xsl:param name="str"/>
        <xsl:param name="output"/>
        <xsl:choose>
            <xsl:when test="contains($str, ',')">
                <xsl:variable name="entity">
                    <xsl:choose>
                        <xsl:when test="contains($str,',')">
                            <xsl:value-of select="substring-before($str,',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$str"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="contains($entity, '|')">
                        <xsl:call-template name="ordering">
                            <xsl:with-param name="str" select="substring-after($str,',')"/>
                            <xsl:with-param name="output">
                                <xsl:copy-of select="$output"/>
                                <xsl:for-each-group select="tokenize($entity, '\|')" group-by=".">
                                    <xsl:variable name="entity-name" select="translate(current-grouping-key(),'(),*? |+~','')"/>
                                    <xsl:value-of select="concat($entity-name, '[preceding-sibling::')"/><xsl:value-of select="string-join((tokenize(translate(translate(substring-after($str,','), '+?*()~ ', ''), '|,', '  '), ' ')), ' or preceding-sibling::')"/><xsl:text>] or </xsl:text>
                                </xsl:for-each-group>
                            </xsl:with-param>
                        </xsl:call-template>                                
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="entity-name" select="translate($entity,'(),*? |+~','')"/>
                        <xsl:call-template name="ordering">
                            <xsl:with-param name="str" select="substring-after($str,',')"/>
                            <xsl:with-param name="output">
                                <xsl:copy-of select="$output"/>
                                <xsl:value-of select="concat($entity-name, '[preceding-sibling::')"/><xsl:value-of select="string-join((tokenize(translate(translate(substring-after($str,','), '+?*()~ ', ''), '|,', '  '), ' ')), ' or preceding-sibling::')"/><xsl:text>] or </xsl:text>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$output"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="paren-nesting">
        <xsl:param name="str"/>
        <xsl:param name="level" select="string-length(substring-before($str, ')')) - string-length(translate(substring-before($str, ')'), '(', ''))"/>
        <xsl:choose>
            <xsl:when test="$level=1">
                <xsl:variable name="content" select="substring-before($str, ')')"/>
                <xsl:value-of select="substring-after($content, '(')"/>
                <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
            </xsl:when>
            <xsl:when test="$level=2">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after($str, ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                             substring-before(substring-after($str, ')'), ')')),                             ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=3">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after($str, ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                             substring-before(substring-after(substring-after($str, ')'), ')'), ')')),                              ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=4">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                              substring-before(substring-after(substring-after($str, ')'), ')'), ')'),                              substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')')),                              ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=5">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                              substring-before(substring-after(substring-after($str, ')'), ')'), ')'),                              substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')')),                             ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=6">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                              substring-before(substring-after(substring-after($str, ')'), ')'), ')'),                               substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')')),                             ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=7">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content" select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                              substring-before(substring-after(substring-after($str, ')'), ')'), ')'),                              substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), ')')),                             ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$level=8">
                <xsl:choose>
                    <xsl:when test="contains(substring-before(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), ')'), ')'), '(')">
                        <xsl:call-template name="paren-nesting">
                            <xsl:with-param name="str" select="$str"/>
                            <xsl:with-param name="level" select="$level+1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="content"
                            select="string-join((                             substring-before($str, ')'),                              substring-before(substring-after($str, ')'), ')'),                              substring-before(substring-after(substring-after($str, ')'), ')'), ')'),                              substring-before(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'),                              substring-before(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), ')'),                             substring-before(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after(substring-after($str, ')'), ')'), ')'), ')'), ')'), ')'), ')'), ')')),                             ')')"/>
                        <xsl:value-of select="substring-after($content, '(')"/>
                        <xsl:value-of select="translate(substring($str, string-length($content) + 1, 2), '|,', '~')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
