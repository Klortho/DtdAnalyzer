<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:sch="http://purl.oclc.org/dsdl/schematron"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:functx="http://www.functx.com" 
	version="2.0" 
	exclude-result-prefixes="#all">

	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:param name="complete" select="'no'"/>

    <xsl:template match="/">
    	<sch:schema>
    		<sch:title>
    			<xsl:text>ISO Schematron file created from </xsl:text>
    			<xsl:value-of select="if(declarations/title) then declarations/title else 'DTD'"/>
    		</sch:title>
            <sch:ns prefix="mml" uri="http://www.w3.org/1998/Math/MathML"/>
            <sch:ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
            <sch:ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
            <sch:pattern id="heading">     	
                <sch:rule context="/">
                	<sch:report test="*">Report date: <sch:value-of select="current-dateTime()"/></sch:report>
                </sch:rule>
            </sch:pattern>
            <xsl:apply-templates select="declarations/*"/>
        </sch:schema>
    </xsl:template>
	
	<xsl:template match="elements">
		<sch:pattern id="elements">
			<sch:title>Element Checks</sch:title>
			<xsl:apply-templates/>
		</sch:pattern>
	</xsl:template>
	
	<xsl:template match="attributes">
		<sch:pattern id="attributes">
			<sch:title>Attribute Checks</sch:title>
			<xsl:apply-templates/>
		</sch:pattern>
	</xsl:template>
	
	<xsl:template match="generalEntities|parameterEntities"/>

    <xsl:template match="element">
        <xsl:variable name="element" select="concat('&lt;', @name, '&gt;')"/>
    	<xsl:variable name="e-name">
       		<xsl:value-of select="@name"/>
    	</xsl:variable>
    	<sch:rule context="{concat('//',@name)}">	
    		<!--<xsl:comment><xsl:value-of select="content-model/@minified"/></xsl:comment>-->
    		<xsl:choose>
    			<xsl:when test="$complete = 'no'"/>
    			<xsl:otherwise>
    				<xsl:apply-templates select="/declarations/attributes" mode="element">
    					<xsl:with-param name="element" select="$element"/>
    					<xsl:with-param name="e-name" select="$e-name"/>
    				</xsl:apply-templates>
    				<xsl:call-template name="model-entities">
    					<xsl:with-param name="str" select="substring-after(content-model/@minified, '(')"/>
    				</xsl:call-template>
    				<xsl:apply-templates select="content-model/@minified">
    					<xsl:with-param name="element" select="$element" tunnel="yes"/>
    				</xsl:apply-templates>
    			</xsl:otherwise>            		
    		</xsl:choose> 
		    <xsl:for-each select="annotations/annotation[@type='schematron']/*">
				<xsl:choose>
					<xsl:when test="self::report">
						<sch:report>
							<xsl:copy-of select="@*"/>
							<xsl:copy-of select="node()"/>
						</sch:report>
					</xsl:when>
					
					<xsl:when test="self::assert">
						<sch:assert>
							<xsl:copy-of select="@*"/>
							<xsl:copy-of select="node()"/>
						</sch:assert>
					</xsl:when>
					
					<xsl:otherwise>
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>    		
    	</sch:rule>
    </xsl:template>
	
	<xsl:template match="attribute">
		<xsl:variable name="attribute" select="concat('@', @name)"/>
		<xsl:if test="annotations/annotation[@type='schematron'] or ($complete='yes' and attributeDeclaration[@mode='#REQUIRED'] or attributeDeclaration[@mode='#FIXED'] or attributeDeclaration[starts-with(@type, '(') and @mode!='#FIXED'])">
			<xsl:if test="annotations/annotation[@type='schematron']">
				<sch:rule context="{concat('//@',@name)}">
					<xsl:copy-of select="annotations/annotation[@type='schematron']/*"/>
				</sch:rule>
			</xsl:if>			
			<xsl:choose>
				<xsl:when test="$complete = 'no'"/>
				<xsl:otherwise>
					<xsl:apply-templates select="attributeDeclaration[@mode='#REQUIRED'], attributeDeclaration[@mode='#FIXED'], attributeDeclaration[starts-with(@type, '(') and @mode!='#FIXED']">
						<xsl:with-param name="attribute" select="$attribute"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<!-- =================== -->
	<!-- 				     -->
	<!-- ATTRIBUTE TEMPLATES -->
	<!-- 				     -->
	<!-- =================== -->
	
	<xsl:template match="attributeDeclaration[@mode='#REQUIRED']">
		<xsl:param name="attribute"/>
		<sch:rule context="{concat('//', @element)}">
			<sch:assert test="{$attribute}">
				<xsl:value-of select="$attribute"/>
				<xsl:text> is a required attribute for </xsl:text>
				<xsl:value-of select="('&lt;', @element, '&gt;')"/>
			</sch:assert>
		</sch:rule>
	</xsl:template>
	
	<xsl:template match="attributeDeclaration[@mode='#FIXED']">
		<xsl:param name="attribute"/>
		<sch:rule context="{concat('//', @element, '/', $attribute)}">
			<sch:assert>
				<xsl:attribute name="test">
					<xsl:text>. = '</xsl:text>
					<xsl:value-of select="@defaultValue"/>
					<xsl:text>'</xsl:text>
				</xsl:attribute>
				<xsl:value-of select="$attribute"/>
				<xsl:text> is a fixed attribute for </xsl:text>
				<xsl:value-of select="concat('&lt;', @element, '&gt;')"/>
				<xsl:text> and must equal "</xsl:text>
				<xsl:value-of select="@defaultValue"/>
				<xsl:text>"</xsl:text>
			</sch:assert>
		</sch:rule>
	</xsl:template>
	
	<xsl:template match="attributeDeclaration[starts-with(@type, '(') and @mode!='#FIXED']">
		<xsl:param name="attribute"/>
		<sch:rule context="{concat('//', @element, '/', $attribute)}">
			<sch:assert>
				<xsl:attribute name="test">
					<xsl:variable name="values">
						<xsl:for-each-group select="tokenize(translate(@type, '()', ''), '\|')" group-by=".">
							<xsl:text>. ='</xsl:text>
							<xsl:value-of select="current-grouping-key()"/>
							<xsl:text>' or </xsl:text>
						</xsl:for-each-group>
					</xsl:variable>
					<xsl:value-of select="string-join((tokenize($values, 'or ')[position() != last()]), 'or ')"/>
				</xsl:attribute>
				<xsl:text>The attribute </xsl:text>
				<xsl:value-of select="$attribute"/>
				<xsl:text> can only equal: </xsl:text>
				<xsl:value-of select="string-join((tokenize(translate(string-join((tokenize(@type, '\|')), ', '), '()', ''), ',')[position() != last()]), ',')"/>
				<xsl:text> or</xsl:text>
				<xsl:value-of select="tokenize(translate(string-join((tokenize(@type, '\|')), ', '), '()', ''), ',')[last()]"/>
				<xsl:text> for the element </xsl:text><xsl:value-of select="concat('&lt;', @element, '&gt;')"/>
			</sch:assert>
		</sch:rule>
	</xsl:template> 
	
	
	
	<!-- ================= -->
	<!-- 				   -->
	<!-- ELEMENT TEMPLATES -->
	<!-- 				   -->
	<!-- ================= -->
        
    <!-- ============================== -->
    <!-- Make allowed attributes report-->
    <!-- ============================== -->
    <xsl:template match="attributes" mode="element">
        <xsl:param name="element"/>
    	<xsl:param name="e-name"/>
    	<xsl:choose>
    		<xsl:when test="attribute[attributeDeclaration/@element=$e-name]">
    			<xsl:variable name="allowed-test">
    				<xsl:text>@* except (</xsl:text>
    				<xsl:variable name="allowed">
    					<xsl:for-each-group select="attribute[attributeDeclaration/@element=$e-name]" group-by="@name">
    						<xsl:value-of select="concat('@', current-grouping-key())"/>
    						<xsl:text> | </xsl:text>
    					</xsl:for-each-group>
    					<xsl:text>)</xsl:text>
    				</xsl:variable>
    				<xsl:value-of select="replace($allowed, ' \| \)', ')')"/>
    			</xsl:variable>
    			<sch:report>
    				<xsl:attribute name="test" select="$allowed-test"/>
    				<xsl:value-of select="$element"/><xsl:text> cannot contain the following attributes: </xsl:text><value-of select="{concat('(', $allowed-test, ')/name()')}"/><xsl:text>.</xsl:text></sch:report>
    		</xsl:when>
    		<xsl:otherwise>
    			<sch:report test="@*"><xsl:value-of select="$element"/> must not contain any attributes.</sch:report>
    		</xsl:otherwise>
    	</xsl:choose>
    </xsl:template>
    
    
    <!-- ============================ -->
    <!-- Make allowed elements report -->
    <!-- ============================ -->
	<xsl:template match="@minified">
        <xsl:param name="element" tunnel="yes"/>
        <xsl:if test="not(contains(., '#PCDATA'))">
            <sch:report test="child::text()[normalize-space()]">
                <xsl:value-of select="$element"/>
                <xsl:text> should not contain #PCDATA</xsl:text>
            </sch:report>
        </xsl:if>
        <xsl:if test=".='EMPTY'">
            <sch:report test="*">
                <xsl:value-of select="$element"/>
                <xsl:text> should be empty</xsl:text>
            </sch:report>
        </xsl:if>
        <xsl:if test=".!='EMPTY' and not(starts-with(., '(#PCDATA)'))">
            <sch:report>
                <xsl:variable name="allowed-test">
                    <xsl:text>* except (</xsl:text>
                    <xsl:value-of select="replace(string-join((tokenize(translate(translate(substring-after(., '('), '|,', '  '), '?()*+', ''), '\s+')), ' | '), '#PCDATA', 'text()')"/>
                    <xsl:text>)</xsl:text>
                </xsl:variable>
                <xsl:attribute name="test" select="$allowed-test"/>
                <xsl:value-of select="$element"/><xsl:text> cannot contain the following elements: </xsl:text><value-of select="{concat('(', $allowed-test, ')/name()')}"/>
            </sch:report>
            
            <!-- ============================ -->
            <!-- Make element ordering report -->
            <!-- ============================ -->            
            <xsl:if test="not(ends-with(., '*')) and contains(., ',')">
                <sch:report>
                    <xsl:attribute name="test">
                        <xsl:variable name="order-test">
                            <xsl:call-template name="ordering">
                                <xsl:with-param name="str" select="substring-after(., '(')"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="string-join((tokenize($order-test, ' or ')[position() != last()]), ' or ')"/>
                    </xsl:attribute>
                    <xsl:text>Child elements of </xsl:text><xsl:value-of select="$element"/><xsl:text> are out of order. <!--The correct order is: </xsl:text><xsl:value-of select="replace(replace(replace(replace(replace(., '\|', ' or '), ',', ', then: '), '\*', '[0 or more]'), '\+', '[1 or more]'), '\?', '[0 or 1]')"/>-->Element model: </xsl:text><xsl:value-of select="replace(replace(., ',', ', '), '\|', ' | ')"/>
                </sch:report>
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
                                    <sch:assert>
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
                                    </sch:assert>
                                </xsl:if>
                                <xsl:variable name="element" select="concat('&lt;',@name,'&gt;')"/>
                                <xsl:choose>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- No more than one of either side -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with($inside-paren, '?')">            
                                        <xsl:for-each select="tokenize(translate($or, '()?+*', ''), ',')">
                                            <sch:report>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="concat('count(',., ') > 1')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="$element"/>
                                                <xsl:text> cannot have more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',.,'&gt;')"/>
                                            </sch:report>
                                        </xsl:for-each>
                                        <xsl:for-each select="tokenize(translate($either, '()?+*', ''), ',')">
                                            <sch:report>
                                                <xsl:attribute name="test">
                                                    <xsl:value-of select="concat('count(',., ') > 1')"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="$element"/>
                                                <xsl:text> cannot have more than one </xsl:text>
                                                <xsl:value-of select="concat('&lt;',.,'&gt;')"/>
                                            </sch:report>
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
                                        <sch:assert>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="concat('(', string-join((tokenize(translate($either, '?+*()', ''), ',')),' or '), ')')"/>
                                                <xsl:text> or </xsl:text>
                                                <xsl:value-of select="concat('(', string-join((tokenize(translate($or, '?+*()', ''), ',')),' or '), ')')"/>
                                              </xsl:attribute>
                                            <xsl:value-of select="$element"/><xsl:text> must contain at least one (&lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($either, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/><xsl:text>&gt;) or (&lt;</xsl:text><xsl:value-of select="string-join((tokenize(string-join((tokenize(translate($or, '?+*()', ''), ',')),'&gt; or &lt;'), '\|')),'&gt; or &lt;')"/><xsl:text>&gt;)</xsl:text>
                                        </sch:assert>
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
                                                     <sch:assert>
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
                                                    </sch:assert>
                                                </xsl:when>
                                                
                                                <!-- No more than one -->
                                                <xsl:when test="ends-with(current-grouping-key(), '?')">
                                                    <sch:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/>
                                                        <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </sch:report>
                                                </xsl:when>
                                                
                                                <!-- One of either and no more than one -->
                                                <xsl:otherwise>
                                                    <sch:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/> <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </sch:report>
                                                    <sch:assert>
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
                                                    </sch:assert>
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
                                                            <sch:assert>
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
                                                            </sch:assert>
                                                        </xsl:when>
                                                    </xsl:choose>                                                    
                                                </xsl:when>
                                                
                                                <!-- No more than one -->
                                                <xsl:when test="ends-with(current-grouping-key(), '?')">
                                                    <sch:report>
                                                        <xsl:attribute name="test">
                                                            <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="$element"/>
                                                        <xsl:text> cannot have more than one </xsl:text>
                                                        <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                    </sch:report>
                                                </xsl:when>
                                                
                                                <!-- One of either and no more than one -->
                                                <xsl:otherwise>
                                                    <xsl:choose>
                                                        <xsl:when test="contains($either, '*')">
                                                            <sch:assert>
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
                                                            </sch:assert>
                                                            <sch:report>
                                                                <xsl:attribute name="test">
                                                                    <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                                </xsl:attribute>
                                                                <xsl:value-of select="$element"/> <xsl:text> cannot have more than one </xsl:text>
                                                                <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                            </sch:report>
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
                        <sch:report>
                            <xsl:attribute name="test">
                                <xsl:value-of select="'*'"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                            <xsl:text> may contain only #PCDATA</xsl:text>
                        </sch:report>
                        <xsl:choose>
                            <xsl:when test="$str = '#PCDATA)*'"/>
                            <xsl:when test="$str = '#PCDATA)'">
                                <sch:assert>
                                    <xsl:attribute name="test">
                                        <xsl:value-of select="'child::text()[normalize-space()]'"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                    <xsl:text> must contain #PCDATA</xsl:text>
                                </sch:assert>
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
                                        <sch:assert>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                            <xsl:text> must have at least one of: </xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                        </sch:assert>
                                    </xsl:when>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- No more than one of either -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:when test="ends-with(translate($entity, ')', ''), '?')">
                                        <sch:report>
                                            <xsl:attribute name="test">
                                                <xsl:value-of select="concat('count(',string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or '), ') > 1')"/>
                                            </xsl:attribute>
                                            <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                            <xsl:text> cannot have more than one of: </xsl:text>
                                            <xsl:value-of select="string-join((tokenize(translate($entity, '?+*()', ''), '\|')), ' or ')"/>
                                        </sch:report>
                                    </xsl:when>
                                    
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <!-- One of either and any number of either -->
                                    <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
                                    <xsl:otherwise>
                                        <sch:assert>
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
                                        </sch:assert>
                                        <xsl:if test="not(contains($entity, '*'))">
                                            <sch:assert>
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
                                            </sch:assert>
                                            <sch:report>
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
                                            </sch:report>
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
                                                <sch:assert>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="$entity-name"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> must have at least one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </sch:assert>
                                            </xsl:when>
                                            
                                            <!-- ~~~~~~~~~~~ -->
                                            <!-- Zero or one -->
                                            <!-- ~~~~~~~~~~~ -->
                                            <xsl:when test="ends-with(translate($entity, ')', ''), '?')">
                                                <sch:report>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> cannot have more than one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </sch:report>
                                            </xsl:when>
                                            
                                            <!-- ~~~~~~~~~~~~~~~~ -->
                                            <!-- One and only one -->
                                            <!-- ~~~~~~~~~~~~~~~~ -->
                                            <xsl:otherwise>
                                                <sch:assert>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="$entity-name"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> must have one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </sch:assert>
                                                <sch:report>
                                                    <xsl:attribute name="test">
                                                        <xsl:value-of select="concat('count(',$entity-name, ') > 1')"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',@name,'&gt;')"/>
                                                    <xsl:text> cannot have more than one </xsl:text>
                                                    <xsl:value-of select="concat('&lt;',$entity-name,'&gt;')"/>
                                                </sch:report>
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
