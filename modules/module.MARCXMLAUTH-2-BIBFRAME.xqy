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
declare variable $marcauth2bibframe:last-edit :="2015-05-28-T11:00:00";
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
	<node domain="work" 	property="bf2:Lccn"			           tag="010" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf2:Isbn"			           tag="020" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf2:Issn"			           tag="022" sfcodes="a"	group="identifiers">Library of Congress Control number</node>
	<node domain="work" 	property="bf2:IssnL"			       tag="022" sfcodes="a"    group="identifiers">Library of Congress Control number</node>	
	<node domain="work" 	property="bf:musicNumber"			   tag="383" sfcodes="a"    group="notes">musicNumber</node>
	<node domain="work" 	property="bf:musicNumber"			   tag="383" sfcodes="b"    group="notes">Library of Congress Control number</node>
	<node domain="work" 	property="bf:musicNumber"			   tag="383" sfcodes="c"    group="notes">Library of Congress Control number</node>
	<node domain="work" 	property="bf:musicKey"			       tag="384" sfcodes="a"    group="notes">musical key</node>
	<node domain="work" 	property="bf2:systemNumber"			   tag="035" sfcodes="a"   	group="identifiers" uri="http://www.worldcat.org/oclc/">System Congress Control number</node>
	<node domain="work"		property="bf:originDate"			   tag="046" sfcodes="kl"   group="notes" stringjoin="-">Date of origin</node>
	<node domain="work"		property="bf:genre"		               tag="380" sfcodes="a"    group="notes">Form subheading from title</node>
	<node domain="work"		property="bf:originDate"			   tag="100" sfcodes="f"	group="notes"				>Date of origin</node>
	<node domain="work"		property="bf:originDate"			   tag="110" sfcodes="f"	group="notes"				>Date of origin</node>
	<node domain="work"		property="bf:originDate"			   tag="111" sfcodes="f"	group="notes"					>Date of origin</node>
	<node domain="work" 	property="bf2:distinguishingFacet"     tag="381" sfcodes="a"   	group="notes">public note</node>
	<node domain="work"		property="bf:musicMediumNote"		   tag="382" sfcodes="adp"  group="notes"> Music medium note </node>	
	<node domain="work" 	property="bf2:seriesNumbering"         tag="642" sfcodes="a"   	group="notes">data source note</node>
	<node domain="work" 	property="bf2:seriesProviderStatement" tag="643" sfcodes="ab"   group="notes">seriesproviderstmt</node>	
	<node domain="work" 	property="bf2:catalogerNote"           tag="667" sfcodes="a"   	group="notes">cataloger note</node>
    <node domain="work" 	property="bf2:dataSourceNote"          tag="670" sfcodes="ab"   group="notes">data source note</node>
    <node domain="work" 	property="bf:note"                     tag="680" sfcodes="ai"   group="notes">public note</node>         
    
    
    <node domain="annotation"	property="descriptionSource"			tag="040" sfcodes="a"  uri="http://id.loc.gov/vocabulary/organizations/" group="identifiers"        >Description source</node>
    <node domain="annotation"	property="descriptionModifier"			tag="040" sfcodes="d"  uri="http://id.loc.gov/vocabulary/organizations/" group="identifiers"        >Description source</node>            
    <node domain="annotation"	property="descriptionConventions"   tag="040" sfcodes="e"     uri="http://id.loc.gov/vocabulary/descriptionConventions/"           >Description conventions</node>
    <node domain="annotation"  property="descriptionLanguage"		tag="040" sfcodes="b"    uri="http://id.loc.gov/vocabulary/languages/"      >Description Language </node>
    <node domain="annotation"	property="descriptionAuthentication"   tag="042" sfcodes="a"     uri="http://id.loc.gov/vocabulary/descriptionAuthentication/"           >Description conventions</node>
    <node domain="classification"		property="bf:classificationSpanEnd"	tag="083" sfcodes="c"	          >classification span end for class number</node>
    <node domain="classification"		property="bf:classificationTableSeq"	tag="083" sfcodes="y"	     	    >DDC table sequence number</node>
    <node domain="classification"		property="bf:classificationTable"		tag="083" sfcodes="z"	         	>DDC table</node>
    <node domain="classification"		property="bf:classificationAssigner"   tag="083" sfcodes="q"	        	>various orgs assigner</node><!-- uri="http://id.loc.gov/vocabulary/organizations/"--> 
         
    <node domain="classification"		property="bf:classificationLcc"   tag="052" sfcodes="ab"	stringjoin="."  uri="http://id.loc.gov/authorities/classification/G"	>geo class</node>
    
    <!--these props are transformed in their own functions:, just listed here by tag to facilitate logging transformed items for bf2:legacydescription -->
    <node domain="complex" 	property="bf:title"                        tag="130" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:contentCategory"              tag="336" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:lcc"              tag="050" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:nlmc"              tag="060" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:class"              tag="082" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:class"              tag="086" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:audience"              tag="385" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:name"              tag="100" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:name"              tag="110" sfcodes="a"   	group="notes">public note</node>
    <node domain="complex" 	property="bf:name"              tag="111" sfcodes="a"   	group="notes">public note</node>        
    <node domain="complex" 	property="bf:seriesAnalysisPractice"            tag="644" sfcodes="a"   	group="notes">seriesAnalysisPractice</node>
    <node domain="complex" 	property="bf:seriesTracingPractice"            tag="645" sfcodes="a"   	group="notes">seriesTracingPractice</node>
    <node domain="complex" 	property="bf:seriesClassPractice"            tag="646" sfcodes="a"   	group="notes">seriesClassPractice</node>
    <node domain="complex" 	property="400"            tag="400" sfcodes="a"   	group="notes">seefrom</node>
    <node domain="complex" 	property="410"            tag="410" sfcodes="a"   	group="notes">seefrom</node>
    <node domain="complex" 	property="411"            tag="411" sfcodes="a"   	group="notes">seefrom</node>
     <node domain="complex" 	property="430"            tag="430" sfcodes="a"   	group="notes">seriesClassPractice</node>
     <node domain="complex" 	property="530"            tag="530" sfcodes="a"   	group="notes">530</node>
  </properties>
	)	;

(:~
:   This function generates uris to ddc, nlm,lcc classifications or a Classification node
:    classificationItem is retained, even though it looks like holdings data.
:  $marcxml    is marcxml:record
:  $resource is work or instance
:   @return ??
:)
declare function marcauth2bibframe:generate-classification(
       $marcxml as element(marcxml:record),
    $resource as xs:string
    ) as element ()*    
{
	  
    let $classes:=         
            $marc2bfutils:classes//property[@domain="Work"]
   
    return
       (
        for $this-tag in $marcxml/marcxml:datafield[@tag="(060)"]
             for $cl in $this-tag/marcxml:subfield[@code="a"]
                let $class:= fn:tokenize(fn:string($cl),' ')[1]
                return	 
                    element  bf:classification{                            			
                        attribute rdf:resource {fn:concat( "http://nlm.example.org/classification/",fn:normalize-space($class))
                        }
                    },
            
            for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"086")][marcxml:subfield[@code="z"]]
             let $scheme:=
                    if ($this-tag[@ind1=" "] and $this-tag/marcxml:subfield[@code="2"] ) then
                                 	       element rdf:type {fn:concat("http://class.example.org/",fn:string($this-tag/marcxml:subfield[@code="2"]))}
                                 	else if ($this-tag[@ind1="0"]  ) then  
                                 	      element rdf:type {attribute rdf:resource{ "http://id.loc.gov/vocabulary/classSchemes/sudocs"}}
                                 	else if ($this-tag[@ind1="1"]  ) then  
                                 	      element  rdf:type {attribute rdf:resource{ "http://id.loc.gov/vocabulary/classSchemes/cacodoc"}}
                                 	  else ()
              let $status:=element bf2:status  {"canceled/invalid"}                 
             return for $cancel in $this-tag/marcxml:subfield[@code="z"]
                        return
                            element bf:classification {
                                        element bf:Classification {                        
                                          	$scheme,
                                          	$status,
                                          	element bf:classificationNumber {  fn:string($cancel)}					 		        
         					 		}
         					}
                 ,
                     
       
        	  for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|060|082|086)")]                            
                for $cl in $this-tag/marcxml:subfield[@code="a"]           
                	let $valid:=
                	 	if (fn:not($this-tag/@tag="050")) then
                			fn:string($cl)
                		else (:050 has non-class stuff in it: :)
                  			let $strip := fn:replace(fn:string($cl), "(\s+|\.).+$", "")			
                  			let $subclassCode := fn:replace($strip, "\d", "")			
                  			return                   		            
        			            
        			            if ( mbshared:validate-lcc($subclassCode))        			              
        			                 then   								  
        			                fn:string($strip)
        			            else (:invalid content in sfa:)
        			                ()                 
        return (
            if ( $valid and
                fn:count($this-tag/marcxml:subfield)=1 and 
                $this-tag/marcxml:subfield[@code="a"] or 
                (fn:count($this-tag/marcxml:subfield)=2  and $this-tag/marcxml:subfield[@code="b"] )
               ) then
                    let $property:=     
                        if (fn:exists($classes[@level="property"][fn:contains(@tag,$this-tag/@tag)])) then
                            fn:string( $classes[@level="property"][fn:contains(@tag,$this-tag/@tag)]/@name)
                        else
                            "classification"                        	
                    return	 
                        element  bf:classification {          
                        (:problem: lots of these links are to properties, not classes! ie., sudocs:)
                     			if ($property="classificationLcc" ) then 
                     				attribute rdf:resource {fn:concat( "http://id.loc.gov/authorities/classification/",fn:string($cl ))}                    				                     		
                     		    else	if ($property="classificationDdc" ) then 
                     		             let $ddc:=fn:normalize-space($this-tag/marcxml:subfield[@code="a"])
                     		             let $ddc:=fn:replace($ddc,"^(.+) (.+)$", "$1") 
                     		             return                      		             
                     		                  attribute rdf:resource {fn:concat("http://dewey.info/class/",fn:encode-for-uri($ddc),"/about")}
                     		    else element bf:Classification {
                                        element bf:classificationNumber {fn:string($cl)},
                                if ($this-tag[@tag="086"] and $this-tag[@ind1=" "] and $this-tag/marcxml:subfield[@code="2"] ) then                                
                                 	       element  rdf:type { attribute rdf:resource {fn:concat("http://classScheme.example.org/",fn:string($this-tag/marcxml:subfield[@code="2"]))}}
                                 	else if ($this-tag[@tag="086"] and $this-tag[@ind1="0"]  ) then  
                                 	      element  rdf:type  {attribute rdf:resource{"http://id.loc.gov/vocabulary/classSchemes/sudocs"}}
                                 	else if ($this-tag[@tag="086"] and $this-tag[@ind1="1"]  ) then  
                                 	      element rdf:type {attribute rdf:resource {fn:concat("http://classScheme.example.org/","CanadianGovernmentClassification")}}
                                 	else if ($property="classificationNlm" or $property="classificationUdc") then 
                                 	  element rdf:type {attribute rdf:resource {fn:concat("http://bibframe.org/vocab2/",fn:string($classes[@level="property"][fn:contains(@tag,$this-tag/@tag)]/@className)  ) }}
                                 	else 
                                        element rdf:type {attribute rdf:resource {fn:concat("http://classScheme.example.org/",fn:string($classes[@level="property"][fn:contains(@tag,$this-tag/@tag)]/@name)  ) }}                                        
                                        }
                                 }
            else if ($valid   ) then
                let $assigner:=              
                       if ($this-tag/@tag="050" and $this-tag/@ind2="0") then "dlc"                       
                       else if (fn:matches($this-tag/@tag,"(060|061)")) then "dnlm"
                       else if (fn:matches($this-tag/@tag,"(070|071)")) then "dnal"
                       else if (fn:matches($this-tag/@tag,"(082|083|084)")  and $this-tag/marcxml:subfield[@code="q"]) then fn:string($this-tag/marcxml:subfield[@code="q"])
                       else ()

               return                       
                       element bf:classification {
                           element bf:Classification {                        
                                if ($this-tag/@tag="050")               then element rdf:type {attribute rdf:resource{ "http://bibframe.org/vocab2/LccClassification"} } 
                                   else if ($this-tag/@tag="082")       then element rdf:type {attribute rdf:resource{ "http://bibframe.org/vocab2/DdcClassification"}}
                                   (:nal??:)
                                   else if (fn:matches($this-tag/@tag,"(084|086)") and $this-tag/marcxml:subfield[@code="2"] ) then 
                                            element rdf:type {fn:concat("http://class.example.org/",fn:string($this-tag/marcxml:subfield[@code="2"]))}
                                   else ()
                               ,                        
                                if ($this-tag/@tag="082" and $this-tag/marcxml:subfield[@code="m"] ) then
                                    element bf:classificationDesignation  {
                                        if ($this-tag/marcxml:subfield[@code="m"] ="a") then "standard" 
                                        else if ($this-tag/marcxml:subfield[@code="m"] ="b") then "optional" 
                                        else ()
                                    }
                                else (),                                    
                     	       element bf:classificationNumber {fn:string($cl)},
                     	       
                      	       if ( $assigner) then 
                      	         (:assigner is string, not uri:)                                  	
                                  	(element bf:classificationAssigner {fn:concat("http://id.loc.gov/organizations/",$assigner)}                                  	
                                  	)
                                else (),             			
         			            	
                    	       if ( $this-tag/@tag="082" and fn:matches($this-tag/@ind1,"(0|1)") ) then  
                     	 		       let $this-edition:=                                     
                                         if ($this-tag/@tag="082"  and $this-tag/@ind1="1") then
         								    "abridged"
                                         else if ($this-tag/@tag="082" and $this-tag/@ind1="0") then							
         								    "full"
         								else if ($this-tag/@tag="082" and $this-tag/marcxml:subfield[@code="2"] ) then
         								    fn:string($this-tag/marcxml:subfield[@code="2"] )
         								else ()
         							  return if ($this-edition ) then
         							    element bf:classificationEdition {$this-edition}
         								   
         								   else ()
         							
                                 else (),
                                 if ($this-tag/@tag="082" and $this-tag/marcxml:subfield[@code="2"] ) then
                                    element bf:classificationEdition {fn:string($this-tag/marcxml:subfield[@code="2"] )}
                                 else ()                           
                    }
            }
     else ()
                        
   )                      )  
};
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
                                         element bf:categoryValue{fn:string($s)},
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

(:
:~
:   This is the function generates series practices based on 644,645, 646 
:
:
::   @param  $marcxml       element is the marcxml record
 

:   @return bf:* as element()
:)
declare function marcauth2bibframe:get-demographic(
   $d as element(marcxml:datafield)    
    ) as element ()*
{ 
   let $property:=if ($d/@tag="385") then "bf:intendedAudience" else "bf2:demographic"
   let $class:= if ($d/@tag="385") then "bf:IntendedAudience" else "bf2:Demographic"
  for $s in $d/marcxml:subfield[@code="a"]  
    return 
       if ($d/marcxml:subfield[@code="2"]="lcsh") then
                 element {$property} { attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/subjects/label/",fn:encode-for-uri(fn:normalize-space(fn:string($s))) )} }
            else             
                element {$property} { 
                    element {$class} { 
                        element bf:label {fn:normalize-space(fn:string($s)) } }
                        }
           
};         
(:~
:   This is the function generates full Identifier classes from m,y,z cancel/invalid identifiers 
:   @param  $this-tag       element is the marc data field
:   @param  $sf             subfield element
:   @param  $scheme         identifier name (lccn etc.)
:   @return bf:Identifier as element()
:)
declare function marcauth2bibframe:handle-cancels($this-tag, $sf, $scheme) 
{
 if ($this-tag[fn:matches(@tag,"(010|015|016|017|020|024|027|030|035|088)")] and $sf[@code="z"]) then
         element bf:Identifier {
  		  element bf:identifierScheme { attribute rdf:resource {fn:concat("http://bibframe.org/vocab2/", $scheme)} },
  		  element bf:identifierValue { fn:normalize-space(fn:string($sf))},
              if ($this-tag[@tag="022"] and $sf[@code="y"]) then                               
                      element bf:identifierStatus{"incorrect"}          
              else if ($this-tag[@tag="022"] and $sf[@code="z"]) then                 
                      element bf:identifierStatus{"canceled/invalid"}                
              else if ($this-tag[@tag="022"] and $sf[@code="m"]) then
                      element bf:identifierStatus {"canceled/invalid"}                
              else if ($this-tag[fn:matches(@tag,"(010|015|016|017|020|024|027|030|035|088)")] and $sf[@code="z"] ) then               
                      element bf:identifierStatus{"canceled/invalid"}                  
              else
                  ()
          }
        else if ( ($this-tag[@tag="022"] and $sf[fn:matches(@code,"m|y|z")]) ) then  
        element bf:Identifier {
  		  element bf:identifierScheme { attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/identifiers/", $scheme)} },
  		  element bf:identifierValue { fn:normalize-space(fn:string($sf))},
              if ($sf[@code="y"]) then                               
                      element bf:identifierStatus{"incorrect"}          
              else if ( $sf[@code="z"]) then                 
                      element bf:identifierStatus{"canceled/invalid"}                
              else if ( $sf[@code="m"]) then
                      element bf:identifierStatus {"canceled/invalid"}                              
              else
                  ()
          }
        else ()
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
                	                   return element  bf:identifier { 
		                                      marcauth2bibframe:handle-cancels($this-tag, $sf, fn:substring-after($id/@property,"bf2:"))
		                                   }
		                                   
                   	return  (:need to construct blank node if there's no uri or there are qualifiers/assigners :)
                   	    	if (fn:not($id/@uri) or  $this-tag/marcxml:subfield[fn:matches(@code,"(b|q|2)")]   or  $this-tag[@tag="037"][marcxml:subfield[@code="c"]] 
                                (:canadian stuff is not  in id:)
                                or  	$this-tag[@tag="040"][fn:starts-with(fn:normalize-space(fn:string(marcxml:subfield[@code="a"])),'Ca')]
                                (:parenthetical in $a is idqualifier:)
                                or $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")])
                   	    	    then 
		                          (:(element {fn:concat("bf:",fn:string($id/@property)) }{:)		                              
		                          (element bf:identifier {
               		                       element bf:Identifier{               
               		                            element rdf:type {				 
               		                               attribute rdf:resource {fn:concat("http://bibframe.org/vocab2/",   fn:substring-after($id/@property,"bf2:"))}
               		                            },	                            
               		                            if ($this-tag/marcxml:subfield[@code="a"]) then 
               		                                if ( $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")]) then
               		                                      let $val:=fn:replace($this-tag/marcxml:subfield[@code="a"],"(.+\()(.+)(\).+)","$1")
               		                            	      return  element bf:identifierValue  { fn:substring($val,1, fn:string-length($val)-1)}
               		                            	else 
               		                                    element bf:identifierValue  { fn:string($this-tag/marcxml:subfield[fn:matches(@code,$id/@sfcodes)][1]) }               		                                   
               		                            else (),
               		                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
               		                            	return element bf2:source { 	fn:string($sub)},		
               		                            for $sub in $this-tag/marcxml:subfield[@code="q" ][$this-tag/@tag!="856"]
               		                            	return element bf2:qualifier {fn:string($sub)},   
               		                            for $sub in $this-tag/marcxml:subfield[@code="a"][fn:matches(text(),"^.+\(.+\).+$")] 
               		                            	return element bf2:qualifier { fn:replace($sub,"(.+\()(.+)(\).+)","$2")},               		                            
               	                                for $sub in $this-tag[@tag="037"]/marcxml:subfield[@code="c"]
               		                            	return element bf2:qualifier {fn:string($sub)}	                          		                           
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
                                    fn:substring-after(fn:string($this-id[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1]/@property),"bf2:")
                            let $property-name:= 
                                                (:unmatched scheme in $2:)
                                        if ( ($this-tag/@ind1="7" and fn:not(fn:matches(fn:string($this-tag/marcxml:subfield[@code="2"]),"(ansi|doi|iso|istc|iswc|local)")))
                                        or $this-tag/@ind1="8" ) then                                                            
                                            " bf:identifier"
                                        else fn:concat("bf:", $scheme)
                                        
                            let $cancels:= 
                                                for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"z")]                                                
                                                     return element {$property-name} { marcauth2bibframe:handle-cancels($this-tag, $sf, $scheme)} 
                                            
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
        			                                    element bf:identifierValue  { fn:string-join($this-tag/marcxml:subfield[fn:matches(@code,"(a|d)")],"-") }
        			                                 else
        			                                     element bf:identifierValue { fn:string($this-tag/marcxml:subfield[@code="a"])}        			                      
        			                             else ()
	                                 return 
	                                   element {$property-name} {
	                                    element bf:Identifier{
       	                                  if ($scheme!="unspecified") then  element rdf:type {  attribute rdf:resource {fn:concat("http://bibframe.org/vocab2/", $scheme)} } else (),
       	                                        $value,
       	                                    for $sub in $this-tag/marcxml:subfield[@code="b"] 
       	                                       return element bf2:source{fn:string($sub)},	        
       	                                    for $sub in $this-tag/marcxml:subfield[@code="q"] 
       	                                       return element bf2:qualifier {fn:string($sub)}       	                                        	                                      
	                                       }	
	                                   }	                                  
                            else (:not c,q,b 2 . (z yes ) :)
                                let $property-name:= (:024 had a z only; no $a: bibid;17332794:)
                                                (:unmatched scheme in $2:)
                                        if ($this-tag/@ind1="7" and fn:not(fn:matches( fn:string($this-tag/marcxml:subfield[@code="2"]),"(ansi|doi|iso|isan|istc|iswc|local)" ))) then                                                            
                                            "bf:identifier"
                                        else fn:concat("http://identifier.example.org/", $scheme)
                                        
                                return
                                    ( if ( $this-tag/marcxml:subfield[fn:matches(@code,"a")]) then                                        
                                            for $s in $this-tag/marcxml:subfield[fn:matches(@code,"a")]
                                                return element {$property-name} {element bf:Identifier {
                                                            element bf:identifierValue  { fn:normalize-space(fn:string($s))        }
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
    $d as element(marcxml:datafield),
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
 
    return    (
      if ( $d/marcxml:subfield[fn:contains($return-codes,fn:string(@code))] ) then
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
                 
       return 
         for $i in $text
                     return  (
                     element {fn:string($node/@property)} { 
                                (:for identifiers, if it's oclc and there's an oclc id (035a) return attribute/uri, else return bf:Id:)
                         if (fn:string($node/@group)="identifiers") then
                                if (fn:starts-with($i,"(OCoLC)") and fn:contains($node/@uri,"worldcat") ) then
                                    let $s :=  marc2bfutils:clean-string(fn:replace($i, "\(OCoLC\)", ""))
                                    return attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($s,"(^ocm|^ocn|^oca)",""))  }
                                else if (fn:contains($node/@uri,"id.loc.gov/vocabulary/organizations") ) then
                                    let $s :=  marc2bfutils:clean-string(fn:lower-case($i))
                                    let $s :=  fn:replace ($s,"-","")
                                    return attribute rdf:resource{fn:concat(fn:string($node/@uri),$s)  }
                                else
                                     element bf:Identifier {
                                                element bf:identifierValue  {
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
      )
};
(:~
:   This is the function generates a seeFrom references (title variations) and creators from 4xx, 430
:
:)
declare function marcauth2bibframe:generate-seeFroms(
    $marcxml as element(marcxml:record)
    
    ) as element ()*
{ 
(for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(400|410|411)")][marcxml:subfield[@code="t"]]            
            (:put t into a and process as 246 title variant::)
            let $names:= 
                if (fn:string( $d/marcxml:subfield[@code="a"]) !=fn:string($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")][1]/marcxml:subfield[@code="a"]) ) then
                    mbshared:get-name($d)        
                else
                ()
            
            let $vartitledata:=
                    element marcxml:datafield { attribute tag {"246"} ,
                        for $s in $d/marcxml:subfield
                            return if ($s/@code="t") then 
                                    element marcxml:subfield{ attribute code {"a"}, $s/*[fn:not(@code)],fn:string($s) }
                                    else if ($s/@code="a") then () 
                                    else
                                        $s
                }
                                   
            return           
                    (mbshared:get-title($vartitledata,"work"),$names)     		          
                ,
            for $d in $marcxml/marcxml:datafield[@tag="430"]
               let $vartitledata:=
                    element marcxml:datafield { attribute tag {"246"} ,$d/@ind1, $d/@ind2,
                        for $s in $d/marcxml:subfield
                            return 
                                    $s
                        }
                return mbshared:get-title($vartitledata,"work")
                 (:       
            return           
                    element bf:title { element bf:Title  {element bf:titleValue {$title}
                    }
                }:)
               )
               };
declare function marcauth2bibframe:generate-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element () 
{ 
    let $workID:=fn:replace($workID, " ","")
    let $cf008 := fn:string($marcxml/marcxml:controlfield[@tag='008'])
    let $leader:=fn:string($marcxml/marcxml:leader)
    let $leader6:=fn:substring($leader,7,1)
    let $leader7:=fn:substring($leader,8,1)
    let $leader19:=fn:substring($leader,20,1)
    let $contentCategory := for $d in $marcxml/marcxml:datafield[@tag="336"] return marcauth2bibframe:generate-contentCategory($d,"work") (:336:)
   
  
 let $seriesType:=           (:008/12 series:)
            if (fn:matches(fn:substring($cf008,13,1),"(a|c)" )) then
                "Series"
            else if (fn:substring($cf008,13,1)= "b") then
                "MultipartMonograph"          
            else 
                "Monograph"                        
          
    let $types:=$seriesType
    let $seriesPractices:=for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(644|645|646)")]
            return  marcauth2bibframe:generate-series-practices($d) 
    let $langs := (
            mbshared:get-languages ($marcxml),
            for $s in $marcxml/marcxml:datafield[@tag="377"]/marcxml:subfield[@code="a"]
                return  element bf:language { 
                                        attribute rdf:resource { 
                                            fn:concat("http://id.loc.gov/vocabulary/languages/",fn:string($s))
                                            }
                        },
            marc2bfutils:process-language(fn:string($marcxml/marcxml:datafield[@tag="377"][@ind2=" "]/marcxml:subfield[@code="l"])),
            marc2bfutils:process-language(fn:string($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]/marcxml:subfield[@code="l"]))
            
            )
    let $mainType :=  if ($langs) then "Expression" else "Work"
    
    let $uniformTitle :=           
       for $d in $marcxml/marcxml:datafield[@tag eq "130"]
            return mbshared:get-uniformTitle($d)         
    let $names := 
        for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]
                return mbshared:get-name($d)                                
    let $seefromTitles:=
                marcauth2bibframe:generate-seeFroms($marcxml)
        
    let $seefromWorks:=
        (
        (:for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(500|510|511)")][marcxml:subfield[@code="t"]]            
            let $title:= fn:string($d/marcxml:subfield[@code="t"])
            return element bf:relatedResource {element bf:Work {           
                    element bf:title { element bf:Title  {element bf:titleValue {$title}
                    }
                }
                }
                }:)
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(500|510|511)")][marcxml:subfield[@code="t"]] |  $marcxml/marcxml:datafield[@tag="530"]       
                    (:change 5 to 7 and process related works:)
                    let $related:= 
                        element marcxml:record {element marcxml:datafield { attribute tag {fn:concat(fn:replace(fn:substring($d/@tag,1,1), "5","7"),fn:substring($d/@tag,2,2))}, $d/@ind1, $d/@ind2,
                            for $s in $d/marcxml:subfield
                                return 
                                       $s
                            }
                        }
                                   
            return           
                    mbshared:related-works($related,$workID,"work")     
                ,
            for $d in $marcxml/marcxml:datafield[@tag="530"] (:this is not right !!!! :)
            let $title:= fn:string($d/marcxml:subfield[preceding-sibling::marcxml:subfield[@code="a"]]) 
            return   element bf:relatedResource {element bf:Work {            
                    element bf:title { element bf:Title  {element bf:titleValue {$title}
                    }
                }
                }}
               )
            
            
    let $titles := 
        <titles>{
    	       for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")][marcxml:subfield[@code="t"]]
    	       return element bf:workTitle {
    	     (:   or (
                                            fn:not(fn:matches(@code,"(e|0|4|6|8|l)" ) ) and 
                                            preceding-sibling::marcxml:subfield[@code="t":)
    	       element bf:Title {element bf:titleValue { fn:string($d/marcxml:subfield[@code= "t"])}
    	               }    	       
    	       }
            } </titles>
    let $hashable :=  marcauth2bibframe:generate-hashable($marcxml, $mainType, $types)
    
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
            
    
    
    let $origin-place := for $s in $marcxml/marcxml:datafield[@tag="370"]/marcxml:subfield[@code="g"]
                return element bf:originPlace {
                            element bf:Place {
                                element bf:label {fn:string($s)}
                            }
                       }
     
   	let $work-classes := marcauth2bibframe:generate-classification($marcxml,"work")
   	let $work-identifiers := marcauth2bibframe:generate-identifiers($marcxml,"work")
    let $music-media:= for $s in $marcxml/marcxml:datafield[@tag="382"]/marcxml:subfield[@code="a"]
                        return element bf:musicMedium {
                                    attribute rdf:resource{
                                        fn:concat("http://id.loc.gov/authorities/performanceMediums/label/",
                                                                            fn:encode-for-uri(fn:normalize-space(fn:string($s) )))}}
    let $audience:= 
     			for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(385|386)")][marcxml:subfield[@code="a"]]
     				return marcauth2bibframe:get-demographic($d) 
     			                        
   	let $transformedtags:=fn:concat("(",fn:string-join(fn:distinct-values($marcauth2bibframe:properties//@tag),"|"),")")
   	
   	let $marctagset:=fn:concat("(",fn:string-join($marcxml//marcxml:datafield/@tag,"|"),")")
   	let $untransformedMarc:= $marcxml/marcxml:datafield[fn:not(fn:matches(@tag, $transformedtags))]
   	                
   	let $bfnotfound:=$marcauth2bibframe:properties[fn:not(fn:matches(@tag, $marctagset))]
   	
   	let $notetagset:= fn:concat("(",fn:string-join(fn:distinct-values($marcauth2bibframe:properties//node[@domain="work"][@group="notes"]/@tag),"|"),")")
                               
   	
   	let $work-simples:= 
   	       for $d in $marcxml/marcxml:datafield[fn:matches( $notetagset ,fn:string(@tag) )]
   	            return 
   	            marcauth2bibframe:generate-simple-property($d,"work")
   	let $genre:= 
   	       for $s in $marcxml/marcxml:datafield[@tag="380"]/marcxml:subfield[@code="a"]
   	            return element bf:genre {
   	                        element  bf:Category {
   	                           element bf:label{fn:string($s)}
   	                            }
   	                   }
   	            
   	       
    let $admin1:= mbshared:generate-admin-metadata($marcxml, $workID)
    
	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marc2bfutils:subject-types//@tag," "),fn:string(@tag))]		
        			return mbshared:get-subject($d)
 	(:let $derivedFrom:= 
         element bf:derivedFrom {           
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }:)
       
    let $changed:=  element bf:generationProcess {fn:concat("DLC authorities transform-tool:",$marcauth2bibframe:last-edit)}
    let $descriptionConventions:=           (:008/12 series:)
            if (fn:matches(fn:substring($cf008,11,1),"(b|c|d)" )) then
                "aacr"
            else if (fn:substring($cf008,11,1)= "z") then
                fn:lower-case(fn:string( $marcxml/marcxml:datafield[@tag="040"]/marcxml:subfield[@code="e"]))
            else 
                ()
 
   let $admin:= 
        element bf:Annotation {$admin1//bf:Annotation/*,
                if ($descriptionConventions) then
                    element bf:descriptionConventions {attribute rdf:resource {fn:concat("http://loc.gov/vocabulary/descriptionConventions/",$descriptionConventions)}}
                else (),
                $changed
               }
return   

        element bf:Work  {
               
            attribute rdf:about {$workID},
            if ($mainType="Expression") then element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $mainType)}
                    } 
                    else (),
                      
             if ($seriesType) then
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $seriesType)}
                    }
                else ()
                ,
            
            $contentCategory,
          
             $aLabel,
            
            if ($uniformTitle/bf:workTitle) then
                $uniformTitle/*[fn:not(fn:local-name()="authoritativeLabel")]
            else
                $titles/* ,
                
            $seefromTitles,
            $seefromWorks,
            $names,              
            $langs,              
            $seriesPractices,
            $subjects,                   
            $work-classes,
            $genre,
            $origin-place,
            $work-simples,
            $music-media,
            $audience,
            $work-identifiers,                                                
         
            $hashable,
     
            element bf2:hasAdminInfo { $admin},
            
         
            (:        element marctagset {$marctagset},:)
            if ($untransformedMarc) then element bf2:marcDataUntransformed {
                    element bf:Annotation{ element bf2:motivation{ "bf2:marcDescription"}, $untransformedMarc }
                }            
                else ()
            (:element bfnotfound{$bfnotfound}}:)
            }
};



(:~
:   This function generates a hashable version of the work, using title, name etc.
:
:   It generates a bf:authorizedAccessPoint xml:lang="x-bf-hash" private language.
:
:   The "hashable" string is an attempt to create an identifier of sorts to help 
:   establish "sameness" between works (this may be extended to instances in the future).
:   While there are other ways to do this (load the data into a search system and do
:   specific field-based queries), this is meant as a way to test out "matching" ideas without 
:   the overhead of loading into a special system.
:
:   The algorithm is as follows:
:       1) Look for a title - take the 130 1xx $t plus whatever's after it.
:       2) Use only select subfields from the title.
:       3) Grab all the names from the 1XX field and the 7XX fields.  Only use a given 7XX field if 
:           it represents a name (name/title 7XX fields, therefore, are not included)
:       4) Sort all the names alphabetically to help control for variation in how the data were 
:           originally entered.
:       5) Include the language from the 008. (or $l)
:       6) Include the type of MARC resource (Text, Audio, etc)
:       7) Concatenate and normalize.  Normalization includes forcing the string to be all lower 
:           case, removing spaces, and removing all special characters.
: 

:   @param  $marcxml        element is the marcxml:datafield  
:   @return bf:authorizedAccessPoint
:)
declare function marcauth2bibframe:generate-hashable(
    $marcxml as element(marcxml:record),
    $mainType as xs:string,
    $types as item()*
    ) as element( bf:authorizedAccessPoint)
{
let $hashableTitle := 
        let $uniform := $marcxml/marcxml:datafield[@tag eq "130"]
        let $primary := $marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]
        let $t := 
            if ($uniform/marcxml:subfield[fn:not(fn:matches(@code,"(g|h|k|l|m|n|o|p|r|s|0|6|8)"))]) then
                (: We have a uniform title that contains /only/ a title and a date of work. :)
                fn:string-join($uniform/marcxml:subfield, " ")
            else
                (:  Otherwise, let's just use the 245 for now.  For example, 
                    we cannot create an uber work for Leaves of Grass. Selections.
                :)
                let $tstr := fn:string-join($primary/marcxml:subfield[@code= "t" or (
                                            fn:not(fn:matches(@code,"(e|0|4|6|8|l)" ) ) and 
                                            preceding-sibling::marcxml:subfield[@code="t"])
                                    ]
                                    ," ")                
                return $tstr
        let $t := marc2bfutils:clean-title-string($t)    
        return $t
    let $hashableNames := 
        (
            let $n := (:fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)") and marcxml:subfield[fn:not(fn:matches(@code,"(e|0|4|6|8)"))]][1]/marcxml:subfield, " "):)
            fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]/marcxml:subfield[fn:not(fn:matches(@code,"(e|0|4|6|8)")) and following-sibling::marcxml:subfield[@code="t"]] , " ")
            return marc2bfutils:clean-name-string($n),
            
            let $n :=(: fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(700|710|711)") and marcxml:subfield[fn:not(fn:matches(@code,"(e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|x|0|3|4|5|6|8)"))]]/marcxml:subfield, " "):)
                    fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(700|710|711)")]/marcxml:subfield[fn:not(fn:matches(@code,"(e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|x|0|3|4|5|6|8)"))], " ")
            return marc2bfutils:clean-name-string($n)
        )
    let $hashableNames := 
        for $n in $hashableNames
        order by $n
        return $n
    let $hashableNames := fn:string-join($hashableNames, " ")
    let $hashableLang := fn:substring-after(marc2bfutils:process-language( fn:string($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]/marcxml:subfield[@code='l']))/@rdf:resource,"languages/") 
                         
    
    let $hashableTypes := fn:concat($mainType, $types[1])
    
    let $hashableStr := fn:concat($hashableNames, " / ", $hashableTitle, " / ", $hashableLang, " / ", $hashableTypes)
    let $hashableStr := fn:replace($hashableStr, "!|\||@|#|\$|%|\^|\*|\(|\)|\{|\}|\[|\]|:|;|'|&amp;quot;|&amp;|<|>|,|\.|\?|~|`|\+|=|_|\-|/|\\| ", "")
    let $hashableStr := fn:replace($hashableStr, '"','')
    let $hashableStr := fn:lower-case($hashableStr)
return 
        element bf:authorizedAccessPoint {
            attribute xml:lang { "x-bf-hash"},
            $hashableStr
        }
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
