xquery version "1.0";
(:
:   Module Name: MARCXML BIB to bibframe
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
:   Module Overview:    Transforms a MARC Bib record
:       into its bibframe parts.  
:
:)
   
(:~
:   Transforms a MARC Bib record
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

module namespace marcbib2bibframe  = 'info:lc/id-modules/marcbib2bibframe#';

(: MODULES :)
import module namespace marcxml2madsrdf = "info:lc/id-modules/marcxml2madsrdf#" at "module.MARCXML-2-MADSRDF.xqy";

import module namespace music = "info:lc/id-modules/marcnotatedmusic2bf#" at "module.MBIB-NotatedMusic-2-BF.xqy";
import module namespace bfdefault = "info:lc/id-modules/marcdefault2bf#" at "module.MBIB-Default-2-BF.xqy";

import module namespace marcerrors  = 'info:lc/id-modules/marcerrors#' at "module.ErrorCodes.xqy";

(: NAMESPACES :)
declare namespace marcxml       	= "http://www.loc.gov/MARC21/slim";
declare namespace rdf           	= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          	= "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            	= "http://bibframe.org/vocab/";
declare namespace madsrdf       	= "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      	= "http://id.loc.gov/vocabulary/relators/";
declare namespace hld              = "http://www.loc.gov/opacxml/holdings/" ;

(: VARIABLES :)
    
(:~
:   This is the main function.  It expects a MARCXML record (with embedded hld:holdings optionally) as input.
:
:   It generates bibframe RDF data as output.
:
:   Modified to allow marcxml:collection with multiple marcxml:records of type bib and holdings as an alternate holdings package
:   calling program (ml.xqy, zorba, saxon) makes a package of each bib record plus it's holdings, so there's only one bib.
:   @param  $collection        element is the top  level (may include marcxml and opac  holdings)
:   @return rdf:RDF as element()
:)
declare function marcbib2bibframe:marcbib2bibframe(
        $collection as element(marcxml:collection),
        $identifier as xs:string
        ) as element(rdf:RDF) 
{   
 for $marcxml in $collection/marcxml:record[fn:not(@type) or @type="Bibliographic"]
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
            
            let $leader:=$marcxml/marcxml:leader
            let $leader6:=fn:substring($leader,7,1)
            let $leader7:=fn:substring($leader,8,1)
		
            let $leader67type:=
                if ($leader6="a") then
                    if (fn:matches($leader7,"(a|c|d|m)")) then
					    "BK"
				    else if (fn:matches($leader7,"(b|i|s)")) then
					    "SE"
				    else ()									
		        else
			        if ($leader6="t") then "BK" 
			        else if ($leader6="p") then "MM"
         		    else if ($leader6="m") then "CF"
         		    else if (fn:matches($leader6,"(e|f|s)")) then "MP"
         		    else if (fn:matches($leader6,"(g|k|o|r)")) then "VM"
         		    else if (fn:matches($leader6,"(c|d|i|j)")) then "MU"
			        else ()
			
            let $musictype:=
                if ($leader67type="MU" and fn:matches($leader6,"(c|d)") ) then "notation" 
                else if (fn:matches($leader6,"(i|j)")) then "audio" 
                else ()

            let $work := 
                if ($musictype = "notation") then
                    music:generate-notatedmusic-work($collection, $about)
                else
                    bfdefault:generate-default-work($collection, $about) 
            
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

declare function marcbib2bibframe:marcbib2bibframe(
        $marcxml as element(marcxml:record)
        ) as element(rdf:RDF) 
{   
    let $identifier := fn:string(fn:current-time())
    let $identifier := fn:replace($identifier, "([:\-]+)", "") 
    return marcbib2bibframe:marcbib2bibframe($marcxml,$identifier)
};
