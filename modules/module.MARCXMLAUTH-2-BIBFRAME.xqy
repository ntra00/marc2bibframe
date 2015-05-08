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
declare namespace identifiers      	= "http://id.loc.gov/vocabulary/identifiers/";
declare namespace skos            = "http://www.w3.org/2004/02/skos/core#";
declare namespace hld               = "http://www.loc.gov/opacxml/holdings/" ;

(: VARIABLES :)
declare variable $marcauth2bibframe:last-edit :="2015-05-08-T11:00:00";
declare variable $marcauth2bibframe:seriesPractices:=( 
    <set>
        <term tag="644" code="a" value="f" elname="bf2:seriesAnalysisPractice">Analyzed in full</term>
        <term tag="644" code="a" value="p" elname="bf2:seriesAnalysisPractice">Analyzed in part</term>
        <term tag="644" code="a" value="n" elname="bf2:seriesAnalysisPractice">Not analyzed</term>
        <term tag="645" code="a" value="t" elname="bf2:seriesTracingPractice">Traced as a serice added entry</term>
        <term tag="645" code="a" value="n" elname="bf2:seriesTracingPractice">Not traced as a series added entry </term>
        <term tag="646" code="a" value="s" elname="bf2:seriesClassPractice">Volumes are classified separately</term>
        <term tag="646" code="a" value="c" elname="bf2:seriesClassPractice">Volumes are classified as a collection </term>
        <term tag="646" code="a" value="m" elname="bf2:seriesClassPractice">Volumes are classified with main or other series</term>        
    </set>
    );
declare variable $marcauth2bibframe:properties:= (
	<properties>
	<node domain="work" 	property="bf:lccn"			           tag="010" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf:isbn"			           tag="020" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf:issn"			           tag="022" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf:issnL"			           tag="022" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work"		property="bf:originDate"			   tag="046" sfcodes="kl" stringjoin="-"					>Date of origin</node>
	<node domain="work" 	property="bf:systemNumber"			   tag="035" sfcodes="a"   	group="identifiers">System Congress Control number</node>
	<node domain="work"		property="bf:formDesignation"		   tag="380" sfcodes="a"      group="notes">Form subheading from title</node>
	<node domain="work"		property="bf:musicMediumNote"			tag="382" sfcodes="adp"		    	> Music medium note </node>
	<node domain="work" 	property="bf2:seriesNumbering"         tag="642" sfcodes="a"   	group="notes">data source note</node>
	<node domain="work" 	property="bf2:seriesProviderStatement" tag="643" sfcodes="ab"   	group="notes">seriesproviderstmt</node>	
	<node domain="work" 	property="bf2:catalogerNote"           tag="667" sfcodes="a"   	group="notes">cataloger note</node>
    <node domain="work" 	property="bf2:dataSourceNote"          tag="670" sfcodes="ab"   	group="notes">data source note</node>
    <node domain="work" 	property="bf:note"                     tag="680" sfcodes="ai"   	group="notes">public note</node>         
    
    
    <!--these props are transformed in their own functions: -->
    <node domain="complex" 	property="bf:title"                        tag="130" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:contentCategory"              tag="336" sfcodes="a"   	group="notes">public note</node>
    
    <node domain="complex" 	property="bf:seriesAnalysisPractice"            tag="644" sfcodes="a"   	group="notes">seriesAnalysisPractice</node>
    <node domain="complex" 	property="bf:seriesTracingPractice"            tag="645" sfcodes="a"   	group="notes">seriesTracingPractice</node>
    <node domain="complex" 	property="bf:seriesClassPractice"            tag="646" sfcodes="a"   	group="notes">seriesClassPractice</node>
    <node domain="annotation"	property="descriptionSource"			tag="040" sfcodes="a"  uri="http://id.loc.gov/vocabulary/organizations/" group="identifiers"        >Description source</node>
    <node domain="annotation"	property="descriptionModifier"			tag="040" sfcodes="d"  uri="http://id.loc.gov/vocabulary/organizations/" group="identifiers"        >Description source</node>            
    <node domain="annotation"	property="descriptionConventions"   tag="040" sfcodes="e"     uri="http://id.loc.gov/vocabulary/descriptionConventions/"           >Description conventions</node>
    <node domain="annotation"  property="descriptionLanguage"		tag="040" sfcodes="b"    uri="http://id.loc.gov/vocabulary/languages/"      >Description Language </node>
    <node domain="annotation"	property="descriptionAuthentication"   tag="042" sfcodes="a"     uri="http://id.loc.gov/vocabulary/descriptionAuthentication/"           >Description conventions</node>     
  </properties>
	)	;
(:
:~
:   This is the function generates contentCategory based on 336. 
:
:
::   @param  $marcxml       element is the marcxml record
:   @param  $domain      string is the "work" 

:   @return bf:* as element()
:)
declare function marcauth2bibframe:generate-contentCategory(
   $d as element(marcxml:datafield),
    $domain as xs:string    
    ) as element ()*
{ 
 
                let $src:=fn:string($d/marcxml:subfield[@code="2"])
               
                return 
                    if (   $src="rdacontent"  and $d/marcxml:subfield[@code="a"]) then
                    for $s in $d/marcxml:subfield[@code="a"]
                            let $content-code:=marc2bfutils:generate-content-code(fn:string($s))
                                return element bf:contentCategory {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/contentTypes/",fn:encode-for-uri($content-code))}	
                                }
                     else if ($d/marcxml:subfield[@code="a"]) then
                           for $s in $d/marcxml:subfield[@code="a"]
                             return element bf:contentCategory { 
                                 element bf:Category {                                       
                                         element rdf:value{fn:string($s)},
                                         element bf:categoryType{"content category"}
                                         } 
                                     }
                        else   if (   $src="rdacontent"  and $d/marcxml:subfield[@code="b"]) then
                                    for $s in $d/marcxml:subfield[@code="b"]
                                        return element bf:contentCategory {attribute rdf:type {fn:concat("http://id.loc.gov/vocabulary/contentTypes/",fn:encode-for-uri(fn:string($s)))}		
                        } 
                     else   ()                   
                     
};
(:
:~
:   This is the function generates series practices based on 644,645, 646 
:
:
::   @param  $marcxml       element is the marcxml record
 

:   @return bf:* as element()
:)
declare function marcauth2bibframe:generate-series-practices(
   $d as element(marcxml:datafield)    
    ) as element ()*
{ 
  for $s in $d/marcxml:subfield[@code="a"]  return 
        for $match in  $marcauth2bibframe:seriesPractices//term[@tag=$d/@tag][@code=$s/@code][@value=$s]                         
            return element { fn:string( $match/@elname) } { 
                            fn:concat ( fn:string( $match ) ,                            
                                        fn:string($d/marcxml:subfield[@code="b"]),
                                        for $s in $d/marcxml:subfield[@code="d"] 
                                            return fn:concat("(",fn:string($s),")"),
                                            " by ",
                                        fn:string-join( $d/marcxml:subfield[@code="5"] , ", ")
                                ) 
                             }               
};


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
             $marcauth2bibframe:properties//node[@domain=$domain][@group="identifiers"]

      let $taglist:= fn:concat("(",fn:string-join(fn:distinct-values($identifiers//@tag),"|"),")")
                    
      let $bfIdentifiers :=         
         	for $this-tag in $marcxml/marcxml:datafield[fn:matches( $taglist,fn:string(@tag) )]
         	return 
                for $id in $identifiers[fn:not(@ind1)][@domain=$domain][@tag=$this-tag/@tag] (:all but 024 and 028:)                        	 
               	
                (:if contains subprops, build class for $a else just prop w/$a:)
                	let $cancels:= for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"(m|y|z)")]
                	                   return element  bf2:identifiedBy { 
		                                      mbshared:handle-cancels($this-tag, $sf, fn:substring-after($id/@property,"bf:"))
		                                   }
		                                   
                   	return  (:need to construct blank node if there's no uri or there are qualifiers/assigners :)
                   	    	if (fn:not($id/@uri) or  $this-tag/marcxml:subfield[fn:matches(@code,"(b|q|2)")]   or  $this-tag[@tag="037"][marcxml:subfield[@code="c"]] 
                                (:canadian stuff is not  in id:)
                                or  	$this-tag[@tag="040"][fn:starts-with(fn:normalize-space(fn:string(marcxml:subfield[@code="a"])),'Ca')]
                                (:parenthetical in $a is idqualifier:)
                                or $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")])
                   	    	    then 
		                          (:(element {fn:concat("bf:",fn:string($id/@property)) }{:)		                              
		                          (element bf2:identifiedBy {
               		                       element bf:Identifier{               
               		                            element rdf:type {				 
               		                               attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/",   fn:substring-after($id/@property,"bf:"))}
               		                            },	                            
               		                            if ($this-tag/marcxml:subfield[@code="a"]) then 
               		                                if ( $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")]) then
               		                                      let $val:=fn:replace($this-tag/marcxml:subfield[@code="a"],"(.+\()(.+)(\).+)","$1")
               		                            	      return  element rdf:value { fn:substring($val,1, fn:string-length($val)-1)}
               		                            	else 
               		                                    element rdf:value { fn:string($this-tag/marcxml:subfield[fn:matches(@code,$id/@sfcodes)][1]) }               		                                   
               		                            else (),
               		                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
               		                            	return element bf2:source { 	fn:string($sub)},		
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
	                        ( marcauth2bibframe:generate-simple-property($this-tag,$domain ) ,	                        
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
                                    fn:substring-after(fn:string($this-id[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1]/@property),"bf:")
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
        			                                    element rdf:value { fn:string-join($this-tag/marcxml:subfield[fn:matches(@code,"(a|d)")],"-") }
        			                                 else
        			                                     element rdf:value{ fn:string($this-tag/marcxml:subfield[@code="a"])}        			                      
        			                             else ()
	                                 return 
	                                   element {$property-name} {
	                                    element bf:Identifier{
       	                                  if ($scheme!="unspecified") then  element rdf:type {  attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/", $scheme)} } else (),
       	                                        $value,
       	                                    for $sub in $this-tag/marcxml:subfield[@code="b"] 
       	                                       return element bf2:source{fn:string($sub)},	        
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
(:~
:   This is the function generates a literal property or simple uri from a marc tag
:       Options in this function are a prefix, (@startwith), indicator2, and concatenation of multiple @sfcodes.
:       If @ind2 is absent on the node, there is no test, otherwise it must match the datafield @ind2
:   <node domain="work" tag ="500" property="note" ind2=" " sfcodes="ab" >Note</note>
:
:   if there's only one subfield code in sfcodes, it looks for all those subfields (repeatables)
:   if there's a string of subfields, it does a stringjoin of all, but still creates a sequence in $text
:   @stringjoin could be on node; else " "
:   @param  $d        element is the MARCXML tag
:   @param  $domain       element is the domain for this element to sit in. is this needed?
:                           maybe needed for building related works??
:   @return bf:* as element()
: 
:)
declare function marcauth2bibframe:generate-simple-property(
    $d as element(marcxml:datafield)*,
    $domain as xs:string
    )
{
(:all the nodes in this domain with this datafield's tag, where there's no @ind1 or it matches the datafield's, and no ind2 or it matches the datafields:)
  for $node in  $marcauth2bibframe:properties//node[fn:string(@domain)=$domain][@tag=$d/@tag][ fn:not(@ind1) or @ind1=$d/@ind1][ fn:not(@ind2) or @ind2=$d/@ind2]
    let $return-codes:=	if ($node/@sfcodes) then fn:string($node/@sfcodes)	else "a"
    let $startwith:= 
        if ($d/@tag="511" and $d/@ind1="0") then 
            "" 
        else
            fn:string($node/@startwith) 
 
    return    
      if ( $d/marcxml:subfield[fn:contains($return-codes,@code)] ) then
        let $text:= if (fn:string-length($return-codes) > 1) then 
                        let $stringjoin:= if ($node/@stringjoin) then fn:string($node/@stringjoin) else " "
                        return   element wrap{ marc2bfutils:clean-string(fn:string-join($d/marcxml:subfield[fn:contains($return-codes,@code)],$stringjoin))}
                    else
                        for $s in $d/marcxml:subfield[fn:contains($return-codes,@code)]
                            return element wrap{ if (fn:matches($s/parent::datafield/@tag,"^5.+$"))then
                                                    fn:string($s)
                                                 else
                                                     marc2bfutils:clean-string(fn:string($s))
                                                }
                 
       return ( (:element {fn:string($node/@property)}{fn:string($text)},:)
           for $i in $text/*
            return  
                     element {fn:concat("bf:",fn:string($node/@property))} { 
                                (:for identifiers, if it's oclc and there's an oclc id (035a) return attribute/uri, else return bf:Id:)
                         if (fn:string($node/@group)="identifiers") then
                                if (fn:starts-with($i,"(OCoLC)") and fn:contains($node/@uri,"worldcat") ) then
                                    let $s :=  marc2bfutils:clean-string(fn:replace($i, "\(OCoLC\)", ""))
                                    return attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($s,"(^ocm|^ocn)",""))  }
                                else if (fn:contains($node/@uri,"id.loc.gov/vocabulary/organizations") ) then
                                    let $s :=  marc2bfutils:clean-string(fn:lower-case($i))
                                    let $s :=  fn:replace ($s,"-","")
                                    return attribute rdf:resource{fn:concat(fn:string($node/@uri),$s)  }
                                else
                                     element bf:Identifier {
                                                element rdf:value {
                                                  if (fn:starts-with($i, "(DLC)" )) then
                                                    fn:normalize-space(fn:replace($i,"(\(DLC\))(.+)$","$2" ))
                                                    else
                                                      fn:normalize-space(fn:concat($startwith,  $i) )
                                                      },
                                                element skos:inScheme {
                                                    if (fn:starts-with($i, "(DLC)" )) then
                                                        attribute rdf:resource {"http://id.loc.gov/vocabulary/identifiers/lccn"}
                                                    else
                                                        attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/",fn:substring-after($node/@property,"bf:") ) }}
                                                }                        
                         
                         
                         (:non-identifiers:)
                         else if (fn:not($node/@uri)) then 
                              fn:normalize-space(fn:concat($startwith,  $i) )    	                
                         (:nodes with uris: :)
                         else if (fn:contains(fn:string($node/@uri),"loc.gov/vocabulary/organizations")) then                         
                                let $s:=fn:lower-case(fn:normalize-space($i))
                                let $s :=  fn:replace ($s,"-","")
                                 return 
                                    if (fn:string-length($s)  lt 10 and fn:not(fn:contains($s, " "))) then
                                    
                                    (:if (fn:string-length($s)  lt 10 and fn:not(fn:contains($s, " ")) or fn:not(fn:starts-with($i,"Ca") ) ) then:)
                                        attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($s,"-",""))}
                                    else
                                        element bf:Organization {element bf:label {$s}}
                         else if (fn:contains(fn:string($node/@property),"lccn")) then
                                 attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($i," ",""))       }                         
                         else 
                                 attribute rdf:resource{fn:concat(fn:string($node/@uri),$i)}
             	             }
     )
     else (:no matching nodes for this datafield:)
        ()      
      
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
    let $contentCategory := for $d in $marcxml/marcxml:datafield[@tag="336"] return marcauth2bibframe:generate-contentCategory($d,"work") (:336:)
   
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
                    else if (fn:substring($cf008,11,1)= "c") then
                        "Serial"
                    else 
                        "Monograph"                        
            else ()
    let $seriesPractices:=for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(644|645|646)")]
            return  marcauth2bibframe:generate-series-practices($d) 
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
    (:let $origindate := for $d in $marcxml/marcxml:datafield[@tag="046"] return mbshared:get-origindate($d):)
     
   	let $work-classes := mbshared:generate-classification($marcxml,"work")
   	let $work-identifiers := marcauth2bibframe:generate-identifiers($marcxml,"work")
   	let $transformedtags:=fn:concat("(",fn:string-join(fn:distinct-values($marcauth2bibframe:properties//@tag),"|"),")")
   	
   	let $marctagset:=fn:concat("(",fn:string-join($marcxml//marcxml:datafield/@tag,"|"),")")
   	let $untransformedMarc:= $marcxml/marcxml:datafield[fn:not(fn:matches(@tag, $transformedtags))]
   	                
   	let $bfnotfound:=$marcauth2bibframe:properties[fn:not(fn:matches(@tag, $marctagset))]
   	
   	let $notetagset:= fn:concat("(",fn:string-join(fn:distinct-values($marcauth2bibframe:properties//node[@domain="work"][@group="notes"]/@tag),"|"),")")
                               
   	
   	let $work-simples:= 
   	       for $d in $marcxml/marcxml:datafield[fn:matches( $notetagset ,fn:string(@tag) )]
   	            return 
   	            marcauth2bibframe:generate-simple-property($d,"work")
   	       
    let $admin:= mbshared:generate-admin-metadata($marcxml, $workID)
    
	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marc2bfutils:subject-types//@tag," "),fn:string(@tag))]		
        			return mbshared:get-subject($d)
 	(:let $derivedFrom:= 
         element bf:derivedFrom {           
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }:)
    let $changed:=  element bf:generationProcess {fn:concat("DLC authorities transform-tool:",$marcauth2bibframe:last-edit)}
   let $admin:= 
        element bf:Annotation {$admin/bf:Annotation/*,               
                $changed
               }
return   

        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},
            
            if ($series) then
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $series)}
                    }
                else ()
                ,
             if ($seriesType) then
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $seriesType)}
                    }
                else ()
                ,
            
            $contentCategory,
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
            $seriesPractices,
            $subjects,                   
            $work-classes,
            $work-simples,            
            $work-identifiers,                                                
         
            $hashable,
     
            element bf2:hasAdminInfo { $admin},
            $changed,
            (:        element marctagset {$marctagset},:)
            element bf2:marcDataUntransformed {
                    element bf:Annotation{ element bf2:motivation{ "bf2:legacydescription"}, $untransformedMarc }
                }            
            (:element bfnotfound{$bfnotfound}}:)
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
                        xmlns:bf2           = "http://bibframe.org/vocab2/"
                        xmlns:madsrdf       = "http://www.loc.gov/mads/rdf/v1#"
                        xmlns:relators      = "http://id.loc.gov/vocabulary/relators/"                                        
                        xmlns:identifiers   = "http://id.loc.gov/vocabulary/identifiers/"
                        xmlns:skos          = "http://www.w3.org/2004/02/skos#"
                        xmlns:marcxml          = "http://www.loc.gov/MARC21/slim"
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



