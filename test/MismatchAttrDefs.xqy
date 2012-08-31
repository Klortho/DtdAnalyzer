<html><body>
  <h1>Attributes with inconsistent definitions</h1>
{
  let $docbase := 'http://jats.nlm.nih.gov/articleauthoring/tag-library/1.0/?attr='
  for $attr in /declarations/attributes/attribute
      let $name := $attr/@name
      let $declarations := $attr/attributeDeclaration
      let $declStrs := distinct-values(
          for $d in $declarations
          return concat("type = '", $d/@type, "'; mode = '", $d/@mode, "'")
      )
      let $numUniqueDecls := count($declStrs) 
      order by $name
      return 
          if ($numUniqueDecls != 1)
          then 
            <div>
              <a href='{concat($docbase, $name)}'>{string($name)}</a>
              has {$numUniqueDecls} unique declarations:
              <ul>{
                for $d in $declStrs
                return <li>{$d}</li>
              }</ul>
            </div>
          else ()
}
</body></html>
  