<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

	<xsl:param name="files"/>
	<xsl:param name="date" select="format-date(current-date(),'[MNn] [D], [Y]')"/>
	<xsl:param name="time" select="format-time(current-time(),'[h]:[m] P')"/>
	<xsl:param name="dir" select="'doc'"/>
	<xsl:param name="css" select="'dtddoc.css'"/>
	<xsl:param name="filesuffixes" select="1"/>

	<xsl:param name="exclude-elems" select="' '"/>
	<xsl:param name="include-files"/>
	
	<xsl:key name="entitiesByLCName" match="entity" use="lower-case(@name)"/>

	<xsl:variable name="title">
		<xsl:choose>
			<xsl:when test="/declarations/title">
				<xsl:value-of select="/declarations/title"/><xsl:text> Documentation</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>Documentation for </xsl:text><xsl:value-of select="/declarations/dtd/@relSysId"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:apply-templates select="declarations" mode="build-page"/>		
		<xsl:apply-templates select="declarations/*[not(title)]"/>
		<xsl:for-each-group select="//annotation[@type='tags']/tag" group-by=".">
			<xsl:apply-templates select="current-group()[1]" mode="build-page"/>			
		</xsl:for-each-group>		
	</xsl:template>	
	
	<!-- ========================= -->
	<!-- Exclude unwanted elements -->
	<!-- ========================= -->
	
	<xsl:template match="elements">
		<xsl:apply-templates select="element[not(matches(@name, $exclude-elems)) and not(@reachable='false')]" mode="build-page"/>
	</xsl:template>
	
	<xsl:template match="attributes">
		<xsl:for-each select="attribute">
			<!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
			<xsl:variable name="notexcluded">	
				<xsl:for-each select="attributeDeclaration">
					<xsl:choose>
						<xsl:when test="matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name">0</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="contains($notexcluded, '1')">
				<xsl:apply-templates select="self::attribute" mode="build-page"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="parameterEntities | generalEntities">
		<xsl:apply-templates select="entity" mode="build-page"/>
	</xsl:template>
	
	<xsl:template match="dtd">
		<xsl:apply-templates select="self::node()" mode="build-page"/>
	</xsl:template>
	

	<!-- ========================= -->
	<!-- Build Page -->
	<!-- ========================= -->
	
	<xsl:template match="element | attribute | entity | tag | dtd | declarations" mode="build-page">
		<xsl:variable name="file">
		  <xsl:value-of select="concat($dir, '/')"/>
			<xsl:if test="self::element or self::attribute">
			  <xsl:call-template name="docFilename">
			    <xsl:with-param name="name" select="@name"/>
			    <xsl:with-param name="type" select="self::node()/name()"/>
			  </xsl:call-template>
			</xsl:if>
		  <xsl:if test="self::entity">
		    <xsl:call-template name="docFilename">
		      <xsl:with-param name="name" select="@name"/>
		      <xsl:with-param name="type" select="parent::node()/name()"/>
		      <xsl:with-param name="index">
		        <xsl:call-template name="makeIndex"/>
		      </xsl:with-param>
		    </xsl:call-template>
			</xsl:if>
		  <xsl:if test="self::tag">
				<xsl:value-of select="concat('tag-', translate(., ':', '-'), '.html')"/>
			</xsl:if>
			<xsl:if test="self::dtd">
				<xsl:value-of select="'index.html'"/>
			</xsl:if>
			<xsl:if test="self::declarations">
				<xsl:value-of select="'sidebar.html'"/>
			</xsl:if>
		</xsl:variable>

		<xsl:result-document href="{$file}">
			<html>
				<head>
				  <!-- 
				    Sidebar gets <base target="_parent"/> so that links will open in the parent window. 
				  -->
				  <xsl:if test='self::declarations'>
				    <base target="_parent" />
				  </xsl:if>
					<xsl:if test="not(self::declarations)">
						<title>
						  <xsl:copy-of select="$title"/>
						  <xsl:text>: </xsl:text>
						  <xsl:value-of select="@name"/>
						  <xsl:text> </xsl:text>
						  <xsl:value-of select="self::node()/name()"/>
						</title>
					</xsl:if>
				  
					<!-- Default Stylesheet -->
				  <xsl:if test="$css != ''">
  					<link rel="stylesheet" type="text/css" href="{$css}"/>
				  </xsl:if>
				  
					<!-- Links to other stylesheets, google fonts, javascript, etc. added here -->
					<xsl:if test="$include-files">
						<xsl:for-each select="tokenize($include-files, ' ')">
							<xsl:if test="contains(., '.js')">
								<script type="text/javascript" src="{.}">
									// <![CDATA[ // ]]>
								</script>
							</xsl:if>
							<xsl:if test="contains(., '.css')">
								<link rel="stylesheet" type="text/css" href="{.}"/>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
					<!-- Default javascript (includes jquery) -->
					<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.1/jquery.min.js">
						// <![CDATA[ // ]]>
					</script>
					<script type="text/javascript" src="expand.js">
						// <![CDATA[ // ]]>
					</script>
				</head>
				<xsl:choose>
					<xsl:when test="self::declarations">
						<xsl:apply-templates select="self::node()" mode="content"/>
					</xsl:when>
					<xsl:otherwise>
						<body>
							<div id="wrapper">
								<div id="head"><a href="index.html"><h1><xsl:copy-of select="$title"/></h1></a></div>
								<iframe id="nav" src="sidebar.html"><p>Sidebar</p></iframe>
								<div id="content">
									<div class="inner">
										<xsl:apply-templates select="self::node()" mode="content"/>
									</div>
								</div>
								<div id="foot">
									<p class="right"><xsl:text>Made with </xsl:text><em>dtddocumentor</em><xsl:text> from </xsl:text><a href="https://github.com/NCBITools/DtdAnalyzer">DtdAnalyzer</a></p>
									<p><xsl:text>Updated on: </xsl:text><xsl:value-of select="$date"/><xsl:text> at </xsl:text><xsl:value-of select="$time"/></p>
								</div>		
							</div>			
						</body>
					</xsl:otherwise>
				</xsl:choose>
			</html>
		</xsl:result-document>
	</xsl:template>
	
	
	<!-- ========================= -->
	<!-- Sidebar -->
	<!-- ========================= -->
	
	<xsl:template match="declarations" mode="content">
		<body class="sidebar">
			<div class="inner">
				<xsl:if test="elements">
					<p class="sidebar-outer">Elements</p>
					<ul class="sidebar-inner">
						<xsl:apply-templates select="elements" mode="sidebar"/>
					</ul>
				</xsl:if>
				<xsl:if test="attributes">
					<p class="sidebar-outer">Attributes</p>
					<ul class="sidebar-inner">
						<xsl:apply-templates select="attributes" mode="sidebar"/>
					</ul>
				</xsl:if>						
				<xsl:if test="parameterEntities">
					<p class="sidebar-outer">Parameter Entities</p>
					<ul class="sidebar-inner">
						<xsl:apply-templates select="parameterEntities" mode="sidebar"/>
					</ul>
				</xsl:if>
				<xsl:if test="generalEntities">
					<p class="sidebar-outer">General Entities</p>
					<ul class="sidebar-inner">
						<xsl:apply-templates select="generalEntities" mode="sidebar"/>
					</ul>
				</xsl:if>
				<xsl:if test="//annotation[@type='tags']">
					<p class="sidebar-outer taglist">Tags</p>
					<ul class="sidebar-inner">
						<xsl:for-each select="distinct-values(//annotation[@type='tags']/tag)">
							<li><a href="tag-{.}.html"><xsl:value-of select="."/></a></li>
						</xsl:for-each>
					</ul>
				</xsl:if>
			</div>					
		</body>
	</xsl:template>
	
	<xsl:template match="elements" mode="sidebar">
		<xsl:for-each select="element[not(matches(@name, $exclude-elems)) and not(@reachable='false')]">
			<xsl:sort select="@name" order="ascending"/>
			<xsl:call-template name="list-link">
				<xsl:with-param name="name" select="@name"/>
				<xsl:with-param name="type" select="'element'"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="attributes" mode="sidebar">
		<xsl:for-each select="attribute">
			<xsl:sort select="@name" order="ascending"/>
			<!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
			<xsl:variable name="notexcluded">
				<xsl:for-each select="attributeDeclaration">
					<xsl:choose>
						<xsl:when test="matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name">0</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="contains($notexcluded, '1')">
				<xsl:call-template name="list-link">
					<xsl:with-param name="name" select="@name"/>
					<xsl:with-param name="type" select="'attribute'"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="parameterEntities" mode="sidebar">
		<xsl:for-each select="entity">
			<xsl:sort select="lower-case(@name)" order="ascending"/>
			<xsl:call-template name="list-link">
				<xsl:with-param name="name" select="@name"/>
				<xsl:with-param name="type" select="'parameterEntities'"/>
				<xsl:with-param name="index">
					<xsl:call-template name="makeIndex"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>	
	
	<xsl:template match="generalEntities" mode="sidebar">
		<xsl:for-each select="entity">
			<xsl:sort select="lower-case(@name)" order="ascending"/>
			<xsl:call-template name="list-link">
				<xsl:with-param name="name" select="@name"/>
				<xsl:with-param name="type" select="'generalEntities'"/>
				<xsl:with-param name="index">
					<xsl:call-template name="makeIndex"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>	
  
  
	
	<!-- ========================= -->
	<!-- Page Content -->
	<!-- ========================= -->
	

	<!-- ===== Element Page ===== -->

	<xsl:template match="element" mode="content">
		<h2>
			<span class="pagetitle">
				<xsl:if test="@root='true'">
					<xsl:text>Root </xsl:text>
				</xsl:if>
				<xsl:text>Element: </xsl:text>
			</span>
			<xsl:value-of select="@name"/>
		</h2>
		<xsl:apply-templates select="annotations/annotation[@type='note']"/>
		<xsl:variable name="e-name">
			<xsl:value-of select="@name"/>
		</xsl:variable>
		<xsl:if test="../../attributes/attribute[attributeDeclaration/@element=$e-name]">
			<h3>Attributes</h3>
			<ul class="attributes">
				<xsl:for-each select="../../attributes/attribute[attributeDeclaration/@element=$e-name]">
					<xsl:sort select="@name"/>
					<xsl:call-template name="list-link">
						<xsl:with-param name="name" select="@name"/>
						<xsl:with-param name="type" select="'attribute'"/>
					</xsl:call-template>
				</xsl:for-each>
			</ul>
		</xsl:if>
		<xsl:if test="content-model/@spec != 'empty'">
			<h3>Content Model</h3>
			<p class="content-model"><xsl:value-of select="content-model/@spaced"/></p>
			<xsl:apply-templates select="annotations/annotation[@type='model']"/>
			<h4>May Contain:</h4>
			<ul class="children">
				<xsl:if test="content-model/@spec='mixed' or content-model/@spec='text'">
					<li>PCDATA</li>
				</xsl:if>
				<xsl:for-each select="content-model//child[not(matches(., $exclude-elems))]">
					<xsl:sort select="."/>
					<xsl:call-template name="list-link">
						<xsl:with-param name="name" select="."/>
						<xsl:with-param name="type" select="'element'"/>
					</xsl:call-template>
				</xsl:for-each>
			</ul>			
		</xsl:if>
		<xsl:apply-templates select="annotations/annotation[@type='tags']"/>
		<xsl:apply-templates select="annotations/annotation[@type='example']"/>
		<xsl:if test="context/parent[not(matches(@name, $exclude-elems))][@name=//element[not(@reachable='false')]/@name]">
			<h3>May be contained in:</h3>
			<ul class="parents">
				<xsl:for-each select="context/parent[not(matches(@name, $exclude-elems))][@name=//element[not(@reachable='false')]/@name]">
					<xsl:sort select="@name"/>
					<xsl:call-template name="list-link">
						<xsl:with-param name="name" select="@name"/>
						<xsl:with-param name="type" select="'element'"/>
					</xsl:call-template>
				</xsl:for-each>								
			</ul>			
		</xsl:if>
	</xsl:template>
	

	<!-- ===== Attribute Page ===== -->
	
	<xsl:template match="attribute" mode="content">
		<h2><span class="pagetitle">Attribute: </span><xsl:value-of select="@name"/></h2>
		<xsl:apply-templates select="annotations/annotation[@type='note']"/>
		<xsl:choose>
			<xsl:when test="count(distinct-values(attributeDeclaration[not(matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name)]/@type)) > 1">
				<table>
					<tr><th>Value</th><th>In Elements</th></tr>
					<xsl:for-each-group select="attributeDeclaration[not(matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name)]" group-by="@type">
						<tr class="attvalue">
							<td><xsl:value-of select="current-grouping-key()"/></td>
							<td>
								<xsl:for-each select="current-group()">
									<xsl:value-of select="concat('&lt;', @element, '&gt;')"/><xsl:text> </xsl:text>
								</xsl:for-each>
							</td>					
						</tr>
					</xsl:for-each-group>
				</table>
			</xsl:when>
			<xsl:otherwise>
				<p class="bold">Value: <span class="attvalue">
					<xsl:value-of select="attributeDeclaration[not(matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name)][1]/@type"/>
				</span>
				</p>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="annotations/annotation[@type='model']"/>
		<xsl:apply-templates select="annotations/annotation[@type='tags']"/>
		<xsl:apply-templates select="annotations/annotation[@type='example']"/>		
		<h3>May be in elements:</h3>
		<ul class="parents">
			<xsl:for-each select="attributeDeclaration[not(matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name)]">
				<xsl:sort select="@element"/>
				<xsl:call-template name="list-link">
					<xsl:with-param name="name" select="@element"/>
					<xsl:with-param name="type" select="'element'"/>
				</xsl:call-template>
			</xsl:for-each>
		</ul>
	</xsl:template>
	
	
	<!-- ===== Entity Page ===== -->
	
	<xsl:template match="entity" mode="content">
		<h2><span class="pagetitle">Entity: </span><xsl:value-of select="@name"/></h2>
		<xsl:apply-templates select="annotations/annotation[@type='note']"/>
		<xsl:if test="value != ''">
			<h3>Content Model</h3>
			<p class="content-model">
				<pre><xsl:value-of select="value"/></pre>
			</p>
			<xsl:apply-templates select="annotations/annotation[@type='model']"/>
		</xsl:if>
		<xsl:apply-templates select="annotations/annotation[@type='tags']"/>
		<xsl:apply-templates select="annotations/annotation[@type='example']"/>
	</xsl:template>
	
	
	<!-- ===== Tag Page ===== -->
	
	<xsl:template match="tag" mode="content">
		<xsl:variable name="tag"><xsl:value-of select="."/></xsl:variable>
		<h2><span class="pagetitle">Tag: </span><xsl:value-of select="$tag"/></h2>
		<h3><xsl:text>Tagged with "</xsl:text><xsl:value-of select="$tag"/><xsl:text>"</xsl:text></h3>
		<ul class="tags">
			<xsl:for-each-group select="//*[annotations[annotation[tag=$tag]]][not(self::element and (@reachable='false' or matches(@name, $exclude-elems))) 
				and not(self::attribute and (matches(@element, $exclude-elems) or @element=//element[@reachable='false']/@name))]" 
				group-by="parent::node()/name()">	
				<h4 class="notetitle"><xsl:value-of select="if (current-grouping-key()='parameterEntities') then 'parameter entities' else 
					if(current-grouping-key()='generalEntities') then 'general entities' else current-grouping-key()"/></h4>
				<ul class="tags">
					<xsl:for-each select="current-group()">
						<xsl:sort select="translate(@name, 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending"/>
						<xsl:call-template name="list-link">
							<xsl:with-param name="name">
								<xsl:value-of select="@name"/>
							</xsl:with-param>
							<xsl:with-param name="type" select="if(self::entity) then parent::node()/name() else self::node()/name()"/>
						</xsl:call-template>
					</xsl:for-each>
				</ul>
			</xsl:for-each-group>
		</ul>
	</xsl:template>


	<!-- ===== Index Page ===== -->
	
	<xsl:template match="dtd" mode="content">
		<h2><span class="pagetitle"><xsl:text> Documentation: </xsl:text></span><xsl:value-of select="@relSysId"/></h2>
		<xsl:apply-templates select="annotations/*"/>
	</xsl:template>
	
	
	<!-- ========================= -->
	<!-- General Templates-->
	<!-- ========================= -->
	
	<xsl:template match="annotation">
		<div class="{@type}">
			<xsl:if test="@type='example' or @type='tags'">
				<h3 class="notetitle"><xsl:value-of select="@type"/></h3>
			</xsl:if>			
			<xsl:copy-of select="* except tag" copy-namespaces="no"/>
			<xsl:if test="@type='tags'">
				<p><xsl:apply-templates select="tag"/></p>
			</xsl:if>
		</div>
	</xsl:template>	
	
	<xsl:template match="tag">
		<a href="tag-{.}.html" class="tag"><xsl:value-of select="."/></a>
		<xsl:if test="following-sibling::tag"><xsl:text>, </xsl:text></xsl:if>
	</xsl:template>
  
  
	<xsl:template name="list-link">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="index"/>
		
		<xsl:variable name="href">
			<xsl:call-template name="docFilename">
				<xsl:with-param name="name" select="$name"/>
				<xsl:with-param name="type" select="$type"/>
				<xsl:with-param name="index" select="$index"/>
			</xsl:call-template>
		</xsl:variable>
		
		<li>
			<a href='{$href}'>
				<xsl:choose>
					<xsl:when test="$type='element'">
						<xsl:value-of select="concat('&lt;', $name, '&gt;')"/>
					</xsl:when>
					<xsl:when test="$type='attribute'">
						<xsl:value-of select="concat('@', $name)"/>
					</xsl:when>
					<xsl:when test="$type='parameterEntities'">
						<xsl:value-of select="concat('%', $name)"/>
					</xsl:when>
					<xsl:when test="$type='generalEntities'">
						<xsl:value-of select="concat('&amp;', $name)"/>
					</xsl:when>
				</xsl:choose>
			</a>
		</li>
	</xsl:template>
  

	<!-- ===== 	docFilename Template  ===== -->
	<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		Notes: Constructs the filename for the documentation page 
		for a thing, given its name and its type. This same 
		template is used both to contruct the output filename 
		when the file is written, and to make the hyperlink to it 
		in the navigation panel.
		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->  	
	<xsl:template name="docFilename">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="index"/>
		
		<xsl:choose>
			<xsl:when test="$type='element'">
				<xsl:text>el-</xsl:text>
				<xsl:value-of select="translate($name, ':', '-')"/>
			</xsl:when>
			<xsl:when test="$type='attribute'">
				<xsl:text>att-</xsl:text>
				<xsl:value-of select="translate($name, ':', '-')"/>
			</xsl:when>
			<xsl:when test="$type='parameterEntities'">
				<xsl:text>pe-</xsl:text>
				<xsl:value-of select="$name"/>
				<xsl:if test="$index != ''">
					<xsl:value-of select="concat('-', $index)"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$type='generalEntities'">
				<xsl:text>ge-</xsl:text>
				<xsl:value-of select="$name"/>
				<xsl:if test="$index != ''">
					<xsl:value-of select="concat('-', $index)"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
		<xsl:text>.html</xsl:text>
	</xsl:template>
	
	<!-- ===== 	makeIndex Template  ===== -->
	<!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		Notes: This template computes an index number, when 
		necessary, to append to a filename. The context should 
		be an <entity> element. If there are other entities 
		that have the same name as this one, ignoring case, 
		then we'll need to append a suffix ("-1", "-2", etc.) 
		to the filenames for those. Because computing the suffix 
		is time-consuming, use the key to find out if there are 
		others with such clashing names.
		~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->  
	<xsl:template name="makeIndex">
		<xsl:choose>
			<xsl:when test="$filesuffixes">
				<xsl:variable name="lcname" select="lower-case(@name)"/>
				<xsl:choose>
					<xsl:when test="count(key('entitiesByLCName', $lcname)) > 1">
						<!-- 
						  This preceding-sibling expression is relatively slow, and was causing
						  performance problems when running against JATS-type DTDs (which have hundreds
						  of entities, and the sidebar was included in every page.
						  But now that the sidebar is in a separate iframe, that doesn't matter.
							There must be a better XSLT 2.0 way to do this, but I don't know it [cfm]. 
						-->
						<xsl:value-of select="count(preceding-sibling::entity[lower-case(@name) = $lcname])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text></xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text></xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>