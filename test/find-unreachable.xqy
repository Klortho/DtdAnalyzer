(:
  This script finds all of the unreachable elements in a DTD.
  The set of root nodes is hard-coded below as $roots.  From there,
  this walks the tree formed by the <child> elements within each 
  <element> element's content model.  Each call to the reachable()
  function descends one layer down the tree.  When it stops finding
  new descendents that it can add to its list, the recursion halts.
:)

(:----------------------------------------------------------
  Each time this function is called, we descend one level down the
  tree.
:)

declare function 
local:reachable($allElems as element(element)*,
                $startSet as xs:string*,
                $lastFound as xs:string*)
   as xs:string* 
{
    (: First, if any of the last-found elements have a content model of 
      "any", then all elements are reachable.
    :)
    if ($allElems[@name=$lastFound and content-model/@spec="any"])
    then ($allElems/@name/string())
    else

        (: Descend another layer down the tree - find all the children 
          of the reachable elements that we found last time :)
        let $newKids := distinct-values(
            $allElems[@name=$lastFound]//child/string()
        )
        
        (: The new "last found set" is the set of all elements that we
          just found, that we've never seen before (are not in $startSet :)
        let $newLastFound := $newKids[not(.=$startSet)]
        
        (: Finally, the new start set is the old start plus all these
          elements that we've just found.  :)
        let $newStartSet := ($startSet, $newLastFound)
        
        (: If we didn't find any new elements this time, then we're done.
          Otherwise, recurse.  :)
        return 
            if (count($newLastFound) = 0)
            then $startSet
            else local:reachable($allElems, $newStartSet, $newLastFound)
};

(:----------------------------------------------------------
  The main query; initialize things, and then call the function.
  This assumes were working on JATS 1.0 Article Authoring.  If not,
  change $title and $docBase.
:)


let $title := "JATS 1.0 Article Authoring"
let $docBase := "http://jats.nlm.nih.gov/articleauthoring/tag-library/1.0/?elem="
let $roots := ('article')

let $allElems := //element
let $reachable := local:reachable($allElems, $roots, $roots)

let $allElemNames := $allElems/@name/string()
let $unreachable := (
  for $u in $allElemNames[not(.=$reachable)]
  order by $u
  return $u
)
return 
  <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <title>Unreachable elements in {$title}</title>
    </head>
    <body>
      <h1>List of elements in {$title} not reachable from elements { 
        string-join($roots, ", ") 
      }</h1>
      <ul>{
        for $u in $unreachable
        return <li><a href='{concat($docBase, $u)}'>{$u}</a></li>
      }</ul>
    </body>
  </html>
