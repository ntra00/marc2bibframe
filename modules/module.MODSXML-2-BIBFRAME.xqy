xquery version "1.0-ml";

(:
:   Module Name: Convert MARCXML to MADS/XML
:
:   Module Version: 1.0
:
:   Date: 2015 April 23
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: xdmp (MarkLogic) 
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Converts MODS/XML to Bibframe  
:       At this time, it uses a stylesheet.
:
:)
   
(:~
:   Converts MARC/XML to MADS/XML.  
:   At this time, it uses a stylesheet.
:
:   @author Nate Trail (ntra@loc.gov)
:   @since April 22, 2015
:   @version 1.0
:)

(: NAMESPACES :)
module namespace modsxml2bibframe        =   'info:lc/id-modules/modsxml2bibframe#';

declare namespace marcxml   = "http://www.loc.gov/MARC21/slim";
declare namespace mods      = "http://www.loc.gov/mods/v3";
declare namespace xdmp      = "http://marklogic.com/xdmp";
declare namespace rdf       ="http://www.w3.org/1999/02/22-rdf-syntax-ns#"; 
declare namespace rdfs      ="http://www.w3.org/2000/01/rdf-schema#"; 
declare namespace bf        ="http://bibframe.org/vocab/";

(: FUNCTIONS :)
(:~
:   This is the main function.  Send in MARCXML, get 
:   MADS/XML back.
:
:   @param  $marcxml      as element() is the rdf data
:   @return html div element
:)
declare function modsxml2bibframe:modsxml2bibframe(
    $modsxml as element()
    )
    as element (rdf:RDF) {

    let $modsrdf := xdmp:xslt-invoke("../xsl/MODS2BIBFRAME.xsl", document{ $modsxml } )
    return                            
           $modsrdf/element()
                    
    
    };



