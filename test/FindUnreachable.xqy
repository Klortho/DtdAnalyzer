let $elems := //element[not(annotations//tag="root")]
return 
    if (exists($elems[content-model/@spec = "any"]))
    then ()
    else 
        for $e in $elems
            let $name := string($e/@name)
            let $sibs := $elems except $e
            order by $name
            return 
                if (exists($sibs[contains(content-model/@minified, $name)]))
                then ()
                else $name
