xquery version "1.0";

(:
:   Module Name: MARC/XML BIB 2 BIBFRAME RDF using MarkLogic
:
:   Module Version: 1.0
:
:   Date: 2012 December 03
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp (MarkLogic)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Transforms MARC/XML Bibliographic records
:       to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:       N-triples, or JSON.
:
:)

(:~
:   Transforms MARC/XML Bibliographic records
:   to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:   N-triples, or JSON.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since December 03, 2012
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace marcbib2bibframe = "info:lc/id-modules/marcbib2bibframe#" at "modules/module.MARCXMLBIB-2-BIBFRAME.xqy";
import module namespace rdfxml2nt = "info:lc/id-modules/rdfxml2nt#" at "modules/module.RDFXML-2-Ntriples.xqy";
import module namespace rdfxml2json = "info:lc/id-modules/rdfxml2json#" at "modules/module.RDFXML-2-JSON.xqy";

(: NAMESPACES :)
declare namespace xdmp  = "http://marklogic.com/xdmp";

declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";

declare option xdmp:output "indent-untyped=yes" ; 

(:~
:   This variable is for the base uri for your Authorites/Concepts.
:   It is the base URI for the rdf:about attribute.
:   
:)
declare variable $baseuri as xs:string := xdmp:get-request-field("baseuri","http://base-uri/");

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string := xdmp:get-request-field("marcxmluri","");

(:~
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), ntriples, json
:)
declare variable $serialization as xs:string := xdmp:get-request-field("serialization","rdfxml");


let $marcxml := 
    xdmp:document-get(
            $marcxmluri, 
            <options xmlns="xdmp:document-get">
                <format>xml</format>
            </options>
        )
       
let $marcxml := $marcxml//marcxml:record

let $resources :=
    for $r in $marcxml
    let $controlnum := xs:string($r/marcxml:controlfield[@tag eq "001"][1])
    let $httpuri := fn:concat($baseuri , $controlnum)
    let $bibframe :=  marcbib2bibframe:marcbib2bibframe($r,$httpuri)
    return $bibframe/child::node()[fn:name()]
    
let $rdfxml := 
        element rdf:RDF {
            $resources
        }
        
let $response :=  
    if ($serialization eq "ntriples") then 
        rdfxml2nt:rdfxml2ntriples($rdfxml)
    else if ($serialization eq "json") then 
        rdfxml2json:rdfxml2json($rdfxml)
    else
        $rdfxml

return $response



