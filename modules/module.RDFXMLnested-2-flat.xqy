xquery version "1.0";

(:
:   Module Name: BIBFRAME RDF/XML Nested (RAW) 2 RDF/XML Flat (Condensed) 
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
:   @update May 23, 2013
:   @version 1.0
:)


module namespace RDFXMLnested2flat = 'info:lc/bf-modules/RDFXMLnested2flat#';

declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace dcterms       = "http://purl.org/dc/terms/";

declare variable $RDFXMLnested2flat:resourcesToIgnore := 
    <ignore>
        <class>Provider</class>
        <class>Authority</class>
    </ignore>;
   
declare variable $RDFXMLnested2flat:inverses := 
    <inverses>
        <inverse sourceResource="bf:Work" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>        
        <inverse sourceResource="bf:Work" targetResource="bf:Description">
            <replace lookForOnSource="bf:describedIn" enterOnTarget="bf:descriptionOf" />
        </inverse>            
        <inverse sourceResource="bf:Work" targetResource="bf:Description">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Work" targetResource="bf:Summary">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:summaryOf" />
        </inverse>
         <inverse sourceResource="bf:Work" targetResource="bf:Review">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
          <inverse sourceResource="bf:Work" targetResource="bf:Review">
            <replace lookForOnSource="bf:reviewedIn" enterOnTarget="bf:reviews" />
        </inverse>
         <inverse sourceResource="bf:Work" targetResource="bf:TableOfContents">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:tableOfContentsFor" />
        </inverse>
        <inverse sourceResource="bf:Instance" targetResource="bf:HeldMaterial">
            <replace lookForOnSource="bf:heldMaterial" enterOnTarget="bf:holdingFor" />
        </inverse>
          
        <inverse sourceResource="bf:HeldMaterial" targetResource="bf:HeldItem">
            <replace lookForOnSource="bf:heldItem" enterOnTarget="bf:componentOf" />
        </inverse>
        <inverse sourceResource="bf:Instance" targetResource="bf:HeldItem">
            <replace lookForOnSource="bf:heldItem" enterOnTarget="bf:holdingFor" />
        </inverse>
        
        <!--old :-->
        <inverse sourceResource="bf:Instance" targetResource="bf:Holding">        
            <replace lookForOnSource="bf:hasHolding" enterOnTarget="bf:holds" />
        </inverse>
        <inverse sourceResource="bf:Instance" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Person" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Work" targetResource="bf:Instance">
            <replace lookForOnSource="bf:hasInstance" enterOnTarget="bf:instanceOf" />
        </inverse>
    </inverses>;

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
    
    let $resources := RDFXMLnested2flat:identifyClasses($rdfxml, $baseuri, 0)
    let $resources := RDFXMLnested2flat:flatten($resources)
    let $resources := RDFXMLnested2flat:removeNesting($resources)
    let $resources := RDFXMLnested2flat:insertInverses($resources)
    return
        (: ntra changed this to an inline element from constructed, so I control the namespaces added.
       
        :)
      
      <rdf:RDF
            xmlns:rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:rdfs          = "http://www.w3.org/2000/01/rdf-schema#"
            xmlns:bf            = "http://bibframe.org/vocab/"
            xmlns:madsrdf       = "http://www.loc.gov/mads/rdf/v1#"
            xmlns:relators      = "http://id.loc.gov/vocabulary/relators/"                  
            xmlns:dcterms       = "http://purl.org/dc/terms/"
            >

        {
     
            $rdfxml/@*,
            for $w in    $resources/self::bf:Work
                order by $w/@rdf:about
                    return $w,
             
        
            $resources/self::bf:Instance,
            $resources/self::bf:Authority,
            $resources/self::bf:Annotation,
            $resources/self::bf:HeldMaterial,
            $resources/self::bf:HeldItem,
            $resources/self::bf:Holding,
            $resources/self::bf:Summary,
            $resources/self::bf:Review,
            $resources/self::bf:TableOfContents,
            $resources/self::bf:*[fn:not(fn:matches(fn:local-name(), "(Work|Instance|Authority|Annotation|Holding|HeldMaterial|HeldItem|Summary|Review|TableOfContents)"))]
          
            }
        </rdf:RDF>
};


(:~
:   Flattens the RDF/XML.  Extract all identified resources.
:
:   @param  $resources      element()* are the resources.   
:   @return element()       resources
:)
declare function RDFXMLnested2flat:flatten($resources as element()*)
        as element()*
{
    
    (:
    let $resources := ($resources[@rdf:about],$resources//child::node()[@rdf:about])
    return $resources
    :)
    for $r in $resources//@rdf:about
    return $r/parent::node()[1]

};


(:~
:   Identify resources.
:   This maintains the nested structure.  It
:   is called recursively.
:
:   @param  $rdfxml         node() is the RDF/XML
:   @param  $baseuri        xs:string is the base uri for identifiers
:   @param  $place          xs:integer is passed on to ensure unique ID assignment  
:   @return element()       resources
:)
declare function RDFXMLnested2flat:identifyClasses
        (
            $rdfxml as element(rdf:RDF),
            $baseuri as xs:string,
            $place as xs:integer
        )
        as element()*
{
    
    let $ignore := fn:string-join($RDFXMLnested2flat:resourcesToIgnore/class, " ")
    
    let $resources := $rdfxml/child::node()[fn:matches(fn:local-name(), "^([A-Z])([a-z]+)")]
    let $identified-resources :=
        for $r at $pos in $resources
        let $n := fn:lower-case(fn:local-name($r))
        let $baseuri-new := 
            if  ($r/@rdf:about) then
                xs:string($r/@rdf:about)                
            else
                $baseuri
        where fn:not(fn:contains($ignore, fn:local-name($r)))
        return
            element {fn:name($r)} { 
                if  ($r/@rdf:about) then
                    $r/@rdf:about                
                else
                    attribute rdf:about { fn:concat($baseuri-new, $n, ($pos + $place)) },                
                
                for $p at $spot in $r/*
                return
                    if ($p/child::node()[fn:matches(fn:local-name(), "^([A-Z])([a-z]+)")]) then
                        let $classes := $p/child::node()[fn:matches(fn:local-name(), "^([A-Z])([a-z]+)")]
                        return
                            element { fn:name($p) } {
                                $p/@*,
                                RDFXMLnested2flat:identifyClasses(<rdf:RDF>{$classes}</rdf:RDF>, $baseuri-new, ($pos + $spot + $place))
                            }
                    else
                        $p
            }
    let $skipped-resources :=
        for $r at $pos in $resources
        let $n := fn:lower-case(fn:local-name($r))
        where fn:contains($ignore, fn:local-name($r))
        return $r
        
    return ($identified-resources, $skipped-resources) 

};


(:
declare variable $RDFXMLnested2flat:inverses := 
    <inverses>
        <inverse sourceResource="bf:Work" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Instance" targetResource="bf:Holding">
            <replace lookForOnSource="bf:hasHolding" enterOnTarget="bf:holds" />
        </inverse>
        <inverse sourceResource="bf:Instance" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Person" targetResource="bf:Annotation">
            <replace lookForOnSource="bf:hasAnnotation" enterOnTarget="bf:annotates" />
        </inverse>
        <inverse sourceResource="bf:Work" targetResource="bf:Instance">
            <replace lookForOnSource="bf:hasInstance" enterOnTarget="bf:instanceOf" />
        </inverse>
    </inverses>;
:)
(:~
:   Insert inverse relations.
:
:   @param  $resources      element()* are the resources.   
:   @return element()       resources
:)
declare function RDFXMLnested2flat:insertInverses($resources as element()*)
        as element()*
{
    
    let $targets := fn:string-join($RDFXMLnested2flat:inverses/inverse/@targetResource, " ")
    (:nate: this won't work because bf:tableOfContents is part of bf:tableOfContentsFor, etc:)
  (:  let $remove-props := fn:concat(
            fn:string-join($RDFXMLnested2flat:inverses/inverse/replace/@enterOnTarget, " "),
            " ",
            fn:string-join($RDFXMLnested2flat:inverses/inverse/replace/@lookForOnSource, " ")
        ):)
    let $remove-props := fn:concat(    
            fn:string-join($RDFXMLnested2flat:inverses/inverse/replace/@enterOnTarget, "|"),
            "|",
            fn:string-join($RDFXMLnested2flat:inverses/inverse/replace/@lookForOnSource, "|")    
        )
    let $modified-targets :=
        for $r in $resources
           let $uri := xs:string($r/@rdf:about)
           let $n := xs:string(fn:name($r))
           let $lookFors := $RDFXMLnested2flat:inverses/inverse[@targetResource = $n]
        where fn:contains($targets, $n)
        return
            element {fn:name($r)} { 
                $r/@*,
                
                $r/*[fn:not( fn:matches( fn:name(),$remove-props ))],                
                     
                for $lf in $lookFors
                let $replace := $lf/replace
                let $related-resources := $resources[fn:name() = $lf/@sourceResource and child::node()[fn:name() = $replace/@lookForOnSource and xs:string(@rdf:resource) eq $uri]]
                let $distinct-abouts := fn:distinct-values($related-resources/@rdf:about)
                return
                    for $rr in $distinct-abouts
                    return
                        element { xs:string($replace/@enterOnTarget) } {
                            attribute rdf:resource { xs:string($rr) }
                        }
            }

    (:
        Need to figure out which resources were not processed as
        targets in the above.
        
        Some "targets" may be sources in other situations, but
        they will have already been processed and must be 
        bypassed.
    :)
    let $unmodified-resources :=
        for $r in $resources
        let $uri := xs:string($r/@rdf:about)
        let $n := xs:string(fn:name($r))
        where fn:not(fn:contains($targets, $n))
        return
            element {fn:name($r)} { 
                $r/@*,                
                $r/*[fn:not( fn:matches( fn:name(),$remove-props ))]               
            }

    return ($modified-targets, $unmodified-resources)
  

};

(:~
:   Remove nesting from extracted, identified resources.
:
:   @param  $resources      element()* are the resources.   
:   @return element()       resources
:)
declare function RDFXMLnested2flat:removeNesting($resources as element()*)
        as element()*
{
    
    let $simplified-resources :=
        for $r in $resources
        let $n := fn:lower-case(fn:local-name($r))
        return
            element {fn:name($r)} { 
                $r/@*,
                
                for $p in $r/*
                return
                    if ($p/child::node()[@rdf:about]) then
                        let $classes := $p/child::node()[fn:matches(fn:local-name(), "^([A-Z])([a-z]+)")]
                        return
                            element { fn:name($p) } {
                                attribute rdf:resource { xs:string($p/child::node()[@rdf:about]/@rdf:about) }
                            }
                    else
                        $p
            }

    return $simplified-resources 

};