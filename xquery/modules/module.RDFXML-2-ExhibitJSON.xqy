xquery version "1.0";

(:
:   Module Name: BIBFRAME RDF/XML 2 JSON for Exhibit
:
:   Module Version: 1.0
:
:   Date: 2013 10 Jan
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Takes BIBFRAME RDF/XML and converts
:       to JSON serialization to be used with MIT Exhibit.
:       This may be a tortured train wreck.  We'll see.
:
:)
   
(:~
:   Takes BIBFRAME RDF/XML and converts
:   to JSON serialization to be used with MIT Exhibit.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since January 10, 2013
:   @version 1.0
:)

module namespace bfRDFXML2exhibitJSON = 'info:lc/bf-modules/bfRDFXML2exhibitJSON#';

declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";


(:~
:   This is the main function.  It converts BIBFRAME RDF/XML 
:   to JSON serialization to be used with MIT Exhibit.
:
:   @param  $rdfxml         node() is the RDF/XML
:   @param  $baseuri        xs:string is the base uri for identifiers
:   @param  $hash           xs:string a unique hash for the identifier
:                           it is designed to be used when this script
:                           is run as part of a larger environment.   
:   @return xs:string       javascript
:)
declare function bfRDFXML2exhibitJSON:bfRDFXML2exhibitJSON
        (
            $rdfxml as element(rdf:RDF),
            $baseuri as xs:string
        ) 
        as xs:string
{
    
    let $resources := 
        for $c in $rdfxml/*[fn:name()]
        let $type := fn:local-name($c)
        let $uri := xs:string($c/@rdf:about)
        let $id := fn:replace($uri, $baseuri, "")
        let $l := ($c/madsrdf:authoritativeLabel|$c/bf:label|$c/rdfs:label)[1]
        let $l := fn:replace(xs:string($l), '"', '\\"')
        let $props-names := 
            for $p in $c/*[fn:name()]
            return fn:name($p)
        let $props-distinct := fn:distinct-values($props-names) 
        let $props := 
            for $name in $props-distinct
            let $ps := 
                for $p in $c/*[fn:name()=$name]
                return
                    if ($p/@rdf:resource) then
                        fn:concat('"', fn:replace(xs:string($p/@rdf:resource), $baseuri, "") , '"')
                    else if ($p/madsrdf:authoritativeLabel or $p/bf:label or $p/rdfs:label) then
                        let $label := ($p/madsrdf:authoritativeLabel|$p/bf:label|$p/rdfs:label)[1]
                        return fn:concat('"', fn:replace(xs:string($label), '"', '\\"') , '"')
                    else if (xs:string($p/@rdf:parseType)="Collection") then
                        let $list-items := 
                            for $i in $p/*[fn:name()]
                            let $t := fn:local-name($i)
                            let $els := 
                                for $e in $i/*[fn:name()]
                                let $n := fn:replace(fn:name($e), ":", "-")
                                return fn:concat('"', $n , '": "', fn:replace(xs:string($e), '"', '\\"'), '"')
                            return
                                fn:concat('{ 
                                    "type": ', fn:concat('"', $t , '"'), ', 
                                    ', fn:string-join($els, ", &#10;"), '
                                    }')
                        return fn:concat('[', fn:string-join($list-items, ', '), ']')
                    else
                        fn:concat('"', fn:replace(xs:string($p), '"', '\\"') , '"')
            let $ps := 
                if ( fn:count($ps) eq 1 ) then
                    fn:concat('"', fn:replace($name, ":", "-") , '": ', $ps)
                else
                    fn:concat('"', fn:replace($name, ":", "-") , '": [', fn:string-join($ps, ', '), ']' )
            where xs:string($name) ne "rdf:type"
            return $ps
        return 
            fn:concat('{ 
                "type": ', fn:concat('"', $type , '"'), ', 
                "id": ', fn:concat('"', $id , '"'), ',
                "uri": ', fn:concat('"', $uri , '"'), ',
                "label": ', fn:concat('"', $l , '"'), ',
                ', fn:string-join($props, ", &#10;"), '
                }')

    return fn:concat('{"items": [' , fn:string-join($resources, ", &#10;"), ']}')

};
