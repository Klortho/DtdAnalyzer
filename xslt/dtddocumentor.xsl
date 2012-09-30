<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

	<xsl:param name="files"/>
	<xsl:param name="date" select="format-date(current-date(),'[MNn] [D], [Y]')"/>
	<xsl:param name="time" select="format-time(current-time(),'[h]:[m] P')"/>
	<xsl:param name="dir"/>

	<xsl:param name="exclude-elems" select="' '"/>
	<xsl:param name="include-files"/>
	
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
		<xsl:apply-templates select="declarations/*[not(title)]"/>
		
		<xsl:for-each-group select="//annotation[@type='tags']/tag" group-by=".">
			<xsl:apply-templates select="current-group()[1]" mode="build-page"/>			
		</xsl:for-each-group>
	</xsl:template>	
	
	<!-- ========================= -->
	<!-- Exclude unwanted elements -->
	<!-- ========================= -->
	
	<xsl:template match="elements">
		<xsl:apply-templates select="element[not(matches(@name, $exclude-elems))]" mode="build-page"/>
	</xsl:template>
	
	<xsl:template match="attributes">
		<xsl:for-each select="attribute">
			<!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
			<xsl:variable name="notexcluded">	
				<xsl:for-each select="attributeDeclaration">
					<xsl:choose>
						<xsl:when test="matches(@element, $exclude-elems)">0</xsl:when>
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
	
	<xsl:template match="element | attribute | entity | tag | dtd" mode="build-page">
		<xsl:variable name="file">
		  <xsl:value-of select='concat($dir, "/")'/>
			<xsl:if test="self::element">
			  <xsl:call-template name='docFilename'>
			    <xsl:with-param name='name' select='@name'/>
			    <xsl:with-param name='type' select='"element"'/>
			  </xsl:call-template>
			</xsl:if>
			<xsl:if test="self::attribute">
			  <xsl:call-template name='docFilename'>
			    <xsl:with-param name='name' select='@name'/>
			    <xsl:with-param name='type' select='"attribute"'/>
			  </xsl:call-template>
			</xsl:if>
		  <xsl:if test="self::entity and parent::parameterEntities">
		    <xsl:call-template name='docFilename'>
		      <xsl:with-param name='name' select='@name'/>
		      <xsl:with-param name='type' select='"parament"'/>
		    </xsl:call-template>
			</xsl:if>
		  <xsl:if test="self::entity and parent::generalEntities">
		    <xsl:call-template name='docFilename'>
		      <xsl:with-param name='name' select='@name'/>
		      <xsl:with-param name='type' select='"genent"'/>
		    </xsl:call-template>
		  </xsl:if>
		  <xsl:if test="self::tag">
				<xsl:value-of select="concat('tag-', translate(., ':', '-'), '.html')"/>
			</xsl:if>
			<xsl:if test="self::dtd">
				<xsl:value-of select="'index.html'"/>
			</xsl:if>
		</xsl:variable>

		<xsl:result-document href="{$file}">
			<html>
				<head>
					<title><xsl:copy-of select="$title"></xsl:copy-of><xsl:text>: </xsl:text><xsl:value-of select="@name"/><xsl:text> </xsl:text><xsl:value-of select="self::node()/name()"></xsl:value-of></title>
					<!-- Default Stylesheet -->
					<link rel="stylesheet" type="text/css">
						<xsl:attribute name="href">
							<xsl:value-of select="'dtddoc.css'"/>
						</xsl:attribute>
					</link>
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
				<body>
					<div id="head"><a href="index.html"><h1><xsl:copy-of select="$title"/></h1></a></div>
					<div id="nav">
						<div class="inner">
							<xsl:apply-templates select="/declarations"/>
						</div>
					</div>
					<div id="content">
						<div class="inner">
							<xsl:apply-templates select="self::node()" mode="content"/>
						</div>
					</div>
					<div id="foot">
						<p><xsl:text>Made with </xsl:text><em>dtddocumentor</em><xsl:text> from </xsl:text><a href="https://github.com/NCBITools/DtdAnalyzer">DtdAnalyzer</a></p>
						<p><xsl:text>Updated on: </xsl:text><xsl:value-of select="$date"/><xsl:text> at </xsl:text><xsl:value-of select="$time"/></p>
					</div>
				</body>
			</html>
		</xsl:result-document>
	</xsl:template>
	
	
	<!-- ========================= -->
	<!-- Sidebar -->
	<!-- ========================= -->
	
	<xsl:template match="declarations">
		<p class="sidebar-outer">Elements</p>
		<ul class="sidebar-inner">
			<xsl:apply-templates select="elements" mode="sidebar"/>
		</ul>
		<p class="sidebar-outer">Attributes</p>
		<ul class="sidebar-inner">
			<xsl:apply-templates select="attributes" mode="sidebar"/>
		</ul>
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
	</xsl:template>
	
	<xsl:template match="elements" mode="sidebar">
		<xsl:for-each select="element[not(matches(@name, $exclude-elems))]">
			<xsl:sort select="@name"/>
			<xsl:call-template name="list-link">
				<xsl:with-param name="name" select="@name"/>
				<xsl:with-param name="type" select="'element'"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="attributes" mode="sidebar">
		<xsl:for-each select="attribute">
			<xsl:sort select="@name"/>
			<!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
			<xsl:variable name="notexcluded">
				<xsl:for-each select="attributeDeclaration">
					<xsl:choose>
						<xsl:when test="matches(@element, $exclude-elems)">0</xsl:when>
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
      <xsl:sort select="@name"/>
      <xsl:call-template name="list-link">
        <xsl:with-param name="name" select="@name"/>
        <xsl:with-param name="type" select="'parament'"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>	
  
  <xsl:template match="generalEntities" mode="sidebar">
    <xsl:for-each select="entity">
      <xsl:sort select="@name"/>
      <xsl:call-template name="list-link">
        <xsl:with-param name="name" select="@name"/>
        <xsl:with-param name="type" select="'genent'"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>	
  
  
	
	<!-- ========================= -->
	<!-- Page Content -->
	<!-- ========================= -->
	
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	<!-- Element Page -->
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->

	<xsl:template match="element" mode="content">
		<h2><span class="pagetitle">Element: </span><xsl:value-of select="@name"/></h2>
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
		<xsl:if test="context/parent">
			<h3>May be contained in:</h3>
			<ul class="parents">
				<xsl:for-each select="context/parent[not(matches(@name, $exclude-elems))][@name=//element/@name]">
					<xsl:sort select="@name"/>
					<xsl:call-template name="list-link">
						<xsl:with-param name="name" select="@name"/>
						<xsl:with-param name="type" select="'element'"/>
					</xsl:call-template>
				</xsl:for-each>								
			</ul>			
		</xsl:if>
	</xsl:template>
	

	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	<!-- Attribute Page -->
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	
	<xsl:template match="attribute" mode="content">
		<h2><span class="pagetitle">Attribute: </span><xsl:value-of select="@name"/></h2>
		<xsl:apply-templates select="annotations/annotation[@type='note']"/>
		<xsl:choose>
			<xsl:when test="count(distinct-values(attributeDeclaration[not(matches(@element, $exclude-elems))][@element=//element/@name]/@type)) > 1">
				<table>
					<tr><th>Value</th><th>In Elements</th></tr>
					<xsl:for-each-group select="attributeDeclaration[not(matches(@element, $exclude-elems))][@element=//element/@name]" group-by="@type">
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
				<p class="bold">Value: <span class="attvalue"><xsl:value-of select="attributeDeclaration[not(matches(@element, $exclude-elems))][@element=//element/@name][1]/@type"/></span></p>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="annotations/annotation[@type='model']"/>
		<xsl:apply-templates select="annotations/annotation[@type='tags']"/>
		<xsl:apply-templates select="annotations/annotation[@type='example']"/>		
		<h3>May be in elements:</h3>
		<ul class="parents">
			<xsl:for-each select="attributeDeclaration[not(matches(@element, $exclude-elems))][@element=//element/@name]">
				<xsl:sort select="@element"/>
				<xsl:call-template name="list-link">
					<xsl:with-param name="name" select="@element"/>
					<xsl:with-param name="type" select="'element'"/>
				</xsl:call-template>
			</xsl:for-each>
		</ul>
	</xsl:template>
	
	
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	<!-- Entity Page -->
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	
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
	
	
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	<!-- Tag Page -->
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	
	<xsl:template match="tag" mode="content">
		<xsl:variable name="tag"><xsl:value-of select="."/></xsl:variable>
		<h2><span class="pagetitle">Tag: </span><xsl:value-of select="$tag"/></h2>
		<h3><xsl:text>Tagged with "</xsl:text><xsl:value-of select="$tag"/><xsl:text>"</xsl:text></h3>
		<ul class="tags">
			<xsl:for-each-group select="//*[annotations[annotation[tag=$tag]]]" group-by="self::node()/name()">	
				<h4 class="notetitle"><xsl:value-of select="if (current-grouping-key()='entity') then 'entities' else concat(current-grouping-key(), 's')"/></h4>
				<ul class="tags">
					<xsl:for-each select="current-group()">
						<xsl:sort select="@name"/>
						<xsl:call-template name="list-link">
							<xsl:with-param name="name">
								<xsl:value-of select="@name"/>
							</xsl:with-param>
							<xsl:with-param name="type" select="self::node()/name()"/>
						</xsl:call-template>
					</xsl:for-each>
				</ul>
			</xsl:for-each-group>
		</ul>
	</xsl:template>


	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->
	<!-- Index Page -->
	<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~ -->	
	
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
  
  <!--
    Make the link to an object's documentation page.
    'type' should be one of "element", "attribute", "genent", or "parament".
  -->
	<xsl:template name="list-link">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
	  
	  <xsl:variable name='href'>
	    <xsl:call-template name='docFilename'>
	      <xsl:with-param name='name' select='$name'/>
	      <xsl:with-param name='type' select='$type'/>
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
    			<xsl:when test="$type='parament'">
  					<xsl:value-of select="concat('%', translate($name, ':', '-'), ';')"/>
    			</xsl:when>
  	      <xsl:when test="$type='genent'">
	          <xsl:value-of select="concat('&amp;', translate($name, ':', '-'), ';')"/>
  	      </xsl:when>
	      </xsl:choose>
	    </a>
	  </li>
	</xsl:template>
  
  <!--
    This template constructs the filename for the documentation page for a thing,
    given its name and its type.  'type' should be one of "element", "attribute",
    "genent", or "parament".
    This same template is used both to contruct the output filename when the file is
    written, and to make the hyperlink to it in the navigation panel.
  -->
  <xsl:template name='docFilename'>
    <xsl:param name="name"/>
    <xsl:param name="type"/>

    <xsl:choose>
      <xsl:when test="$type='element'">
        <xsl:value-of select="translate($name, ':', '-')"/>
      </xsl:when>
      <xsl:when test="$type='attribute'">
        <xsl:text>att-</xsl:text>
        <xsl:value-of select="translate($name, ':', '-')"/>
      </xsl:when>
      <xsl:when test="$type='parament'">
        <xsl:text>pe-</xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:when test="$type='genent'">
        <xsl:text>ge-</xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:when>
    </xsl:choose>
    <xsl:text>.html</xsl:text>
  </xsl:template>
</xsl:stylesheet>
