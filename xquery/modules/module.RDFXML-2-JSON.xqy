xquery version "1.0";

(:
:   Module Name: RDF 2 JSON
:
:   Module Version: 1.0
:
:   Date: 2011 June 13
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Takes NTriples and converts  
:       to JSON serialization.
:
:)
   
(:~
:   Takes NTriples and converts  
:   to JSON serialization.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since June 13, 2011
:   @version 1.0
:)

module namespace rdfxml2json = 'info:lc/id-modules/rdfxml2json#';

(: Imported Modules :)
import module namespace rdfxml2nt   = "info:lc/id-modules/rdfxml2nt#" at "module.RDFXML-2-Ntriples.xqy";

(: Namespace(s) :)
declare namespace   rdf             = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace   madsrdf         = "http://www.loc.gov/mads/rdf/v1#";


(:~
:   This is the main function.  It converts full RDF/XML to 
:   Protovis's Javascript for a force-directed graph. 
:
:   @param  $rdfxml         node() is the RDF/XML  
:   @return xs:string       javascript
:)
declare function rdfxml2json:rdfxml2json
        ($rdfxml) 
        as xs:string
{
    let $ntriples := rdfxml2nt:rdfxml2ntriples($rdfxml)
    let $lines := fn:tokenize($ntriples , "\n")[fn:normalize-space(.) ne ""]
    let $uri := fn:replace( fn:substring-before($ntriples, "&#x20;"), '[<>]' , '' )      
    let $xml :=
        element xml {
            for $l in $lines
            order by $l
            return
                element spo {
                    element s { 
                        let $s := fn:substring-before($l, "&#x20;")
                        return 
                            (
                                attribute sclean { fn:replace($s , '[<>]' , '') },
                                text { $s }
                            )
                    },
                    element p { 
                        let $p := fn:substring-before(fn:substring-after($l, "&#x20;"), "&#x20;")
                        return 
                            (
                                attribute pclean { fn:replace($p , '[<>]' , '') },
                                text { $p }
                            )
                    },
                    element o { 
                        let $o := fn:replace(fn:substring-after(fn:substring-after($l, "&#x20;"), "&#x20;") , " \. " , "")
                        return 
                            (
                                attribute oclean { fn:replace($o , '[<>]' , '') },
                                text { $o }
                            )
                    }
                }
        }
        
    let $distinctSubjects := fn:distinct-values($xml/spo/s)
    let $nodes :=
        for $y in $distinctSubjects
        return
            let $distinctPredicates := fn:distinct-values($xml/spo[s = $y]/p)  
            let $predicatesANDobjects :=
                for $z in $distinctPredicates
                return     
                    for $x in $xml/spo[s = $y and p = $z]  
                        let $pANDo := 
                            fn:concat('"' , xs:string($z) , '": 
                                [
                                    ',
                                    fn:string-join(
                                        for $o in $x/o
                                        return rdfxml2json:compute-value-block(xs:string($o)),
                                        (: return fn:concat('{ "value" : "' , xs:string($o/@oclean) , '" }'), :)
                                    ', '),
                                    '
                                ]')
                        return $pANDo
                return
                    fn:concat('"' , xs:string($y) , '" : {
                        ',
                        fn:string-join(
                            for $po in $predicatesANDobjects
                            return ($po),
                            ', 
                            '),
                        '
                        }')

    return fn:concat(
        "   {
            ",
            fn:string-join($nodes , ',
            
            '),
        "
    }")

};


(:~
:   This is the main function.  It converts full RDF/XML to 
:   Protovis's Javascript for a force-directed graph. 
:
:   @param  $rdfxml         node() is the RDF/XML  
:   @return xs:string       javascript
:)
declare function rdfxml2json:compute-value-block($o as xs:string)
{
    let $o := fn:normalize-space($o)
    let $firstChar := fn:substring($o, 1, 1)
    
    let $value := 
        if ($firstChar eq '"') then
            if (fn:substring-before($o, '"^^')) then
                fn:substring( fn:substring-before($o, '"^^') , 2)
            
            else if (fn:substring-before($o, '"@')) then
                fn:substring( fn:substring-before($o, '"@') , 2)
            
            else
                fn:substring($o, 2, ( fn:string-length($o)-2 ))
        else if ($firstChar eq '<') then
            fn:substring( fn:substring-before($o, '>') , 2)        
        else
            $o
                            
    let $type := 
        if ($firstChar eq "<") then
            "uri"
        else if ($firstChar eq "_") then
            "bnode"
        else 
            "literal"
    
    let $dtype := fn:substring-after($o, "^^")
    let $datatype := 
        if ($type eq "literal" and $dtype) then
            $dtype
        else ()
        
    let $lang := fn:substring-after($o, "@")
    let $langvalue := 
        if ($type eq "literal" and $lang) then
            $lang
        else ()

    return 
        fn:concat('{ 
                                        "value" : "' , $value , '",
                                        "type" : "' , $type , '"',
                if ($datatype) then
                    fn:concat(',
                                        "datatype" : "' , $datatype , '"')
                else "",
                if ($langvalue) then
                    fn:concat(',
                                        "lang" : "' , $langvalue , '"')
                else "",
                '
                                    }')

};