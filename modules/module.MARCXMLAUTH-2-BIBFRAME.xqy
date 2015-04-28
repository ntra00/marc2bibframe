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
declare variable $marcauth2bibframe:last-edit :="2015-04-27-T11:00:00";

declare variable $marcauth2bibframe:simple-properties:= (
	<properties>
       	 <node domain="work" 		property="issnL"			           	    tag="022" sfcodes="l"		group="identifiers"    >linking International Standard Serial Number</node>
         <node domain="work"		   property="systemNumber"					      	tag="776" sfcodes="w"	   group="identifiers"    uri="http://www.worldcat.org/oclc/"   >system number</node>
         <node domain="7xx"		property="issn"					      	tag="776" sfcodes="x"	     group="identifiers"     >issn</node>
         <node domain="7xx"		property="coden"					      	tag="776" sfcodes="y"	     group="identifiers"     >CODEN</node>
         <node domain="7xx"		property="isbn"					      	tag="776" sfcodes="z"	     group="identifiers"     >issn</node>
         
         <node domain="work"		property="musicVersion"			     tag="130" sfcodes="s"      >version</node>
         <node domain="work"		property="musicVersion"			     tag="240" sfcodes="s"      >version</node>
         <node domain="instance"	property="titleStatement"		    	tag="245" sfcodes="ab"         >title Statement</node>
             
         <node domain="work"	    property="treatySignator"		    	tag="710" sfcodes="g"         >treaty Signator</node>
         <node domain="work"				property="musicKey"					      tag="384" sfcodes="a"	startwith="Transposed key: " ind1="1"	    		> Key </node>
         <node domain="work"				property="musicKey"					      tag="384" sfcodes="a" ind1=" "	    		> Key </node>
         <node domain="work"				property="musicKey"					      tag="384" sfcodes="a" ind1="0"	    		> Key </node>
         <node domain="work"				property="musicKey"					      tag="130" sfcodes="r"				    > Key </node>
         <node domain="work"				property="musicKey"					      tag="240" sfcodes="r"			 	    > Key </node>
         <node domain="work"		property="formDesignation"			     tag="130" sfcodes="k"      >Form subheading from title</node>         
         <node domain="work"		property="formDesignation"			     tag="240" sfcodes="k"      >Form subheading from title</node>         
         
         <node domain="work"				property="musicMediumNote"				tag="382" sfcodes="adp"		    	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="130" sfcodes="m"				    > Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="730" sfcodes="m"			     	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="240" sfcodes="m"			     	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="243" sfcodes="m"	     			> Music medium note </node>

         <node domain="work"				property="duration"					    tag="306" sfcodes="a"			     	>Playing time</node>
       
         <node domain="work"				property="originDate"					tag="130" sfcodes="f"						>Date of origin</node>
       
         <node domain="work"				property="originDate"					tag="046" sfcodes="kl" stringjoin="-"					>Date of origin</node>

         <node domain="work"				property="musicNumber"       			tag="130" sfcodes="n"						>Music Number</node>
         <node domain="work"				property="partNumber"					tag="730" sfcodes="n"						>Music Number</node>
         <node domain="work"				property="musicVersion"					tag="130" sfcodes="o"						>Music Version</node>
         <node domain="work"				property="musicVersion"					tag="240" sfcodes="o"						>Music Version</node>
         <node domain="work"				property="legalDate"					tag="130" sfcodes="d"						>Legal Date</node>         
         <node domain="work"				property="legalDate"					tag="730" sfcodes="d"						>Legal Date</node>                 
         <node domain="work"				property="dissertationNote"				tag="502" sfcodes="a"		                >Dissertation Note</node>
         <node domain="work"				property="dissertationDegree"			tag="502" sfcodes="b"			                >Dissertation Note</node>
         <node domain="work"				property="dissertationYear"				tag="502" sfcodes="d"				                >Dissertation Note</node>
         <node domain="work"				property="dissertationNote"				tag="502" sfcodes="g"		                >Dissertation Note</node>
         
         <node domain="work"				property="temporalCoverageNote"		tag="513" sfcodes="b"						>Period Covered Note</node>
         <node domain="work"				property="temporalCoverageNote"		tag="648" sfcodes="a"						>temporalCoverage Note</node>
         <node domain="event"			    property="eventDate"					    tag="518" sfcodes="d"						>Event Date</node>
         <node domain="work"			    property="note"					    tag="518" sfcodes="a"						>Event Date</node>
         <node domain="work"				property="geographicCoverageNote"	tag="522"				                >Geographic Coverage Note</node>
         <node domain="work"				property="supplementaryContentNote"	tag="525" sfcodes="a"					>Supplement Note</node>
         <node domain="work"		        property="awardNote"			    		tag="586" sfcodes="3a"					>Awards Note</node>
         <node domain="work"			property="geographicCoverageNote"	 	tag="662" sfcodes="abcdefg"  stringjoin="--"	      >geographicCoverage Note</node>
         <node domain="work"			property="geographicCoverageNote"	 	tag="662" sfcodes="h" >geographicCoverage Note</node>
         
  </properties>
	)	;

(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a,y,z,m,l,2,b,q
:
::   @param  $marcxml       element is the marcxml record
:   @param  $domain      string is the "work" or "instance"
: skip isbn; do it on generate-instance from isbn, since it's a splitter and you don't want multiple per instance
:   @return bf:* as element()
:)
declare function marcauth2bibframe:generate-identifiers(
   $marcxml as element(marcxml:record),
    $domain as xs:string    
    ) as element ()*
{ 
      let $identifiers:=         
             $marcauth2bibframe:simple-properties//node[@domain=$domain][@group="identifiers"]

      let $taglist:= fn:concat("(",fn:string-join(fn:distinct-values($identifiers//@tag),"|"),")")
                    
      let $bfIdentifiers := 
        
         	for $this-tag in $marcxml/marcxml:datafield[fn:matches( $taglist,fn:string(@tag) )]
         	return 
                for $id in $identifiers[fn:not(@ind1)][@domain=$domain][@tag=$this-tag/@tag] (:all but 024 and 028:)                        	 
               	
                (:if contains subprops, build class for $a else just prop w/$a:)
                	let $cancels:= for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"(m|y|z)")]
                	                   return element {fn:concat("bf:",fn:string($id/@property)) }{ 
		                                   mbshared:handle-cancels($this-tag, $sf, fn:string($id/@property))
		                                   }
                   	return  (:need to construct blank node if there's no uri or there are qualifiers/assigners :)
                   	    	if (fn:not($id/@uri) or  $this-tag/marcxml:subfield[fn:matches(@code,"(b|q|2)")]   or  $this-tag[@tag="037"][marcxml:subfield[@code="c"]] 
                                (:canadian stuff is not  in id:)
                                or  	$this-tag[@tag="040"][fn:starts-with(fn:normalize-space(fn:string(marcxml:subfield[@code="a"])),'Ca')]
                                (:parenthetical in $a is idqualifier:)
                                or $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")])
                   	    	    then 
		                          (element {fn:concat("bf:",fn:string($id/@property)) }{		                              
               		                       element bf:Identifier{               
               		                            element bf:identifierScheme {				 
               		                               attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/",  fn:string($id/@property))}
               		                            },	                            
               		                            if ($this-tag/marcxml:subfield[@code="a"]) then 
               		                                if ( $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")]) then
               		                                      let $val:=fn:replace($this-tag/marcxml:subfield[@code="a"],"(.+\()(.+)(\).+)","$1")
               		                            	      return  element bf:identifierValue { fn:substring($val,1, fn:string-length($val)-1)}
               		                            	else 
               		                                    element bf:identifierValue { fn:string($this-tag/marcxml:subfield[fn:matches(@code,$id/@sfcodes)][1]) }               		                                   
               		                            else (),
               		                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
               		                            	return element bf:identifierAssigner { 	fn:string($sub)},		
               		                            for $sub in $this-tag/marcxml:subfield[@code="q" ][$this-tag/@tag!="856"]
               		                            	return element bf:identifierQualifier {fn:string($sub)},   
               		                            for $sub in $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")] 
               		                            	return element bf:identifierQualifier { fn:replace($sub,"(.+\()(.+)(\).+)","$2")},               		                            
               	                                for $sub in $this-tag[@tag="037"]/marcxml:subfield[@code="c"]
               		                            	return element bf:identifierQualifier {fn:string($sub)}	                          		                           
               	                        	}
               	                       },
	                        	$cancels	                        			                              
		                        )
	                    	else 	(: not    @code,"(b|q|2) , contains uri :)                
	                        ( mbshared:generate-simple-property($this-tag,$domain ) ,	                        
	                        $cancels	                  	                           
			                 )(: END OF not    @code,"(b|q|2), end of tags matching ids without @ind1:)
               
               (:----------------------------------------   024 and 028 , where ind1 counts (no o28 in auths! ----------------------------------------:)
               (:024 had a z only; no $a: bibid;17332794:)
let $id024-028:=
      for $this-tag at $x in $marcxml/marcxml:datafield[fn:matches(@tag,"(024|028)")][marcxml:subfield[@code="a" or @code="z"]]                
                let $this-id:= $identifiers[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1] (: i1=7 has several ?:)             
                  return
                        if ($this-id) then(: if there are any 024/028s on this record in this domain (work/instance):) 
                            let $scheme:=   	       	  	
                                if ($this-tag/@ind1="7") then (:use the contents of $2 for the name: :)
                                    fn:string($this-tag[@ind1=$this-id/@ind1]/marcxml:subfield[@code="2"])
                                else if ($this-tag/@ind1="8") then 
                                    "unspecified"
                                else            (:use the $id name:)
                                    fn:string($this-id[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1]/@property)
                            let $property-name:= 
                                                (:unmatched scheme in $2:)
                                        if ( ($this-tag/@ind1="7" and fn:not(fn:matches(fn:string($this-tag/marcxml:subfield[@code="2"]),"(ansi|doi|iso|istc|iswc|local)")))
                                        or $this-tag/@ind1="8" ) then                                                            
                                            "bf:identifier"
                                        else fn:concat("bf:", $scheme)
                                        
                            let $cancels:= 
                                                for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"z")]                                                
                                                     return element {$property-name} { mbshared:handle-cancels($this-tag, $sf, $scheme)} 
                                            
                                (:if  024 has a c, b, q,  it  needs a class  else just prop w/$a Zs are handled in handle-cancels :)
                            return
                              ( if ( fn:not($this-tag/marcxml:subfield[@code="z"]) and ($this-tag/marcxml:subfield[@code="a"] and 
                                        ( fn:contains(fn:string($this-tag/marcxml:subfield[@code="c"]), "(") or 
                                            $this-tag/marcxml:subfield[@code="q" or @code="b" or @code="2"]  
        			                     )
        			                     
        			                    or
        			                     fn:not($this-id/@uri) or
        			                    $scheme="unspecified" ) 
        			                 ) then	
        			                 let $value:= if ($this-tag/marcxml:subfield[@code="a"] or $this-tag/marcxml:subfield[@code="d"]) then
        			                                 if ($this-tag/marcxml:subfield[@code="d"]) then 
        			                                    element bf:identifierValue { fn:string-join($this-tag/marcxml:subfield[fn:matches(@code,"(a|d)")],"-") }
        			                                 else
        			                                     element bf:identifierValue{ fn:string($this-tag/marcxml:subfield[@code="a"])}        			                      
        			                             else ()
	                                 return 
	                                   element {$property-name} {
	                                    element bf:Identifier{
       	                                  if ($scheme!="unspecified") then  element bf:identifierScheme {  attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/", $scheme)} } else (),
       	                                        $value,
       	                                    for $sub in $this-tag/marcxml:subfield[@code="b"] 
       	                                       return element bf:identifierAssigner{fn:string($sub)},	        
       	                                    for $sub in $this-tag/marcxml:subfield[@code="q"] 
       	                                       return element bf:identifierQualifier {fn:string($sub)}       	                                        	                                      
	                                       }	
	                                   }	                                  
                            else (:not c,q,b 2 . (z yes ) :)
                                let $property-name:= (:024 had a z only; no $a: bibid;17332794:)
                                                (:unmatched scheme in $2:)
                                        if ($this-tag/@ind1="7" and fn:not(fn:matches( fn:string($this-tag/marcxml:subfield[@code="2"]),"(ansi|doi|iso|isan|istc|iswc|local)" ))) then                                                            
                                            "bf:identifier"
                                        else fn:concat("bf:", $scheme)
                                        
                                return
                                    ( if ( $this-tag/marcxml:subfield[fn:matches(@code,"a")]) then                                        
                                            for $s in $this-tag/marcxml:subfield[fn:matches(@code,"a")]
                                                return element {$property-name} {element bf:Identifier {
                                                            element rdf:value { fn:normalize-space(fn:string($s))        }
                                                            }
                                                        }
                                        else ()
                                      )                                      
                        ,     $cancels                            
                        )
                        else   ()         (:end 024 / 028 none found :)
                        

	return  
     	  for $bfi in ($bfIdentifiers,$id024-028)
        		return 
		       (:     if (fn:name($bfi) eq "bf:Identifier") then
		                element bf:identifier {$bfi}
		            else:)
		                $bfi
		                
};		   
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
 let $series:= if         (fn:substring($cf008,15,1)= "a") then
            "Series"
            else ()
 let $seriesType:= 
            if ($series="Series") then
                    if (fn:substring($cf008,11,1)= "a") then
                        "Serial"
                    else if (fn:substring($cf008,11,1)= "b") then
                        "MultipartMonograph"
                    else if (fn:substring($cf008,11,1)= "b") then
                    "a Serial"
                    else 
                        "a Monograph"                        
            else ()
            
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
    let $changed:=  element bf:generationProcess {fn:concat("DLC authorities transform-tool:",$marcauth2bibframe:last-edit)}
   
return   

        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},
            if ($series) then
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $series)}
                    }
                else ()
                ,
            $seriesType,    
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
            element bf:test {$work-identifiers},                                                
            $derivedFrom,
            $hashable,
            $admin,
            $changed
        }

};

(:~
:   This is the main function.  It expects a MARCXML record  as input.
:
:   It generates bibframe RDF data as output.
:
:   @param  $collection        element is the top  level (marcxml ?)
:   @return rdf:RDF as element()
:)
declare function marcauth2bibframe:marcauth2bibframe(
        $collection as element(),
        $identifier as xs:string
        )  

{ 
 for $marcxml in $collection/marcxml:record
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
           let $work:=marcauth2bibframe:generate-work($marcxml, $workID) 
            return
               <rdf:RDF
                        xmlns:rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                        xmlns:rdfs          = "http://www.w3.org/2000/01/rdf-schema#"
                        xmlns:bf            = "http://bibframe.org/vocab/"
                        xmlns:madsrdf       = "http://www.loc.gov/mads/rdf/v1#"
                        xmlns:relators      = "http://id.loc.gov/vocabulary/relators/"                                        
                        >
                {                          
       
                   $work                    
                }
                </rdf:RDF>
    return $out
    
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



