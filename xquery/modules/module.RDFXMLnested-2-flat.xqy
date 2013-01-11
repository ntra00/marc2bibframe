xquery version "1.0";

(:
:   Module Name: BIBFRAME RDF/XML Nested (RAW) 2 RDF/XML Nested (Condensed) 
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
:   Module Overview:    Takes BIBFRAME RDF/XML, which can be
:       deeply nested, and flattens it by assigning each resource
:       a URI. This should really be generalized to RDF, i.e. 
:       not BF specific.
:
:)
   
(:~
:   Takes BIBFRAME RDF/XML, which can be
:   deeply nested, and flattens it by assigning each resource
:   a URI.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since January 10, 2013
:   @version 1.0
:)


module namespace RDFXMLnested2flat = 'info:lc/bf-modules/RDFXMLnested2flat#';

declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";


(:~
:   This is the main function.  Takes BIBFRAME RDF/XML, which can be
:   deeply nested, and flattens it by assigning each resource
:   a URI.  This should really be generalized to RDF, 
:   i.e. not BF specific.
:
:   @param  $rdfxml         node() is the RDF/XML
:   @param  $baseuri        xs:string is the base uri for identifiers  
:   @return element         rdf:RDF
:)
declare function RDFXMLnested2flat:RDFXMLnested2flat
        (
            $rdfxml as element(rdf:RDF),
            $baseuri as xs:string
        ) 
        as element(rdf:RDF)
{
    
    let $works := RDFXMLnested2flat:isolateAndIdentify($rdfxml, "Work", $baseuri)
    let $instances := RDFXMLnested2flat:isolateAndIdentify($rdfxml, "Instance", $baseuri)
    let $ientities := RDFXMLnested2flat:isolateAndIdentify($rdfxml, "IndexEntity", $baseuri)
    let $annotations := RDFXMLnested2flat:isolateAndIdentify($rdfxml, "Annotation", $baseuri)
    
    let $works := 
        for $w in $works/bf:Work

        let $w-works := $w/child::node()[fn:name(child::node()[1])="bf:Work"]
        let $w-works := 
            for $rw in $w-works
            return RDFXMLnested2flat:createResourceOrNot($rw, $works)

        let $w-ientities := $w/child::node()[
            fn:name(child::node()[1])="bf:Person" or
            fn:name(child::node()[1])="bf:Place" or
            fn:name(child::node()[1])="bf:Topic" or
            fn:name(child::node()[1])="bf:Genre" or
            fn:name(child::node()[1])="bf:Organization"]
        let $w-ientities := 
            for $ie in $w-ientities
            return RDFXMLnested2flat:createResourceOrNot($ie, $ientities)
        
        let $w-id := $w/@rdf:about  
        let $w-instances := $instances/bf:Instance[bf:instanceOf[@rdf:resource eq $w-id]]
        let $w-instances := 
            for $rw in $w-instances
            return 
                element bf:instance {
                    attribute rdf:resource {xs:string($rw/@rdf:about)}
                }
                  
        let $w-annotations := $instances/bf:Annotation[bf:annotates[@rdf:resource eq $w-id]]
        let $w-annotations := 
            for $rw in $w-annotations
            return 
                element bf:annotation {
                    attribute rdf:resource {xs:string($rw/@rdf:about)}
                }
            
        return 
            element {fn:name($w)} {
                $w/@*,
                $w/child::node()[
                    fn:name(child::node()[1])!="bf:Work" and
                    fn:name(child::node()[1])!="bf:Person" and
                    fn:name(child::node()[1])!="bf:Place" and
                    fn:name(child::node()[1])!="bf:Topic" and
                    fn:name(child::node()[1])!="bf:Genre" and
                    fn:name(child::node()[1])!="bf:Organization"],
                $w-ientities,
                $w-works,
                $w-instances,
                $w-annotations
            }
            
    let $instances := 
        for $i in $instances/bf:Instance

        let $i-ientities := $i/child::node()[
            fn:name(child::node()[1])="bf:Person" or
            fn:name(child::node()[1])="bf:Place" or
            fn:name(child::node()[1])="bf:Topic" or
            fn:name(child::node()[1])="bf:Genre" or
            fn:name(child::node()[1])="bf:Organization"]
        let $i-ientities := 
            for $ie in $i-ientities
            return RDFXMLnested2flat:createResourceOrNot($ie, $ientities)
        
        let $i-id := $i/@rdf:about  
        let $i-annotations := $instances/bf:Annotation[bf:annotates[@rdf:resource eq $i-id]]
        let $i-annotations := 
            for $ri in $i-annotations
            return 
                element bf:annotation {
                    attribute rdf:resource {xs:string($ri/@rdf:about)}
                }
            
        return 
            element {fn:name($i)} {
                $i/@*,
                $i/child::node()[
                    fn:name(child::node()[1])!="bf:Work" and
                    fn:name(child::node()[1])!="bf:Person" and
                    fn:name(child::node()[1])!="bf:Place" and
                    fn:name(child::node()[1])!="bf:Topic" and
                    fn:name(child::node()[1])!="bf:Genre" and
                    fn:name(child::node()[1])!="bf:Organization"],
                $i-ientities,
                $i-annotations
            }
            
    let $annotations := $annotations/bf:Annotation
    let $ientities := $ientities/*
    
    return 
        element rdf:RDF {
            $works,
            $instances,
            $annotations,
            $ientities
        }

};

(:~
:   Return a resource with an identifer.  Identifier is added if
:   the resource does not have one.
:
:   @param  $resources      element()* of all resources needing an identifier
:   @param  $baseuri        xs:string is the baseuri to use with the identifier
:   @return element()*      resources, with identifiers
:)
declare function RDFXMLnested2flat:createIdentifiedResource(
            $resources as element()*,
            $baseuri as xs:string
        ) as element()*
{
    for $r at $pos in $resources
    let $n := fn:lower-case(fn:local-name($r))
    return
        element {fn:name($r)} { 
            if  ($r/@rdf:about) then
                $r/@rdf:about
            else
                attribute rdf:about { fn:concat($baseuri, $n, $pos) },
            $r/*
        }
};

(:~
:   Try to match label of a resource to an existing one.
:   If there is a match, create an rdf:resource link;
:   if not, return the node.
:
:   @param  $needle         node() is the resource to match
:   @param  $haystack       node() is the RDF/XML of all resources
:   @return element()       node as a link or fully inline
:)
declare function RDFXMLnested2flat:createResourceOrNot(
            $needle as element(),
            $haystack as element(rdf:RDF)
        ) as element()
{
    let $label := ($needle/child::node()[1]/madsrdf:authoritativeLabel|$needle/child::node()[1]/rdfs:label|$needle/child::node()[1]/bf:label)[1]
    let $needle-found := $haystack/child::node()[child::node()=$label]
    return
        if ($needle-found[1]) then
            element {fn:name($needle)} {
                attribute rdf:resource {xs:string($needle-found[1]/@rdf:about)}
            }
        else
            $needle
};


(:~
:   Isolate and identify resources.
:   This will isolate all the resources of a particular
:   type and also given them identifiers.
:
:   @param  $rdfxml         node() is the RDF/XML
:   @param  $isolate        xs:string is the type of isolate
:   @param  $baseuri        xs:string is the base uri for identifiers  
:   @return xs:string       rdf:RDF of only those types
:)
declare function RDFXMLnested2flat:isolateAndIdentify
        (
            $rdfxml as element(rdf:RDF),
            $isolate as xs:string,
            $baseuri as xs:string
        )
        as element(rdf:RDF)
{
    let $resources := 
        if ($isolate eq "Work") then
            $rdfxml//bf:Work
        else if ($isolate eq "Instance") then
            $rdfxml//bf:Instance
        else if ($isolate eq "IndexEntity") then
            $rdfxml//bf:Person|$rdfxml//bf:Place|$rdfxml//bf:Topic|$rdfxml//bf:Genre|$rdfxml//bf:Organization
        else if ($isolate eq "Annotation") then
            $rdfxml//bf:Annotation
        else 
            ()
    let $resources := RDFXMLnested2flat:createIdentifiedResource($resources, $baseuri)
    return 
        element rdf:RDF {
            $resources
        }
};