xquery version "1.0";
(:
:   Module Name: Error checks and codes.
:
:   Module Version: 1.0
:
:   Date: 2014 Oct 3
:
:   Copyright: Public Domain 
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Check MARC/XML for errors before processing.
:
:)
   
(:~
:   Check MARC/XML for errors before processing.
:	
:   @author Kevin Ford (kefo@loc.gov)
:   @author Nate Trail (ntra@loc.gov)
:   @since October 3, 2014
:   @version 1.0
:)
 
module namespace marcerrors  = 'info:lc/id-modules/marcerrors#';


(: NAMESPACES :)
declare namespace marcxml       	= "http://www.loc.gov/MARC21/slim";
declare namespace marcerr       	= "http://www.loc.gov/MARC21/error";

(:~
:   This is the main function.  It expects a MARCXML record as input.
:   It check's it for basic errors.
:
:   @param  $marcxml        element is the marc record
:)
declare function marcerrors:check(
        $marcxml as element(marcxml:record)
        )
{
    if ( fn:not($marcxml/marcxml:leader) ) then
        fn:error(fn:QName('http://www.loc.gov/MARC21/error', 'marcerr:LEADER001'), 'No leader found.')
    
    else if ( fn:not($marcxml/marcxml:controlfield[@tag eq "001"][1]) ) then
        fn:error(fn:QName('http://www.loc.gov/MARC21/error', 'marcerr:CF001001'), 'No 001 found.')
    
    else if ( fn:count($marcxml/marcxml:controlfield[@tag eq "001"]) > 1 ) then
        fn:error(fn:QName('http://www.loc.gov/MARC21/error', 'marcerr:CF001002'), 'Multiple 001s found.')
    
    else
        ()
};