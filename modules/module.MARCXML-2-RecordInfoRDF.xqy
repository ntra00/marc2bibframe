xquery version "1.0";

(:
:   Module Name: MADSRDF For Triplestore
:
:   Module Version: 1.0
:
:   Date: 2010 Feb 17
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Primary purpose is to derive
:       administrative metadata from MARCXML for RDF.  
:
:)
   
(:~
:   Primary purpose is to derive
:   administrative metadata from MARCXML for RDF.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since February 14, 2011
:   @version 1.0
:)
        

(: NAMESPACES :)
module namespace  marcxml2recordinfo    = "info:lc/id-modules/recordInfoRDF#";
declare namespace marcxml               = "http://www.loc.gov/MARC21/slim";
declare namespace rdf                   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace ri                    = "http://id.loc.gov/ontologies/RecordInfo#";


(: FUNCTIONS :)
(:
-------------------------

    Dervives admin metadata from MARCXML, returns RecordInfo RDF:
    
        $marcxml as element() is the MARCXML
100630|| anannbabn          |n ana      </marcxml:controlfield>
00390nz  a2200133n  4500

-------------------------
:)

(:~
:   This is the main function, which expects a boolean 
:   parameter set.  It takes MARCXML and 
:   generates RecordInfo RDF.
:
:   @param  $marcxml        element is the MARCXML  
:   @return ri:RecordInfo node
:)
declare function marcxml2recordinfo:recordInfoFromMARCXML(
        $marcxml as element(marcxml:record), 
        $all as xs:boolean
        ) as element(ri:RecordInfo)* {
    marcxml2recordinfo:marcxml2ri($marcxml, $all)
};

(:~
:   This is the alternate main function, without 
:   a boolean parameter set.  It defaults to "true."
:   It will output a RecordInfo block for every administrative
:   date present in the MARCXMLfor "all".
:
:   @param  $marcxml        element is the MARCXML  
:   @return ri:RecordInfo node
:)
declare function marcxml2recordinfo:recordInfoFromMARCXML(
        $marcxml as element(marcxml:record)
        ) as element(ri:RecordInfo)* {
    marcxml2recordinfo:marcxml2ri($marcxml, fn:true())
};


declare function marcxml2recordinfo:marcxml2ri(
        $marcxml as element(marcxml:record), 
        $all as xs:boolean
        ) as element(ri:RecordInfo)* {

    let $marc001 := fn:replace( $marcxml/marcxml:controlfield[@tag='001'] , ' ', '')
    
    let $marc005 := $marcxml/marcxml:controlfield[@tag='005']
    let $modifiedDT := fn:concat(
                    fn:substring($marc005, 1 , 4),"-",
                    fn:substring($marc005, 5 , 2),"-",
                    fn:substring($marc005, 7 , 2),
                    "T",
                    fn:substring($marc005, 9 , 2),":",
                    fn:substring($marc005, 11 , 2),":",
                    fn:substring($marc005, 13 , 2),""
                    )
    (: 
        altering the xquery type to "1.0-ml" and performing a try/catch 
        will catch an invalid date.  But, what does that do for us?  It's not 
        reported.
        For the time being, I want to catch the errors.  Perhaps the validation is performed 
        *before* it gets to this point, but I want to know how common this is.
        Of 8M records, there was only 1 invalid date.
    :)   
    (:
    let $modifiedDT := 
        try {
            xs:dateTime($modifiedDT)
        } catch ($e) {
            $modifiedDT
        }
    :)
    let $modifiedDT_element :=
        element ri:recordChangeDate { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#dateTime'},
            text {$modifiedDT}
        }
            
    let $marc008 := $marcxml/marcxml:controlfield[@tag='008']
    let $first2digits := fn:substring($marc008 , 1 , 2)
    let $createdYear := 
        if (xs:integer($first2digits) gt 20) then  
            fn:concat('19' , $first2digits)
        else
            fn:concat('20' , $first2digits)
    let $createdDT := fn:concat(
                    $createdYear,"-",
                    fn:substring($marc008, 3 , 2),"-",
                    fn:substring($marc008, 5 , 2),
                    "T00:00:00"
                    )
    (:  changing the property here from ri:recordCreationDate
        to ri:recordChangeDate.  The recordStatus will indicate
        the type of date
    :)
    let $createdDT_element :=
            element ri:recordChangeDate { 
                attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#dateTime'},
                text {$createdDT}
            }
            
    let $createdRecordStatus := "new"  
    let $createdRSElement :=  
        element ri:recordStatus { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#string'},
            text {$createdRecordStatus}
        }
            
    let $leader_pos5 := fn:substring($marcxml/marcxml:leader, 6 , 1)
    let $record_status :=  
        if ($leader_pos5 eq 'd') then
            "deprecated" (: was "deleted" :)
        else if ($leader_pos5 eq 'c') then
            "revised"
        else if ($leader_pos5 eq 'n') then
            "new"
        else if ($leader_pos5 eq 'o') then
            "obsolete"
        else if ($leader_pos5 eq 's') then
            "deleted, replaced by two or more headings"
        else if ($leader_pos5 eq 'x') then
            "deleted, replaced by another"
        else ()
    let $rs_element :=  
        element ri:recordStatus { 
            attribute rdf:datatype {'http://www.w3.org/2001/XMLSchema#string'},
            text {$record_status}
        }
        
    let $marc040a := $marcxml/marcxml:datafield[@tag='040']/marcxml:subfield[@code='a']
	let $marc040a := fn:replace($marc040a,"<>-","")
    let $content_source := 
        if ($marc040a) then
            element ri:recordContentSource { 
                attribute rdf:resource {fn:concat('http://id.loc.gov/vocabulary/organizations/' , fn:lower-case($marc040a))}
            }
        else ()

    let $marc040b := $marcxml/marcxml:datafield[@tag='040']/marcxml:subfield[@code='b']
    let $language_of_cataloging := 
        if ($marc040b) then
            element ri:languageOfCataloging { 
                attribute rdf:resource {fn:concat('http://id.loc.gov/vocabulary/iso639-2/' , fn:lower-case($marc040b))}
            }
        else ()
        
    (: let $lf := fn:codepoints-to-string(10) :) 
    (: 
        The line feeds make validation work.
        There's got to be a better way.
    :)
    let $rdf :=
        (
            if ($all) then
                element ri:RecordInfo {
                    $createdDT_element,
                    $createdRSElement,
                    $content_source,
                    $language_of_cataloging
                }
            else (),
            if ($record_status ne "new") then
                element ri:RecordInfo {
                    $modifiedDT_element,
                    $rs_element,
                    $content_source,
                    $language_of_cataloging
                }
            else ()
        )
         
    return $rdf

};

