declare function local:distinct-nodes($arg as node()*) as node()* 
{ 
   for $a at $apos in $arg 
   let $before_a := fn:subsequence($arg, 1, $apos - 1) 
   where every $ba in $before_a satisfies not($ba is $a) 
   return $a 
};

declare function 
local:reachable($allElems as element(element)*,
                $startSet as element(element)*,
                $newKids as element(element)*)
   as element(element)* 
{
    let $set := ($startSet, $allElems[@name='article'])
    (: Find all the children of $newKids :)
    let $nextKidNames := $newKids//child/string()
    (:let $nextKids := $allElems[@name=$nextKidNames]:)
    let $nextKids :=
        for $n in $nextKidNames
            return $allElems[@name=$n]
    (: Are there any in this set that are not in startSet? :)
    let $newNextKids :=
        for $nk in $nextKids
            return if ($nk = $startSet)
                   then ()
                   else $nk
    let $newStartSet := ($startSet, $newNextKids)
    
    (:let $nextSet := local:distinct-nodes($set):)
    return $newNextKids
};

let $elements := //element
let $roots := $elements[@name='article']
return local:reachable($elements, $roots, $roots)

(:
let $e1 := $elements[@name='article']
let $e2 := ($elements[@name='aricle'], $elements[@name='chapter-title'])
return $e1 = $e2
:)


