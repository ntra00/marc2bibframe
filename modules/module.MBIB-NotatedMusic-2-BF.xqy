xquery version "1.0";
(:
:   Module Name: MARCXML BIB to bibframe
:
:   Module Version: 1.0
:
:   Date: 2014 Jan 30
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Transforms special kinds of MARC Bib records
:       into their bibframe parts.  
:
:)
   
(:~
:   This module handles transformations of specific types of marc records, starting with Music (audio and notated)
:   It is called from MarcxmlBib-2-Bibframe, and calls generic functions from that module. 
:	
:   @author Kevin Ford (kefo@loc.gov)
:   @author Nate Trail (ntra@loc.gov)
:   @since January 30, 2014
:   @version 1.0
:)

module namespace music  = "info:lc/id-modules/marcnotatedmusic2bf#";

(: MODULES :)

import module namespace marc2bfutils = "info:lc/id-modules/marc2bfutils#" at "module.MARCXMLBIB-BFUtils.xqy";
import module namespace mbshared  = 'info:lc/id-modules/mbib2bibframeshared#' at "module.MBIB-2-BIBFRAME-Shared.xqy";

(: NAMESPACES :)
declare namespace marcxml       	= "http://www.loc.gov/MARC21/slim";
declare namespace rdf           	= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          	= "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            	= "http://bibframe.org/vocab/";
declare namespace madsrdf       	= "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      	= "http://id.loc.gov/vocabulary/relators/";
declare namespace hld              = "http://www.loc.gov/opacxml/holdings/" ;
 
(:~
:   This is the function that generates a notated music work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function music:generate-notatedmusic-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()  {
    let $instances := mbshared:generate-instances($marcxml, $workID)
   
    let $types := mbshared:get-resourceTypes($marcxml)
        
    let $mainType := "Work" (:NotatedMusic?:)
    return    
        element {fn:concat("bf:" , $mainType)} {
                    attribute rdf:about {$workID},            
         for $t in fn:distinct-values($types)
            return            
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $t)}
                },
                 
            for $i in $instances 
                return element  bf:hasInstance{$i}
         }
};