<html><body>
  <h1>Attributes with inconsistent definitions</h1>
{
  let $docbase := 'http://jats.nlm.nih.gov/articleauthoring/tag-library/1.0/?attr='
  for $attr in /declarations/attributes/attribute
      let $name := $attr/@name
      let $declarations := $attr/attributeDeclaration
      let $decl1 := $declarations[1]
      let $numMismatches := 
          count(
              for $declx in $declarations
                  return 
                      if ($decl1/@type != $declx/@type or
                          $decl1/@mode != $declx/@mode) 
                      then (1)
                      else ()
          )
      order by $name
      return 
          if ($numMismatches != 0)
          then 
            <span>
              <a href='{concat($docbase, $name)}'>{string($name)}</a>
              has {$numMismatches} mismatches.<br/>
            </span>
          else ()
}
</body></html>
  