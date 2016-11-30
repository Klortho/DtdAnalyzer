<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0">
    
    <!-- ============================================================================== -->
    <!-- OUTPUT                                                                         -->
    <!-- ============================================================================== -->
    <xsl:output method="html" omit-xml-declaration="no" encoding="UTF-8" indent="yes"  />
    
    <!-- ============================================================================== -->
    <!-- WHITESPACE HANDLING                                                            -->
    <!-- ============================================================================== -->
   <xsl:strip-space elements="*"/>
    
    <!-- ============================================================================== -->
    <!-- VARIABLES                                                                      -->
    <!-- ============================================================================== -->
    <xsl:variable name="elements">
        <!-- Context node: final-list -->        
        <xsl:apply-templates select="//element"  mode="build-variable">
            <xsl:sort select="@name"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:variable name="tagsets">
        <!-- Context node: final-list -->
        <xsl:call-template name="build-tagset">
            <xsl:with-param name="rid" select="/final-list/declarations/@relsysid"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="versions">
        <!-- Context node: final-list -->
        <xsl:apply-templates select="//dtd-info" mode="build-variable">
            <xsl:sort select="@version-date"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:variable name="auth-versions">
        <!-- Context node: final-list -->
        <xsl:apply-templates select="//dtd-info[parent::declarations[contains(@relsysid,'articleauthoring')]]" mode="build-auth-variable">
            <xsl:sort select="@version-date"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <!-- ============================================================================== -->
    <!-- ELEMENT MODE="BUILD-VARIABLE"                                                  -->
    <!-- ============================================================================== -->
    <xsl:template match="element" mode="build-variable">
        <xsl:variable name="nm" select="@name"/>
        <xsl:if test="not(preceding::element[@name=$nm])">
            <element><xsl:value-of select="@name"/></element>
        </xsl:if> 
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- DTD-INFO MODE="BUILD-VARIABLE"                                                 -->
    <!-- ============================================================================== -->
    <xsl:template match="dtd-info" mode="build-variable">
        <xsl:variable name="vs" select="@version"/>
        <xsl:if test="not(preceding::dtd-info[@version=$vs])">
           <version><xsl:value-of select="@version"/></version>
        </xsl:if> 
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- DTD-INFO MODE="BUILD-AUTH-VARIABLE"                                            -->
    <!-- ============================================================================== -->
    <xsl:template match="dtd-info[parent::declarations[contains(@relsysid,'articleauthoring')]]" mode="build-auth-variable">
        <xsl:variable name="vs" select="@version"/>
        <xsl:if test="not(preceding::dtd-info[parent::declarations[contains(@relsysid,'articleauthoring')]][@version=$vs])">
            <version><xsl:value-of select="@version"/></version>
        </xsl:if>
    </xsl:template>    
    
    <!-- ============================================================================== -->
    <!-- NAMED TEMPLATE: BUILD-TAGSET                                                   -->
    <!-- ============================================================================== -->
    <xsl:template name="build-tagset">
        <xsl:param name="rid"/>
        <xsl:if test="$rid='archivearticle.dtd' or $rid='archivearticle3.dtd' or $rid='JATS-archivearticle1.dtd'">
            <tagset><xsl:value-of select="'Journal Archive &amp; Interchange'"/></tagset>
        </xsl:if>
        <xsl:if test="$rid='journalpublishing.dtd' or $rid='journalpublishing3.dtd' or $rid='JATS-journalpublishing1.dtd'">
            <tagset><xsl:value-of select="'Journal Publishing'"/></tagset>
        </xsl:if>
        <xsl:if test="$rid='articleauthoring.dtd' or $rid='articleauthoring3.dtd' or $rid='JATS-articleauthoring1.dtd'">
            <tagset><xsl:value-of select="'Journal Article Authoring'"/></tagset>
        </xsl:if>
        <xsl:if test="$rid='BITS-book0.dtd' or $rid='BITS-book1.dtd' or $rid='BITS-book2.dtd'">
            <tagset><xsl:value-of select="'Books Interchange'"/></tagset>
        </xsl:if>
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- Start building HTML here                                                       -->
    <!-- ============================================================================== -->
    
    <xsl:template match="final-list">
        <html>
            <head>
                <xsl:choose>
                    <xsl:when test="$tagsets/tagset='Books Interchange'">
                        <title>BITS Element Index</title>
                    </xsl:when>
                    <xsl:otherwise>
                        <title>NLM/JATS Element Index</title>
                    </xsl:otherwise>
                </xsl:choose>
                <link rel="stylesheet" type="text/css" href="../dtddoc.css"/>
            </head>
            <xsl:choose>
                <xsl:when test="$tagsets/tagset='Books Interchange'">
                    <body class="book">            
                    <div id="wrapper">
                    <div id="head">
                         <h1 class="main">BITS Element Index</h1>
                    </div>
                    <div id="nav">
                         <div class="sidebar">
                              <div class="inner">
                                   <p class="sidebar-outer-book">Elements</p>
                                       <ul class="sidebar-inner">
                                            <xsl:for-each select="$elements/element">
                                                <li>
                                                    <a><xsl:attribute name="href"><xsl:value-of select="concat('../bits/el-',.,'.html')"/></xsl:attribute>
                                                    <xsl:value-of select="concat('&lt;',.,'&gt;')"/></a>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                              </div>
                         </div>
                     </div>
                     <div id="content">
                          <div class="inner">
                               <h2 class="inner-head-book">BITS Element Index</h2>
                                  <div id="intro">
                                      <h3>Introduction</h3>
                                           <p>The Book Interchange Tag Suite (BITS) version 2.0 contains an XML model for STM books that is based on the Journal Article Tag Suite (JATS; ANSI/NISO Z39-96-2015) version 1.1.</p>
                                           <p>BITS has added material to describe STM books, book components such as chapters, and information concerning the inclusion of books and book components in book series.</p>
                                           <p>The intent of the BITS is to provide a common format in which publishers and archives can exchange book content, including book parts such as chapters.</p>
                                           <p>The Suite provides a set of XML schema modules that define elements and attributes for describing the textual and graphical content of books and book components as well as a package for book part interchange.</p>
                                           <p><a href="https://jats.nlm.nih.gov/extensions/bits/rationale.html">Read more...</a></p>
                                  </div>    
                                  <div id="doc">
                                       <h3>Documentation</h3>
                                          <p>Complete documentation for the Tag Set is available in Tag Library. Each version has its own Tag Library that documents the rules and usage for that version.  The Tag Library for the most recent release of this Tag Set will always be available at the following URI:</p>
                                                <ul class="vlist">
                                                    <li><a href="https://jats.nlm.nih.gov/extensions/bits/tag-library/2.0/index.html">https://jats.nlm.nih.gov/extensions/bits/tag-library/</a></li>
                                                </ul>
                                          <p>The structure and suggested usage of the Tag Library is described in the  <a href="https://jats.nlm.nih.gov/extensions/bits/tag-library/2.0/chapter/how-to-read.html">How to Use (Read Me First)</a> section of each Tag Library.</p>
                                  </div> 
                                  <div class="notes">
                                        <h3>Notes</h3>
                                           <p>The BITS Element Index not only defines elements and attributes within each model, but also shows comparisons and differences.</p>
                                           <p>The BITS models included in this index are: BITS 0.1, BITS 0.2, BITS 1.0 and BITS 2.0. BITS is managed by the National Center for Biotechnology Information (NCBI) at the US National Library of Medicine (NLM).</p>
                                           <p>BITS is not a NISO standard.</p>
                                  </div>
                              </div>
                            </div>
                            <div id="foot">
                                <p class="right">Last updated: 2016-10-20</p>
                            </div>
                </div>
                </body>
            </xsl:when>
            <xsl:otherwise>               
                <body>            
                    <div id="wrapper">
                         <div id="head">
                              <h1 class="main">NLM/JATS Element Index</h1>
                         </div>
                         <div id="nav">
                              <div class="sidebar">
                                  <div class="inner">
                                      <p class="sidebar-outer">Elements</p>
                                        <ul class="sidebar-inner">
                                            <xsl:for-each select="$elements/element">
                                                <li>
                                                    <a><xsl:attribute name="href"><xsl:value-of select="concat('../nlm_jats/el-',.,'.html')"/></xsl:attribute>
                                                        <xsl:value-of select="concat('&lt;',.,'&gt;')"/></a>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                  </div>
                              </div>
                         </div>
                        <div id="content">
                            <div class="inner">
                                <h2 class="inner-head">NLM/JATS Element Index</h2>
                                <div class="notes">
                                    <p>The NLM/JATS Element Index not only defines elements and attributes within each model, but also shows comparisons and differences.</p>
                                    <p>This index includes the elements from all three article models: Journal Archiving(Green), Journal Publishing(Blue) and Article Authoring(Orange).</p>
                                    <p>The NLM models included in this index are: NLM 1.0, NLM 1.1, NLM 2.0, NLM 2.1, NLM 2.2, NLM 2.3 and NLM 3.0. The JATS models included in this index are: JATS 1.0, JATS 1.1d1, JATS 1.1d2, JATS 1.1d3 and JATS 1.1.</p>
                                    <p>The NLM Archiving and Interchange DTD is managed by the National Center for Biotechnology Information (NCBI) at the US National Library of Medicine (NLM), which began in 2002. JATS is a continuation of this work and is also a NISO standard.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div id="foot">
                        <p class="right">Last updated: 2016-10-20</p>
                    </div>
                </body>
            </xsl:otherwise>
          </xsl:choose>                   
        </html>
        
        <xsl:call-template name="write-elements">
            <xsl:with-param name="element" select="$elements/element"/>
        </xsl:call-template>
        
    </xsl:template>
    
    
    
    <!-- ============================================================================== -->
    <!-- NAMED TEMPLATE: WRITE-ELEMENTS                                                 -->
    <!-- ============================================================================== -->
    <xsl:template name="write-elements">
        <xsl:param name="element"/>
        
        <xsl:variable name="v1">
            <xsl:for-each select="declarations/dtd-info[following-sibling::element[@name=$element[1]]]">
                <version><xsl:value-of select="@version"/></version>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="el-page">
            <xsl:choose>
                <xsl:when test="$tagsets/tagset='Books Interchange'">
                    <xsl:if test="$element">                
                        <xsl:value-of select="concat('../bits/el-',$element[1],'.html')"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$element">                
                        <xsl:value-of select="concat('../nlm_jats/el-',$element[1],'.html')"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>
            
                <xsl:if test="$element">
                    <xsl:result-document method="html" href="{$el-page}" omit-xml-declaration="no">
                    <html>
                        <head>
                            <title><xsl:value-of select="concat('Element: ','&lt;',$element[1],'&gt;')"/></title>
                            <link rel="stylesheet" type="text/css" href="../dtddoc.css"/>
                            <script type="text/javascript"
                                src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.1/jquery.min.js">
                                // //
                            </script>
                            <script type="text/javascript" src="../expand.js">
                                // //
                            </script>
                        </head>
                        
                        <xsl:choose>
                            <xsl:when test="$tagsets/tagset='Books Interchange'">
                                <body class="book">
                                    <div id="wrapper">
                                        <div id="head"> 
                                            <h1 class="main">BITS Element Index</h1>
                                        </div>
                                        <div id="nav">
                                            <div class="sidebar">
                                                <div class="inner">
                                                    <p class="sidebar-outer-book">Elements</p>
                                                    <ul class="sidebar-inner">
                                                        <xsl:for-each select="$elements/element">
                                                            <li>
                                                                <a><xsl:attribute name="href"><xsl:value-of select="concat('../bits/el-',.,'.html')"/></xsl:attribute>
                                                                    <xsl:value-of select="concat('&lt;',.,'&gt;')"/></a>
                                                            </li>
                                                        </xsl:for-each>
                                                    </ul>
                                                </div>
                                            </div>
                                        </div>
                                        <div id="content">
                                            <div class="inner">
                                                <h1 class="inner-head-book"><xsl:value-of select="concat('Element: ','&lt;',$element[1],'&gt;')"/></h1>
                                                <h1 class="inner-head-book">Element first appeared in version: <xsl:value-of select="$v1/version[1]"/></h1>
                                            
                                                <xsl:call-template name="write-tag-sets">
                                                    <xsl:with-param name="tagset" select="$tagsets/tagset"/>
                                                    <xsl:with-param name="element" select="$element[1]"/>
                                                </xsl:call-template>
                                            </div>
                                        </div>
                                    </div>
                                </body>
                            </xsl:when>
                            <xsl:otherwise>
                                <body>
                                    <div id="wrapper">
                                        <div id="head"> 
                                            <h1 class="main">NLM/JATS Element Index</h1>
                                        </div>
                                        <div id="nav">
                                            <div class="sidebar">
                                                <div class="inner">
                                                    <p class="sidebar-outer">Elements</p>
                                                    <ul class="sidebar-inner">
                                                        <xsl:for-each select="$elements/element">
                                                            <li>
                                                                <a><xsl:attribute name="href"><xsl:value-of select="concat('../nlm_jats/el-',.,'.html')"/></xsl:attribute>
                                                                    <xsl:value-of select="concat('&lt;',.,'&gt;')"/></a>
                                                            </li>
                                                        </xsl:for-each>
                                                    </ul>
                                                </div>
                                            </div>
                                        </div>
                                        <div id="content">
                                            <div class="inner">
                                                <h1 class="inner-head"><xsl:value-of select="concat('Element: ','&lt;',$element[1],'&gt;')"/></h1>
                                                <h1 class="inner-head">Element first appeared in version: <xsl:value-of select="$v1/version[1]"/></h1>
                                            
                                                <xsl:call-template name="write-tag-sets">
                                                    <xsl:with-param name="tagset" select="$tagsets/tagset"/>
                                                    <xsl:with-param name="element" select="$element[1]"/>
                                                </xsl:call-template>
                                            </div>
                                        </div>
                                    </div>
                                </body>
                            </xsl:otherwise>
                        </xsl:choose>
                    </html>
                    </xsl:result-document>
                    
                    <xsl:call-template name="write-elements">
                        <xsl:with-param name="element" select="$element[position()!=1]"/>
                    </xsl:call-template>
                    
                </xsl:if>
        
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- NAMED TEMPLATE: WRITE-TAG-SETS                                                 -->
    <!-- ============================================================================== -->
    <xsl:template name="write-tag-sets">
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        
        <xsl:choose>
            <xsl:when test="$tagset">
                    
                    <xsl:if test="$tagset!='Books Interchange'">
                        <h1 class="inner-head"><xsl:value-of select="$tagset[1]"/></h1>
                    </xsl:if>               
                    
                        <h3>CONTENT MODELS:</h3>
                        <div id="model">
                            <xsl:choose>
                                <xsl:when test="$tagset[1] = 'Journal Archive &amp; Interchange'">
                                    <xsl:call-template name="write-arch-version-models">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Journal Publishing'">
                                    <xsl:call-template name="write-pub-version-models">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Journal Article Authoring'">                            
                                    <xsl:call-template name="write-author-version-models">
                                        <xsl:with-param name="auth-version" select="$auth-versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Books Interchange'">                            
                                    <xsl:call-template name="write-bits-version-models">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                            </xsl:choose>
                        </div>
                
                        <h3>ATTRIBUTES:</h3>
                        <div id="att">
                            <xsl:choose>
                                <xsl:when test="$tagset[1] = 'Journal Archive &amp; Interchange'">
                                    <xsl:call-template name="write-arch-version-attributes">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Journal Publishing'">
                                    <xsl:call-template name="write-pub-version-attributes">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Journal Article Authoring'">
                                    <xsl:call-template name="write-author-version-attributes">
                                        <xsl:with-param name="auth-version" select="$auth-versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$tagset[1] = 'Books Interchange'">
                                    <xsl:call-template name="write-bits-version-attributes">
                                        <xsl:with-param name="version" select="$versions/version"/>
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="tagset" select="$tagset[1]"/>
                                    </xsl:call-template>
                                </xsl:when>
                            </xsl:choose>
                        </div>
                    
                
                
                <xsl:call-template name="write-tag-sets">
                   <xsl:with-param name="tagset" select="$tagset[position()!=1]"/>
 				   <xsl:with-param name="element" select="$element"/>
               </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED VERSION MODEL TEMPLATES ==================================================================== -->
    <!-- =================================================================================================================================================================================== -->
    
    <!-- ========================================= -->
    <!-- NAMED TEMPLATE: WRITE-ARCH-VERSION-MODELS -->
    <!-- ========================================= -->
    <xsl:template name="write-arch-version-models">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'archivearticle')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/content-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                
                <div class="arch">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <xsl:choose>
                        <xsl:when test="$my-model">
                            <xsl:choose>
                                <xsl:when test="$current-model=''">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$current-model = $my-model">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                    </xsl:call-template>
                                </xsl:when>  
                                <xsl:otherwise>
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'ELEMENT NOT FEATURED IN THIS VERSION'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
                
                <xsl:call-template name="write-arch-version-models">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="element" select="$element"/>                    
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>            
            
        </xsl:choose>
    </xsl:template>
    
    <!-- ======================================== -->
    <!-- NAMED TEMPLATE: WRITE-PUB-VERSION-MODELS -->
    <!-- ======================================== -->
    <xsl:template name="write-pub-version-models">
        <xsl:param name="version"/>
        <xsl:param name="element"/>
        <xsl:param name="tagset"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'journalpublishing')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/content-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                
                <div class="pub">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <xsl:choose>
                        <xsl:when test="$my-model">
                            <xsl:choose>
                                <xsl:when test="$current-model=''">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$current-model = $my-model">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                    </xsl:call-template>
                                </xsl:when>  
                                <xsl:otherwise>
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'ELEMENT NOT FEATURED IN THIS VERSION'"/>
                        </xsl:otherwise>
                    </xsl:choose> 
                </div>
                
                <xsl:call-template name="write-pub-version-models">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- =========================================== -->
    <!-- NAMED TEMPLATE: WRITE-AUTHOR-VERSION-MODELS -->
    <!-- =========================================== -->
    <xsl:template name="write-author-version-models">
        <xsl:param name="auth-version"/>
        <xsl:param name="element"/>
        <xsl:param name="tagset"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'articleauthoring')]/element[@name=$element and preceding-sibling::dtd-info[@version=$auth-version[1]]]/content-model"/>
        
        <xsl:choose>
            <xsl:when test="$auth-version">
                
                <div class="auth">
                    <h4><xsl:value-of select="$auth-version[1]"/></h4>
                    <xsl:choose>
                        <xsl:when test="$my-model">
                            <xsl:choose>
                                <xsl:when test="$current-model=''">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$current-model = $my-model">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                    </xsl:call-template>
                                </xsl:when>  
                                <xsl:otherwise>
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'ELEMENT NOT FEATURED IN THIS VERSION'"/>
                        </xsl:otherwise>
                    </xsl:choose> 
                </div>
                
                <xsl:call-template name="write-author-version-models">
                    <xsl:with-param name="auth-version" select="$auth-version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========================================= -->
    <!-- NAMED TEMPLATE: WRITE-BITS-VERSION-MODELS -->
    <!-- ========================================= -->
    <xsl:template name="write-bits-version-models">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'BITS')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/content-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                
                <div class="bits">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <xsl:choose>
                        <xsl:when test="$my-model">
                            <xsl:choose>
                                <xsl:when test="$current-model=''">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:when test="$current-model = $my-model">
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                    </xsl:call-template>
                                </xsl:when>  
                                <xsl:otherwise>
                                    <xsl:call-template name="write-models">             
                                        <xsl:with-param name="my-model" select="$my-model"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'ELEMENT NOT FEATURED IN THIS VERSION'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
                
                <xsl:call-template name="write-bits-version-models">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="element" select="$element"/>                    
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>            
            
        </xsl:choose>
    </xsl:template>
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED VERSION MODEL TEMPLATES ==================================================================== -->
    <!-- =================================================================================================================================================================================== -->
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED VERSION ATTRIBUTE TEMPLATES ================================================================ -->
    <!-- =================================================================================================================================================================================== -->
    
    <!-- ======================================== -->
    <!-- NAMED TEMPLATE: WRITE-VERSION-ATTRIBUTES -->
    <!-- ======================================== -->
    <xsl:template name="write-arch-version-attributes">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'archivearticle')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/attribute-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                <div class="arch">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <div>
                        <table width="800">
                            <xsl:choose>
                                <xsl:when test="$my-model!='EMPTY'">
                                    <xsl:choose>
                                        <xsl:when test="$current-model=''">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:when test="$current-model = $my-model">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                            </xsl:call-template>
                                        </xsl:when>  
                                        <xsl:otherwise>
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION'"/> 
                                </xsl:otherwise>
                            </xsl:choose>
                        </table>
                    </div>
                </div>
                
                <xsl:call-template name="write-arch-version-attributes">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- ============================================ -->
    <!-- NAMED TEMPLATE: WRITE-PUB-VERSION-ATTRIBUTES -->
    <!-- ============================================ -->
    <xsl:template name="write-pub-version-attributes">
        <xsl:param name="version"/>
        <xsl:param name="element"/>
        <xsl:param name="tagset"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'journalpublishing')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/attribute-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                <div class="pub">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <div>
                        <table width="800">
                            <xsl:choose>
                                <xsl:when test="$my-model!='EMPTY'">
                                    <xsl:choose>
                                        <xsl:when test="$current-model=''">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:when test="$current-model = $my-model">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                            </xsl:call-template>
                                        </xsl:when>  
                                        <xsl:otherwise>
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION'"/> 
                                </xsl:otherwise>
                            </xsl:choose>
                        </table>
                    </div>
                </div>
                
                <xsl:call-template name="write-pub-version-attributes">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- =============================================== -->
    <!-- NAMED TEMPLATE: WRITE-AUTHOR-VERSION-ATTRIBUTES -->
    <!-- =============================================== -->
    <xsl:template name="write-author-version-attributes">
        <xsl:param name="auth-version"/>
        <xsl:param name="element"/>
        <xsl:param name="tagset"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'articleauthoring')]/element[@name=$element and preceding-sibling::dtd-info[@version=$auth-version[1]]]/attribute-model"/>
        
        <xsl:choose>
            <xsl:when test="$auth-version">
                <div class="auth">
                    <h4><xsl:value-of select="$auth-version[1]"/></h4>
                    <div>
                        <table width="800">
                            <xsl:choose>
                                <xsl:when test="$my-model!='EMPTY'">
                                    <xsl:choose>
                                        <xsl:when test="$current-model=''">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:when test="$current-model = $my-model">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                            </xsl:call-template>
                                        </xsl:when>  
                                        <xsl:otherwise>
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION'"/> 
                                </xsl:otherwise>
                            </xsl:choose>
                        </table>
                    </div>
                </div>
                
                <xsl:call-template name="write-author-version-attributes">
                    <xsl:with-param name="auth-version" select="$auth-version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- ============================================= -->
    <!-- NAMED TEMPLATE: WRITE-BITS-VERSION-ATTRIBUTES -->
    <!-- ============================================= -->
    <xsl:template name="write-bits-version-attributes">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'BITS')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/attribute-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                <div class="bits">
                    <h4><xsl:value-of select="$version[1]"/></h4>
                    <div>
                        <table width="800">
                            <xsl:choose>
                                <xsl:when test="$my-model!='EMPTY'">
                                    <xsl:choose>
                                        <xsl:when test="$current-model=''">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:when test="$current-model = $my-model">
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="'UNCHANGED'"/>
                                            </xsl:call-template>
                                        </xsl:when>  
                                        <xsl:otherwise>
                                            <xsl:call-template name="write-attributes">             
                                                <xsl:with-param name="my-model" select="$my-model"/>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION'"/> 
                                </xsl:otherwise>
                            </xsl:choose>
                        </table>
                    </div>
                </div>
                
                <xsl:call-template name="write-bits-version-attributes">
                    <xsl:with-param name="version" select="$version[position()!=1]"/>
                    <xsl:with-param name="element" select="$element"/>
                    <xsl:with-param name="tagset" select="$tagset"/>
                    <xsl:with-param name="current-model" select="$my-model"/>
                </xsl:call-template>
                
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED VERSION ATTRIBUTE TEMPLATES ================================================================ -->
    <!-- =================================================================================================================================================================================== -->
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED SHARED TEMPLATES =========================================================================== -->
    <!-- =================================================================================================================================================================================== -->
   
    <!-- ============================ -->
    <!-- NAMED TEMPLATE: WRITE-MODELS -->
    <!-- ============================ -->
    <xsl:template name="write-models">
        <xsl:param name="my-model"/>
        <xsl:value-of select="if ($my-model='UNCHANGED') then 'NO CHANGE IN CONTENT MODEL' else $my-model/@sp-model"/>
    </xsl:template>
    
    <!-- ================================ -->
    <!-- NAMED TEMPLATE: WRITE-ATTRIBUTES -->
    <!-- ================================ -->
    <xsl:template name="write-attributes">
        <xsl:param name="my-model"/>
        <xsl:choose>
            <xsl:when test="$my-model = 'UNCHANGED'">
                <tr><td><xsl:value-of select="'NO CHANGE IN ATTRIBUTE MODEL'"/></td></tr>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$my-model/attribute">
                    <tr>
                        <td><xsl:value-of select="concat('&#x0040;',@name)"/></td>
                        <td><xsl:value-of select="concat('Type: ',@type)"/></td>
                        <td><xsl:value-of select="concat('Mode: ',@mode)"/></td>
                    </tr>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>            
    </xsl:template>
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED SHARED TEMPLATES =========================================================================== -->
    <!-- =================================================================================================================================================================================== -->
</xsl:stylesheet>
