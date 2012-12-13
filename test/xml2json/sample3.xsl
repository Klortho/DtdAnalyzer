<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:np="http://ncbi.gov/portal/XSLT/namespace"
                version="1.0">
  
  <xsl:import href="../../xslt/xml2json.xsl"/>

  <!-- 
    For the TranslationStack, just for fun, I took on the challenge of converting it
    into a JSON tree structure.  The stack is a sequence of TermSet objects and 
    binary operators, in reverse-polish notation.  It is tricky to convert this into
    a tree structure, using recursion within XSLT.
  -->
  <xsl:template match='TranslationStack'>
    <xsl:param name='indent' select='""'/>

    <xsl:value-of select='concat($indent, np:mkey("translationstack"), $nl)'/>
    <xsl:call-template name='term-tree'>
      <xsl:with-param name='indent' select='concat($indent, $iu)'/>
      <xsl:with-param name='elems' select='*'/>
      <xsl:with-param name='trailing-comma' select='position() != last()'/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- term-tree is the entry point for the recursion.  It prints out one node of
    the tree.  When the $elems is a single TermSet, it prints it as a JSON object.
    When it is a list, with an operator at the end, it prints it as an array of
    three elements, e.g.,   [ "AND", { ... }, { ... } ]
  -->
  <xsl:template name='term-tree'>
    <xsl:param name='indent' select='""'/>
    <xsl:param name='elems'/>
    <xsl:param name='trailing-comma' select='false()'/>
    
    <xsl:variable name='numelems' select='count($elems)'/>
    <xsl:variable name='lastelem' select='$elems[last()]'/>
    
    <xsl:choose>
      <!-- If there's only one element, it better be a TermSet.  Render this
        as an object inside an array.  -->
      <xsl:when test='$numelems = 1'>
        <xsl:for-each select='$elems[1]'>
          <xsl:call-template name='object-in-array'>
            <xsl:with-param name='indent' select='$indent'/>
            <xsl:with-param name='force-comma' select='$trailing-comma'/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      
      <!-- We ignore the "GROUP" operator - not sure what it is for. -->
      <xsl:when test='$lastelem[self::OP] and string($lastelem) = "GROUP"'>
        <xsl:call-template name='term-tree'>
          <xsl:with-param name='indent' select='$indent'/>
          <xsl:with-param name='elems' select='$elems[position() &lt; last()]'/>
          <xsl:with-param name='trailing-comma' select='$trailing-comma'/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- If the last thing on the stack is a binary operator, then put out
        an array. -->
      <xsl:when test='$lastelem[self::OP]'>
        <xsl:value-of select='np:start-array($indent)'/>
        <xsl:value-of 
          select='np:simple(concat($indent, $iu), np:dq($lastelem), true())'/>
        
        <!-- Count how many elements compose the second of my operands -->
        <xsl:variable name='num-top-elems'>
          <xsl:call-template name='count-top-elems'>
            <xsl:with-param name='elems' 
              select='$elems[position() &lt; last()]'/>
          </xsl:call-template>
        </xsl:variable>
        
        <!-- Recurse for the first operand.  -->
        <xsl:call-template name='term-tree'>
          <xsl:with-param name='indent' select='concat($indent, $iu)'/>
          <xsl:with-param name='elems'
            select='$elems[position() &lt; $numelems - $num-top-elems]'/>
          <xsl:with-param name='trailing-comma' select='true()'/>
        </xsl:call-template>
        
        <!-- Recurse for the second operand. -->
        <xsl:call-template name='term-tree'>
          <xsl:with-param name='indent' select='concat($indent, $iu)'/>
          <xsl:with-param name='elems'
            select='$elems[position() >= $numelems - $num-top-elems and position() &lt; last()]'/>
        </xsl:call-template>
        
        <xsl:value-of select='np:end-array($indent, $trailing-comma)'/>
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