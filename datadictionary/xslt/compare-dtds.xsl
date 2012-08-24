<?xml version="1.0"?>
<!-- ============================================================================== -->
<!-- COMPARE DTDS
     
     Generates HTML report comparing one DTD to another. Input is the XML
     represetation of the "DTD1". XML representation must conform to the
     dtd-information.dtd used by the DataDictionary application. 
     
     Pass in the full "file://" to the second DTD XML file. -->
<!-- ============================================================================== -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   <xsl:output method="html" indent="yes"/>
   
   <!-- ============================================================================== -->
   <!-- PARAMETERS  -->
   <!-- ============================================================================== -->
   <xsl:param name="dtd2-loc" select="'file://urn:UNKNOWN'"/> <!-- Location of second instance to compare -->
   <xsl:param name="dtd1-name" select="'DTD 1'"/> <!-- Name of first DTD -->
   <xsl:param name="dtd2-name" select="'DTD 2'"/> <!-- Name of second DTD -->
   
   <!-- ============================================================================== -->
   <!-- GLOBAL VARIABLES  -->
   <!-- ============================================================================== -->
   
   <!-- Cache the root of input XML so we can refer to it again even after applying
        templates to dtd2 -->
   <xsl:variable name="dtd1" select="/"/>
   <xsl:variable name="dtd2" select="document($dtd2-loc)"/>
        
   <!-- ============================================================================== -->
   <!-- Start building HTML here   -->
   <!-- ============================================================================== -->
   <xsl:template match="/">
      <html>
         <head>
            <title>
               <xsl:text>Comparison of </xsl:text>
               <xsl:value-of select="$dtd1-name"/>
               <xsl:text> to </xsl:text>
               <xsl:value-of select="$dtd2-name"/>            
            </title>
         </head>
         <body>
            <table width="100%" border="1">
               <tr bgcolor="lightblue">
                  <th>
                     <xsl:value-of select="$dtd1-name"/>
                  </th>
                  <th>
                     <xsl:value-of select="$dtd2-name"/>
                  </th>                  
               </tr>
               
               <tr bgcolor="#FAEBD7">
                  <th colspan="2">
                     <b>Differences in common elements</b>
                  </th>
               </tr>
               
               <xsl:apply-templates select="/declarations/elements/element" mode="common-check">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
               
               <tr bgcolor="#FAEBD7">
                  <th colspan="2">
                     <b>
                        <xsl:text>Elements present in </xsl:text>
                        <xsl:value-of select="$dtd1-name"/>
                        <xsl:text> but not in </xsl:text>
                        <xsl:value-of select="$dtd2-name"/>
                     </b>
                  </th>
               </tr>

               <xsl:apply-templates select="/declarations/elements/element" mode="dtd1-only">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>

               <tr bgcolor="#FAEBD7">
                  <th colspan="2">
                     <b>
                        <xsl:text>Elements present in </xsl:text>
                        <xsl:value-of select="$dtd2-name"/>
                        <xsl:text> but not in </xsl:text>
                        <xsl:value-of select="$dtd1-name"/>
                     </b>
                  </th>
               </tr>

               <xsl:apply-templates select="$dtd2/declarations/elements/element" mode="dtd2-only">
                  <xsl:sort select="@name"/>
               </xsl:apply-templates>
               
            </table>
         </body>
      </html>
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- @model
        
        Clean up the text so add whitespace after ',' and '|': so can flow the text-->
   <!-- ============================================================================== -->
   <xsl:template match="@model">
      <xsl:call-template name="insert-whitespace">
         <xsl:with-param name="text" select="."/>
      </xsl:call-template>
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- element
        mode: common-check
        
        See whether this element is present in DTD2 and, if it is, whether there
        are any differences. If there are differences, list them. -->
   <!-- ============================================================================== -->
   <xsl:template match="element" mode="common-check">
      <xsl:variable name="current-name" select="@name"/>
      <xsl:variable name="dtd2-element" select="$dtd2/declarations/elements/element[@name = $current-name]"/>
      <xsl:variable name="dtd1-attributes" select="/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]"/>
      <xsl:variable name="dtd2-attributes" select="$dtd2/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]"/>
      
      <xsl:variable name="are-models-same">
         <xsl:call-template name="same-model">
            <xsl:with-param name="dtd1-model" select="@model"/>
            <xsl:with-param name="dtd2-model" select="$dtd2-element/@model"/>
         </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="are-atts-same">
         <xsl:call-template name="same-attributes">
            <xsl:with-param name="dtd1-atts" select="$dtd1-attributes"/>
            <xsl:with-param name="dtd2-atts" select="$dtd2-attributes"/>
         </xsl:call-template>
      </xsl:variable>
            
      <xsl:if test="$dtd2-element">
         <!-- If differences in either attributes or model, we need to make a listing -->
         <xsl:if test="$are-models-same = 'false' or $are-atts-same = 'false'">
            <tr bgcolor="silver">
               <td colspan="2">
                  <xsl:apply-templates select="@name"/>
               </td>
            </tr>
            
            <xsl:if test="$are-models-same = 'false'">
               <tr>
                  <td colspan="2">
                     <b>Model differences:</b>
                  </td>
               </tr>
               <tr>
                  <td>
                     <xsl:apply-templates select="@model"/>
                  </td>
                  <td>
                     <xsl:apply-templates select="$dtd2-element/@model"/>
                  </td>
               </tr>
            </xsl:if>
            
            <xsl:if test="$are-atts-same = 'false'">
               <tr>
                  <td colspan="2">
                     <b>Attribute differences:</b>
                  </td>
               </tr>
               
               <tr>
                  <td>
                     <xsl:choose>
                        <xsl:when test="$dtd1-attributes">
                           <ul>
                              <xsl:apply-templates select="$dtd1-attributes"/>
                           </ul>
                        </xsl:when>
                        
                        <xsl:otherwise>
                           <xsl:text>No attributes</xsl:text>
                        </xsl:otherwise>
                     </xsl:choose>
                  </td>
                  <td>
                     <xsl:choose>
                        <xsl:when test="$dtd2-attributes">
                           <ul>
                              <xsl:apply-templates select="$dtd2-attributes"/>
                           </ul>
                        </xsl:when>
                        
                        <xsl:otherwise>
                           <xsl:text>No attributes</xsl:text>
                        </xsl:otherwise>
                     </xsl:choose>
                  </td>
               </tr>
            </xsl:if>
         </xsl:if>            
      </xsl:if>
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- element
        mode: dtd1-only
        
        Display elements only present in DTD1 -->
   <!-- ============================================================================== -->
   <xsl:template match="element" mode="dtd1-only">
      <xsl:variable name="current-name" select="@name"/>
   
      <xsl:if test="not($dtd2/declarations/elements/element[@name = $current-name])">
         <tr>
            <td>
               <b>
                  <xsl:apply-templates select="@name"/>
               </b>
               <br/>
               <xsl:apply-templates select="@model"/>
               <br/>

               <xsl:if test="/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]">
                  <ul>
                     <xsl:apply-templates select="/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]"/>
                  </ul>
               </xsl:if>
            </td>
            <td>
               <xsl:text>Not present</xsl:text>
            </td>
         </tr>
      </xsl:if>
   
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- element
        mode: dtd2-only
        
        Display elements only present in DTD2 -->
   <!-- ============================================================================== -->
   <xsl:template match="element" mode="dtd2-only">
      <xsl:variable name="current-name" select="@name"/>
   
      <xsl:if test="not($dtd1/declarations/elements/element[@name = $current-name])">
         <tr>
            <td>
               <xsl:text>Not present</xsl:text>
            </td>
            
            <td>
               <b>
                  <xsl:apply-templates select="@name"/>
               </b>
               <br/>
               <xsl:apply-templates select="@model"/>
               <br/>

               <xsl:if test="$dtd2/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]">
                  <ul>
                     <xsl:apply-templates select="$dtd2/declarations/attributes/attribute/attributeDeclaration[@element = $current-name]"/>
                  </ul>
               </xsl:if>
            </td>
         </tr>
      </xsl:if>
   
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- element/@name
        
        Basic display of the name -->
   <!-- ============================================================================== -->
   <xsl:template match="element/@name">
      <b>
         <xsl:text>Element: </xsl:text>
         <xsl:text>&lt;</xsl:text>
         <xsl:value-of select="."/>
         <xsl:text>&gt;</xsl:text>
      </b>
   </xsl:template>

   <!-- ============================================================================== -->
   <!-- attributeDeclaration  
   
        Basic display of attributeDeclaration: will always be part of a list -->
   <!-- ============================================================================== -->
   <xsl:template match="attributeDeclaration">
      <li>
         <xsl:value-of select="parent::attribute/@name"/>
         <xsl:text> Type: </xsl:text>
         
         <xsl:call-template name="insert-whitespace">
            <xsl:with-param name="text" select="@type"/>
         </xsl:call-template>
         
         <xsl:if test="@mode">
            <xsl:text> Mode: </xsl:text>

            <xsl:call-template name="insert-whitespace">
               <xsl:with-param name="text" select="@mode"/>
            </xsl:call-template>

         </xsl:if>
      </li>  
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- same-model 
        
        Returns 'true' if models are the same; 'false' otherwise -->
   <!-- ============================================================================== -->
   <xsl:template name="same-model">
      <xsl:param name="dtd1-model" select="''"/>
      <xsl:param name="dtd2-model" select="''"/>
      
      <xsl:choose>
         <xsl:when test="normalize-space($dtd1-model) = normalize-space($dtd2-model)">
            <xsl:text>true</xsl:text>
         </xsl:when>
         
         <xsl:otherwise>
            <xsl:text>false</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- same-attributes
   
        Returns 'true' if the attributes are the same, 'false' otherwise
        
        Pass in nodelist of attributeDeclarations for each DTD. As soon as we find
        a difference between the lists, return 'false'. If we get to the
        end, then return true. -->
   <!-- ============================================================================== -->
   <xsl:template name="same-attributes">
      <xsl:param name="dtd1-atts"/>
      <xsl:param name="dtd2-atts"/>
      <xsl:param name="recursing" select="0"/>
      
      <xsl:choose>
         <!-- Initialization: check if the atts match up-->
         <xsl:when test="not($recursing)">
            <xsl:choose>
               <!-- None in either: can say are the same -->
               <xsl:when test="not($dtd1-atts) and not($dtd2-atts)">
                  <xsl:text>true</xsl:text>
               </xsl:when>
               
               <!-- Different counts: definitely different -->
               <xsl:when test="count($dtd1-atts) != count($dtd2-atts)">
                  <xsl:text>false</xsl:text>
               </xsl:when>
               
               <!-- Darn, we need to step through and look for differences -->
               <xsl:otherwise>
                  <xsl:call-template name="same-attributes">
                     <xsl:with-param name="dtd1-atts" select="$dtd1-atts"/>
                     <xsl:with-param name="dtd2-atts" select="$dtd2-atts"/>
                     <xsl:with-param name="recursing" select="1"/>
                  </xsl:call-template>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         
         <!-- Compare dtd1 attributes to dtd2 attributes -->
         <xsl:otherwise>
                     
            <xsl:choose>
               <!-- Out of nodes in DTD1 and DTD2: must have all matched -->
               <xsl:when test="not($dtd1-atts) and not($dtd2-atts)">
                  <xsl:text>true</xsl:text>
               </xsl:when>
               
               <!-- Number of nodes doesn't match: must not be the same -->
               <xsl:when test="count($dtd1-atts) != count($dtd2-atts)">
                  <xsl:text>false</xsl:text>
               </xsl:when>
            
               <!-- DTD1 attribute not present in DTD2-->
               <xsl:when test="not($dtd2-atts[parent::attribute/@name = $dtd1-atts[1]/parent::attribute/@name])">
                  <xsl:text>false</xsl:text>                  
               </xsl:when>
               
               <!-- Attribute in DTD1 must be present in DTD2, so let's compare them -->
               <xsl:otherwise>
                  <xsl:variable name="att1" select="$dtd1-atts[1]"/>
                  <xsl:variable name="att2" select="$dtd2-atts[parent::attribute/@name = $att1/parent::attribute/@name]"/>
                  
                  <xsl:choose>
                     <!-- Same type: that's promising -->
                     <xsl:when test="normalize-space($att1/@type) = normalize-space($att2/@type)">
                        <!-- Need to compare modes, but remember it may not be present -->
                        <xsl:choose>
                           <!-- att1 has mode but not att2: different!-->
                           <xsl:when test="$att1/@mode and not($att2/@mode)">
                              <xsl:text>false</xsl:text>
                           </xsl:when>
                           
                           <!-- att2 has mode but not att1: different!-->
                           <xsl:when test="$att2/@mode and not($att1/@mode)">
                              <xsl:text>false</xsl:text>
                           </xsl:when>
                           
                           <!-- Both have modes: need to check -->
                           <xsl:otherwise>
                              <xsl:choose>
                                 <!-- Modes are different! -->
                                 <xsl:when test="normalize-space($att1/@mode) != normalize-space($att2/@mode)">
                                    <xsl:text>false</xsl:text>
                                 </xsl:when>
                                 
                                 <!-- Nuts: everything is the same, we need to keep looking.
                                      This is tricky, drop the attributes from the nodelists -->
                                 <xsl:otherwise>
                                    <xsl:call-template name="same-attributes">
                                       <xsl:with-param name="recursing" select="1"/>
                                       <xsl:with-param name="dtd1-atts" select="$dtd1-atts[position() != 1]"/>
                                       <!-- We exclude the two atts we just compared;
                                       just drop first item from dtd1, and drop the node that matches att2 from dtd2-->
                                       <xsl:with-param name="dtd2-atts" select="$dtd2-atts[generate-id() != generate-id($att2)]"/>
                                    </xsl:call-template>
                                 </xsl:otherwise>
                              </xsl:choose>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:when>
                     
                     <!-- different types:ha!-->
                     <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <!-- ============================================================================== -->
   <!-- insert-whitespace
   
        Put a space after commas and pipes -->
   <!-- ============================================================================== -->
   <xsl:template name="insert-whitespace">
      <xsl:param name="text" select="''"/>
      
      <xsl:choose>
         <xsl:when test="string-length($text) = 0">
            <!-- Done -->
         </xsl:when>
         
         <xsl:when test="starts-with($text, ',') or starts-with($text, '|')">
            <xsl:value-of select="substring($text, 1, 1)"/>
            <xsl:text> </xsl:text>
            <xsl:call-template name="insert-whitespace">
               <xsl:with-param name="text" select="substring($text, 2)"/>
            </xsl:call-template>
         </xsl:when>
         
         <xsl:otherwise>
            <xsl:value-of select="substring($text, 1, 1)"/>
            <xsl:call-template name="insert-whitespace">
               <xsl:with-param name="text" select="substring($text, 2)"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
</xsl:stylesheet>