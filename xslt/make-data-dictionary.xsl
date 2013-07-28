<?xml version="1.0" ?>
<!-- #######################################################################################-->
<!-- make-data-dictionary.xsl

     Creates a dictionary of all elements, attributes, parameter entities and general 
     entities declared in a DTD. XSL operates on an XML instance that conforms to 
     dtd-information.dtd.                                                                   -->
<!-- #######################################################################################-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:output method="html" indent="yes"/>
   
   <!-- ########################################################### -->
   <!--                    GLOBAL KEYS                              -->                    
   <!-- ########################################################### -->
   <xsl:key name="attributeDeclarations" match="attributeDeclaration" use="@element"/> <!-- Retrieve attribute declarations by element name -->
   <xsl:key name="elementDeclarations" match="element" use="@name"/> <!-- Retrieve element declarations by element name -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: /

        Starts process of building the data dictionary -->
   <!-- =========================================================== -->
   <xsl:template match="/">
      <html>
         <head>
            <title>Data Dictionary</title>
         </head>

         <body>
            <center>
               <!-- Title -->
               <h1>Data Dictionary</h1>
               
               <!-- Top anchor -->
               <a name="top"/>
               
               <!-- Section jump-to list -->
               <p>|
                  <a href="#datadictionary.index">Index</a> |
                  <a href="#datadictionary.definitions.elements">Element Definitions</a> |
                  <xsl:if test="declarations/attributes">
                     <a href="#datadictionary.definitions.attributes">Attribute Definitions</a> |
                  </xsl:if>
                  <xsl:if test="declarations/parameterEntities">
                     <a href="#datadictionary.definitions.parameterentities">Parameter Entity Definitions</a> |
                  </xsl:if>
                  <xsl:if test="declarations/generalEntities">
                     <a href="#datadictionary.definitions.generalentities">General Entity Definitions</a> |
                  </xsl:if>
               </p>
               
               <!-- Index -->
               <xsl:call-template name="make-index">
                  <xsl:with-param name="elements" select="declarations/elements"/>
                  <xsl:with-param name="attributes" select="declarations/attributes"/>
                  <xsl:with-param name="parameterEntities" select="declarations/parameterEntities"/>
                  <xsl:with-param name="generalEntities" select="declarations/generalEntities"/>
               </xsl:call-template>
            </center>
            
            <!-- Spacer-->
            <br/>
            
            <!-- Make element definitions -->
            <xsl:call-template name="make-element-definitions">
               <xsl:with-param name="elements" select="declarations/elements/element"/>
            </xsl:call-template>
            
            <!-- Make attribute definitions -->
            <xsl:call-template name="make-attribute-definitions">
               <xsl:with-param name="attributes" select="declarations/attributes/attribute"/>
            </xsl:call-template>
            
            <!-- Make parameter entity definitions -->
            <xsl:call-template name="make-parameter-entity-definitions">
               <xsl:with-param name="entities" select="declarations/parameterEntities/entity"/>
            </xsl:call-template>

            <!-- Make general entity definitions -->
            <xsl:call-template name="make-general-entity-definitions">
               <xsl:with-param name="entities" select="declarations/generalEntities/entity"/>
            </xsl:call-template>            
         </body>
      </html>
   </xsl:template>   
   
   <!-- ########################################################### -->
   <!--                    INDEX TEMPLATES   
   
        These templates build the index -->                    
   <!-- ########################################################### -->
         
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-index

        Starts process to create the boxed index at top of data 
        dictionary page -->
   <!-- =========================================================== -->
   <xsl:template name="make-index">
      <xsl:param name="elements"/>
      <xsl:param name="attributes"/>
      <xsl:param name="parameterEntities"/>
      <xsl:param name="generalEntities"/>
      
      <a name="datadictionary.index"/>
      <table width="50%" frame="box" rules="rows" bgcolor="silver" cellpadding="10">
         <tr bgcolor="lightblue"><th colspan="2">Index of Items</th></tr>
         
         <!-- Jump to list in index -->
         <tr bgcolor="lightblue">
            <td colspan="2" align="center">| 
               <a href="#datadictionary.index.elements">Element Index</a> |
               <xsl:if test="/declarations/attributes">
                  <a href="#datadictionary.index.attributes">Attribute Index</a> |
               </xsl:if>
               <xsl:if test="/declarations/parameterEntities">
                  <a href="#datadictionary.index.parameterentities">Parameter Entity Index</a> |
               </xsl:if>
               <xsl:if test="/declarations/generalEntities">
                  <a href="#datadictionary.index.generalentities">General Entity Index</a> |
               </xsl:if>
            </td>
         </tr>
         
         <!-- Output all the elements -->
         <xsl:apply-templates select="$elements" mode="index"/>

         <!-- Output all the attributes -->
         <xsl:apply-templates select="$attributes" mode="index"/>

         <!-- Output all the parameter entities -->
         <xsl:apply-templates select="$parameterEntities" mode="index"/>
         
         <!-- Output all the general entities -->
         <xsl:apply-templates select="$generalEntities" mode="index"/>
      </table>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: elements
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="elements" mode="index">
      <tr align="left">
         <td>
            <a name="datadictionary.index.elements"/>
            <b>&lt;Elements&gt;</b>
            <ul>
               <xsl:apply-templates mode="index">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
            </ul>
         </td>
         <td align="right" valign="top">
            <a href="#top">[Top]</a>
         </td>
      </tr>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: element
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="element" mode="index">
      <li>
         <a href="#{@name}">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>&gt;</xsl:text>
         </a>
      </li>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: attributes
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="attributes" mode="index">
      <tr align="left">
         <td>
            <a name="datadictionary.index.attributes"/>
            <b>@Attributes</b>
            <ul>
               <xsl:apply-templates mode="index">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
            </ul>
         </td>
         <td align="right" valign="top">
            <a href="#top">[Top]</a>
         </td>
      </tr>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: attribute
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="attribute" mode="index">
      <li>
         <a href="#@{@name}">
            <xsl:text>@</xsl:text>
            <xsl:value-of select="@name"/>
         </a>
      </li>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: parameterEntities
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="parameterEntities" mode="index">
      <tr align="left">
         <td>
            <a name="datadictionary.index.parameterentities"/>
            <b>%Parameter_Entities;</b>
            <ul>
               <xsl:apply-templates mode="index">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
            </ul>
         </td>
         <td align="right" valign="top">
            <a href="#top">[Top]</a>
         </td>
      </tr>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: entity
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="entity" mode="index">
   
      <!-- Prefix to prepend to anchor name: will either
           be pe for parameter entity or ge for general entity -->
      <xsl:variable name="prefix">
         <xsl:choose>
            <xsl:when test="parent::parameterEntities">
               <xsl:text>pe_</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>ge_</xsl:text>
            </xsl:otherwise>
         </xsl:choose>      
      </xsl:variable>
      
      <!-- Symbol to prepend to name: will either
           be % for parameter entity or & for general entity -->
      <xsl:variable name="symbol">
         <xsl:choose>
            <xsl:when test="parent::parameterEntities">
               <xsl:text>%</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>&amp;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>      
      </xsl:variable>
   
      <li>
         <a href="#{concat($prefix, @name)}">
            <xsl:value-of select="$symbol"/>
            <xsl:value-of select="@name"/>
            <xsl:text>;</xsl:text>
         </a>
      </li>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: generalEntities
        MODE: index -->
   <!-- =========================================================== -->
   <xsl:template match="generalEntities" mode="index">
      <tr align="left">
         <td>
            <a name="datadictionary.index.generalentities"/>
            <b>&amp;General_Entities;</b>
            <ul>
               <xsl:apply-templates mode="index">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
            </ul>
         </td>
         <td align="right" valign="top">
            <a href="#top">[Top]</a>
         </td>
      </tr>
   </xsl:template>

   <!-- ########################################################### -->
   <!--                    ELEMENT DEFINITIONS   
   
        These templates build the element definitions -->                    
   <!-- ########################################################### -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-element-definitions
        
        Starts process of outputting the element definitions -->
   <!-- =========================================================== -->
   <xsl:template name="make-element-definitions">
      <xsl:param name="elements"/>
      
      <!-- Make the divider -->
      <a name="datadictionary.definitions.elements"/>
      <xsl:call-template name="make-divider">
         <xsl:with-param name="name" select="'ELEMENT DEFINITIONS'"/>
      </xsl:call-template>
      
      <!-- Output all the definitions -->
      <xsl:apply-templates mode="definition" select="$elements">
         <xsl:sort select="@name"/>  
      </xsl:apply-templates>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: element
        MODE: definition
        
        Outputs an element definition -->
   <!-- =========================================================== -->
   <xsl:template match="element" mode="definition">
   
      <!-- DTD file containing the element declaration -->
      <xsl:variable name="dtd">
         <xsl:call-template name="get-base-filename">
            <xsl:with-param name="systemId" select="declaredIn/@systemId"/>
         </xsl:call-template>
      </xsl:variable>
      
      <!-- Line number of declaration -->
      <xsl:variable name="linenumber" select="declaredIn/@lineNumber"/>
         
      <div style="border-style: solid; padding: 5; margin-bottom: 5; margin-top: 5">
         <a name="{@name}"/>
         
         <p style="margin-top: 0; margin-bottom: 0">
            <b>
               Element: &lt;<xsl:value-of select="@name"/>&gt;
            </b>
         </p>
         <p style="margin-top: 0">
            <i>
               declared in: <xsl:value-of select="$dtd"/>, line <xsl:value-of select="$linenumber"/> 
            </i>
         </p>
         
         <!-- Output attributes if any belong to this element -->
         <xsl:if test="key('attributeDeclarations', @name)">
            <p style="border-top: thin solid; margin-bottom: 0">
               <b>attributes:</b>
            </p>
            
            <ul style="margin-top: 0">
               <xsl:apply-templates select="key('attributeDeclarations', @name)" mode="definition">
                  <xsl:sort select="parent::attribute/@name"/>
               </xsl:apply-templates>
            </ul>
         </xsl:if>
                
         <!-- Display content model and make links to all elements -->
         <p style="border-top: thin solid; margin-bottom: 0">
            <b>content model:</b>
         </p>
         <p style="margin-top: 0">
            <xsl:call-template name="make-model-links">
               <xsl:with-param name="str" select="content-model/@minified"/>
            </xsl:call-template>
         </p>

         <!-- context information -->
         <p style="border-top: thin solid; margin-bottom: 0">
            <b>&lt;<xsl:value-of select="@name"/>&gt;
            <xsl:choose>
               <xsl:when test="context">
                  <xsl:text> appears in:</xsl:text>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:text> does not appear in any elements</xsl:text>
               </xsl:otherwise>
            </xsl:choose>
            </b>
         </p>
         
         <xsl:apply-templates select="context" mode="definition"/>
         
         <xsl:call-template name="make-jump-to-top"/>
      </div>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: attributeDeclaration
        MODE: definition -->
   <!-- =========================================================== -->
   <xsl:template match="attributeDeclaration" mode="definition">
      <xsl:variable name="dtd">
         <xsl:call-template name="get-base-filename">
            <xsl:with-param name="systemId" select="declaredIn/@systemId"/>
         </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="linenumber" select="declaredIn/@lineNumber"/>
      
      <li>
         <!-- attribute name -->
         <b><xsl:value-of select="parent::attribute/@name"/></b>
         <xsl:text> </xsl:text>
         
         <!-- content model for attribute -->
         <xsl:call-template name="replace-pipes-commas">
            <xsl:with-param name="str" select="@type"/>
         </xsl:call-template>
         
         <!-- mode (#IMPLIED, etc.) -->
         <xsl:text> </xsl:text>
         <xsl:value-of select="@mode"/>
         
         <!-- default -->
         <xsl:if test="@defaultValue">
            <xsl:text> Default value: </xsl:text>
            <xsl:value-of select="@defaultValue"/>
         </xsl:if>
         
         <!-- location -->
         <xsl:text> </xsl:text>
         <i>
            (declared in <xsl:value-of select="$dtd"/>, line <xsl:value-of select="$linenumber"/>)
         </i>
      </li>
      
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: context
        MODE: definition -->
   <!-- =========================================================== -->
   <xsl:template match="context" mode="definition">
      <ul style="margin-top: 0">
         <xsl:apply-templates mode="definition">
            <xsl:sort select="@name"/>
         </xsl:apply-templates>
      </ul>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: parent
        MODE: definition -->
   <!-- =========================================================== -->
   <xsl:template match="parent" mode="definition">
      <xsl:variable name="dtd">
         <xsl:call-template name="get-base-filename">
            <xsl:with-param name="systemId" select="key('elementDeclarations', @name)/declaredIn/@systemId"/>
         </xsl:call-template>      
      </xsl:variable>
      
      <xsl:variable name="linenumber" select="key('elementDeclarations', @name)/declaredIn/@lineNumber"/>
      
      <li>
         <a href="#{@name}">&lt;<xsl:value-of select="@name"/>&gt;</a> 
         <i>
            (declared in <xsl:value-of select="$dtd"/>, line <xsl:value-of select="$linenumber"/>)
         </i>
      </li>   
   </xsl:template>
      
   <!-- ########################################################### -->
   <!--                    ATTRIBUTE DEFINITIONS   
   
        These templates build the attribute definitions -->                    
   <!-- ########################################################### -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-attribute-definitions
        
        Starts process of outputting the attribute definitions -->
   <!-- =========================================================== -->
   <xsl:template name="make-attribute-definitions">
      <xsl:param name="attributes"/>
      
      <xsl:if test="$attributes">
         <a name="datadictionary.definitions.attributes"/>
         
         <xsl:call-template name="make-divider">
            <xsl:with-param name="name" select="'ATTRIBUTE DEFINITIONS'"/>
         </xsl:call-template>  
         
         <xsl:apply-templates select="$attributes" mode="definition">
            <xsl:sort select="@name"/>
         </xsl:apply-templates>
      </xsl:if>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: attribute
        MODE: definition -->
   <!-- =========================================================== -->
   <xsl:template match="attribute" mode="definition">
   
      <div style="border-style: solid; padding: 5; margin-bottom: 5; margin-top: 5">
         <a name="@{@name}"/>
         
         <p style="margin-top: 0">
            <b>Attribute: @<xsl:value-of select="@name"/></b>
         </p>
         
         <p style="border-top: thin solid; margin-bottom: 0">
            <b>Appears in the following elements:</b>
         </p>
         <ul style="margin-top: 0">
            <xsl:apply-templates mode="attribute-definition">
               <xsl:sort select="@element"/>
            </xsl:apply-templates>
         </ul>

         <xsl:call-template name="make-jump-to-top"/>
      </div>
      
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: attributeDeclaration
        MODE: attribute-definition -->
   <!-- =========================================================== -->
   <xsl:template match="attributeDeclaration" mode="attribute-definition">
      <xsl:variable name="dtd">
         <xsl:call-template name="get-base-filename">
            <xsl:with-param name="systemId" select="declaredIn/@systemId"/>
         </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="linenumber" select="declaredIn/@lineNumber"/>
   
      <li>
         <a href="#{@element}">&lt;<xsl:value-of select="@element"/>&gt;</a>
         <xsl:text> </xsl:text>
         <i>
            (attribute declared in <xsl:value-of select="$dtd"/>, line <xsl:value-of select="$linenumber"/>)
         </i>
      </li>      
   </xsl:template>

   <!-- ########################################################### -->
   <!--                    PARAMETER ENTITY DEFINITIONS   
   
        These templates build the parameter entity  definitions -->                    
   <!-- ########################################################### -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-parameter-entity-definitions
        
        Starts process of outputting the param entity definitions -->
   <!-- =========================================================== -->
   <xsl:template name="make-parameter-entity-definitions">
      <xsl:param name="entities"/>
      
      <xsl:if test="$entities">
         <a name="datadictionary.definitions.parameterentities"/>      
         <xsl:call-template name="make-divider">
            <xsl:with-param name="name" select="'PARAMETER ENTITY DEFINITIONS'"/>
         </xsl:call-template>  
         
         <xsl:apply-templates select="$entities" mode="definition">
            <xsl:sort select="@name"/>
         </xsl:apply-templates>
      </xsl:if>
   </xsl:template>
   
   <!-- ########################################################### -->
   <!--                    GENERAL ENTITY DEFINITIONS   
   
        These templates build the general entity  definitions -->                    
   <!-- ########################################################### -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-general-entity-definitions
        
        Starts process of outputting the param entity definitions -->
   <!-- =========================================================== -->
   <xsl:template name="make-general-entity-definitions">
      <xsl:param name="entities"/>
      
      <xsl:if test="$entities">
         <a name="datadictionary.definitions.generalentities"/>
         <xsl:call-template name="make-divider">
            <xsl:with-param name="name" select="'GENERAL ENTITY DEFINITIONS'"/>
         </xsl:call-template>  
         
         <xsl:apply-templates select="$entities" mode="definition">
            <xsl:sort select="@name"/>
         </xsl:apply-templates>
      </xsl:if>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: entity
        MODE: definition -->
   <!-- =========================================================== -->
   <xsl:template match="entity" mode="definition">
   
      <!-- Prefix to prepend to anchor name: will either
           be pe for parameter entity or ge for general entity -->
      <xsl:variable name="prefix">
         <xsl:choose>
            <xsl:when test="parent::parameterEntities">
               <xsl:text>pe_</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>ge_</xsl:text>
            </xsl:otherwise>
         </xsl:choose>      
      </xsl:variable>
      
      <!-- Symbol to prepend to name: will either
           be % for parameter entity or & for general entity -->
      <xsl:variable name="symbol">
         <xsl:choose>
            <xsl:when test="parent::parameterEntities">
               <xsl:text>%</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>&amp;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>      
      </xsl:variable>
      
      <!-- Key word to use in the title -->
      <xsl:variable name="keyword">
         <xsl:choose>
            <xsl:when test="parent::parameterEntities">
               <xsl:text>Parameter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>General</xsl:text>
            </xsl:otherwise>
         </xsl:choose>      
      </xsl:variable>
      
      <xsl:variable name="dtd">
         <xsl:call-template name="get-base-filename">
            <xsl:with-param name="systemId" select="declaredIn/@systemId"/>
         </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="linenumber" select="declaredIn/@lineNumber"/>
      
      <!-- True when "value" has a line breaks; false otherwise -->
      <xsl:variable name="has-line-breaks">
         <xsl:choose>
            <xsl:when test="contains(value, '&#10;') or contains(value, '&#13;')">
               <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>false</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      <div style="border-style: solid; padding: 5; margin-bottom: 5; margin-top: 5">
         <a>
            <xsl:attribute name="name">
               <xsl:value-of select="concat($prefix, @name)"/>
            </xsl:attribute>
         </a>
         
         <p style="margin-top: 0; margin-bottom: 0">
            <b><xsl:value-of select="$keyword"/> Entity: <xsl:value-of select="$symbol"/><xsl:value-of select="@name"/>;</b>
         </p>
         <p style="margin-top: 0">
            <i>declared in: <xsl:value-of select="$dtd"/>, line <xsl:value-of select="$linenumber"/></i>
         </p>
         
         <xsl:if test="@systemId or @publicId">
            <p style="border-top: thin solid; margin-bottom: 0">
               <b>identifiers:</b>
            </p>

            <ul style="margin-top: 0">
               <xsl:if test="@systemId">
                  <li>System ID: <xsl:value-of select="@systemId"/></li>
               </xsl:if>
              
               <xsl:if test="@publicId">
                  <li>Public ID: <xsl:value-of select="@publicId"/></li>
               </xsl:if>
            </ul>
         </xsl:if>
         
         <!-- Value is optional, so if not present, we don't output anything. -->
         <xsl:if test="value">
            <p style="border-top: thin solid; margin-bottom: 0">
               <b>value:</b>
               
               <!-- No line breaks, so can output on same line as the intro -->
               <xsl:if test="$has-line-breaks = 'false'">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="value"/>
               </xsl:if>
            </p>
            
            <!-- Line breaks, so output here, below the para, inside pre tags -->
            <xsl:if test="$has-line-breaks = 'true'">
               <pre><xsl:apply-templates select="value"/></pre>
            </xsl:if>
         </xsl:if>
         
         <xsl:call-template name="make-jump-to-top"/>
      </div>

   </xsl:template>
      
   <!-- ########################################################### -->
   <!--                    HELPER TEMPLATES  
   
        These templates are used throughout the stylehsheet -->                    
   <!-- ########################################################### -->
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: get-base-filename
        
        Retrieves the portion of the system id that follows the last
        "/": this should be the base filename -->
   <!-- =========================================================== -->
   <xsl:template name="get-base-filename">
      <xsl:param name="systemId" select="''"/>
      
      <xsl:choose>
         <!-- No more slashes, so return whatever is left -->
         <xsl:when test="not(contains($systemId, '/'))">
            <xsl:value-of select="$systemId"/>
         </xsl:when>
         
         <!-- Still have slashes, so keep going -->
         <xsl:otherwise>
            <xsl:call-template name="get-base-filename">
               <xsl:with-param name="systemId" select="substring-after($systemId, '/')"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: make-divider
        
        Makes divider that appears between definition sections -->
   <!-- =========================================================== -->
   <xsl:template name="make-divider">
      <xsl:param name="name"/>
      
      <table width="100%" bgcolor="lightblue">
         <tr>
            <td align="left" valign="center">
               <b>
                  <xsl:value-of select="$name"/>
               </b>
            </td>
            <td align="right" valign="center">
               <a href="#top">[Top]</a>
            </td>
         </tr>
      </table>      
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: make-jump-to-top
        
        Makes link to jump to top of dictionary -->
   <!-- =========================================================== -->
   <xsl:template name="make-jump-to-top">
      <p style="margin-top: 0; margin-bottom: 0; text-align: right">
         <a href="#top">[Top]</a>
      </p>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: make-model-links -->
   <!-- =========================================================== -->
   <xsl:template name="make-model-links">
      <xsl:param name="str"/>
      
      <xsl:choose>
         <!-- Base case: no more characters -->
         <xsl:when test="not($str)"/>
         
         <!-- Starts with a reserved string -->         
         <xsl:when test="normalize-space($str)='EMPTY'">
            <xsl:text>EMPTY</xsl:text>
         </xsl:when>

         <!-- Starts with a reserved string -->         
         <xsl:when test="normalize-space($str) = 'ANY'">
            <xsl:text>ANY</xsl:text>
         </xsl:when>
         
         <xsl:when test="starts-with($str, '#PCDATA')">
            <xsl:text>#PCDATA</xsl:text>
            <xsl:call-template name="make-model-links">
               <xsl:with-param name="str" select="substring-after($str, '#PCDATA')"/>
            </xsl:call-template>
         </xsl:when>
                  
         <xsl:when test="starts-with($str, '(')
                         or starts-with($str, ')')
                         or starts-with($str, '+')
                         or starts-with($str, '|')
                         or starts-with($str, '?')
                         or starts-with($str, '*')
                         or starts-with($str, ',')">
            <xsl:call-template name="replace-pipes-commas">
               <xsl:with-param name="str" select="substring($str, 1, 1)"/>
            </xsl:call-template>
            <xsl:call-template name="make-model-links">
               <xsl:with-param name="str" select="substring($str, 2)"/>
            </xsl:call-template>
         </xsl:when>
         
         <!-- Must be the start of an element name - must retrieve it -->
         <xsl:otherwise>
            <xsl:variable name="element-name">
               <xsl:call-template name="find-element-name">
                  <xsl:with-param name="str" select="$str"/>
               </xsl:call-template>
            </xsl:variable>
       
            <xsl:call-template name="start-link">
               <xsl:with-param name="anchor" select="normalize-space($element-name)"/>
            </xsl:call-template>
       
            <xsl:value-of select="normalize-space($element-name)"/>
       
            <xsl:call-template name="end-link"/>
       
            <!-- Now continue recursing -->
            <xsl:call-template name="make-model-links">
               <xsl:with-param name="str" select="substring-after($str, normalize-space($element-name))"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: start-link -->
   <!-- =========================================================== -->
   <xsl:template name="start-link">
      <xsl:param name="anchor"/>
      
      <xsl:text disable-output-escaping="yes">&lt;a href="#</xsl:text>
      <xsl:value-of select="$anchor"/>
      <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: end-link -->
   <!-- =========================================================== -->
   <xsl:template name="end-link">
      <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
   </xsl:template>
   
   <!-- =========================================================== -->
   <!-- TEMPLATE: find-element-name -->
   <!-- =========================================================== -->
   <xsl:template name="find-element-name">
      <xsl:param name="str"/>
         
         <xsl:choose>
            <!-- Cover your ass base case (impossible) -->
            <xsl:when test="not($str)"/>
            
            <!-- Real base case: found a delimiter, so stop -->
            <xsl:when test="starts-with($str, ')')
                         or starts-with($str, ' ')
                         or starts-with($str, '+')
                         or starts-with($str, '|')
                         or starts-with($str, '?')
                         or starts-with($str, '*')
                         or starts-with($str, ',')"/>
               
            <!-- Otherwise, still in element name -->
            <xsl:otherwise>
               <xsl:value-of select="substring($str, 1, 1)"/>
               <xsl:call-template name="find-element-name">
                  <xsl:with-param name="str" select="substring($str, 2)"/>
               </xsl:call-template>
            </xsl:otherwise>
         </xsl:choose>
   </xsl:template>

   <!-- =========================================================== -->
   <!-- TEMPLATE: replace-pipes-commas
        
        Puts extra spaces around pipes and commas so that 
        content model and attribute content has whitespace for
        better display in a browser-->
   <!-- =========================================================== -->
   <xsl:template name="replace-pipes-commas">
      <xsl:param name="str"/>
      
      <xsl:choose>
         <xsl:when test="not($str)"/>
         
         <xsl:when test="starts-with($str, '|')">
            <xsl:text> | </xsl:text>
            <xsl:call-template name="replace-pipes-commas">
               <xsl:with-param name="str" select="substring($str, 2)"/>
            </xsl:call-template>
         </xsl:when>
         
         <xsl:when test="starts-with($str, ',')">
                <xsl:text>, </xsl:text>
                <xsl:call-template name="replace-pipes-commas">
                   <xsl:with-param name="str" select="substring($str, 2)"/>
                </xsl:call-template>
         </xsl:when>
         
         <xsl:otherwise>
            <xsl:value-of select="substring($str, 1, 1)"/>
            <xsl:call-template name="replace-pipes-commas">
               <xsl:with-param name="str" select="substring($str, 2)"/>
            </xsl:call-template>   
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
</xsl:stylesheet>