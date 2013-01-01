<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
                version="1.0">

  <!-- 
    This is an example of using a custom stylesheet to handle XML-to-JSON
    conversions that can't be handled by the DTD annotations.
    
    In this case, we're doing a pretty elaborate transformation of the
    TranslationStack element.  The stack is a sequence of TermSet objects and 
    binary operators, in reverse-polish notation (see sample3.xml).  
    These templates convert that into a nested tree structure,
    using recursion within XSLT.
  -->
  <xsl:template match='TranslationStack'>
    <xsl:call-template name='term-tree'>
      <xsl:with-param name='elems' select='*'/>
      <xsl:with-param name='k' select='"translationstack"'/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- 
    term-tree is the entry point for the recursion.  It prints out one node of
    the tree.  When the $elems is a single TermSet, it prints it as a JSON object.
    When it is a list, with an operator at the end, it prints it as an array of
    three elements, e.g.,   [ "AND", { ... }, { ... } ]
  -->
  <xsl:template name='term-tree'>
    <xsl:param name='elems'/>
    <!-- This is only used on the top-level -->
    <xsl:param name='k'/>
    
    <xsl:variable name='numelems' select='count($elems)'/>
    <xsl:variable name='lastelem' select='$elems[last()]'/>
    
    <xsl:choose>
      <!-- If there's only one element, it better be a TermSet.  Render this
        as an object inside an array.  -->
      <xsl:when test='$numelems = 1'>
        <xsl:for-each select='$elems[1]'>
          <xsl:call-template name='o-in-a'/>
        </xsl:for-each>
      </xsl:when>
      
      <!-- We ignore the "GROUP" operator - not sure what it is for. -->
      <xsl:when test='$lastelem[self::OP] and string($lastelem) = "GROUP"'>
        <xsl:call-template name='term-tree'>
          <xsl:with-param name='elems' select='$elems[position() &lt; last()]'/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- If the last thing on the stack is a binary operator, then put out
        an array. -->
      <xsl:when test='$lastelem[self::OP]'>
        <a>
          <!-- If this is the top-level array, it will be inside an object wrapper,
            and so will have a name. -->
          <xsl:if test='$k != ""'>
            <xsl:attribute name='k'>
              <xsl:value-of select='$k'/>
            </xsl:attribute>
          </xsl:if>
          
          <s>
            <xsl:value-of select='$lastelem'/>
          </s>
          
          <!-- Count how many elements compose the second of my operands -->
          <xsl:variable name='num-top-elems'>
            <xsl:call-template name='count-top-elems'>
              <xsl:with-param name='elems' 
                select='$elems[position() &lt; last()]'/>
            </xsl:call-template>
          </xsl:variable>
          
          <!-- Recurse for the first operand.  -->
          <xsl:call-template name='term-tree'>
            <xsl:with-param name='elems'
              select='$elems[position() &lt; $numelems - $num-top-elems]'/>
          </xsl:call-template>
          
          <!-- Recurse for the second operand. -->
          <xsl:call-template name='term-tree'>
            <xsl:with-param name='elems'
              select='$elems[position() >= $numelems - $num-top-elems and position() &lt; last()]'/>
          </xsl:call-template>
        </a>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- This template just counts the number of XML elements that make up the
    branch of the term tree at the top of the stack (counting backwards
    from the end). -->
  <xsl:template name='count-top-elems'>
    <xsl:param name='elems'/>
    <xsl:choose>
      <!-- If the thing on top is a TermSet, then the answer is 1. -->
      <xsl:when test='$elems[last()][self::TermSet]'>1</xsl:when>
      
      <!-- If the top is the "GROUP" OP, then pop it off and recurse.
        Basically, the "GROUP" operator is ignored.  -->
      <xsl:when test='$elems[last()][self::OP][.="GROUP"]'>
        <xsl:variable name='num-top-elems'>
          <xsl:call-template name='count-top-elems'>
            <xsl:with-param name='elems'
              select='$elems[position() &lt; last()]'/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select='1 + $num-top-elems'/>
      </xsl:when>
      
      <!-- Otherwise the top is a binary OP, such as "OR", "AND", or
        "RANGE".  -->
      <xsl:otherwise>
        <xsl:variable name='num-top-elems'>
          <xsl:call-template name='count-top-elems'>
            <xsl:with-param name='elems'
              select='$elems[position() &lt; last()]'/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name='num-next-elems'>
          <xsl:call-template name='count-top-elems'>
            <xsl:with-param name='elems'
              select='$elems[position() &lt; last() - $num-top-elems]'/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select='1 + $num-top-elems + $num-next-elems'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>