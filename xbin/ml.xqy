xquery version "1.0-ml";

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
import module namespace marcbib2bibframe = "info:lc/id-modules/marcbib2bibframe#" at "../modules/module.MARCXMLBIB-2-BIBFRAME.xqy";
import module namespace rdfxml2nt = "info:lc/id-modules/rdfxml2nt#" at "../modules/module.RDFXML-2-Ntriples.xqy";
import module namespace rdfxml2json = "info:lc/id-modules/rdfxml2json#" at "../modules/module.RDFXML-2-JSON.xqy";
import module namespace bfRDFXML2exhibitJSON = "info:lc/bf-modules/bfRDFXML2exhibitJSON#" at "../modules/module.RDFXML-2-ExhibitJSON.xqy";
import module namespace RDFXMLnested2flat = "info:lc/bf-modules/RDFXMLnested2flat#" at "../modules/module.RDFXMLnested-2-flat.xqy";

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

declare namespace log           =  "info:lc/marc2bibframe/logging#";
declare namespace mlerror       =  "http://marklogic.com/xdmp/error";

declare option xdmp:output "indent-untyped=yes" ; 

(:~
:   This variable is for the base uri for your Authorites/Concepts.
:   It is the base URI for the rdf:about attribute.
:   
:)
declare variable $baseuri as xs:string := xdmp:get-request-field("baseuri","http://example.org/");

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string := xdmp:get-request-field("marcxmluri","");

(:~
:   This variable is for desired serialzation.  Expected values are: rdfxml (default), rdfxml-raw, ntriples, json, exhibitJSON, log
:)
declare variable $serialization as xs:string := xdmp:get-request-field("serialization","rdfxml");

(:~
:   If set to "true" will write log file to directory.
:)
declare variable $writelog as xs:string := xdmp:get-request-field("writelog","false");

(:~
:   Directory for log files.  MUST end with a slash.
:)
declare variable $logdir as xs:string := xdmp:get-request-field("logdir","");

let $startDT := fn:current-dateTime()
let $logfilename := fn:replace(fn:substring-before(xs:string($startDT), "."), "-|:", "")
let $logfilename := fn:concat($logdir, $logfilename, '.log.xml')

let $marcxml := 
    xdmp:document-get(
            $marcxmluri, 
            <options xmlns="xdmp:document-get">
                <format>xml</format>
            </options>
        )
       
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
        } catch ($e) {
            (: ML provides the full stack, but for brevity only take the spawning error. :)
            let $stack1 := $e/mlerror:stack/mlerror:frame[1]
            let $vars := 
                for $v in $stack1/mlerror:variables/mlerror:variable
                return
                    element log:error-variable {
                        element log:error-name { xs:string($v/mlerror:name) },
                        element log:error-value { xs:string($v/mlerror:value) }
                    }
            let $logmsg := 
                element log:error {
                    attribute uri {$httpuri},
                    attribute datetime { fn:current-dateTime() },
                    element log:error-details {
                        (: ML appears to be the actual err:* code in mlerror:name :)
                        element log:error-enginecode { xs:string($e/mlerror:code) },
                        element log:error-xcode { xs:string($e/mlerror:name) },
                        element log:error-msg { xs:string($e/mlerror:message) },
                        element log:error-description { xs:string($e/mlerror:format-string) },
                        element log:error-expression { xs:string($e/mlerror:expr) },
                        element log:error-file { xs:string($stack1/mlerror:uri) },
                        element log:error-line { xs:string($stack1/mlerror:line) },
                        element log:error-column { xs:string($stack1/mlerror:column) },
                        element log:error-operation { xs:string($stack1/mlerror:operation) }    
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
        RDFXMLnested2flat:RDFXMLnested2flat($rdfxml-raw, $baseuri)
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

(: This might be a problem if run in a modules database. :)
let $logwritten := 
    if ($writelog eq "true") then
        xdmp:save($logfilename, $log,
            <options xmlns="xdmp:save">
                <indent>yes</indent>
                <method>xml</method>
                <output-encoding>utf-8</output-encoding>
            </options>
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



