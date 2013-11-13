<?xml version="1.0" encoding="UTF-8"?>
<!--
  This stylesheet builds the DTD documentation for the DtdAnalyzer.
  Input is XML that's produced as output from the dtdanalyzer stage.
  Output is a set of XHTML files that land in $docDir (default is "doc"):
    - index.html
    - toc.html - the navigation panel on the left
    - entries
        - elem-*.html
        - attr-*.html

  This applies templates through the entire input document twice, each time with
  a different mode:
    - toc:  when building the toc.html page.
    - pages:  when building the index.html and all the entry pages.
-->

<xsl:stylesheet xmlns:pmc="http://www.ncbi.nlm.nih.gov/pmc/ns" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                version="2.0">

  <xsl:output method="html" 
              encoding="UTF-8" 
              indent="yes"/>

  <!-- Current date and time, for stamping onto each output page -->
  <xsl:param name="date" select="format-date(current-date(),'[MNn] [D], [Y]')"/>
  <xsl:param name="time" select="format-time(current-time(),'[h]:[m] P')"/>

  <!-- The directory to which to write the results -->
  <xsl:param name="docDir" select="'doc'"/>

  <!-- CSS file to include -->
  <xsl:param name="css" select="'http://dtd.nlm.nih.gov/ncbi/jatsdoc/0.1/jatsdoc.css'"/>

  <!-- JS file to include -->
  <xsl:param name='js' select='"http://dtd.nlm.nih.gov/ncbi/jatsdoc/0.1/jatsdoc.js"'/>

  <!-- Allows user to add more CSS and JS files, if they want.  -->
  <xsl:param name="include-files"/>

  <!-- This should be 1 if we are supposed to create suffixes for filenames that otherwise
    would differ only by case. -->
  <xsl:param name="filesuffixes" select="1"/>

  <!-- Exclude all the elements that match the regular expression $exclude-elems,
    except those that match the regular expression $exclude-except. -->
  <xsl:param name="exclude-elems" select="' '"/>
  <xsl:param name="exclude-except" select="' '"/>

  <!-- Controls documentation generation for parameter and general entities -->
  <xsl:param name="entities" select="'off'"/>

  <xsl:key name="entitiesByLCName" match="entity" use="lower-case(@name)"/>

  <xsl:variable name="title">
    <xsl:choose>
      <xsl:when test="/declarations/title">
        <xsl:value-of select="/declarations/title"/>
        <xsl:text> Documentation</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Documentation for </xsl:text>
        <xsl:value-of select="/declarations/dtd/@relSysId"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <!--================================================================
    Root template:  start here 
  -->
  
  <xsl:template match="/">
    <!-- Build the toc.html page -->
    <xsl:apply-templates mode="toc"/>
    
    <!-- Build index.html and all of the entry pages -->
    <xsl:apply-templates select='declarations/*[not(title)]' mode="pages"/>

    <!-- Build entry pages for each tag --> 
    <xsl:for-each-group select="//annotation[@type='tags']/tag" group-by=".">
      <xsl:apply-templates select="current-group()[1]" mode="pages"/>
    </xsl:for-each-group>

  </xsl:template>


  <!--===================================================================================
    Build the toc.html, which is the navigation panel on the left.
    These use mode='toc'
  -->

  <!-- 
    Matches the top-level element while we're building the toc.  This will
    create the toc.html file. 
  -->
  <xsl:template match="declarations" mode='toc'>
    <xsl:variable name="file" select="concat($docDir, '/toc.html')"/>

    <xsl:result-document href="{$file}">
      <ul id="categories">
        <!-- elements, attributes, param-entities, general-entities -->
        <xsl:apply-templates mode="toc"/>

        <!-- tags, if any exist -->
        <xsl:if test="//annotation[@type='tags']">
          <li class="top-cat has-kids">
            <span class="top-cat-name">Tags</span>
            <ul class="entries">
              <xsl:for-each select="distinct-values(//annotation[@type='tags']/tag)">
                <xsl:call-template name='navLink'>
                  <xsl:with-param name="name" select="string(.)"/>
                  <xsl:with-param name="type" select="'tag'"/>
                </xsl:call-template>
              </xsl:for-each>
            </ul>
          </li>
        </xsl:if>
      </ul>
    </xsl:result-document>
  </xsl:template>
  
  <!-- Discard these, they aren't used in the toc.html -->
  <xsl:template match='title|dtd' mode='toc'/>

  <xsl:template match="elements" mode="toc">
    <li class="top-cat has-kids">
      <span class="top-cat-name">Elements</span>
      <ul class="entries">
        <xsl:for-each select="element[pmc:included(@name) and not(@reachable='false')]">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:call-template name="navLink">
            <xsl:with-param name="name" select="@name"/>
            <xsl:with-param name="type" select="'elem'"/>
          </xsl:call-template>
        </xsl:for-each>
      </ul>
    </li>
  </xsl:template>

  <xsl:template match="attributes" mode="toc">
    <li class="top-cat has-kids">
      <span class="top-cat-name">Attributes</span>
      <ul class="entries">
        <xsl:for-each select="attribute">
          <xsl:sort select="@name" order="ascending"/>
          <xsl:variable name="notexcluded">
            <!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
            <xsl:for-each select="attributeDeclaration">
              <xsl:choose>
                <xsl:when test="not(pmc:included(@element)) or @element=//element[@reachable='false']/@name">0</xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:variable>
          <xsl:if test="contains($notexcluded, '1')">
            <xsl:call-template name="navLink">
              <xsl:with-param name="name" select="@name"/>
              <xsl:with-param name="type" select="'attr'"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each>
      </ul>
    </li>
  </xsl:template>
  
  <xsl:template match="parameterEntities" mode="toc">
    <xsl:if test="$entities='on'">
      <li class="top-cat has-kids">
        <span class="top-cat-name">Parameter Entities</span>
        <ul class="entries">
          <xsl:for-each select="entity">
            <xsl:sort select="lower-case(@name)" order="ascending"/>
            <xsl:call-template name="navLink">
              <xsl:with-param name="name" select="@name"/>
              <xsl:with-param name="type" select="'pe'"/>
            </xsl:call-template>
          </xsl:for-each>
        </ul>
      </li>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="generalEntities" mode="toc">
    <xsl:if test="$entities='on'">
      <li class="top-cat has-kids">
        <span class="top-cat-name">General Entities</span>
        <ul class="entries">
          <xsl:for-each select="entity">
            <xsl:sort select="lower-case(@name)" order="ascending"/>
            <xsl:call-template name="navLink">
              <xsl:with-param name="name" select="@name"/>
              <xsl:with-param name="type" select="'ge'"/>
            </xsl:call-template>
          </xsl:for-each>
        </ul>
      </li>
    </xsl:if>
  </xsl:template>

  <!--
    navLink - creates one link in the navigation panel corresponding to an entry
    (an element, attribute, entity, etc.)  $type should be one of "elem", "attr",
    "pe", or "ge".
  -->
  <xsl:template name="navLink">
    <xsl:param name="name"/>
    <xsl:param name="type"/>
    
    <xsl:variable name='slug'>
      <xsl:call-template name='makeSlug'>
        <xsl:with-param name="name" select='$name'/>
        <xsl:with-param name="type" select='$type'/>
      </xsl:call-template>
    </xsl:variable>
        
    <li class='entry' data-slug='{$slug}'>
      <span class="title">
        <xsl:call-template name="makeLabel">
          <xsl:with-param name="name" select='$name'/>
          <xsl:with-param name="type" select='$type'/>
        </xsl:call-template>
      </span>
    </li>
  </xsl:template>
  
  

  <!--==============================================================================
    Build index.html page
  -->

  <xsl:template match="dtd" mode="pages">
    <xsl:variable name="file" select="concat($docDir, '/index.html')"/>
    
    <xsl:result-document href="{$file}">
      <!-- We require the HTML5 doctype, otherwise scrolling is messed up.  -->
      <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
      <html>
        <head>
          <title>
            <xsl:copy-of select="$title"/>
          </title>
          
          <xsl:if test="$css != ''">
            <link rel="stylesheet" type="text/css" href="{$css}"/>
          </xsl:if>
          
          <!-- Links to other stylesheets, google fonts, javascript, etc. added here -->
          <xsl:if test="$include-files">
            <xsl:for-each select="tokenize($include-files, ' ')">
              <xsl:choose>
                <xsl:when test="contains(., '.js')">
                  <script type="text/javascript" src="{.}">
                    // <![CDATA[//]]>
                  </script>
                </xsl:when>
                <xsl:when test="contains(., '.css')">
                  <link rel="stylesheet" type="text/css" href="{.}"/>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </xsl:if>
          
          <xsl:if test='$js != ""'>
            <script type="text/javascript" src="{$js}">
              // <![CDATA[//]]>
            </script>
          </xsl:if>
        </head>
        
        <body>
          <!-- Boilerplate content for the jatsdoc library -->
          <div id='sidebar'>
            <div id='search'>
              <input autocomplete='off'
                     autofocus='autofocus'
                     autosave='searchdoc'
                     id='search-field'
                     placeholder='Search'
                     results='0'
                     type='search' />
            </div>
            <div id='sidebar-content'>
              <ul id='categories'>
                <li class='loader'>Loading...</li>
              </ul>
              <ul class='entries' id='results'>
                <li class='not-found'>Nothing found.</li>
              </ul>
            </div>
          </div>
          
          <div id="content">
            <div id='header'>
              <ul id='signatures-nav'>
                <li>
                  <xsl:copy-of select="$title"/>
                </li>
              </ul>
              <ul id='navigation'>
                <li>
                  <a href='.'>
                    <span>Home</span>
                  </a>
                </li>
              </ul>
            </div>
            
            <div id='entry'>
              <div id='entry-wrapper'>
                <h1>
                  <xsl:copy-of select="$title"/>
                </h1>
                <xsl:apply-templates select="annotations/*"/>
              </div>

              <div id='footer'>
                <h2>
                  <xsl:copy-of select="$title"/>
                </h2>
                <p class='ack'>Rendered with 
                  <a href='http://github.com/Klortho/jatsdoc'>jatsdoc</a>.
                </p>
                
                <!-- Reconcile these.  "pubdate" is in the JATS tag library.  -->
                <p>Generated by the 
                  <a href="http://dtd.nlm.nih.gov/ncbi/dtdanalyzer/">DtdAnalyzer</a>
                  on <xsl:value-of select="$date"/> at <xsl:value-of select="$time"/>.
                </p>
              </div>
            </div>
          </div>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>
  
  <!--==============================================================================
    Build entry pages
  -->

  <!--
    Exclude unwanted elements, attributes, and entities
  -->

  <xsl:template match="elements" mode='pages'>
    <xsl:apply-templates select="element[pmc:included(@name) and not(@reachable='false')]" mode="pages"/>
  </xsl:template>
  
  <xsl:template match="attributes" mode="pages">
    <xsl:for-each select="attribute">
      <!-- Checks to see if only excluded elements are in attributeDeclarations. Excludes attributes if so. -->
      <xsl:variable name="notexcluded">
        <xsl:for-each select="attributeDeclaration">
          <xsl:choose>
            <xsl:when test="not(pmc:included(@element)) or @element=//element[@reachable='false']/@name">0</xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="contains($notexcluded, '1')">
        <xsl:apply-templates select="self::attribute" mode="pages"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="parameterEntities | generalEntities" mode="pages">
    <xsl:if test="$entities='on'">
      <xsl:apply-templates select="entity" mode="pages"/>
    </xsl:if>
  </xsl:template>
  


  <!-- This builds a page. -->
  <xsl:template match="element | attribute | entity | tag" mode="pages">
    <xsl:variable name='type'>
      <xsl:choose>
        <xsl:when test="self::element">
          <xsl:text>elem</xsl:text>
        </xsl:when>
        <xsl:when test="self::attribute">
          <xsl:text>attr</xsl:text>
        </xsl:when>
        <xsl:when test='self::entity and parent::parameterEntities'>
          <xsl:text>pe</xsl:text>
        </xsl:when>
        <xsl:when test='self::entity and parent::generalEntities'>
          <xsl:text>ge</xsl:text>
        </xsl:when>
        <xsl:when test='self::tag'>
          <xsl:text>tag</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name='name'>
      <xsl:choose>
        <xsl:when test="$type != 'tag'">
          <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="string(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="filename">
      <xsl:value-of select='concat($docDir, "/entries/")'/>
      <xsl:call-template name='makeSlug'>
        <xsl:with-param name="name" select='$name'/>
        <xsl:with-param name="type" select='$type'/>
      </xsl:call-template>
      <xsl:text>.html</xsl:text>
    </xsl:variable>

    <xsl:result-document href="{$filename}">
      <div id="entry-wrapper">
        <xsl:apply-templates select="self::node()" mode="content">
          <xsl:with-param name="type" select='$type'/>
        </xsl:apply-templates>
      </div>
    </xsl:result-document>
  </xsl:template>
  
  
  
  <!-- ====================================================== 
    Page Content
  -->


  <!-- Element Page -->

  <xsl:template match="element" mode="content">
    <h1>
      <xsl:call-template name="makeLabel">
        <xsl:with-param name="name" select='@name'/>
        <xsl:with-param name="type" select='"elem"'/>
      </xsl:call-template>
      <xsl:if test="@root='true'">
        <xsl:text> (root)</xsl:text>
      </xsl:if>
    </h1>
    
    <xsl:apply-templates select="annotations/annotation[@type='notes']"/>
    
    <xsl:variable name="e-name">
      <xsl:value-of select="@name"/>
    </xsl:variable>
    <xsl:if test="../../attributes/attribute[attributeDeclaration/@element=$e-name]">
      <h2>Attributes</h2>
      <ul class="attributes">
        <xsl:for-each select="../../attributes/attribute[attributeDeclaration/@element=$e-name]">
          <xsl:sort select="@name"/>
          <li>
            <xsl:call-template name="makeLink">
              <xsl:with-param name="name" select="@name"/>
              <xsl:with-param name="type" select="'attr'"/>
            </xsl:call-template>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
    
    <xsl:if test="content-model/@spec != 'empty'">
      <h2>Content Model</h2>
      <pre class="contentdesc">
        <xsl:value-of select="content-model/@spaced"/>
      </pre>
      
      <xsl:apply-templates select="annotations/annotation[@type='model']"/>
      <xsl:if test="content-model//child[pmc:included(.)]">
        <p>May Contain:</p>
        <ul class="children">
          <xsl:if test="content-model/@spec='mixed' or content-model/@spec='text'">
            <li>PCDATA</li>
          </xsl:if>
          <xsl:for-each select="content-model//child[pmc:included(.)]">
            <xsl:sort select="."/>
            <li>
              <xsl:call-template name="makeLink">
                <xsl:with-param name="name" select="."/>
                <xsl:with-param name="type" select="'elem'"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
      </xsl:if>
    </xsl:if>
    
    <xsl:apply-templates select="annotations/annotation[@type='tags']"/>
    <xsl:apply-templates select="annotations/annotation[@type='examples']"/>
    
    <xsl:if test="context/parent[pmc:included(@name)][@name=//element[not(@reachable='false')]/@name]">
      <h2>May be contained in:</h2>
      <ul class="parents">
        <xsl:for-each select="context/parent[pmc:included(@name)][@name=//element[not(@reachable='false')]/@name]">
          <xsl:sort select="@name"/>
          <li>
            <xsl:call-template name="makeLink">
              <xsl:with-param name="name" select="@name"/>
              <xsl:with-param name="type" select="'elem'"/>
            </xsl:call-template>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>


  <!-- Attribute Page -->

  <xsl:template match="attribute" mode="content">
    <h1>
      <xsl:call-template name="makeLabel">
        <xsl:with-param name="name" select='@name'/>
        <xsl:with-param name="type" select='"attr"'/>
      </xsl:call-template>
    </h1>
    
    <xsl:apply-templates select="annotations/annotation[@type='notes']"/>
    
    <xsl:choose>
      <xsl:when test="count(distinct-values(attributeDeclaration[
                        not(not(pmc:included(@element)) or @element=//element[@reachable='false']/@name)]/@type)) > 1">
        <table class="attrtable">
          <tr>
            <th>Value</th>
            <th>In Elements</th>
          </tr>
          <xsl:for-each-group select="attributeDeclaration[not(not(pmc:included(@element)) or @element=//element[@reachable='false']/@name)]" group-by="@type">
            <xsl:sort select="count(current-group()/@element)" order="ascending"/>
            <tr class="attvalue">
              <td>
                <xsl:value-of select="current-grouping-key()"/>
              </td>
              <td>
                <xsl:for-each select="current-group()">
                  <xsl:value-of select="concat('&lt;', @element, '&gt;')"/>
                  <xsl:text> </xsl:text>
                </xsl:for-each>
              </td>
            </tr>
          </xsl:for-each-group>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <p class="bold">Value: <span class="attvalue">
            <xsl:value-of select="attributeDeclaration[not(not(pmc:included(@element)) or @element=//element[@reachable='false']/@name)][1]/@type"/>
          </span>
        </p>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:apply-templates select="annotations/annotation[@type='model']"/>
    <xsl:apply-templates select="annotations/annotation[@type='tags']"/>
    <xsl:apply-templates select="annotations/annotation[@type='examples']"/>
    
    <h2>May be in elements</h2>
    <ul class="parents">
      <xsl:for-each select="attributeDeclaration[not(not(pmc:included(@element)) or @element=//element[@reachable='false']/@name)]">
        <xsl:sort select="@element"/>
        <li>
          <xsl:call-template name="makeLink">
            <xsl:with-param name="name" select="@element"/>
            <xsl:with-param name="type" select="'elem'"/>
          </xsl:call-template>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>


  <!-- Entity Page -->

  <xsl:template match="entity" mode="content">
    <xsl:param name="type"/>
    <h1>
      <xsl:call-template name="makeLabel">
        <xsl:with-param name="name" select='@name'/>
        <xsl:with-param name="type" select='$type'/>
      </xsl:call-template>
    </h1>
    
    <xsl:apply-templates select="annotations/annotation[@type='notes']"/>
    
    <xsl:if test="value != ''">
      <h2>Content Model</h2>
      <p class="content-model">
        <pre><xsl:value-of select="value"/></pre>
      </p>
      <xsl:apply-templates select="annotations/annotation[@type='model']"/>
    </xsl:if>
    
    <xsl:apply-templates select="annotations/annotation[@type='tags']"/>
    <xsl:apply-templates select="annotations/annotation[@type='examples']"/>
  </xsl:template>


  <!-- Tag Page -->

  <xsl:template match="tag" mode="content">
    <xsl:variable name="name" select='string(.)'/>
    
    <h1>Tag: <xsl:value-of select="$name"/></h1>
    
    <h2>
      <xsl:text>Tagged with "</xsl:text>
      <xsl:value-of select="$name"/>
      <xsl:text>"</xsl:text>
    </h2>
    <ul class="tags">
      <xsl:for-each-group select="//*[annotations[annotation[tag=$name]]][not(self::element and (@reachable='false' or not(pmc:included(@name)))) and
        not(self::attribute and ( @element and not(pmc:included(@element)) or @element=//element[@reachable='false']/@name))]" group-by="parent::node()/name()">
        <h4 class="notetitle">
          <xsl:value-of select="if (current-grouping-key()='parameterEntities') then 'parameter entities' else
            if(current-grouping-key()='generalEntities') then 'general entities' else current-grouping-key()"/>
        </h4>
        <ul class="tags">
          <xsl:for-each select="current-group()">
            <xsl:sort select="translate(@name, 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending"/>
            <xsl:call-template name="makeLink">
              <xsl:with-param name="name" select='@name'/>
              <!-- FIXME -->
              <xsl:with-param name="type" select="if(self::entity) then parent::node()/name() else self::node()/name()"/>
            </xsl:call-template>
          </xsl:for-each>
        </ul>
      </xsl:for-each-group>
    </ul>
  </xsl:template>


  <!-- Named templates for making links inside content.  -->
  
  <xsl:template name="makeLink">
    <xsl:param name='name'/>
    <xsl:param name='type'/>
    <a>
      <xsl:attribute name='href'>
        <xsl:text>#p=</xsl:text>
        <xsl:call-template name="makeSlug">
          <xsl:with-param name='name' select='$name'/>
          <xsl:with-param name="type" select='$type'/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:call-template name="makeLabel">
        <xsl:with-param name="name" select='$name'/>
        <xsl:with-param name="type" select='$type'/>
      </xsl:call-template>
    </a>
  </xsl:template>
  
  <xsl:template match="annotation[not(@type='schematron')]">
    <div class="{@type}">
      <xsl:if test="@type='examples'">
        <h2 class="notetitle">Examples</h2>
      </xsl:if>
      <xsl:if test="@type='tags'">
        <h2 class="notetitle">Tags</h2>
      </xsl:if>
      <xsl:apply-templates select="text()|* except tag" mode='content'/>
      <xsl:if test="@type='tags'">
        <p>
          <xsl:apply-templates select="tag"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template match='@*|node()' mode='content'>
    <xsl:copy>
      <xsl:apply-templates select='@*|node()' mode='content'/>
    </xsl:copy>
  </xsl:template>

  <!-- We have to intercept the <a> hyperlinks to other pages that were created by Java,
    because Java doesn't know about the index suffixes that we might have added. -->
  <xsl:template match='a[starts-with(@href, "#p=")]' mode='content'>
    <xsl:variable name='orig-slug' select='substring-after(@href, "#p=")'/>
    <xsl:variable name='name' select='substring-after($orig-slug, "-")'/>
    <xsl:variable name='type' select='substring-before($orig-slug, "-")'/>
    
    <!-- Redo the hyperlink with a new href, but preserve other attributes and content -->
    <a>
      <xsl:apply-templates select='@* except @href' mode='content'/>
      <xsl:attribute name='href'>
        <xsl:text>#p=</xsl:text>
        <xsl:call-template name="makeSlug">
          <xsl:with-param name='name' select='$name'/>
          <xsl:with-param name="type" select='$type'/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates select='node()' mode='content'/>
    </a>
  </xsl:template>
  

  <xsl:template match="annotation[@type='schematron']"/>
  
  <xsl:template match="tag">
    <xsl:call-template name="makeLink">
      <xsl:with-param name="name" select='.'/>
      <xsl:with-param name="type" select='"tag"'/>
    </xsl:call-template>
    <xsl:if test="following-sibling::tag">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  

  <!-- ================================================================= 
    General Templates
  -->


  <!-- 
    makeSlug 
    Constructs the base part of the filename for the documentation page for a thing (element, 
    attribute, etc.), given its name and its type.  This same template is used:
      * to contruct the slug used in the navigation panel (toc.html),
      * to create the output filename when the file is written, and
      * to create inter-page links
      
    $type should be one of "elem", "attr", "pe", "ge", or "tag".
  -->
  <xsl:template name="makeSlug">
    <xsl:param name="name"/>
    <xsl:param name="type"/>
    <xsl:variable name='index'>
      <xsl:call-template name='makeIndex'>
        <xsl:with-param name="name" select='$name'/>
        <xsl:with-param name="type" select='$type'/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select='concat($type, "-")'/>
    <xsl:choose>
      <xsl:when test="$type='elem' or $type='attr'">
        <xsl:value-of select="translate($name, ':', '-')"/>
      </xsl:when>
      <xsl:when test="$type='pe' or $type='ge'">
        <xsl:value-of select="$name"/>
        <xsl:if test="$index != ''">
          <xsl:value-of select="concat('-', $index)"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$type='tag'">
        <xsl:value-of select="translate($name, ':', '-')"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!--
    makeLabel - the label is what the human sees when there's a link to an attribute,
    element, etc.  It includes the "@", angle-bracket, "&" decorations.
  -->
  <xsl:template name='makeLabel'>
    <xsl:param name='name'/>
    <xsl:param name='type'/>
    <xsl:choose>
      <xsl:when test="$type='elem'">
        <xsl:value-of select="concat('&lt;', $name, '&gt;')"/>
      </xsl:when>
      <xsl:when test="$type='attr'">
        <xsl:value-of select="concat('@', $name)"/>
      </xsl:when>
      <xsl:when test="$type='pe'">
        <xsl:value-of select="concat('%', $name, ';')"/>
      </xsl:when>
      <xsl:when test="$type='ge'">
        <xsl:value-of select="concat('&amp;', $name, ';')"/>
      </xsl:when>
      <xsl:when test='$type="tag"'>
        <xsl:value-of select='$name'/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- 
    makeIndex
    This template computes an index number suffix, when necessary, to append to a slug for a parameter
    or general entity.  If there are other entities that have the same name 
    as this one, ignoring case, then we'll need to append a suffix ("-1", "-2", etc.) to the 
    filenames for those. Because computing the suffix is time-consuming, use the key to find out 
    if there are others with such clashing names.
  -->
  <xsl:template name="makeIndex">
    <xsl:param name='name'/>
    <xsl:param name='type'/>

    <xsl:if test='$filesuffixes and ($type = "pe" or $type = "ge")'>
      <!-- Use xsl:for-each to change the context to the <entity> element called out by this name and type. -->
      <xsl:choose>
        <xsl:when test='$type="pe"'>
          <xsl:for-each select='/declarations/parameterEntities/entity[@name=$name]'>
            <xsl:call-template name='entityIndex'>
              <xsl:with-param name="name" select='$name'/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test='$type="ge"'>
          <xsl:for-each select='/declarations/generalEntities/entity[@name=$name]'>
            <xsl:call-template name='entityIndex'>
              <xsl:with-param name="name" select='$name'/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name='entityIndex'>
    <xsl:param name='name'/>

    <xsl:variable name="lcname" select="lower-case($name)"/>
    <xsl:if test="count(key('entitiesByLCName', $lcname)) > 1">
      <!--
        This preceding-sibling expression is relatively slow, and was causing
        performance problems when running against JATS-type DTDs (which have hundreds
        of entities, and the sidebar was included in every page.
        But now that the sidebar is in a separate iframe, that doesn't matter.
        There must be a better XSLT 2.0 way to do this, but I don't know it [cfm].
      -->
      <xsl:value-of select="count(preceding-sibling::entity[lower-case(@name) = $lcname])"/>
    </xsl:if>
  </xsl:template>


  <xsl:function name="pmc:included" as="xs:boolean">
    <xsl:param name="elemName" as="xs:string"/>
    <xsl:value-of select="not(matches($elemName, $exclude-elems)) or matches($elemName, $exclude-except)"/>
  </xsl:function>

</xsl:stylesheet>
