xquery version "3.0";

(:
:   Module Name: MARC/XML BIB 2 BIBFRAME RDF using Saxon
:
:   Module Version: 1.0
:
:   Date: 2012 December 03
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: Zorba (expath)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Transforms MARC/XML Bibliographic records
:       to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:       N-triples, or JSON.
:
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="http://location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="../location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
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
import module namespace http            =   "http://www.zorba-xquery.com/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://www.zorba-xquery.com/modules/xml";
import schema namespace parseoptions    =   "http://www.zorba-xquery.com/modules/xml-options";

import module namespace marcbib2bibframe = "info:lc/id-modules/marcbib2bibframe#" at "modules/module.MARCXMLBIB-2-BIBFRAME.xqy";
import module namespace rdfxml2nt = "info:lc/id-modules/rdfxml2nt#" at "modules/module.RDFXML-2-Ntriples.xqy";
import module namespace rdfxml2json = "info:lc/id-modules/rdfxml2json#" at "modules/module.RDFXML-2-JSON.xqy";
import module namespace bfRDFXML2exhibitJSON = "info:lc/bf-modules/bfRDFXML2exhibitJSON#" at "modules/module.RDFXML-2-ExhibitJSON.xqy";
import module namespace RDFXMLnested2flat = "info:lc/bf-modules/RDFXMLnested2flat#" at "modules/module.RDFXMLnested-2-flat.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";

declare namespace an = "http://www.zorba-xquery.com/annotations";
declare namespace httpexpath = "http://expath.org/ns/http-client";

(:~
:   This variable is for the base uri for your Authorites/Concepts.
:   It is the base URI for the rdf:about attribute.
:   
:)
declare variable $baseuri as xs:string external;

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string external;

(:~
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), rdfxml-raw, ntriples, json, exhibitJSON
:)
declare variable $serialization as xs:string external;

(:~
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), rdfxml-raw, ntriples, json, exhibitJSON
:)
declare variable $resolveLabelsWithID as xs:string external := "false";

(:~
Performs an http get but does not follow redirects

$l          as xs:string is the label
$scheme     as xs:string is the scheme    
:)
declare %an:sequential function local:http-get(
            $label as xs:string,
            $scheme as xs:string
    )
{
    let $l := fn:encode-for-uri($label)
    let $request := 
        http:send-request(
            <httpexpath:request 
                method="GET" 
                href="http://id.loc.gov/authorities/{$scheme}/label/{$l}" 
                follow-redirect="false"/>, 
            (), 
            ()
        )
    return $request
};

(:~
Outputs a resource, replacing verbose hasAuthority property
with a simple rdf:resource pointer

$resource   as element() is the resource
$authuri    as xs:string is the authority URI    
:)
declare %an:nondeterministic function local:generate-resource(
            $r as element(),
            $authuri as xs:string
    )
{
    element { fn:name($r) } {
        $r/@*,
        $r/*[fn:name() ne "bf:hasAuthority"],
        element bf:hasAuthority {
            attribute rdf:resource { $authuri }
        }
    }
};


(:~
Tries to resolve Labels to URIs

$resource   as element() is the resource
$authuri    as xs:string is the authority URI    
:)
declare %an:sequential function local:resolve-labels(
        $flatrdfxml as element(rdf:RDF)
    )
{
    let $resources := 
        for $r in $flatrdfxml/*
        let $n := fn:local-name($r)
        let $scheme := 
            if ( fn:matches($n, "Person|Organization|Place|Meeting|Family") ) then
                "names"
            else
                "subjects"
        return
            if ( fn:matches($n, "Person|Organization|Place|Meeting|Family") ) then
                let $label := ($r/bf:authorizedAccessPoint, $r/bf:label)[1]
                let $label := fn:normalize-space(xs:string($label))
                let $req1 := local:http-get($label, $scheme)
                let $resource := 
                    if ($req1[1]/@status eq 302) then
                        let $authuri := xs:string($req1[1]/httpexpath:header[@name eq "X-URI"][1]/@value)
                        return local:generate-resource($r, $authuri)
                    else if ( 
                        $req1[1]/@status ne 302 and
                        fn:ends-with($label, ".")
                        ) then
                        let $l := fn:substring($label, 1, fn:string-length($label)-1) 
                        let $req2 := local:http-get($l, $scheme)
                        return
                            if ($req2[1]/@status eq 302) then
                                let $authuri := xs:string($req2[1]/httpexpath:header[@name eq "X-URI"][1]/@value)
                                return local:generate-resource($r, $authuri)
                            else 
                                (: There was no match or some other message, keep moving :)
                                $r
                    else 
                        $r
                return $resource
                    
            else
                $r
    
    return <rdf:RDF>{$resources}</rdf:RDF>
};

let $marcxml := 
    if ( fn:starts-with($marcxmluri, "http://" ) or fn:starts-with($marcxmluri, "https://" ) ) then
        let $http-response := http:get-node($marcxmluri) 
        return $http-response[2]
    else
        let $raw-data as xs:string := file:read-text($marcxmluri)
        let $mxml := parsexml:parse(
                    $raw-data, 
                    <parseoptions:options />
                )
        return $mxml
let $marcxml := $marcxml//marcxml:record

let $resources :=
    for $r in $marcxml
    let $controlnum := xs:string($r/marcxml:controlfield[@tag eq "001"][1])
    let $httpuri := fn:concat($baseuri , $controlnum)
    let $bibframe :=  marcbib2bibframe:marcbib2bibframe($r,$httpuri)
    return $bibframe/child::node()[fn:name()]
    
let $rdfxml-raw := 
        element rdf:RDF {
            $resources
        }
        
let $rdfxml := 
    if ( $serialization ne "rdfxml-raw" ) then
        let $flatrdfxml := RDFXMLnested2flat:RDFXMLnested2flat($rdfxml-raw, $baseuri)
        return
            if ($resolveLabelsWithID eq "true") then
                local:resolve-labels($flatrdfxml)
            else
                $flatrdfxml
    else
        $rdfxml-raw 
        
let $response :=  
    if ($serialization eq "ntriples") then 
        rdfxml2nt:rdfxml2ntriples($rdfxml)
    else if ($serialization eq "json") then 
        rdfxml2json:rdfxml2json($rdfxml)
    else if ($serialization eq "exhibitJSON") then
        bfRDFXML2exhibitJSON:bfRDFXML2exhibitJSON($rdfxml, $baseuri)
    else
        $rdfxml

return $response

