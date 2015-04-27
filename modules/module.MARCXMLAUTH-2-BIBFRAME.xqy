xquery version "1.0";
(:
:   Module Name: MARCXML AUTH to bibframe
:
:   Module Version: 1.0
:
:   Date: 2012 Sept 13
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Transforms a MARC AUTH record (name/title or title)
:       into its bibframe parts.  
:
:)
   
(:~
:   Transforms a MARC AUTH record
:   into its bibframe parts.  This is a *raw* 
:   transform, meaning that it takes what it
:   can see and does what it can.  To really make this 
:   useable, additional work and modules will be necessary  
:
:	For examples of individual marc tags and subfield codes, look here:
:	http://lcweb2.loc.gov/natlib/util/natlib/marctags-nojs.html#[tag number]
:	
:   @author Kevin Ford (kefo@loc.gov)
:   @author Nate Trail (ntra@loc.gov)
:   @since January 30, 2014
:   @version 1.0
:)

module namespace marcauth2bibframe  = 'info:lc/id-modules/marcauth2bibframe#';

(: MODULES :)
import module namespace mbshared            = 'info:lc/id-modules/mbib2bibframeshared#' at "module.MBIB-2-BIBFRAME-Shared.xqy";
import module namespace marcxml2madsrdf 	= "info:lc/id-modules/marcxml2madsrdf#" at "module.MARCXML-2-MADSRDF.xqy";
import module namespace music 				= "info:lc/id-modules/marcnotatedmusic2bf#" at "module.MBIB-NotatedMusic-2-BF.xqy";

import module namespace bfdefault 			= "info:lc/id-modules/marcdefault2bf#" at "module.MBIB-Default-2-BF.xqy";
import module namespace marcerrors 	 		= 'info:lc/id-modules/marcerrors#' at "module.ErrorCodes.xqy";
import module namespace modsxml2bibframe    = 'info:lc/id-modules/modsxml2bibframe#' at "module.MODSXML-2-BIBFRAME.xqy";
import module namespace marc2bfutils = "info:lc/id-modules/marc2bfutils#" at "module.MARCXMLBIB-BFUtils.xqy";
(: NAMESPACES :)
declare namespace marcxml       	= "http://www.loc.gov/MARC21/slim";
declare namespace rdf           	= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          	= "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            	= "http://bibframe.org/vocab/";
declare namespace bf2            	= "http://bibframe.org/vocab2/";(: additional terms :)
declare namespace madsrdf       	= "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      	= "http://id.loc.gov/vocabulary/relators/";
declare namespace hld              = "http://www.loc.gov/opacxml/holdings/" ;

(: VARIABLES :)
declare function marcauth2bibframe:generate-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element () 
{ 
  
    let $cf008 := fn:string($marcxml/marcxml:controlfield[@tag='008'])
    let $leader:=fn:string($marcxml/marcxml:leader)
    let $leader6:=fn:substring($leader,7,1)
    let $leader7:=fn:substring($leader,8,1)
    let $leader19:=fn:substring($leader,20,1)

    let $typeOf008:=
			if ($leader6="a") then
					if (fn:matches($leader7,"(a|c|d|m)")) then
						"BK"
					else if (fn:matches($leader7,"(b|i|s)")) then
						"SE"
					else ""					
					
			else
				if ($leader6="t") then "BK" 
				else if ($leader6="p") then "MM"
				else if ($leader6="m") then "CF"
				else if (fn:matches($leader6,"(e|f|s)")) then "MP"
				else if (fn:matches($leader6,"(g|k|o|r)")) then "VM"
				else if (fn:matches($leader6,"(c|d|i|j)")) then "MU"
				else ""
 let $types := mbshared:get-resourceTypes($marcxml)
        
    let $mainType := "Work"
    
    let $uniformTitle := (:work title can be from 245 if no 240/130:)           
       for $d in ($marcxml/marcxml:datafield[@tag eq "130"]|$marcxml/marcxml:datafield[@tag eq "240"])[1]
            return mbshared:get-uniformTitle($d)         
    let $names := 
        (for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]
                return mbshared:get-name($d),
                (:joined addl-names to names so we can get at least the first 700 if htere are no 1xx's into aap:)
    (:let $addl-names:= :)
        for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(700|710|711|720)")][fn:not(marcxml:subfield[@code="t"])]                    
            return mbshared:get-name($d)
         )
        
    let $titles := 
        <titles>{
    	       for $t in $marcxml/marcxml:datafield[fn:matches(@tag,"(243|245|247)")]
    	       return mbshared:get-title($t, "work")
            }</titles>
    let $hashable := mbshared:generate-hashable($marcxml, $mainType, $types)     
    (: Let's create an authoritativeLabel for this :)
    let $aLabel := 
        if ($uniformTitle[bf:workTitle]) then 
            fn:concat( fn:string($names[1]/bf:*[1]/bf:label), " ", fn:string($uniformTitle/bf:workTitle) )
        else if ($titles) then
            fn:concat( fn:string($names[1]/bf:*[1]/bf:label), " ", fn:string($titles/bf:workTitle[1]) )
        else
            ""
            
    let $aLabel := 
        if (fn:ends-with($aLabel, ".")) then
            fn:substring($aLabel, 1, fn:string-length($aLabel) - 1 )
        else
            $aLabel
            
    let $aLabel := 
        if ($aLabel ne "") then
            element bf:authorizedAccessPoint { fn:normalize-space($aLabel) }
        else
            ()
            
    let $langs := mbshared:get-languages ($marcxml)
   	let $work-classes := mbshared:generate-classification($marcxml,"work")
   	let $work-identifiers := mbshared:generate-identifiers($marcxml,"work")
    let $admin:=mbshared:generate-admin-metadata($marcxml, $workID)
	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marc2bfutils:subject-types//@tag," "),fn:string(@tag))]		
        			return mbshared:get-subject($d)
 	let $derivedFrom:= 
         element bf:derivedFrom {           
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }		
return $marcxml  
(:
        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},            
         
            for $t in fn:distinct-values($types)
            return             
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $t)}
                },
             $aLabel,
            
            if ($uniformTitle/bf:workTitle) then
                $uniformTitle/*
            else
                $titles/*                ,       
            
            $names,                                                    
            $langs,            
            $subjects,                   
            $work-classes,            
            $work-identifiers,                                                
            $derivedFrom,
            $hashable,
            $admin             
        }:)

};

(:~
:   This is the main function.  It expects a MARCXML record  as input.
:
:   It generates bibframe RDF data as output.
:
:  
:   @param  $collection        element is the top  level (marcxml ?)
:   @return rdf:RDF as element()
:)
declare function marcauth2bibframe:marcauth2bibframe(
        $collection as element(),
        $identifier as xs:string
        )  
{    marcauth2bibframe:marcauth2bibframe($collection/marcxml:record[1], "123") 
(: for $marcxml in $collection/marcxml:record
    let $error := marcerrors:check($marcxml)
    let $out := 
        if ($error) then
            $error
        else
            let $about := 
                if ($identifier eq "") then
                    ()
                else if ( fn:not( fn:starts-with($identifier, "http://") ) ) then
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $identifier) }
                else
                    attribute rdf:about { $identifier }
           
        
            
         
            let $workID:=fn:normalize-space(fn:string($marcxml/marcxml:controlfield[@tag="001"]))                                
           let $work:=marcauth2bibframe:marcauth2bibframe($marcxml, $workID) 
            return
               <rdf:RDF
                        xmlns:rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                        xmlns:rdfs          = "http://www.w3.org/2000/01/rdf-schema#"
                        xmlns:bf            = "http://bibframe.org/vocab/"
                        xmlns:madsrdf       = "http://www.loc.gov/mads/rdf/v1#"
                        xmlns:relators      = "http://id.loc.gov/vocabulary/relators/"                                        
                        >
                {                          
       
                  element bf:test { $work }                   
                }
                </rdf:RDF>
    return $out:)
    
};
(:
: main function
:)
declare function marcauth2bibframe:marcauth2bibframe(
        $collection as element()
        ) as element(rdf:RDF) 
{   
    let $identifier := fn:string(fn:current-time())
    let $identifier := fn:replace($identifier, "([:\-]+)", "") 
	return	
	   if ($collection/*[fn:local-name()='mods'] ) then
			 modsxml2bibframe:modsxml2bibframe($collection)
	else
    	 marcauth2bibframe:marcauth2bibframe($collection,$identifier)
};

declare function marcauth2bibframe:modsbib2bibframe(
        $collection as element()
        ) as element(rdf:RDF) 
{   
  modsxml2bibframe:modsxml2bibframe($collection)

};



