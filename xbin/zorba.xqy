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
import module namespace http            =   "http://zorba.io/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://zorba.io/modules/xml";
import schema namespace parseoptions    =   "http://zorba.io/modules/xml-options";

import module namespace marcbib2bibframe = "info:lc/id-modules/marcbib2bibframe#" at "../modules/module.MARCXMLBIB-2-BIBFRAME.xqy";
import module namespace rdfxml2nt = "info:lc/id-modules/rdfxml2nt#" at "../modules/module.RDFXML-2-Ntriples.xqy";
import module namespace rdfxml2json = "info:lc/id-modules/rdfxml2json#" at "../modules/module.RDFXML-2-JSON.xqy";
import module namespace bfRDFXML2exhibitJSON = "info:lc/bf-modules/bfRDFXML2exhibitJSON#" at "../modules/module.RDFXML-2-ExhibitJSON.xqy";
import module namespace RDFXMLnested2flat = "info:lc/bf-modules/RDFXMLnested2flat#" at "../modules/module.RDFXMLnested-2-flat.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";

declare namespace an = "http://zorba.io/annotations";
declare namespace httpexpath = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace log           = "info:lc/marc2bibframe/logging#";
declare namespace err           = "http://www.w3.org/2005/xqt-errors";
declare namespace zerror        = "http://zorba.io/errors";

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
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), rdfxml-raw, ntriples, json, exhibitJSON, log
:)
declare variable $serialization as xs:string external;

(:~
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), rdfxml-raw, ntriples, json, exhibitJSON
:)
declare variable $resolveLabelsWithID as xs:string external := "false";

(:~
:   If set to "true" will write log file to directory.
:)
declare variable $writelog as xs:string external := "false";

(:~
:   Directory for log files.  MUST end with a slash.
:)
declare variable $logdir as xs:string external := "";

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
    (:
    let $request := 
        httpexpath:send-request(
            <httpexpath:request 
                method="GET" 
                href="http://id.loc.gov/authorities/{$scheme}/label/{$l}" 
                follow-redirect="false"/>
            )
    :)
    let $options := fn:concat('{
            "method": "GET",
            "href": "http://id.loc.gov/authorities/', $scheme, '/label/', $l , '",
            "options":
            {
                "status-only": true,
                "override-media-type": "text/plain",
                "follow-redirect": false,
                "timeout": 5,
                "user-agent": "MARC2BIBFRAME"
            }
        }')
    let $request := http:send-request(jn:parse-json($options))
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
            if ( fn:matches($n, "Topic|TemporalConcept") ) then
                "subjects"
            else
                "names"
        return
            if ( fn:matches($n, "Person|Organization|Place|Meeting|Family|Topic|TemporalConcept") ) then
                let $label := ($r/bf:authorizedAccessPoint, $r/bf:label)[1]
                let $label := fn:normalize-space(xs:string($label))
                let $req1 := local:http-get($label, $scheme)
                let $resource := 
                    if ($req1("status") eq 302) then
                        let $authuri := xs:string($req1("headers")("X-URI"))
                        return local:generate-resource($r, $authuri)
                    else if ( 
                        $req1("status") ne 302 and
                        fn:ends-with($label, ".")
                        ) then
                        let $l := fn:substring($label, 1, fn:string-length($label)-1) 
                        let $req2 := local:http-get($l, $scheme)
                        return
                            if ($req2("status") eq 302) then
                                let $authuri := xs:string($req2("headers")("X-URI"))
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

let $startDT := fn:current-dateTime()
let $logfilename := fn:replace(fn:substring-before(xs:string($startDT), "."), "-|:", "")
let $logfilename := fn:concat($logdir, $logfilename, '.log.xml')

let $marcxml := 
    if ( fn:starts-with($marcxmluri, "http://" ) or fn:starts-with($marcxmluri, "https://" ) ) then
        let $json := http:get($marcxmluri)
        return parsexml:parse($json("body")("content"), <parseoptions:options/>)
    else
        let $raw-data as xs:string := file:read-text($marcxmluri)
        let $mxml := parsexml:parse(
                    $raw-data, 
                    <parseoptions:options />
                )
        return $mxml
let $marcxml := $marcxml//marcxml:record

let $result :=
    for $r in $marcxml
    let $controlnum := xs:string($r/marcxml:controlfield[@tag eq "001"][1])
    let $httpuri := fn:concat($baseuri , $controlnum)
    let $r :=  
        try {
            let $rdf := marcbib2bibframe:marcbib2bibframe($r,$httpuri)
            let $o := $rdf/child::node()[fn:name()]
            let $logmsg := 
                element log:success {
                    attribute uri {$httpuri},
                    attribute datetime { fn:current-dateTime() }
                }
            return 
                element result {
                    element logmsg {$logmsg},
                    element rdf {$o}
                }
        } catch * {
            (: Could get entire stack trace from Zorba, but omitting for now. :)
            let $stack1 := $zerror:stack-trace
            let $logmsg := 
                element log:error {
                    attribute uri {$httpuri},
                    attribute datetime { fn:current-dateTime() },
                    element log:error-details {
                        element log:error-xcode { xs:string($err:code) },
                        element log:error-description { xs:string($err:description) },
                        element log:error-file { xs:string($err:module) },
                        element log:error-line { xs:string($err:line-number) },
                        element log:error-column { xs:string($err:column-number) }
                        (: element log:error-stack { $stack1 } :)
                    },
                    element log:offending-record {
                        $r
                    }
                }
            return
                element result {
                    element logmsg {$logmsg}
                }
        }
    return 
        $r
    
let $rdfxml-raw := 
        element rdf:RDF {
            $result//rdf/child::node()[fn:name()]
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
        
let $endDT := fn:current-dateTime()
let $log := 
    element log:log {
        attribute engine {"MarkLogic"},
        attribute start {$startDT},
        attribute end {$endDT},
        attribute source {$marcxmluri},
        attribute total-submitted { fn:count($marcxml) },
        attribute total-success { fn:count($marcxml) - fn:count($result//logmsg/log:error) },
        attribute total-error { fn:count($result//logmsg/log:error) },
        $result//logmsg/log:*
    }
    
let $logwritten := 
    if ($writelog eq "true") then
        file:write-text($logfilename, serialize($log,
            <output:serialization-parameters>
                <output:indent value="yes"/>
                <output:method value="xml"/>
                <output:omit-xml-declaration value="no"/>
            </output:serialization-parameters>)
        )
    else
        ()

(:
    For now, not injecting notice about an error into the JSON outputs.
    There are a couple of ways to do it (one is a hack, the other is the right way)
    but 1) will it break anything and 2) is there a need?
:)
let $response :=  
    if ($serialization eq "ntriples") then 
        if (fn:count($result//logmsg/log:error) > 0) then
            fn:concat("# Errors encountered.  View 'log' for details.", fn:codepoints-to-string(10), rdfxml2nt:rdfxml2ntriples($rdfxml))
        else
            rdfxml2nt:rdfxml2ntriples($rdfxml)
    else if ($serialization eq "json") then 
        rdfxml2json:rdfxml2json($rdfxml)
    else if ($serialization eq "exhibitJSON") then
        bfRDFXML2exhibitJSON:bfRDFXML2exhibitJSON($rdfxml, $baseuri)
    else if ($serialization eq "log") then 
        $log
    else
        if (fn:count($result//logmsg/log:error) > 0) then
            element rdf:RDF {
                comment {"Errors encountered.  View 'log' for details."},
                $rdfxml/*
            }
        else 
            $rdfxml
            
return $response

