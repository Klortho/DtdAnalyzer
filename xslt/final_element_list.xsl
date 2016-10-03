<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0">
    
    <!-- ============================================================================== -->
    <!-- OUTPUT                                                                         -->
    <!-- ============================================================================== -->
    <xsl:output method="html" indent="yes"/>
    
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
            <head><title>Element report of NLM and JATS DTDs</title></head>
            <body>
                <xsl:call-template name="write-elements">
                    <xsl:with-param name="element" select="$elements/element"/>
                </xsl:call-template>
            </body>
        </html>
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
        
        <xsl:choose>
           <xsl:when test="$element">
               <div style="border:thick solid black;margin:2em 2em 2em 2em;">
                   <h2><xsl:value-of select="concat('Element: ','&lt;',$element[1],'&gt;')"/></h2>
                   <h3>Element first appeared in version: <xsl:value-of select="$v1/version[1]"/></h3>
                   
                   <xsl:call-template name="write-tag-sets">
                     <xsl:with-param name="tagset" select="$tagsets/tagset"/>
                     <xsl:with-param name="element" select="$element[1]"/>
                   </xsl:call-template>
                   
               </div>
               
               <xsl:call-template name="write-elements">
                   <xsl:with-param name="element" select="$element[position()!=1]"/>
               </xsl:call-template>
               
           </xsl:when>
           <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- ============================================================================== -->
    <!-- NAMED TEMPLATE: WRITE-TAG-SETS                                                 -->
    <!-- ============================================================================== -->
    <xsl:template name="write-tag-sets">
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        
        <xsl:choose>
            <xsl:when test="$tagset">
                
                <div>
                    <xsl:attribute name="style">
                        <xsl:choose>
                            <xsl:when test="$tagset='Journal Archive &amp; Interchange'">
                                <xsl:value-of select="'border:thick solid green;margin:2em 2em 2em 2em;'"/>
                            </xsl:when>
                            <xsl:when test="$tagset='Journal Publishing'">
                                <xsl:value-of select="'border:thick solid blue;margin:2em 2em 2em 2em;'"/>
                            </xsl:when>
                            <xsl:when test="$tagset='Journal Article Authoring'">
                                <xsl:value-of select="'border:thick solid orange;margin:2em 2em 2em 2em;'"/>
                            </xsl:when>
                            <xsl:when test="$tagset='Books Interchange'">
                                <xsl:value-of select="'border:thick solid brown;margin:2em 2em 2em 2em;'"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                    
                    <h4>MODELS:</h4>
                    <xsl:choose>
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
                        <xsl:otherwise>
                            <xsl:call-template name="write-version-models">
                                <xsl:with-param name="version" select="$versions/version"/>
                                <xsl:with-param name="element" select="$element"/>
                                <xsl:with-param name="tagset" select="$tagset[1]"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    
                    <h4>ATTRIBUTES:</h4>
                    <xsl:choose>
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
                        <xsl:otherwise>
                            <xsl:call-template name="write-version-attributes">
                                <xsl:with-param name="version" select="$versions/version"/>
                                <xsl:with-param name="element" select="$element"/>
                                <xsl:with-param name="tagset" select="$tagset[1]"/>
                            </xsl:call-template>
                        </xsl:otherwise>
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
    
    <!-- ==================================== -->
    <!-- NAMED TEMPLATE: WRITE-VERSION-MODELS -->
    <!-- ==================================== -->
    <xsl:template name="write-version-models">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'archivearticle')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/content-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
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
                            <h4>ELEMENT NOT FEATURED IN THIS VERSION</h4>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
                
                <xsl:call-template name="write-version-models">
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
                
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
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
                            <h4>ELEMENT NOT FEATURED IN THIS VERSION</h4> 
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
                
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
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
                            <h4>ELEMENT NOT FEATURED IN THIS VERSION</h4>
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
                
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
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
                            <h4>ELEMENT NOT FEATURED IN THIS VERSION</h4>
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
    <xsl:template name="write-version-attributes">
        <xsl:param name="version"/>
        <xsl:param name="tagset"/>
        <xsl:param name="element"/>
        <xsl:param name="current-model"/>
        
        <xsl:variable name="my-model" select="declarations[contains(@relsysid,'archivearticle')]/element[@name=$element and preceding-sibling::dtd-info[@version=$version[1]]]/attribute-model"/>
        
        <xsl:choose>
            <xsl:when test="$version">
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
                    <h4><xsl:value-of select="$version[1]"/></h4>
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
                            <h4>ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION</h4> 
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
                
                <xsl:call-template name="write-version-attributes">
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
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
                    <h4><xsl:value-of select="$version[1]"/></h4>
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
                            <h4>ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION</h4> 
                        </xsl:otherwise>
                    </xsl:choose>
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
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
                    <h4><xsl:value-of select="$auth-version[1]"/></h4>
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
                            <h4>ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION</h4> 
                        </xsl:otherwise>
                    </xsl:choose>
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
                <div style="border:thick solid red;margin:2em 2em 2em 2em;">
                    <h4><xsl:value-of select="$version[1]"/></h4>
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
                            <h4>ATTRIBUTE MODEL NOT FEATURED IN THIS VERSION</h4> 
                        </xsl:otherwise>
                    </xsl:choose>
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
                <h4>NO CHANGE IN ATTRIBUTE MODEL</h4>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$my-model/attribute">
                    <h4><xsl:value-of select="concat('&#x0040;',@name,'&#x00A0;','Type: ',@type,'&#x00A0;','Mode: ',@mode,'&#x000D;')"/></h4>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>            
    </xsl:template>
    
    <!-- =================================================================================================================================================================================== -->
    <!-- ================================================================================ NAMED SHARED TEMPLATES =========================================================================== -->
    <!-- =================================================================================================================================================================================== -->
</xsl:stylesheet>
