(:
  This script finds all of the unreachable elements in a DTD.
  The set of root nodes is hard-coded below as $roots.  From there,
  this walks the tree formed by the <child> elements within each 
  <element> element's content model.  Each call to the reachable()
  function descends one layer down the tree.  When it stops finding
  new descendents that it can add to its list, the recursion halts.
:)

declare function 
local:reachable($allElems as element(element)*,
                $startSet as xs:string*,
                $lastFound as xs:string*)
   as xs:string* 
{
    (: Find all the children of the new reachable elements that we
      found last time :)
    let $newKidNames := distinct-values(
        $allElems[@name=$lastFound]//child/string()
    )
    
    (: The new "last found set" is the set of all elements that we
      just found, that we've never seen before (are not in $startSet :)
    let $newLastFound := $newKidNames[not(.=$startSet)]
    
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

(:----------------------------------------------------------:)
let $allElems := //element
let $roots := ('article')

let $reachable := local:reachable($allElems, $roots, $roots)

let $allElemNames := $allElems/@name/string()
let $unreachable := (
  for $u in $allElemNames[not(.=$reachable)]
  order by $u
  return $u
)
return count($unreachable)

