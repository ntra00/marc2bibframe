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
:   @since September 13, 2012
:   @version 1.0
:)

module namespace marcbib2bibframe  = 'info:lc/id-modules/marcbib2bibframe#';

(: MODULES :)
import module namespace marcxml2madsrdf = "info:lc/id-modules/marcxml2madsrdf#" at "module.MARCXML-2-MADSRDF.xqy";
import module namespace marc2bfutils = "info:lc/id-modules/marc2bfutils#" at "module.MARCXMLBIB-BFUtils.xqy";

(: NAMESPACES :)
declare namespace marcxml       	= "http://www.loc.gov/MARC21/slim";
declare namespace rdf           	= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          	= "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            	= "http://bibframe.org/vocab/";
declare namespace madsrdf       	= "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      	= "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   	= "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes  		    = "http://id.loc.gov/vocabulary/notes/";
 declare namespace dcterms	        = "http://purl.org/dc/terms/";
 declare namespace hld              = "http://www.loc.gov/opacxml/holdings/" ;
 declare namespace cnt              = "http://www.w3.org/2011/content#";

(: VARIABLES :)
declare variable $marcbib2bibframe:last-edit :="2013-12-02-T11:00";



(:code=a unless specified:)
declare variable $marcbib2bibframe:identifiers :=
    ( 
    <identifiers>
       
   <vocab-identifiers>     
   	<property name="lccn" label="Library of Congress Control Number" domain="Instance"   marc="010--/a,z"   tag="010"   sfcodes="a,z"/>
	 <property name="nbn" label="National Bibliography Number" domain="Instance"   marc="015--/a,z"   tag="015"   sfcodes="a,z"/>
		 <property name="nban" label="National bibliography agency control number"   domain="Instance"   marc="016--/a,z"   tag="016"   sfcodes="a,z"/>
		 <property name="legalDeposit" label="copyright or legal deposit number"   domain="Instance"   marc="017--/a,z"   tag="017"   sfcodes="a,z"/>
		 <property name="isbn" label="International Standard Bibliographic Number"   domain="Instance"   marc="020--/a,z"   tag="020"   sfcodes="a,z"/>
		 <property name="issn" label="International Standard Serial Number" domain="Instance"   marc="022--/a,z,y"   tag="022"   sfcodes="a,z,y"/>
		 <property name="issnL" label="linking International Standard Serial Number"   domain="Work"   marc="022--/l,m"   tag="022"   sfcodes="l,m"/>
		 <property name="isrc" label="International Standard Recording Code" domain="Instance"   marc="0240-/a,z"   tag="024"   ind1="0"   sfcodes="a,z"/>
		 <property name="upc" label="Universal Product Code" domain="Instance" marc="0241-/a,z"   tag="024"   ind1="1"   sfcodes="a,z" uri="http://www.checkupc.com/search.php?keyword=076714006997"/>
		 <property name="ismn" label="International Standard Music Number" domain="Instance"   marc="0242-/a,z"   tag="024"   ind1="2"   sfcodes="a,z" uri="http://www.loc.gov/ismn/987-10-11110" />
		 <property name="ean" label="International Article Identifier (EAN)" domain="Instance"   marc="0243-/a,z,d(sep by -)"   tag="024"   ind1="3"   sfcodes="a,z,d(sep by -)" uri="http://www.ean-search.org/perl/ean-search.pl?q=5099750442227"/>
		 <property name="sici" label="Serial Item and Contribution Identifier" domain="Instance"   marc="0244-/a,z"   tag="024"   ind1="4"   sfcodes="a,z"/>
		 <property name="various" label="contents of $2"   domain="Instance"   marc="0247-+2'ansi'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <!--<property name="ansi" label="American National Standard Institute Number"   domain="Instance"   marc="0247-+2'ansi'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <property name="iso"   label="International Organization for Standardization standard number"   domain="Instance"   marc="0247-+2'iso'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <property name="local" label="local identifier" domain="Instance"   marc="0247-+2'local'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <property name="uri" label="Uniform Resource Identifier" domain="Instance"   marc="0247-+2'uri'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <property name="urn" label="Uniform Resource Number" domain="Instance"   marc="0247-+2'urn'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>-->
		 <property name="isan" label="International Standard Audiovisual Number" domain="Work"   marc="0247-+2'isan'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>		 
		 <property name="istc" label="International Standard Text Code" domain="Work"   marc="0247-+2'istc'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
		 <property name="iswc" label="International Standard Musical Work Code" domain="Work"   marc="0247-+2'iswc'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>		 
		 <property name="lcOverseasAcq"   label="Library of Congress Overseas Acquisition Program number"   domain="Instance"   marc="025--/a"   tag="025"   sfcodes="a"/>
		 <property name="fingerprint" label="fingerprint identifier" domain="Instance"   marc="026--/e"   tag="026"   sfcodes="e"/>
		 <property name="strn" label="Standard Technical Report Number" domain="Instance"   marc="027--/a,z"   tag="027"   sfcodes="a,z"/>
		 <property name="issueNumber" label="sound recording publisher issue number"   domain="Instance"   marc="0280-/a"   tag="028"   ind1="0"   sfcodes="a"/>
		 <property name="matrixNumber" label="sound recording publisher matrix master number"   domain="Instance"   marc="0281-/a"   tag="028"   ind1="1"   sfcodes="a"/>
		 <property name="musicPlate" label="music publication number assigned by publisher"   domain="Instance"   marc="0282-/a"   tag="028"   ind1="2"   sfcodes="a"/>
		 <property name="musicPublisherNumber" label="other publisher number for music"   domain="Instance"   marc="0283-/a"   tag="028"   ind1="3"   sfcodes="a"/>
		 <property name="videorecordingNumber"   label="publisher assigned videorecording number"   domain="Instance"   marc="0284-/a"   tag="028"   ind1="4"   sfcodes="a"/>
		 <property name="publisherNumber" label="other publisher assigned number"   domain="Instance"   marc="0285-/a"   tag="028"   ind1="5"   sfcodes="a"/>
		 <property name="coden" label="CODEN" domain="Instance" marc="030--/a,z" tag="030"   sfcodes="a,z" uri="http://cassi.cas.org/coden/"/>
		 <property name="postalRegistration" label="postal registration number" domain="Instance"   marc="032--/a"   tag="032"   sfcodes="a"/>
		 <property name="systemNumber" label="system control number" domain="Instance"   marc="035--/a,z"   tag="035"   sfcodes="a,z"/>
		 <!--<property name="oclcNumber" domain="Instance"   marc="035 - - /a,z prefix 'OCOLC'"   tag="035"   sfcodes="a,z"/> -->
		 <property name="studyNumber"   label="original study number assigned by the producer of a computer file"   domain="Instance"   marc="036--/a"   tag="036"   sfcodes="a"/>
		 <property name="stockNumber" label="stock number for acquisition" domain="Instance"   marc="037--/a"   tag="037"   sfcodes="a"/>
		 <property name="reportNumber" label="technical report number" domain="Instance"   marc="088--/a,z"   tag="088"   sfcodes="a,z"/>		 
		 <property name="hdl" label="handle for a resource" domain="Instance"   marc="555;856--/u('hdl' in URI)"   tag="856"   sfcodes="u('hdl' in URI)"/>
		 <!--<property name="isni" label="International Standard Name Identifier" domain="Agent"   marc="authority:0247-+2'isni'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>
		 <property name="orcid" label="Open Researcher and Contributor Identifier" domain="Agent"   marc="authority:0247-+2'orcid'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>
		 <property name="viaf" label="Virtual International Authority File number" domain="Agent"   marc="authority:0247-+2'via,zf'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>-->
             </vocab-identifiers>
    </identifiers>
    );

(:		 <property name="doi" label="Digital Object Identifier" domain="Instance"   marc="856--/u('doi' in URI)"   tag="856"   sfcodes="u" uri="http://www.crossref.org/guestquery/"/>:)
		 
		 
declare variable $marcbib2bibframe:physdesc-list:= 
    (
        <physdesc>
            <instance-physdesc>
                <field tag="300" codes="3" property="materialsSpecified">Materials specified</field>
                <field tag="300" codes="a" property="extent">Physical Description</field>
                <field tag="300" codes="b" property="illustrationNote">Illustrative content note</field>
                <field tag="300" codes="c" property="dimensions">Physical Size</field>
        	   </instance-physdesc>
	           <work-physdesc>	           
	                <field tag="384" codes="a" property="musicKey" > Key </field>
	       </work-physdesc>
        </physdesc>
    );
    
declare variable $marcbib2bibframe:notes-list:= (
<notes>
	<work-notes>
		<note tag ="245" property="contentType" sfcodes="k">Nature of content</note>
		<note tag ="306" property="duration" sfcodes="a">Playing time</note>		
		<note tag ="310" property="frequency" sfcodes="a">Issue frequency</note>
		<note tag ="336" property="contentType" sfcodes="a">Nature of content</note>
		<note tag ="500" sfcodes="3a" property="note">General Note</note>		
		<!-- <note tag ="502" property="dissertationNote" domain="Dissertation">Dissertation Note</note>-->		
		<note tag ="505" property="contents" ind2=" " sfcodes="agrtu" >Formatted Contents Note</note>
		<note tag ="513" property="contentType" sfcodes="a">Nature of content</note>		
		<note tag ="513" property="temporalCoverageNote" sfcodes="b">Period Covered Note</note>
		<!--<note tag ="514" property="dataQuality">Data Quality Note</note> -->
		<note tag ="516" property="contentType" sfcodes="a">Type of Computer File or Data Note</note>		
		<note tag ="518" property="contentCoverage" sfcodes="a" >Date/Time and Place of an Event Note</note>
		<!-- has its own function<note tag ="521" property="targetAudience">Target Audience Note</note>-->
		<note tag ="522" property="geographicCoverageNote">Geographic Coverage Note</note>
		<note tag ="525" property="supplementaryContentNote" sfcodes="a" >Supplement Note</note>		
		<!-- <note tag ="526" property="studyProgram">Study Program Information Note</note>-->
		<note tag ="530" comment="WORK, but needs to be reworked to be an instance or to match with an instance (Delsey - Manifestation)" property="otherPhysicalFormat">Additional Physical Form Available Note </note>
<!-- moved to relateds;			<note tag ="533"  comment="(develop link) (Delsey - Manifestation)" property="reproduction">Reproduction Note</note>
 		<note tag ="534" comment="(develop link)(Delsey - Manifestation)" sfcodes="b" property="originalVersion">Original Version Note</note>-->
		<note tag ="535" property="originalLocation">Location of Originals/Duplicates Note</note>
		<note tag ="536" property="funding">Funding Information Note</note>		
		<note tag ="544" sfcodes="3dea" comment="(develop link?)" property="archiveLocation">Location of Other Archival Materials Note</note>
		<note tag ="545"  comment ="annotation to name???" property="biographicalHistoricalNote">Biographical or Historical Data</note>
		<note tag ="547" property="formerTitleComplexity">Former Title Complexity Note</note>
		<note tag ="552" property="entityInformation">Entity and Attribute Information Note</note>
	<!--	<note tag ="555" comment="(link?)" property="index">Cumulative Index/Finding Aids Note </note>-->
		<note tag ="565" property="caseFile">Case File Characteristics Note</note>
		<note tag ="567" property="methodology">Methodology Note</note>
		<note tag ="580" property="linkingEntryComplexity">Linking Entry Complexity Note</note>
		<note tag ="581" property="publicationAbout" sfcodes="3a" startswith="Publications about: ">Publications About Described Materials Note</note>
		<note tag ="586" property="awardNote" sfcodes="3a">Awards Note</note>
		(:<note tag ="588" comment="(actually Annotation? Admin?)" property="source" >Source of Description Note </note>:)
	
	</work-notes>
	<instance-notes>	
		<note tag ="300" property="illustrationNote" sfcodes="b">Illustrative content note</note>
		<note tag ="500" sfcodes="3a" property="note">General Note</note>
		<note tag ="501" property="with" sfcodes="a">With Note</note>
		<note tag ="504" property="supplementaryContentNote" startwith=". References: " comment="525a,504--/a+b(precede info in b with References:" sfcodes="ab">Supplementary content note</note>
		<note tag ="506" property="restrictionsOnAccess">Restrictions on Access Note</note>
		<note tag ="507" property="graphicScaleNote" sfcodes="a" >Scale Note for Graphic Material</note>
		<note tag ="508" property="creditsNote" startwith="Credits: "  comment="precede text with 'Credits:'" >Creation/Production Credits Note </note>
		<note tag ="511" property="performerNote" comment="precede text with 'Cast:'" startwith="Cast: ">Participant or Performer Note </note>
		<note tag ="515" property="note">Numbering Peculiarities Note </note>
		<note tag ="524" property="preferredCitation">Preferred Citation of Described Materials Note</note>
		<note tag ="538" property="systemDetails">System Details Note</note>
		<note tag ="540" comment="(Delsey - Manifestation)" property="useAndReproduction">Terms Governing Use and Reproduction Note </note>
		<note tag ="541" sfcodes="cad" property="immediateAcquisition">Immediate Source of Acquisition Note</note>
		<note tag ="542" property="copyrightStatus">Information Relating to Copyright Status</note>
		<note tag ="546" property="languageNote" sfcodes="3a" >Language Note</note>
		<note tag ="546" property="notation" sfcodes="b" >Language Notation(script)</note>
		<note tag ="550" property="issuers">Issuing Body Note</note>
		<note tag ="556" property="documentation">Information about Documentation Note</note>
		<note tag ="561" property="custodialHistory">Ownership and Custodial History</note>
		<note tag ="562" property="versionIdentification">Copy and Version Identification Note</note>
		<note tag ="563" property="binding">Binding Information</note>
		<note tag ="583" comment="annotation later?" property="exhibitions">Action Note</note>
		<note tag ="584" property="useFrequency">Accumulation and Frequency of Use Note</note>
		<note tag ="585" property="exhibitions">Exhibitions Note</note>	
	</instance-notes>
</notes>
);

(:$related fields must have $t except 510 630,730,830 , 767? 740 ($a is title),  :)
declare variable $marcbib2bibframe:relationships := 
(
    <relationships>
        <!-- Work to Work relationships -->
        <work-relateds all-tags="()">
            <type tag="(700|710|711|720)" ind2="2" property="contains">isIncludedIn</type>
            
            <type tag="(700|710|711|720)" ind2="( |0|1)" property="relatedResource">relatedWork</type>        		                        
            <type tag="740" ind2=" " property="relatedWork">relatedWork</type>
		    <type tag="740" ind2="2" property="contains">isContainedIn</type>
		    <type tag="760" property="subseriesOf">hasParts</type>	
		    <type tag="762" property="subseries">hasParts</type>	
		    <type tag="765" property="translationOf">hasTranslation</type>
		    <type tag="767" property="translation">translationOf</type>
		    <type tag="770" property="supplement">supplement</type>
		    <type tag="772" ind2=" " property="supplementTo">isSupplemented</type>		    	
		   <!-- <type tag="772" ind2="0" property="memberOf">host</type>-->
		    <type tag="773" property="containedIn">hasConstituent</type>
		    <type tag="775" property="otherEdition" >hasOtherEdition</type>
		    <type tag="776" property="otherPhysicalFormat">hasOtherPhysicalFormat</type>
		   
		   <type tag="777" property="issuedWith">issuedWith</type>
		   <!--???the generic preceeding and succeeding may not be here -->
		    <type tag="780" ind2="0" property="continues">continuationOf</type>		    
		    <type tag="780" ind2="1" property="continuesInPart">partiallyContinuedBy</type>
		    <type tag="780" ind2="2" property="supersedes">continuationOf</type>
		    <type tag="780" ind2="3" property="supersedesInPartBy">partiallyContinuedBy</type>
		    <type tag="780" ind2="4" property="unionOf">preceding</type>
		    <type tag="780" ind2="5" property="absorbedBy">isAbsorbedBy</type>
		    <type tag="780" ind2="6" property="absorbedInPartBy">isPartlyAbsorbedBy</type>
		    <type tag="780" ind2="7" property="separatedFrom">formerlyIncluded</type>				   
		    <type tag="785" ind2="0"  property="continuedBy">continues</type>
		    <type tag="785" ind2="1" property="continuedInPartBy">partiallyContinues</type>	
		    <type tag="785" ind2="2"  property="supersededBy">continues</type>
		    <type tag="785" ind2="3" property="supersededInPartBy">partiallyContinues</type>
		    <type tag="785" ind2="4" property="absorbedBy">absorbs</type>
		    <type tag="785" ind2="5"  property="absorbedInPartBy">partiallyAbsorbs</type>
		    <type tag="785" ind2="6"  property="splitInto">splitFrom</type>
		    <type tag="785" ind2="7"  property="mergedToForm">mergedFrom</type>	
    		<!--<type tag="785" ind2="8"  property="changedBackTo">formerlyNamed</type> -->
    	<type tag="785" ind2="8"  property="succeeds">formerlyNamed</type>
		    <type tag="786" property="dataSource"></type>
		    <type tag="533" property="reproduction"></type>
		    <type tag="534" property="originalVersion"></type>
    		<type tag="787" property="relatedResource">relatedItem</type>					  	    	  	   
	  	    <!--<type tag="490" ind1="0" property="inSeries">hasParts</type>-->
	  	    <type tag="510" property="describedIn">isReferencedBy</type>
	  	    <type tag="630"  property="subject">isSubjectOf</type>
	  	    <type tag="(400|410|411|440|490|760|800|810|811|830)" property="series">hasParts</type>
            <type tag="730" property="relatedWork">relatedItem</type>             
        </work-relateds>
        <!-- Instance to Work relationships (none!) -->
	  	<instance-relateds>
	  	  (:<type tag="6d30"  property="subject">isSubjectOf</type>:)
	  	  <type tag="776" property="otherPhysicalFormat">hasOtherPhysicalFormat</type>
	  	</instance-relateds>
	</relationships>
);

(:~
:   This is the main function.  It expects a MARCXML record (with embedded hld:holdings optionally) as input.
:   It generates bibframe RDF data as output.
:
:   @param  $marcxml        element is the top  level (may include marcxml and holdings)
:   @return rdf:RDF as element()
:)
declare function marcbib2bibframe:marcbib2bibframe(
        $marcxml as element(marcxml:record),
        $identifier as xs:string
        ) as element(rdf:RDF) 
{   

    let $about := 
        if ($identifier eq "") then
            ()
        else if ( fn:not( fn:starts-with($identifier, "http://") ) ) then
            attribute rdf:about { fn:concat("http://id/test/" , $identifier) }
        else
            attribute rdf:about { $identifier }

    return
        if ($marcxml/marcxml:leader) then
            let $work := marcbib2bibframe:generate-work($marcxml, $about) 
            
            return
                element rdf:RDF {  
                (:comment { fn:concat("last edited: ",$marcbib2bibframe:last-edit)},:)                
                    $work               
                }
        else
            element rdf:RDF {
            	 (:comment {element dcterms:modified {$marcbib2bibframe:last-edit}},:)
            	
                comment {"No leader - invalid MARC/XML input"}                
            }
};

declare function marcbib2bibframe:marcbib2bibframe(
        $marcxml as element(marcxml:record)
        ) as element(rdf:RDF) 
{   
    let $identifier := fn:string(fn:current-time())
    let $identifier := fn:replace($identifier, "([:\-]+)", "") 
    return marcbib2bibframe:marcbib2bibframe($marcxml,$identifier)
};

(:~
:   This is the function generates instance resources.
:
:   @param  $d        element is the MARCXML 260   
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-instance-from260(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element () 
{

    let $derivedFrom := 
        element bf:derivedFrom {
            attribute rdf:resource {
                fn:concat(
                    "http://id.loc.gov/resources/bibs/",
                    fn:string($d/../marcxml:controlfield[@tag eq "001"])
                 )
            }
        }
        
    
    let $instance-title := 
        for $titles in $d/../marcxml:datafield[fn:matches(@tag,"(245|246|222|242|210)")]
            for $t in $titles
            return marcbib2bibframe:get-title($t)
    
    let $names := 
        for $datafield in $d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag,"(700|710|711|720)")][fn:not(marcxml:subfield[@code="t"])]                    
        return marcbib2bibframe:get-name($datafield)
        
        
    let $edition := 
     for $e in $d/../marcxml:datafield[@tag eq "250"][1]
        (:$a may have stripable punctuation:)
        return (element bf:edition {marc2bfutils:clean-string($e/marcxml:subfield[@code="a"])},        
                if ($e/marcxml:subfield[@code="b"]) then element bf:editionResponsibility {fn:string($e/marcxml:subfield[@code="b"])}
                else ()
                )
    let $edition-instances:= 
    for $e in $d/../marcxml:datafield[@tag eq "250"][fn:not(1)]
        return 
            element relatedInstance {
                element Instance {
                   $instance-title,
                    $derivedFrom    ,            
                    (element bf:edition {marc2bfutils:clean-string($e/marcxml:subfield[@code="a"])},        
                        if ($e/marcxml:subfield[@code="b"]) then element bf:editionResponsibility {fn:string($e/marcxml:subfield[@code="b"])}
                        else ()
                    )
                }
            }
                
    let $publication:= 
            if (fn:matches($d/@tag, "(260|264)")) then marcbib2bibframe:generate-publication($d)
            else if (fn:matches($d/@tag, "(261|262)")) then marcbib2bibframe:generate-26x-pub($d)
            else ()
    

    let $physMapData := 
        (
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "a"]   
            return element bf:cartographicScale {
            		if (fn:string($i)="a") then "Linear scale" 
            		else if (fn:string($i)="b") then "Angular scale" else if (fn:string($i)="z") then "Other scale type" else "invalid"
            		},
	for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "b" or @code eq "c"]  
            	return element bf:cartographicScale { fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "a"]
            return element bf:cartographicScale {fn:string($i)},
                       
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "b"]
            return element bf:cartographicProjection {fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "c"]
            return element bf:cartographicCoordinates  {fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "d" or @code eq "e" or @code eq "f" or @code eq "g"]  
            return element bf:cartographicCoordinates {fn:string($i)}
        ) 
let             $physBookData:=()
let $physSerialData:=()
let $physResourceData:=()
            (:this is not right yet  :)        
    let $leader:=fn:string($d/../marcxml:leader)
    let $leader7:=fn:substring($leader,8,1)
	let $leader19:=fn:substring($leader,20,1)
 let $issuance:=
           	if (fn:matches($leader7,"(a|c|d|m)")) 		then "Monographic"
           	else if ($leader7="b") 						then "Continuing"
           	else if ($leader7="m" and  fn:matches($leader19,"(a|b|c)")) 	then "Multipart"
           	else if ($leader7='m' and $leader19='#') 				then "SingleUnit"
           	else if ($leader7='i') 						           	then "IntegratingResource"
           	else if ($leader7='s')           						then "Serial"
           	else ()
     let $issuance := 
                if ($issuance) then 
                   element rdf:type {   attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" ,$issuance)}}                  
                else ()
      (:instance subclasses are tactile, manuscript, modes of issuance
      Replaces instanceType:)
      
    let $instanceType :=         
        if ( fn:count($physBookData) gt 0 ) then
            "PhysicalBook"
        else if ( fn:count($physMapData) gt 0 ) then
            "PhysicalMap"
        else if ( fn:count($physSerialData) gt 0 ) then
            "Serial"
        else if ( fn:count($physResourceData) > 0 ) then
            "PhysicalResource"
        else 
            ""
      let $holdings := marcbib2bibframe:generate-holdings($d/ancestor::marcxml:record, $workID)
 
    let $instance-identifiers :=
             (                       
            marcbib2bibframe:generate-identifiers($d/ancestor::marcxml:record,"Instance")    
        )
            
    (: all relationships at work level:)
     
    let $notes := marcbib2bibframe:generate-notes($d/ancestor::marcxml:record,"instance")
    let $physdesc := marcbib2bibframe:generate-physdesc($d/ancestor::marcxml:record,"instance")
  
    return 
        element bf:Instance {        
           $issuance,
            if ($instanceType ne "") then
                element rdf:type {
                    attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" , $instanceType) }
                }
            else
                (),               
            $instance-title,            
            $names,
            $edition,
            $publication,          
            $physResourceData,  (: ??? work on this:)         
            $physMapData,
            $physSerialData,            
            $instance-identifiers,               
            $physdesc,
            element bf:instanceOf {
                attribute rdf:resource {$workID}
                },
            $notes,        
            $derivedFrom,
            $holdings
        }
};


(:~
:   This is the function generates other language authlabel or label from associated 880s
:	name, subject, title, authlabel; others: label
:	if $6 on any tag =880-##, then go looking for the matching 880
:   Will there ever only be one 880 per other field?  Should this loop?
:	
:   @param  $datafield        element is the tag that may have an 880
:	@param 	$node-name		  string is the type of datafield, name, subject, title 
:   @return bf:* as element()
:	
:)
declare function marcbib2bibframe:generate-880-label
    (
        $d as element(marcxml:datafield), 
        $node-name as xs:string
    ) as element ()*
{

    if (fn:starts-with($d/marcxml:subfield[@code="6"],"880")) then
    
        let $hit-num := fn:substring(fn:tokenize($d/marcxml:subfield[@code="6"],'-')[2],1,2)
        
        let $lang := fn:substring(fn:string($d/../marcxml:controlfield[@tag="008"]), 36, 3)     
      	
        let $this-tag:= fn:string($d/@tag)
        let $hit-num:=fn:tokenize($d/marcxml:subfield[@code="6"],"-")[2]			
        let $match:=$d/../marcxml:datafield[@tag="880" and fn:starts-with(marcxml:subfield[@code="6"] , fn:concat($this-tag ,"-", $hit-num ))]
	
	let $scr := fn:tokenize($match/marcxml:subfield[@code="6"],"/")[2]
    let $xmllang:= marcbib2bibframe:generate-xml-lang($scr, $lang)
(:        let $script:=
	       if ($scr="(3" ) then "arab"
	       else if ($scr="(B" ) then "latn"
	       else if ($scr="$1"  and $lang="kor" ) then "hang"
	       else if ($scr="$1"  and $lang="chi" ) then "hani"
	       else if ($scr="$1"  and $lang="jpn" ) then "jpan"	       
	       else if ($scr="(N" ) then "cyrl"
	       else if ($scr="(S" ) then "grek"
	       else if ($scr="(2" ) then "hebr"
	       else ()
	       
        let $xmllang:= if ($script) then fn:concat($lang,"-",$script) else $lang
        :)
        return 
            if ($node-name="name") then
                element bf:authorizedAccessPoint {
                    attribute xml:lang {$xmllang},
                    
                     if ($d/@tag!="534") then   
                    marc2bfutils:clean-string(fn:string-join($match/marcxml:subfield[@code="a" or @code="b" or @code="c" or @code="d" or @code="q"] , " "))
                    else
                    marc2bfutils:clean-string($match/marcxml:subfield[@code="a"])
                }
            else if ($node-name="title") then 
                let $subfs := 
                    if ( fn:matches($d/@tag, "(245|242|243|246|490|510|630|730|740|830)") ) then
                        "(a|b|f|h|k|n|p)"
                    else
                        "(t|f|k|m|n|p|s)"
                return
                    element bf:authorizedAccessPoint {
                        attribute xml:lang {$xmllang},   
                        
                        (: marc2bfutils:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,"(a|b)")] ," "),"^(.+)/$","$1")) :)
                        marc2bfutils:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,$subfs)] ," "),"^(.+)/$","$1"))
                    }
            else if ($node-name="subject") then 
                element bf:authorizedAccessPoint{
	                   attribute xml:lang {$xmllang},   
                        marc2bfutils:clean-string(fn:string-join($match/marcxml:subfield[fn:not(@code="6")], " "))
                }
            else if ($node-name="place") then 
                for $sf in $match/marcxml:subfield[@code="a"]
                return
                    element  bf:providerPlace {
                        element bf:Place {
                            element bf:label { attribute xml:lang {$xmllang},
                                    marc2bfutils:clean-string(fn:string($sf))
                            }
                        }
                    }
	else if ($node-name="provider") then 
                for $sf in $match/marcxml:subfield[@code="b"]
                return
                    element bf:providerName {
                      element bf:Organization {
                            element bf:label {
                                attribute xml:lang {$xmllang},   			
                                marc2bfutils:clean-string(fn:string($sf))
                            }
                        }
                    }
            else 
                element { fn:concat("bf:",$node-name)} {
                    fn:string($match/marcxml:subfield[@code="a"])					
				}				
	else ()
	
};


(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a,y,z,m,l,2,b,q
:
::   @param  $marcxml       element is the marcxml record
:   @param  $resource      string is the "work" or "instance"
: skip isbn; do it on generate-instance from isbn, since it's a splitter and yo udon't want multiple per instance
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-identifiers(
   $marcxml as element(marcxml:record),
    $resource as xs:string
    ) as element ()*
{
    let $identifiers:= 
        if ($resource="Instance") then 
            $marcbib2bibframe:identifiers//vocab-identifiers/property[@domain=$resource][fn:not(@tag="020")]
        else 
            $marcbib2bibframe:identifiers//vocab-identifiers/property[@domain=$resource]
    
    let $bfIdentifiers := 
       (     for $id in $identifiers[fn:not(@ind1)][@domain=$resource] (:all but 024 and 028:)                        	 
               	return
               	for $this-tag in $marcxml/marcxml:datafield[@tag eq $id/@tag] (:for each matching marc datafield:)          		
                			(:if contains subprops, build class for $a else just prop w/$a:)
            	    	(:first, deal with the $a):) 
                   		return 
                   		if ( $this-tag/marcxml:subfield[fn:matches(@code,"(b|q|2)")] or                    		
		                        (:($this-tag/@tag="020" and fn:contains(fn:string($this-tag/marcxml:subfield[@code="a"]),"(")  )   or:)			
		                        ($this-tag[@tag="037"][marcxml:subfield[@code="c"]]) 				
					           ) then 
		                        element bf:Identifier{
		                            element bf:identifierScheme {				 
		                                fn:string($id/@name)
		                            },	                            
		                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
		                            	return element bf:identifierAssigner {        	fn:string($sub)},
		
		                            for $sub in $this-tag/marcxml:subfield[@code="q" ]
		                            	return element bf:identifierQualifier {fn:string($sub)},
	                            (: 
	                                kefo - 1 march
	                                ALERT - I had to insert [1] to get this to work in a crunch.
	                                BUT this needs to be modified.
	                                ntra:?? 020$a is Not repeatable should not need [1]!!
	                            :)
		                            element bf:identifierValue { 
		                                if ($this-tag[@tag="020"]/marcxml:subfield[@code="a"]) then
		                                    fn:substring-before($this-tag[@tag="020"]/marcxml:subfield[@code="a"],"(" )					
		                                else
		                                    fn:string($this-tag/marcxml:subfield[@code="a"][1])
		                            }
	                        	}
	                    	else 	(: not    @code,"(b|q|2):)                
	                        (
	                           if ( $this-tag[@tag="010"]/marcxml:subfield[@code="a"] ) then
	                      	      element bf:lccn {    
	                            		attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/identifiers/lccn/",fn:replace(fn:string($this-tag[@tag="010"]/marcxml:subfield[@code="a"])," ",""))}                                         
	                            }
			                   else  if ( $this-tag[@tag="030"]/marcxml:subfield[@code="a"] ) then
	                            	element bf:coden {    
	                            		attribute rdf:resource {fn:concat("http://cassi.cas.org/coden/",fn:normalize-space(fn:string($this-tag[@tag="030"]/marcxml:subfield[@code="a"])))}                                         
	                            	}		
	                        else if ( fn:contains(fn:string($this-tag[@tag="035"]/marcxml:subfield[@code="a"]), "(OCoLC)" ) ) then
                                let $iStr := marc2bfutils:clean-string(fn:replace(fn:string($this-tag[@tag="035"]/marcxml:subfield[@code="a"]), "\(OCoLC\)", ""))
                                return 
                                (
                                    (:element bf:oclcNumber { $iStr },:)
                                    element bf:systemNumber {  
                                        attribute rdf:resource {fn:concat("http://www.worldcat.org/oclc/",fn:replace($iStr, "[a-z]",""))}
                                    }
	                            )
        	
	                        else if (fn:contains(fn:string-join($this-tag[fn:matches(@tag,"(856|859)")]/marcxml:subfield[@code="u"],""),"doi") ) then
	                        	for $doi in $this-tag[fn:matches(@tag,"(856|859)")]/marcxml:subfield[@code="u"][fn:contains(.,"doi")]
	                            		return element bf:doi {        fn:normalize-space( fn:string($doi))                        }
	                        else if (fn:contains(fn:string-join($this-tag[fn:matches(@tag,"(856|859)")]/marcxml:subfield[@code="u"],""),"hdl" ) ) then
	                        	for $hdl in $this-tag[fn:matches(@tag,"(856|859)")]/marcxml:subfield[@code="u"][fn:contains(.,"hdl")]
	                            		return element bf:hdl {fn:normalize-space( fn:string($hdl))           }
	                        else  
	                            for $sub in $this-tag/marcxml:subfield[@code="a"]
	                                   return element { fn:concat("bf:",$id/@name) } {
	                                       fn:string($sub)
	                              }	                         
                          	,
	                        
	                    (:then deal with the z's:)
		           if ( $this-tag/marcxml:subfield[fn:matches(@code,"(y|z)")]) then
	                            for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"(y|z)")]     
		                            return
		                                element bf:Identifier {
		                                    element bf:identifierScheme { fn:string($id/@name) },
		                                    marcbib2bibframe:handle-cancels($this-tag, $sf)
		                                }
		           else ()	           
			) )(: END OF not    @code,"(b|q|2), end of tags matching ids without @ind1:)
               
               (:----------------------------------------   024 and 028 , where ind1 counts----------------------------------------:)
let $id024-028:=
          for $this-tag at $x in $marcxml/marcxml:datafield[fn:matches(@tag,"(024|028)")]
                    return
                    	let $this-id:= $identifiers[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1] (: i1=7 has several ?:)   	       	  
                    	return
                        if ($this-id) then(: if there are any 024s on this record in this domain (work/instance):) 
                            let $scheme:=   	       	  	
                                if ($this-tag/@ind1="7") then (:use the contents of $2 for the name: :)
                                    fn:string($this-tag[@ind1=$this-id/@ind1]/marcxml:subfield[@code="2"])
                                else (:use the $id name:)
                                    fn:string($this-id[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1]/@name)
                            
                            (:if  024 has a c, it's qualified, needs a class  else just prop w/$a:)
                            return
                            if ( fn:contains(fn:string($this-tag/marcxml:subfield[@code="c"]), "(") or 
                                $this-tag/marcxml:subfield[@code="q"] or 
			                     $this-tag/marcxml:subfield[@code="b"]
			                 ) then	
	                                element bf:Identifier{
	                                    element bf:identifierScheme {$scheme},		
	                            
	                                    for $sub in $this-tag/marcxml:subfield[@code="b"] 
	                                       return element bf:identifierAssigner{fn:string($sub)},
	        
	                                    for $sub in $this-tag[fn:contains(fn:string(marcxml:subfield[@code="c"]),"(") ]
	                                       return element bf:identifierQualifier {fn:replace(fn:substring-after($sub,"(" ),"\)","")},
	        
	                                    for $sub in $this-tag/marcxml:subfield[@code="q"] 
	                                       return element bf:identifierQualifier {fn:string($sub)},
	            
	                                    element bf:identifierValue {
	                                        fn:string($this-tag/marcxml:subfield[@code="a"]),						
	                                        if ($this-tag/marcxml:subfield[@code="d"] ) then
	                                            fn:concat("-",fn:string($this-tag/marcxml:subfield[@code="d"]))
	                                        else
					            ()
				  }
	                                }	
                            else (:not c,q,b:)
                                let $property:= (:024 had a z only; no $a: bibid;17332794:)
                                    if ($this-tag/@ind1="7") then
                                       (:"bf:identifier":)
                                       fn:concat("bf:", $scheme)
                                       (:fn:string($this-tag[@ind1=$this-id/@ind1]/marcxml:subfield[@code="2"]):)								
                                    else
                                        fn:concat("bf:",fn:string($this-id/@name))					
                                return
                                    (if ( $this-tag/marcxml:subfield[fn:matches(@code,"a")]) then
                                        element {$property} {		                                                                                        	
                                           			fn:normalize-space(fn:string($this-tag/marcxml:subfield[@code="a"]))
                                                                                      
                                        }
                                        else ()
                                        ,
                                      
                                        (:then deal with the z's:)
                                        if ( $this-tag/marcxml:subfield[fn:matches(@code,"z")]) then
                                            for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"z")]
                                            return          
                                                element bf:Identifier{
                                                    element bf:identifierScheme {$scheme},		
                                                    marcbib2bibframe:handle-cancels($this-tag, $sf)
                                                }
                                        else ()
                                    )
                        else ()         (:end 024:)

	return  
     	   for $bfi in ($bfIdentifiers,$id024-028)
        		return 
		            if (fn:name($bfi) eq "bf:Identifier") then
		                element bf:identifier {$bfi}
		            else
		                $bfi
};
(:~
:   This is the function that handles $0 in various fields
:   @param  $sys-num       element is the marc subfield $0
     
:   @return  element() either bf:systemNumber or bf:hasAuthority with uri
:)
declare function marcbib2bibframe:handle-system-number( $sys-num   ) 
{
 if (fn:starts-with(fn:normalize-space($sys-num),"(DE-588")) then
                                    let $id:=fn:normalize-space(fn:tokenize(fn:string($sys-num),"\)")[2] )
                                    return element bf:hasAuthority {attribute rdf:resource{fn:concat("http://d-nb.info/gnd/",$id)} }
                                else
                                    element bf:systemNumber {fn:string($sys-num)}
};
(:~
:   This is the function generates full Identifier classes from m,y,z cancel/invalid identifiers and qualifiers
:   @param  $this-tag       element is the marc data field
:   @param  $sf             subfield element     
:   @return bf:Identifier as element()
:)
declare function marcbib2bibframe:handle-cancels($this-tag, $sf) 
{

   
    if ($this-tag[@tag="022"] and $sf[@code="y"]) then
        (
            element bf:identifierValue { fn:normalize-space(fn:string($sf))},
            element bf:identifierStatus{"incorrect"}
        )
    else if ($this-tag[@tag="022"] and $sf[@code="z"]) then 
        (
            element bf:identifierValue { fn:normalize-space(fn:string($sf))},
            element bf:identifierStatus{"canceled/invalid"}
        ) 
    else if ($this-tag[@tag="022"] and $sf[@code="m"]) then
        (
            element bf:identifierValue { fn:normalize-space(fn:string($sf))},
            element bf:identifierStatus {"canceled/invalid"}
        ) 
    else if ($this-tag[fn:matches(@tag,"(010|015|016|017|020|027|030|024|088)")] and $sf[@code="z"] ) then
        (
            element bf:identifierValue { fn:normalize-space(fn:string($sf))},
            element bf:identifierStatus{"canceled/invalid"}
        ) 
    else
        ()
            
};
(:~
:   This is the function generates publication  data for 261, 262 
:

:)
declare function marcbib2bibframe:generate-26x-pub
    (
           $d as element(marcxml:datafield) 
    ) as element ()*
{
    
   (: 261  $f is place $a is producer name,    $d is date,
    262 is $a place, $b publisher $c date.:)
 
  element bf:publication {
            element bf:Provider {	
                for $pub in $d[@tag="261"]/marcxml:subfield[@code="a"][1] |
                    $d[@tag="262"]/marcxml:subfield[@code="b"][1]
	                 return              
	                    element bf:providerName {
	                    element bf:Organization {
	                       element bf:label {marc2bfutils:clean-string(fn:string($pub))}
	                       }
	                    }
	             ,
	             for $pub in $d[@tag="261"]/marcxml:subfield[@code="f"][1] |
                    $d[@tag="262"]/marcxml:subfield[@code="a"][1]
	                 return              
	                    element bf:providerPlace {element bf:Place {
	                       element bf:label {
	                           marc2bfutils:clean-string(fn:string($pub))}
                            }
                        }
	                   ,
	            for $pub in $d[@tag="261"]/marcxml:subfield[@code="d"][1] |
                    $d[@tag="262"]/marcxml:subfield[@code="c"][1]
	                 return              
	                    element bf:providerDate {marc2bfutils:clean-string(fn:string($pub))}	                    	                  
	       }
	     }
	};
(:~
:   This is the function generates publication  data for instance 
:	Returns bf: node of elname 
: abc are repeatable!!! each repetition of b or c is another publication; should it be another instance????
abc and def are parallel, so a and d are treated the same, etc, except the starting property name publication vs manufacture
:   @param  $d       element is the datafield 260 or 264 
:   @param  $resource      string is the "work" or "instance"
:   @return bf:* 	   element()


!!! work on 880s in 260abc, def
:)
declare function marcbib2bibframe:generate-publication
    (
        $d as element(marcxml:datafield)        
    ) as element ()*
{ (:first handle abc, for each b, set up a publication with any associated A's and Cs:)
    if ($d/marcxml:subfield[@code="b"]) then
    
        for $pub at $x in $d/marcxml:subfield[@code="b"]
	        let $propname :=  
	           if ($d/@tag="264" and $d/@ind2="3" ) then
	               "bf:manufacture"
	           else
	                "bf:publication"
	            
                            
	        return 
	            element {$propname} {
	                element bf:Provider {
	                 (: 
                            k-note: added call to clean-str here.  
                            We'll need to figure out where this is and 
                            isn't a problem
                        :)
	                    element bf:providerName {
	                       element bf:Organization {
	                           element bf:label {
	                       marc2bfutils:clean-string(fn:string($pub))}
	                       }
	                    },
	                    marcbib2bibframe:generate-880-label($d,"provider") ,
	                    if ( $d/marcxml:subfield[@code="a"][$x]) then
	                        (element bf:providerPlace {
	                           element bf:Place {
	                               element bf:label {
	                                   marc2bfutils:clean-string($d/marcxml:subfield[@code="a"][$x])}
	                           }
                           },
	                         marcbib2bibframe:generate-880-label($d,"place") )
	                          
	                    else (),
	                    if ($d/marcxml:subfield[@code="c"][$x] and fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") ) then (:\D filters out "c" and other non-digits, but also ?, so switch to clean-string for now. may want "clean-date??:)
	                        element bf:copyrightDate {marc2bfutils:clean-string($d/marcxml:subfield[@code="c"][$x])}
	                    else if ($d/marcxml:subfield[@code="c"][$x] and fn:not(fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") )) then
	                        element bf:providerDate {marc2bfutils:clean-string($d/marcxml:subfield[@code="c"][$x])}                 
	                    else ()
	                }
		}   
		(:there is no $b:)
        else if ($d/marcxml:subfield[fn:matches(@code,"(a|c)")]) then	
	            element bf:publication {
	                element bf:Provider {
	                    for $pl in $d/marcxml:subfield[@code="a"]
	                    return (element bf:providerPlace {
	                                   element bf:Place {
	                                       element bf:label {fn:string($pl)}
	                                   }
	                               },
	                    		     marcbib2bibframe:generate-880-label($d,"place")  ),
	                    for $pl in $d/marcxml:subfield[@code="c"]
	                    	return 
	                        if (fn:starts-with($pl,"c")) then				
				       element bf:providerDate {marc2bfutils:clean-string($pl)}
	                        else 
				       element bf:copyrightDate {marc2bfutils:clean-string($pl)}		
		      }
	        }
        (:handle $d,e,f like abc :)
        else if ($d/marcxml:subfield[@code="e"]) then
        for $pub at $x in $d/marcxml:subfield[@code="e"]
	        let $propname := "bf:manufacture"   
	        return 
	            element {$propname} {
	                element bf:Provider {
	                    element bf:providerName {
	                        element bf:Organization {
	                           element bf:label {  
	                               marc2bfutils:clean-string(fn:string($pub))}
	                           }
	                           },
	                    marcbib2bibframe:generate-880-label($d,"provider") ,
	                    if ( $d/marcxml:subfield[@code="d"][$x]) then
	                        (element bf:providerPlace {
	                               element bf:Place {
	                                   element bf:label {                      fn:string($d/marcxml:subfield[@code="d"][$x])}
	                                   }
	                                   },
	                        marcbib2bibframe:generate-880-label($d,"place") )
	                    else (),
	                    if ($d/marcxml:subfield[@code="f"][$x]) then
	                        element bf:providerDate {marc2bfutils:clean-string($d/marcxml:subfield[@code="f"][$x])}	                                     
	                    else ()
	                }
		}   
		(:there is no $b:)       
        else if ($d/marcxml:subfield[fn:matches(@code,"(d|f)")]) then	
            element bf:publication {
                element bf:Provider {
                    for $pl in $d/marcxml:subfield[@code="d"]
                    	return (element bf:providerPlace {
                    	           element bf:Place {
	                       element bf:label {fn:string($pl)}
	                       }
	                       },
                    			marcbib2bibframe:generate-880-label($d,"place") 
                    		),
                    for $pl in $d/marcxml:subfield[@code="f"]							
                    	return element bf:providerDate {marc2bfutils:clean-string($pl)}						
                }
            }
    
    else ()

};
(:~
:   This is the function generates 3XX  data for instance or work, based on mappings in $physdesc-list
:	Returns bf: node of elname 
:
:   @param  $marcxml       element is the marcxml record
:   @param  $resource      string is the "work" or "instance"
:   @return bf:* 	   element()
:)
declare function marcbib2bibframe:generate-physdesc
    (
        $marcxml as element(marcxml:record),
        $resource as xs:string
    ) as element ()*
{

    let $physdescs:= 
    	if ($resource="instance") then 
           	 $marcbib2bibframe:physdesc-list/instance-physdesc
        	else 
           	$marcbib2bibframe:physdesc-list/work-physdesc
    return 
        (
            for $physdesc in $physdescs/field
             let $codes := 
                    if ($physdesc/@codes) then 
                        fn:string($physdesc/@codes)
                    else 
                        "a"                        
	           for $each-field in $marcxml/marcxml:datafield[@tag eq $physdesc/@tag]

                for $subelement in $each-field/marcxml:subfield[fn:matches($codes,@code)]
                
                let $elname:=
                    if ($physdesc/@property) then 
                        fn:string($physdesc/@property) 
                    else 
                        "propertyname"
                return						
                    element {fn:concat("bf:", $elname)} {			                  
                        fn:normalize-space( fn:string($subelement))                        
                    },
             (:---337,338:)
             	if ($resource="instance") then 
              ( for $d in $marcxml/marcxml:datafield[@tag="337" ]
                let $src:=fn:string($d/marcxml:subfield[@code="2"])
                
                return
                    if (   $src="rdamedia"  and $d/marcxml:subfield[@code="a"]) then
                           element bf:mediaType {attribute rdf:resource {fn:concat("http://id.loc.gov/test/carriers/",fn:encode-for-uri(fn:string($d/marcxml:subfield[@code="a"])))}	
                                }
                     else if         ($d/marcxml:subfield[@code="a"]) then
                      element bf:mediaType { 
                            element bf:MediaType {
                                    element bf:label{fn:string($d/marcxml:subfield[@code="a"])}		
                                    } 
                                }
                        else   if (   $src="rdamedia"  and $d/marcxml:subfield[@code="b"]) then
                           element bf:mediaType {attribute rdf:type {fn:concat("http://id.loc.gov/test/rdamedia/",fn:encode-for-uri(fn:string($d/marcxml:subfield[@code="b"])))}		
                        } 
                     else  (),  
               for $d in $marcxml/marcxml:datafield[@tag="338"]
                let $src:=fn:string($d/marcxml:subfield[@code="2"])
                
                return
                    if (   $src="rdacarrier"  and $d/marcxml:subfield[@code="a"]) then
                           element bf:carrierType {attribute rdf:resource {fn:concat("http://id.loc.gov/test/marcsmd/",fn:encode-for-uri(fn:string($d/marcxml:subfield[@code="a"])))}		
                                }
                     else if         ($d/marcxml:subfield[@code="a"]) then
                      element bf:carrierType {                           
                            attribute rdf:resource {fn:concat("http://id.loc.gov/test/somecarrier/",
                          fn:encode-for-uri(fn:string($d/marcxml:subfield[@code="a"])))}
                          }
                        else   if (   $src="rdacarrier"  and $d/marcxml:subfield[@code="b"]) then
                           element bf:carrierType {attribute rdf:resource {fn:concat("http://id.loc.gov/test/rdacarrrier/",fn:string($d/marcxml:subfield[@code="b"]))}		
                        } 
                     else  (),  
              (:---337, 338 end ---:)
              for $issuedate in $marcxml/marcxml:datafield[@tag="362"]
                let $subelement:=fn:string($issuedate/marcxml:subfield[@code="a"])
                return
                    if (   $issuedate/@ind1="0" and fn:contains($subelement,"-") ) then
                       ( element bf:serialFirstIssue {		
                            fn:normalize-space( fn:substring-before($subelement,"-"))
                        },
                        if ( fn:normalize-space(fn:substring-after($subelement,"-"))!="") then 
                        element bf:serialLastIssue{		
                            fn:normalize-space( fn:substring-after($subelement,"-"))
                        }
                        else ()
                        )
                    else  (:no hyphen or it's ind1=1:)
                        element bf:serialFirstIssue {
                            fn:normalize-space( $subelement)
                        },
                        for $d in $marcxml/marcxml:datafield[@tag="351"]                              
                             return                             
                                 element bf:arrangement {		
                                    
                                         element bf:Arrangement {
                                         for $sub in $d/marcxml:subfield[@code="3"] 
                                            return element bf:materialPart {
                                                fn:normalize-space( fn:string($sub))
                                                },
                                            for $sub in $d/marcxml:subfield[@code="a"] 
                                            return element bf:materialOrganization {
                                                fn:normalize-space( fn:string($sub))
                                                },
                                            for $sub in $d/marcxml:subfield[@code="b"] 
                                              return  element bf:materialArrangement {
                                                fn:normalize-space( fn:string($sub))
                                            },
                                            for $sub in $d/marcxml:subfield[@code="c"] 
                                              return
                                                element bf:materialHierarchicalLevel {
                                                fn:normalize-space( fn:string($sub))
                                                }
                                        }
                                     }
                 )
                 else () (:work physdesc excludes the above:)
        	)
};

(:~
:   This is the function generates isbn-based instance resources. (ie books???)
:   ntra 2013-03-13
	changed to just pass in the isbn string, in case it's not int hte data, plus marcxml:record instead of marcxml:subfield, for further processing
	and moved $instance (generating the rest of the instance from the 260 out 
:   @param  $d        element is the 020  $a
:   @param  $isbn-string       is the isbn string; may have come from subfield or calculation
:   @param  $isbn-extra       is the stuff after the number (eg pbk v. 12 )
:  @param  $instance 	element bf:Instance is generated fromthe first 260  
:   @return bf:* as element()

:)
declare function marcbib2bibframe:generate-instance-fromISBN(
    $d as element(marcxml:record),
    $isbn-set as element (bf:set),   
    (:something needed to be a null instance???:)
    $instance as element (bf:Instance)?,
    
    $workID as xs:string
    ) as element ()*
    
{
                
    let $isbn-extra:=fn:normalize-space(fn:tokenize(fn:string($isbn-set/marcxml:subfield[1]),"\(")[2])
    let $volume:= 
        if (fn:contains($isbn-extra,":")) then    
            fn:replace(marc2bfutils:clean-string(fn:normalize-space(fn:tokenize($isbn-extra,":")[2])),"\)","")
        else
            fn:replace(marc2bfutils:clean-string(fn:normalize-space($isbn-extra)),"\)","")
let $v-test:= 
    fn:replace(marc2bfutils:clean-string(fn:normalize-space($isbn-extra)),"\)","")
 
 let $volume-test:= ($v-test, fn:tokenize($v-test,":")[1],fn:tokenize($v-test,":")[2])
 let $volume-test:= fn:tokenize($v-test,":")[2]
 
    let $volume-info-test:=
        if (fn:not(fn:empty($volume-test ))) then
        for $v in  $volume-test
            for $vol in fn:tokenize(fn:string($d/marcxml:datafield[@tag="505"]/marcxml:subfield[@code="a"]),"--")[fn:contains(.,$v)][1]           
		      return if  (fn:contains($vol,$v)) then element bf:subtitle {fn:concat("experimental 505a matching to isbn:",$vol)} else ()
        else ()
                
    let $volume-info:= ()
    (:bib id 467 has multiple matches for t 1: t 1, t 11, t12 etc:)
        (:if ($volume ) then		
            for $vol in fn:tokenize(fn:string($d/marcxml:datafield[@tag="505"]/marcxml:subfield[@code="a"]),"--")[fn:contains(.,$volume)][1]           
		      return if  (fn:contains($vol,$volume)) then element bf:subtitle {fn:concat("experimental 505a matching to isbn:",$vol)} else ()
        else ():)

    let $carrier:=
        if (fn:tokenize( $isbn-set/marcxml:subfield[1],"\(")[1]) then        
            marc2bfutils:clean-string(fn:normalize-space(fn:tokenize($isbn-set/marcxml:subfield[1],"\(")[2]))            
        else () 
    
    let $physicalForm:=                                				  	                        
            if (fn:matches($carrier,"(pbk|softcover)","i")) then
                "paperback"
            else if (fn:matches($carrier,"(hbk|hdbk|hardcover|hc|hard)","i") ) then 
                "hardback"
            else if (fn:matches($carrier,"(ebook|eresource|e-isbn|ebk)","i") ) then
                "electronic resource"
            else if (fn:contains($carrier,"lib. bdg.") ) then
                "library binding"			
            else if (fn:matches($carrier,"(acid-free|acid free|alk)","i")) then
                "acid free"					           
            else 
                ""
            (:else fn:replace($carrier,"\)",""):)
    (:9781555631185 (v. 4. print):)
    let $i-title := 
        if ($d/marcxml:datafield[@tag = "245"]) then
            marcbib2bibframe:get-title($d/marcxml:datafield[@tag = "245"])
        else
            ()
    let $extent-title :=
        if ($volume ne "") then
            for $t in $i-title
            return
                element bf:title {
                    $t/@*,
                    fn:normalize-space(fn:concat(xs:string($t), " (", $volume, ")"))
                }
        else if ($physicalForm ne "") then
            for $t in $i-title
            return
                element bf:title {                
                    $t/@*,                    
                    fn:normalize-space(fn:concat(xs:string($t), " (", $physicalForm, ")"))
                }
        else if ($carrier ne "") then
            for $t in $i-title
            return
                element bf:title {
                    $t/@*,
                    fn:normalize-space(fn:concat(xs:string($t), " (", $carrier, ")"))
                }
        else 
            $i-title
            
        
    let $clean-isbn:= 
        for $item in $isbn-set/bf:isbn
        	return marc2bfutils:clean-string(fn:normalize-space(fn:tokenize( fn:string($item),"\(")[1]))

    let $isbn := 
        for $i in $clean-isbn
        let $element-name :=
            if (fn:string-length($i) gt 11  ) then 
                "bf:isbn13" 
            else 
                "bf:isbn10" 
        return (
                element {$element-name} {
                    fn:normalize-space($i)
                },
                if (fn:string-length($i) lt 11  ) then 
                 (:element bf:relatedInstance {attribute rdf:resource {fn:concat("http://www.lookupbyisbn.com/Search/Book/",fn:normalize-space($i),"/1")}}:)
                 element bf:relatedInstance {attribute rdf:resource {fn:concat("http://isbn.example.org/",fn:normalize-space($i))}}
                 else ()
                )
	       

 
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
        		$isbn,
        		(: See extent-title above :)
        		(: if ($volume) then element bf:title{ $volume} else (), :)
        		$extent-title,
        		(:for $t in $extent-title
        		return 
                    element bf:label { 
                        $t/@*,
                        xs:string($t)
                    },:)
        		if ($physicalForm) then      element bf:physicalForm {$physicalForm} else (),
        		$volume-info,
        (:not done yet: nate 2013-05-21
        element bf:test{$v-test},
        $volume-test,:)
   	        		        
   	         if ( fn:exists($instance) ) then
	                (
	                    $instance/@*,
	                    if ($volume or $volume-info) then
	                       $instance/*[fn:not(fn:local-name()="title") and fn:not(fn:local-name()="extent")]
	                    else
	                       $instance/*
	                )
	            else 
	                $instanceOf           
		}
    
};
(:~
:   This is the function generates edition instance resources.
:
:   @param  $d        element is each  250 after the first  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-instance-from250(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element ()*
{

   
    
    let $pubnum := 
            if ($d/marcxml:subfield[@code="a"]) then
                element bf:publisherNumber
         			{
                    	marc2bfutils:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="a"])))              
                	}
        	else ()
    let $pubsource := 
        if ($d/marcxml:subfield[@code="b"]) then
                element bf:publisherNumberSource
             		{
                        marc2bfutils:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="b"])))              
                    }
                else ()
		
     let $pubqual :=
        if ($d/marcxml:subfield[@code="q"]) then
            element bf:publisherNumberQualifier
     			{
                	marc2bfutils:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="q"])))              
            	}
        else ()
    (:get the physical details:)
    (: We only ask for the first 260 :)
	let $instance :=  marcbib2bibframe:generate-instance-from260($d/../marcxml:datafield[@tag eq "260" or @tag eq "264"][1], $workID)
        
        
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
            (if ( fn:exists($instance) ) then
                (
                    $instance/@*,
                    $instance/*
                )
            else 
                $instanceOf),                         
            $pubnum,$pubsource	
		}
     
};

(:~
:   This is the function generates 856-based instance resources or annotations
: 	856 to resource is an instance, else annotation. Contributor link annotates 1xx uri
:
:   @param  $marcxml        element is the whole record
:   @return bf:* as element()
:	contributor ex:13546156

:)
declare function marcbib2bibframe:generate-instance-from856(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element ()* 
{
    let $bibid:=$d/../marcxml:controlfield[@tag="001"]
    let $biblink:= 
        element bf:derivedFrom {
            attribute rdf:resource{fn:concat("http://id.loc.gov/resources/bibs/",$bibid)}
        } 
  
     

        let $category:=         
            if (      fn:contains(
            		fn:string-join($d/marcxml:subfield[@code="u"],""),"hdl.loc.gov") and(:u is repeatable:)
                fn:not(fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"finding aid","i") ) 
                ) then
                "instance"
            else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]) ,"(pdf|page view) ","i"))   then
                "instance"
            else if ($d/@ind1="4" and $d/@ind2="0" ) then
                "instance"
            else if ($d/@ind1="4" and $d/@ind2="1" and fn:not(fn:string($d/marcxml:subfield[@code="3"]) )  ) then
                "instance"
            else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"finding aid","i") ) then
                "findaid"    
            else 
                "annotation"
            let $annotates:=  if ($workID!="person" and $category="annotation") then
                        element bf:annotates {
                            attribute rdf:resource {$workID}
                        }
                       else ()
   
        let $type:= 
            if (fn:matches(fn:string-join($d/marcxml:subfield[@code="u"],""),"catdir","i")) then            
                if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"contents","i")) then "contents"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"sample","i")) then "sample"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"contributor","i")) then "contributor"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"publisher","i")) then "publisher"
                else  ()
            else ()
            
 	return 
	 if ( $category="instance" ) then 
                element bf:hasInstance {
                	element bf:Instance {
                    		element bf:label {
                    			if ($d/marcxml:subfield[@code="3"]) then fn:normalize-space(fn:string($d/marcxml:subfield[@code="3"]))
                    			else "Electronic Resource"
                    		},
	                    for $u in $d/marcxml:subfield[@code="u"]
	                    		return element bf:identifier {fn:normalize-space(fn:string($u))},
	                    element bf:instanceOf {
	                        attribute rdf:resource {$workID}
	                  	},
                    		$biblink,
                    		$annotates
                	}
                }
             else             	
               element bf:hasAnnotation {
            	 	element bf:Annotation {
            	 	element bf:label {
                    		if (fn:string($d/marcxml:subfield[@code="3"]) ne "") then                        		
                            			fn:string($d/marcxml:subfield[@code="3"])       					                        		
                    		else  "No label"
                    		},
	                    	                    
	                    for $u in $d/marcxml:subfield[@code="u"]
	                    	return element bf:annotationBody { 
	                    	                  attribute rdf:resource {                  	
	                    		                 fn:normalize-space(fn:string($u))
	                    		                }
	                    		},                    		
	                    $biblink,
	                
	                    $annotates
              		}
              	}

};
(:~
:   This is the function generates dissertation on Work from 502.
: 
:   @param  $marcxml        element is the 502 datafield  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-dissertation(
    $d as element(marcxml:datafield)   
    ) as element ()* 
{

( element rdf:type {attribute rdf:resource{"http://bibframe.org/vocab/Dissertation"}},
    if ($d/marcxml:subfield[@code="a"] and fn:count($d/*)=1) then
        element bf:dissertationNote{fn:string($d/marcxml:subfield[@code="a"])}
    else 
	
		if ($d/marcxml:subfield[@code="a"]) then
			element bf:dissertationNote{fn:string($d/marcxml:subfield[@code="a"])}
		else (),
		if ($d/marcxml:subfield[@code="b"]) then
			element bf:dissertationDegree{fn:string($d/marcxml:subfield[@code="b"])}
		else (),
		if ($d/marcxml:subfield[@code="c"]) then
			element bf:dissertationInstitution{marc2bfutils:clean-string($d/marcxml:subfield[@code="c"])}
		else (),
		if ($d/marcxml:subfield[@code="d"]) then
			element bf:dissertationYear{marc2bfutils:clean-string($d/marcxml:subfield[@code="d"])}
		else (),
		if ($d/marcxml:subfield[@code="o"]) then
			element bf:dissertationIdentifier{fn:string($d/marcxml:subfield[@code="o"])}
		else ()

   )
};
(:~
:   This is the function generates cartography properties from 255
: 
:   @param  $marcxml        element is the 255 datafield  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-cartography(
    $d as element(marcxml:datafield)   
    ) as element ()* 
{


if ($d/marcxml:subfield[@code="a"] and fn:count($d/*)=1) then
	element bf:cartographicScale{fn:string($d/marcxml:subfield[@code="a"])}
else 	
		if ($d/marcxml:subfield[@code="a"]) then
			element bf:cartographicScale{fn:string($d/marcxml:subfield[@code="a"])}
		else (),
		if ($d/marcxml:subfield[@code="b"]) then
			element bf:cartographicProjection{marc2bfutils:clean-string($d/marcxml:subfield[@code="b"])}
		else (),
		if ($d/marcxml:subfield[@code="c"]) then
			element bf:cartographicCoordinates {marc2bfutils:clean-string($d/marcxml:subfield[@code="c"])}
		else (),
		if ($d/marcxml:subfield[@code="d"]) then
			element bf:cartographicAscensionAndDeclination{marc2bfutils:clean-string($d/marcxml:subfield[@code="d"])}
		else (),
		if ($d/marcxml:subfield[@code="e"]) then
			element bf:cartographicEquinox{marc2bfutils:clean-string($d/marcxml:subfield[@code="e"])}
		else (),
		if ($d/marcxml:subfield[@code="f"]) then
			element bf:cartographicOuterGRing{marc2bfutils:clean-string($d/marcxml:subfield[@code="f"])}
		else (),
		if ($d/marcxml:subfield[@code="g"]) then
			element bf:cartographicExclusionGRing{marc2bfutils:clean-string($d/marcxml:subfield[@code="g"])}
		else ()

  
};
(:~
:   This is the function generates holdings properties from hld:holdings.
: 
:   @param  $marcxml        element is the MARCXML
:                           may also contain hld:holdings
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-holdings-from-hld(
    $holdings as element(hld:holdings)?
    
    ) as element ()* 
{
for $hold in $holdings/hld:holding
    let $elm :=  
    if (  $hold/hld:volumes/hld:volume[2]) then "HeldMaterial" else "HeldItem"
    let $summary-set :=
            for $property in $hold/*
                return                 
                    if ( fn:matches(fn:local-name($property), "callNumber")) then
                        (element bf:label {fn:string($property)},
                        element bf:shelfMark {fn:string($property)})  
                    else if ( fn:matches(fn:local-name($property), "localLocation")) then
                        element bf:subLocation {fn:string($property)} 
                    else if ( fn:matches(fn:local-name($property), "(enumeration|enumAndChron)")) then
                        element bf:enumerationAndChronology {fn:string($property)}
                      
                    else if ( fn:matches( fn:local-name($property), "(publicNote|copyNumber)")) then
                        element {fn:concat("bf:", fn:local-name($property))} {fn:string($property)}
                    else ()
                        
   let $item-set :=
               if  ($hold/hld:volumes ) then
                        for $vol in $hold/hld:volumes/hld:volume
                            let $enum:=fn:normalize-space(fn:string($vol/hld:enumAndChron))
                            let $circs:= $vol/ancestor::hld:holding/hld:circulations
                            let $circ   := 
                                for $circ in $circs/hld:circulation[fn:normalize-space(fn:string(hld:enumAndChron ))=$enum]
                                    let $status:= if ($circ/hld:availableNow/@value="1") then "available" else  "not available" 
                                        return (element bf:circulationStatus {$status},
                                                if ($circ/hld:itemId) then element bf:itemId  {fn:string($circ/hld:itemId )} else ()
                                                )
                           return            
                              element bf:heldItem {
                                element bf:HeldItem {
                                    element bf:label {fn:string($vol/hld:enumAndChron)},
                                    element bf:enumerationAndChronology  {$enum },     
                                     element bf:enumerationAndChronology {fn:string($vol/hld:enumeration)},   
                                    $circ
                                  }
                               }
             else  (: no volumes,  just add circ  to the summary heldmaterial:)              
                        let $status:= if ($hold/hld:circulations/hld:circulation/hld:availableNow/@value="1") then "available" else  "not available" 
                        return (element bf:circulationStatus {$status},                                
                                element bf:itemId  {fn:string($hold/hld:circulations/hld:circulation/hld:itemId )}
                                )
         
            
     return
      if ($elm = "HeldItem" ) then
         element bf:heldItem {
            element bf:HeldItem {
             $summary-set, $item-set//bf:HeldItem/*[fn:not(fn:local-name()='label')]
            }
            }
         
            
      else
        element bf:heldMaterial{   
               element bf:HeldMaterial {
                     $summary-set,
                      $item-set
                                                 
                    }
            }
    
        
};
(:~
:   This is the function generates holdings resources.
: 
:   @param  $marcxml        element is the MARCXML
:                           may also contain hld:holdings
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-holdings(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()* 
{
let $hld:= marcbib2bibframe:generate-holdings-from-hld($marcxml//hld:holdings)
(:udc is subfields a,b,c; the rest are ab:) 
(:call numbers: if a is a class and b exists:)
 let $shelfmark:=  (: regex for call# "^[a-zA-Z]{1,3}[1-9].*$" :)        	        	         	         
	for $tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|051|055|060|061|070|071|080|082|084)")]
(:	multiple $a is possible: 2017290 use $i to handle :)
		for $class at $i in $tag[marcxml:subfield[@code="b"]]/marcxml:subfield[@code="a"][fn:matches(.,"^[a-zA-Z]{1,3}[1-9].*$")]
       		let $element:= 
       			if (fn:matches($class/../@tag,"(050|051|055|060|061|070|071)")) then "bf:shelfMarkLcc"
       			else if (fn:matches($class/../@tag,"080") ) then "bf:shelfMarkUdc"
       			else if (fn:matches($class/../@tag,"082") ) then "bf:shelfMarkDdc"
       			else if (fn:matches($class/../@tag,"084") ) then "bf:shelfMark"
       				else ()
            let $value:= 
                if ($i=1) then  
                    fn:concat(fn:normalize-space(fn:string($class))," ",fn:normalize-space(fn:string($class/../marcxml:subfield[fn:matches(@code,"b")]))) 
                else
                    fn:normalize-space(fn:string($class))
        (:080 doesnt' have $c, so took this out::)
	       return (: if ($element!="bf:callno-udc") then:)
	        		element {$element } {$value}
	        		(:else 
	        		element {$element } {fn:normalize-space(fn:string-join($class/../marcxml:subfield[fn:matches(@code, "(a|b|c)")]," "))}:)
let $d852:= 
    if ($marcxml/marcxml:datafield[@tag="852"]) then
        for $d in $marcxml/marcxml:datafield[@tag="852"]
        return 
            (
            for $s in $d/marcxml:subfield[@code="a"] return element bf:location{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="b"] return element bf:subLocation{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="c"] return element bf:shelfLocation{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="e"] return element bf:address{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="f"] return element bf:codedLocation{fn:string($s)},
            if ($d/marcxml:subfield[fn:matches(@code,"(h|i|j|k|l|m)")]) then 
                    element bf:shelfMark{fn:string-join($d/marcxml:subfield[fn:matches(@code,"(h|i|j|k|l|m)")]," ")}
            else (),
           (: for $s in $d/marcxml:subfield[@code="p"] return element bf:piece{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="q"] return element bf:pieceCondition{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="t"] return element  bf:copyNumber{fn:string($s)},:)
            for $s in $d/marcxml:subfield[@code="u"] return
                        element bf:uri { 
                             attribute rdf:resource{fn:string($s)}
                            },
            for $s in $d/marcxml:subfield[@code="z"] return element  bf:copyNote{fn:string($s)}        
            )
    else 
    ()
    
return 
        if (fn:not($hld) and ($shelfmark or $d852  )) then        
            element bf:heldItem{   
                element bf:HeldItem {
                   
                   (:this is for matching later:)
                    element bf:label{fn:string($shelfmark[1])},
         	    $shelfmark,
         	    $d852
         	     	
                }
            }
            
      	else if ($hld) then $hld else ()
    
};
(:~
:   This is the function generates instance resources.
: 
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-instances(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()* 
{  
let $isbn-sets:=
	if ($marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]) then
		marcbib2bibframe:process-isbns($marcxml) 
	else ()

    return    
        (        
        if ( $isbn-sets//bf:set) then           
        	(:use the first 260 to set up a book instance... what else is an instance in other formats?:)
            let $instance:= 
                for $i in $marcxml/marcxml:datafield[fn:matches(@tag, "(260|261|262|264)")][1]
          		      return marcbib2bibframe:generate-instance-from260($i, $workID)        

            for $set in $isbn-sets/bf:set
          	  return marcbib2bibframe:generate-instance-fromISBN($marcxml,$set, $instance, $workID)
	   	
        else 	        (: $isbn-sets//bf:set is false:)		
            for $i in $marcxml/marcxml:datafield[@tag eq "260"]|$marcxml/marcxml:datafield[@tag eq "264"]
     	       return marcbib2bibframe:generate-instance-from260($i, $workID)   
    )
};
(:~
:   This is the function generates a nonsort version of titles using private language tags
:   accepts element, property label
:
::   @param  $d       element is the marcxml datafield
:   @param  $title      string is the title as merged subfields
:   @param  $property      string is the title property name 
:   @return {$property} as element()
:)
declare function marcbib2bibframe:generate-titleNonsort(
   $d  as element(marcxml:datafield),   
    $title as xs:string, 
    $property as xs:string 
    ) as element ()*
{
if (fn:matches($d/@tag,"(222|242|243|245|440)" ) and fn:number($d/@ind2) gt 0 ) then
                (:need to sniff for begin and end nonsort codes also:)                
                element {$property} {attribute xml:lang {"en-US-bf"},
                        fn:substring($title, fn:number($d/@ind2)+1)
                             }
else if (fn:matches($d/@tag,"(130|630)" ) and fn:number($d/@ind1) gt 0 ) then
                (:need to sniff for begin and end nonsort codes also:)                
                element {$property} {attribute xml:lang {"en-US-bf"},
                        fn:substring($title, fn:number($d/@ind1)+1)
                             }

else ()

};
(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $notes-list
:   Returns subfield $a
:
::   @param  $marcxml       element is the marcxml record

:   @param  $resource      string is the "work" or "instance"
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-notes(
   $marcxml as element(marcxml:record),
    $resource as xs:string
    ) as element ()*
{

    let $notes:= 
	   if ($resource="instance") then 
	       $marcbib2bibframe:notes-list/instance-notes
	   else 
	       $marcbib2bibframe:notes-list/work-notes

    return 			
	(	
		for $note in $notes/note[@ind2]
			for $marc-note in $marcxml/marcxml:datafield[@tag eq $note/@tag][@ind2=$note/@ind2]
			let $return-codes:=
 				if ($note/@sfcodes) then fn:string($note/@sfcodes)
 				else "a"
 			let $precede:=fn:string($note/@startwith)
			return
		                element {fn:concat("bf:",fn:string($note/@property))} {	               
		                    fn:normalize-space(fn:concat($precede,fn:string-join($marc-note/marcxml:subfield[fn:contains($return-codes,@code)]," ")))
		                },                
		for $note in $notes/note[fn:not(@ind2)]
			for $marc-note in $marcxml/marcxml:datafield[@tag eq $note/@tag]
			
					let $return-codes:=
 						if ($note/@sfcodes) then fn:string($note/@sfcodes)
 						else "a"
	 				let $precede:= if ($marc-note/@tag!="504") then 
	 							fn:string($note/@startwith)
	 						else if ($marc-note/@tag="504" and $marc-note/marcxml:subfield[@code="b"]) then
	 							fn:concat(fn:string($note/@startwith),marc2bfutils:clean-string($marc-note/marcxml:subfield[@code="b"]))
		 					else ()
					return
					   if ($marc-note/marcxml:subfield[fn:contains($return-codes,@code)]) then
	                			element {fn:concat("bf:",fn:string($note/@property))} {
	                    					if ($marc-note/@tag!="504" and $marc-note/marcxml:subfield[fn:matches(@code,$return-codes)]) then	                    							                    						
	                    						marc2bfutils:clean-string(fn:concat($precede,fn:string-join($marc-note/marcxml:subfield[fn:matches(@code,$return-codes)]," ")))	                    						
	                    					else 
	                    						fn:normalize-space(fn:concat($precede,fn:string-join($marc-note/marcxml:subfield[@code="a"]," ")))
	                				}
                        else ()
                     
		 	
        )
};
(:533 to reproduction
sample bib 723007
:)
declare function marcbib2bibframe:generate-related-reproduction
    (
        $d as element(marcxml:datafield) ,$type     
    )
{ 	 
let $title:=fn:string($d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"])
let $carrier:= 
    if ($d/marcxml:subfield[@code="a"]) then 
        fn:string($d/marcxml:subfield[@code="a"]) 
    else if ($d/marcxml:subfield[@code="3"]) then 
        $d/marcxml:subfield[@code="3"] 
    else ()
let $pubPlace:= for  $pl in $d/marcxml:subfield[@code="b"]
			return element bf:providerPlace{
			element bf:Place {
	                       element bf:label {fn:string($pl)}
	                       }}
let $agent:= for  $aa in $d/marcxml:subfield[@code="c"] 
			return element bf:providerName {
			         element bf:Organization {
	                      element bf:label {fn:string($aa)}
	                   }
	                 }
let $pubDate:=marc2bfutils:clean-string($d/marcxml:subfield[@code="d"])
let $extent:= fn:string($d/marcxml:subfield[@code="e"])
let $coverage:= fn:string($d/marcxml:subfield[@code="m"])
(:gwu has multiple 533$n:)
let $note:= for $n in $d/marcxml:subfield[@code="n"]
		return element bf:note { fn:string($n)}
return 
	element {fn:concat("bf:",fn:string($type/@property))} {
			element bf:Work{
			    element bf:authorizedAccessPoint {$title},
				element bf:title {$title},			
				element bf:label{$title},	
				if ($pubDate or $pubPlace or $agent or $extent or $coverage or $note) then
				element bf:hasInstance {
					element bf:Instance {
						element bf:instanceTitle {element bf:Title {element bf:titleValue{$title}}},
						element bf:publication {
							element bf:Provider {
								$pubPlace,
								element bf:providerDate{$pubDate},								
								$agent
							}
						},
					
						if ($extent) then element bf:extent {$extent} else (),
						if ($coverage) then element bf:coverage {$coverage}  else (),						
						element bf:carrier {$carrier},	
						if ($note) then  $note  else ()						
						(: do we need this? nate removed 2013-04-17:)
						(:$3, $c, $b, $d, $e, $f, $m, $n, $5 in that order:)						
						(:element bf:relatedNote {fn:string-join ($d/*[fn:not(@code="a")]," - ")}:)
					}
				}
				else ()				 							
				}
			}
};

(:555 finding aids note may be related work link or a simple property
sample bib 14923309
consider linking 555 w/856 on $u!

:)
declare function marcbib2bibframe:generate-finding-aids
    (
        $d as element(marcxml:datafield) 
    )
{ 	 
 element bf:findingAid        
    {
    if ($d/marcxml:subfield[@code="u"]) then
        element bf:Work{ 
            element bf:authorizedAccessPoint {fn:string($d/marcxml:subfield[@code="a"])},
            element bf:title {fn:string($d/marcxml:subfield[@code="a"])},
            element bf:label {fn:string($d/marcxml:subfield[@code="a"])},
            for $u in $d/marcxml:subfield[@code="u"]
                let $link-property:=
                    if (fn:contains(fn:string($u),"hdl")) then "bf:hdl"
                    else if (fn:contains(fn:string($u),"doi")) then "bf:doi" 
                    else "bf:identifier"
                return
                    element bf:hasInstance {
                                element bf:Instance {
                                    element  {$link-property} {fn:string($u)}
                            }
                     }
          }
       
    else    
        fn:string($d/marcxml:subfield[@code="a"])       
        }
};
(:
For RDA:   040$e = rda
For AACR2:  Leader/18 = a

Under AACR2, when two works were published together the first work in the compilation was given the 1XX/240, and the second work was given a 700 analytic (name/title).  This essentially resulted in identifying the aggregate work by only the first work in the compilation.
Under RDA, we identify the aggregate work in the 240 (not just one of the works), and provide analytical added entries (name/title) for the works in the compilation.
(245 would be the instance title, 240 the UT)
:)
declare function marcbib2bibframe:generate-related-work
    (
        $d as element(marcxml:datafield), 
        $type as element() 
    )
{ 	 

    let $titleFields := 
        if (fn:matches($d/@tag,"(630|730|740)")) then
            "(a|n|p)"            
        else if  (fn:matches($d/@tag,"(440|490|830)")) then
            "(a|n|p|v)"
        else if (fn:matches($d/@tag,"(534)")) then
            "(t|b|f)"
        else if (fn:matches($d/@tag,"(510)")) then
            "(a|b|c)"
        else
            "(t|f|k|m|n|o|p|s)"
    let $title := marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[fn:matches(@code,$titleFields)] , ' '))
    
    let $name := 
        if (
            $d/marcxml:subfield[@code="a"] and 
            $d/@tag="740" and 
            $d/@ind2="2" and
            $d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag, "(100|110|111)")][1]
           ) then
            marcbib2bibframe:get-name($d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag, "(100|110|111)")][1])               
        else if (  $d/marcxml:subfield[@code="a"]  and fn:not(fn:matches($d/@tag,"(400|410|411|440|490|800|810|811|510|630|730|740|830)")) ) then
            marcbib2bibframe:get-name($d)
        else ()
        
        
    let $aLabel := 
        fn:concat(
            fn:string(($name//bf:label)[1]),
            " ",
            $title
        )
    let $aLabel := fn:normalize-space($aLabel)
    
    let $aLabelWork880 := marcbib2bibframe:generate-880-label($d,"title")
    let $aLabelWork880 :=
        if ($aLabelWork880/@xml:lang) then
            let $lang := $aLabelWork880/@xml:lang 
            let $n := $name//bf:authorizedAccessPoint[@xml:lang=$lang][1]
            let $combinedLabel := fn:normalize-space(fn:concat(fn:string($n), " ", fn:string($aLabelWork880)))
            return
                element bf:authorizedAccessPoint {
                    $aLabelWork880/@xml:lang,                    
                    $combinedLabel
                }
        else
            $aLabelWork880
            
    return 
 	  element {fn:concat("bf:",fn:string($type/@property))} {
		element bf:Work {		          
		element bf:label {$title},
            element bf:authorizedAccessPoint {$aLabel},
            $aLabelWork880,
            if ($d/marcxml:subfield[@code="w" or @code="x"] and fn:not($d/@tag="630")) then (:(identifiers):)
                for $s in $d/marcxml:subfield[@code="w" or @code="x" ]
  	              let $iStr :=  marc2bfutils:clean-string(fn:replace($s, "\(OCoLC\)", ""))
           	    return 
	                    if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then
	                        (
	                           (:element bf:oclc-number {$iStr},:)
	                           element bf:systemNumber {  attribute rdf:resource {fn:concat("http://www.worldcat.org/oclc/",fn:replace($iStr,"^ocm","")) }}
	                        )
	                    else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
	                        element bf:lccn { attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/identifiers/lccn/fakelookup/",fn:replace( fn:replace($iStr, "\(DLC\)", "")," ",""))} }                	                    
	                    else if ($s/@code="x") then
	                       element bf:hasInstance{ element bf:Instance{ 
	                                   element bf:title {$title},
	                                   element bf:issn {attribute rdf:resource {fn:concat("http://issn.example.org/", fn:replace(marc2bfutils:clean-string($iStr)," ","")) } }
	                                   }
	                                   }
		               else ()		               
     	   else 
     	       (),		
            element bf:title {$title},
            marcbib2bibframe:generate-titleNonsort($d,$title, "bf:title"),
            
            $name                    
			}
		}
};

(:~
:   This is the function that finds and dedups isbns, delivering a complete set for generate-instancefrom isbn
:  If the 020$a has a 10 or 13, they are matched in a set, if the opposite of a pair doesn't exist, it is calculated
:   @param  $marcxml        element is the MARCXML record
:   @return wrap as as wrapper for bf:set* as element() containing both marcxml:subfield [code=a] and bf:isbn calculated nodes
:   	
:)
declare function marcbib2bibframe:process-isbns (
	$marcxml as element (marcxml:record)
) as element() {
    
    (:for books with isbns, generate all isbn10 and 13s from the data, list each pair on individual instances:)
    let $isbns:=$marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
    let $isbn-sets:=
        for $str in $isbns 
        let $isbn-str:=fn:normalize-space(fn:tokenize(fn:string($str),"\(")[1])
        return 
            element bf:isbn-pair {
                marcbib2bibframe:get-isbn( marc2bfutils:clean-string( $isbn-str ) )/*
            }
	
	let $unique-13s := fn:distinct-values($isbn-sets/bf:isbn13)
	let $unique-pairs:=
        for $isbn13 in $unique-13s
        let $isbn-set := $isbn-sets[bf:isbn13=$isbn13][1]
		(: for $isbn-set in $isbn-sets :)
        return 
            element set {
                (: 
                $isbn-set/bf:isbn[1],
                $isbn-set/bf:isbn[2], 
                :)
                element bf:isbn { fn:string($isbn-set/bf:isbn10) },
                element bf:isbn { fn:string($isbn-set/bf:isbn13) },
            	for $sfa in $marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
            	where fn:contains(fn:string($sfa),fn:string($isbn-set/bf:isbn10)) or fn:contains(fn:string($sfa),fn:string($isbn-set/bf:isbn13))
                return $sfa
            }
    return
        element wrap {
            for $set in $unique-pairs
            return element bf:set { $set/* }
        }
        (:
        element wrap {
            for $set in $unique-pairs 
            return 
                element bf:set {
                    $set//marcxml:subfield,
                    if (fn:count($set//marcxml:subfield)=2) then
                        () ( :both isbns are in the data: )
                    else if (fn:count($set//marcxml:subfield)=0) then
                        () ( :neither isbns are in the data: )
                    else
            			for $bf in $set//bf:isbn
            			( :bl has multiple 020a with same isbn: 0786254815 on lccn:2003047845, so only take the first : )
            			return 
            			     if (fn:not(fn:matches(fn:string($set/marcxml:subfield[1]),$bf/text()))) then
                                $bf
                             else 
                                ()
            		}
            }
        :)
};
(:~
:   This is the function generates related item works.
: ex 710 constituent title with 880 : 15015234
:   @param  $marcxml        element is the MARCXML
:	@param  $resource      string is the "work" or "instance"
:   @return bf:* as element()
:)
declare function marcbib2bibframe:related-works
    (
        $marcxml as element(marcxml:record),
        $workID as xs:string,
        $resource as xs:string
    ) as element ()*  
{ 

    let $relateds:= 
        if ($resource="instance") then 
            $marcbib2bibframe:relationships/instance-relateds
        else 
            $marcbib2bibframe:relationships/work-relateds

    let $relatedWorks :=     
        for $type in $relateds/type
        	return 
            if (fn:matches($type/@tag,"740")) then (: title is in $a , @ind2 needs attention:)
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][@ind2=$type/@ind2]		
                return marcbib2bibframe:generate-related-work($d,$type)
     	    else if ( $type/@ind2 and $marcxml/marcxml:datafield[fn:matches(@tag,"772")] ) then 
               for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][fn:matches(@ind2,fn:string($type/@ind2))]		
			   return marcbib2bibframe:generate-related-work($d,$type)
             
     	    else if (fn:matches($type/@tag,"533")) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))]		
			    return marcbib2bibframe:generate-related-reproduction($d,$type)                                           
            
            else if ($type/@ind2 and $marcxml/marcxml:datafield[fn:matches(@tag,"(700|710|711|720|780|785)")] ) then 
               for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][fn:matches(@ind2,fn:string($type/@ind2))][marcxml:subfield[@code="t"]]		
			   return marcbib2bibframe:generate-related-work($d,$type)
            
           
            else if (fn:matches($type/@tag,"(490|510|630|730|830)")) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][marcxml:subfield[@code="a"]]		
			    return marcbib2bibframe:generate-related-work($d,$type)
            
            else if (fn:matches($type/@tag,"(534)")  and $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][marcxml:subfield[@code="f"]] ) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][marcxml:subfield[@code="f"]](:	series:)
			  	return marcbib2bibframe:generate-related-work($d,$type)
            
            else 	
                for $d in $marcxml/marcxml:datafield[fn:matches(fn:string($type/@tag),@tag)][marcxml:subfield[@code="t"]]		
			   	return marcbib2bibframe:generate-related-work($d,$type)
				
    return $relatedWorks
				
};
(:~
:   This is the function that generates an xml:lang attribute from the script and language
:
:   @param  $scr         string is from the subfield $6
:   @param  $lang         string is the from the 008 (or 040?)
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-xml-lang(
    $scr as xs:string?,
    $lang as xs:string
    ) as xs:string 
{ 
let $xml-lang:=
         $marc2bfutils:lang-xwalk/language[iso6392=$lang]/@xmllang 
    
        let $script:=
	       if ($scr="(3" ) then "arab"
	       else if ($scr="(B" ) then "latn"
	       else if ($scr="$1"  and $lang="kor" ) then "hang"
	       else if ($scr="$1"  and $lang="chi" ) then "hani"
	       else if ($scr="$1"  and $lang="jpn" ) then "jpan"	       
	       else if ($scr="(N" ) then "cyrl"
	       else if ($scr="(S" ) then "grek"
	       else if ($scr="(2" ) then "hebr"
	       else ()
	    return   
            if ($script) then fn:concat($xml-lang,"-",$script) else $xml-lang
        };
(:~
:   This is the function that generates a work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element () 
{ (:2013-05-01 ntra moved instances inside work;  :)
    let $instances := marcbib2bibframe:generate-instances($marcxml, $workID)
    let $instancesfrom856:=
     if ( $marcxml/marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:not(fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i"))]) then         
        (:set up instances/annotations for each non-contributor bio link:)    
        for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:not(fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i"))]
            return marcbib2bibframe:generate-instance-from856($d, $workID)            
        else 
            ()
    let $types := marcbib2bibframe:get-resourceTypes($marcxml)
        
    let $mainType := "Work"
    
    let $uniformTitle := 
        for $d in ($marcxml/marcxml:datafield[@tag eq "130"]|$marcxml/marcxml:datafield[@tag eq "240"])[1]
        return marcbib2bibframe:get-uniformTitle($d)
                
    let $names := 
        for $d in (
                    $marcxml/marcxml:datafield[@tag eq "100"]|
                    $marcxml/marcxml:datafield[@tag eq "110"]|
                    $marcxml/marcxml:datafield[@tag eq "111"]
                    )
        return marcbib2bibframe:get-name($d)
        
    let $titles := 
        <titles>
            {
    	       for $t in $marcxml/marcxml:datafield[fn:matches(@tag,"(210|245|243|247)")]
    	       return marcbib2bibframe:get-title($t)
            }
        </titles>
        
        
    (: Let's create an authoritativeLabel for this :)
    let $aLabel := 
        if ($uniformTitle[bf:workTitle]) then
            fn:concat( fn:string($names[1]/bf:*[1]/bf:label), " ", fn:string($uniformTitle/bf:workTitle) )
        else if ($titles) then
            fn:concat( fn:string($names[1]/bf:*[1]/bf:label), " ", fn:string($titles/bf:title[1]) )
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
            
    let $aLabelsWork880 := $titles/bf:authorizedAccessPoint
    let $aLabelsWork880 :=
        for $al in $aLabelsWork880
        let $lang := $al/@xml:lang 
        let $n := $names//bf:authorizedAccessPoint[@xml:lang=$lang][1]
        let $combinedLabel := fn:normalize-space(fn:concat(fn:string($n), " ", fn:string($al)))
        where $al/@xml:lang
        return
            element bf:authorizedAccessPoint {
                    $al/@xml:lang,                   
                    $combinedLabel
                }
        
    let $cf008 := fn:string($marcxml/marcxml:controlfield[@tag='008'])
    let $leader:=fn:string($marcxml/marcxml:leader)
    let $leader7:=fn:substring($leader,8,1)
	let $leader19:=fn:substring($leader,20,1)

     let $issuance:=
           	if (fn:matches($leader7,"(a|c|d|m)")) 		then "monographic"
           	else if ($leader7="b") 						then "continuing"
           	else if ($leader7="m" and  fn:matches($leader19,"(a|b|c)")) 	then "multipart monograph"
           	else if ($leader7='m' and $leader19='#') 				then "single unit"
           	else if ($leader7='i') 						           	then "integrating resource"
           	else if ($leader7='s')           						then "serial"
           	else ()
     let $issuance := 
                if ($issuance) then 
                   element bf:modeOfIssuance {$issuance}                  
                else ()
    (: 
        Here's a thought. If this Work *isn't* English *and* it does 
        have a uniform title (240), we should probably figure out the 
        lexical value of the language code and append it to the 
        authoritativeLabel, thereby creating a type of expression.
    :)
    
    let $language := fn:normalize-space(fn:substring($cf008, 36, 3))
    let $language := 
        if ($language ne "" and $language ne "|||") then
            element bf:language {
                attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , $language) }
            }
        else
            ()
   let $langs := marcbib2bibframe:get-languages ($marcxml)
   let $dissertation:= 
   	for $diss in $marcxml/marcxml:datafield[@tag="502"]
      		return marcbib2bibframe:generate-dissertation($diss)
    let $audience := fn:substring($cf008, 23, 1)
    let $audience := 
        if ($audience ne "") then
            let $aud := fn:string($marc2bfutils:targetAudiences/type[@cf008-22 eq $audience]) 
            return
                if (
                    $aud ne ""
                       (: What others would have audience? :)
                    (:??  ntra: I think audience s.b. there regardless of the subclass of work and anyway, mainType is Work
                    and
                    (
                        $mainType eq "Text" or
                        $mainType eq "SoftwareOrMultimedia" or
                        $mainType eq "StillImage" or
                        $mainType eq "NotatedMusic" or
                        $mainType eq "MusicRecording"
                     
                    ):)
                ) then
                    element bf:intendedAudience {
                        attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/targetAudiences/" , $aud) }
                    }
                else ()
        else
            ()
            
     let $aud521:= if ($marcxml/marcxml:datafield[@tag eq "521"]) then 
     			for $tag in $marcxml/marcxml:datafield[@tag eq "521"]
     				return marcbib2bibframe:get-521audience($tag) 
     			else ()
     
    (: Don't be surprised when genre turns into "form" :)
    let $genre := fn:substring($cf008, 24, 1)
    let $genre := 
        if ($genre ne "") then
            let $gen := fn:string($marc2bfutils:formsOfItems/type[@cf008-23 eq $genre and fn:contains(fn:string(@rType), $mainType)]) 
            return
                if ($gen ne "") then
                    element bf:genre {$gen}
                else ()
        else
            ()
            
            
     let $work3xx := marcbib2bibframe:generate-physdesc($marcxml,"work")
      let $cartography:=  for $carto in $marcxml/marcxml:datafield[@tag="255"] 
      				return marcbib2bibframe:generate-cartography($carto)
(:
        # - Summary
        0 - Subject
        1 - Review
        2 - Scope and Content
        3 - Abstract
        4 - ContentAdvice
        8 - No display constant generated
    :)
	let $abstract:= 
		for $d in  $marcxml/marcxml:datafield[@tag="520"][fn:not(marcxml:subfield[@code="c"]) and fn:not(marcxml:subfield[@code="u"])] 
		(:	let $abstract-type:=
				if ($d/@ind1="") then "summary"
             			else if ($d/@idn1="0") then "contentDescription"
				else if ($d/@ind1="1") then "review"
				else if ($d/@ind1="2") then "scopeContent"
				else if ($d/@ind1="3") then "abstract"
				else if ($d/@ind1="4") then "contentAdvice"
				else 				"summary":)
			return	
			
				element  bf:hasAnnotation {				
				        element    bf:Description {						        
				            	element bf:label {fn:string-join($d/marcxml:subfield[fn:matches(@code,"(3|a|b)") ]," ")}
					}
				}      			
			
    let $abstract-annotation:= 
        for $d in  $marcxml/marcxml:datafield[@tag="520"][marcxml:subfield[fn:matches(@code,"(c|u)")]] 
        let $abstract-type:=
            if ($d/@ind1="") then "Description" (:Summary:)
            else if ($d/@ind1="0") then "Description"(:Content Description:) 
            else if ($d/@ind1="1") then "Review"
            else if ($d/@ind1="2") then "Description" (:Scope and Content:)
            else if ($d/@ind1="3") then "Description" (:Abstract:)
            else if ($d/@ind1="4") then "Description" (:Content advice:)
            else                        "Description"
        return (:link direction should be reversed:)
            element bf:hasAnnotation {
                element bf:Annotation {
                    element rdf:type {
                        attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" , fn:replace($abstract-type, " ", "") ) }
                    },
                       
                    element bf:label { $abstract-type},
                        
                    if (fn:string($d/marcxml:subfield[@code="c"][1]) ne "") then
                        for $sf in $d/marcxml:subfield[@code="c"]
                        return element bf:annotationAssertedBy { fn:string($sf) }
                    else
                        element bf:annotationAssertedBy { 
                            attribute rdf:resource {"http://id.loc.gov/vocabulary/organizations/dlc" }
                        },
                        (:??? annotationbody  and literal aren't right:)
                    for $sf in $d/marcxml:subfield[@code="u"]
                    return element bf:annotationBody { attribute rdf:resource {fn:string($sf)} },
                        
                        element cnt:chars { fn:string-join($d/marcxml:subfield[fn:matches(@code,"(3|a|b)") ],"") },
                    (:element bf:annotationBody { fn:string-join($d/marcxml:subfield[fn:matches(@code,"(3|a|b)") ],"") },
                        :)
                    element bf:annotates {
                        attribute rdf:resource {$workID}
                    }
                }
            }
       
 
  
	let $work-identifiers := marcbib2bibframe:generate-identifiers($marcxml,"Work")
	let $work-classes := marcbib2bibframe:generate-class($marcxml,"work")
	
 	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marc2bfutils:subject-types//@tag," "),fn:string(@tag))]		
        			return marcbib2bibframe:get-subject($d)
 	let $work-notes := marcbib2bibframe:generate-notes($marcxml,"work")
 	let $findaids:= for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"555")]
 	                  return marcbib2bibframe:generate-finding-aids($d)
 	let $work-relateds := marcbib2bibframe:related-works($marcxml,$workID,"work")
 	(:audio ex:12241297:)
 	let $complex-notes:= 
 		for $marc-note in $marcxml/marcxml:datafield[@tag eq "505"][@ind2="0"]
 			let $sub-codes:= fn:distinct-values($marc-note/marcxml:subfield[@code!="t"]/@code)
			let $return-codes := "gru"			
			let $set:=
				for $title in $marc-note/marcxml:subfield[@code="t"]
				let $t := fn:replace(fn:string($title), " /", "")
              
                let $details := 
                    element details {
                        for $subfield in $title/following-sibling::marcxml:subfield[@code!="t"][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)]                
                        let $elname:=
                            if ($subfield/@code="g") then "bf:note" 
                            else if ($subfield/@code="r") then "bf:creator" 
                            else if ($subfield/@code="u") then "rdf:resource" 
                            else fn:concat("bf:f505c" , fn:string($subfield/@code))
                        let $sfdata := fn:replace(fn:string($subfield), " --", "")
                        return
                            if ($elname eq "rdf:resource") then
                                element {$elname} { attribute rdf:resource {$sfdata} }
                            else if ($elname eq "bf:creator") then
                                if ( fn:contains($sfdata, ";") ) then
                                    (: we have multiples :)
                                    for $c in fn:tokenize($sfdata, ";")
                                    return marcbib2bibframe:get-name-fromSOR($c,"bf:creator")
                                else
                                    marcbib2bibframe:get-name-fromSOR($sfdata,"bf:creator")
                            else
                                element {$elname} {$sfdata}
                    }
                return 
                    element part {
                        element bf:authorizedAccessPoint {
                            fn:string-join( ($details/bf:creator[1]/bf:*[1]/bf:label, $t), ". " )
                        },
                        element bf:preferredTitle {$t},
                        (:
                        element bf:hasAuthority{
                            element madsrdf:Authority { element madsrdf:authoritativeLabel{fn:string-join( ($details/bf:creator[1]/bf:label, $t), ". " )},
                                element madsrdf:elementList {
                                    attribute rdf:parseType {"Collection"},
                                    element madsrdf:MainTitleElement {
                                        element madsrdf:elementValue {$t}
                                    }
                                }
                            }
                        },
                        :)                       
                        $details/*                                 
                    }
		return						
                for $item in $set
                return
	                    element bf:contains {   
	                        element bf:Work {	                            
	                            $item/*
	                        }																								
		     }
						
 	let $gacs:= 
            for $d in $marcxml/marcxml:datafield[@tag = "043"]/marcxml:subfield[@code="a"]
            (:filter out trailing hyphens:)
            	let $gac :=  fn:replace(fn:normalize-space(fn:string($d)),"-+$","")            	
	            return
	                element bf:subject { 	                
	                    attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/geographicAreas/", $gac) }	                
                   }
            		
    let $biblink:= 
        element bf:derivedFrom {
            attribute rdf:resource{fn:concat("http://id.loc.gov/resources/bibs/",fn:string($marcxml/marcxml:controlfield[@tag eq "001"]))}
        }
        let $edited:=fn:concat(fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),1,4),"-",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),5,2),"-",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),7,2),"T",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),9,2),":",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),11,2))
      let $changed:= (  element bf:generationProcess {fn:concat("DLC transform-tool:",$marcbib2bibframe:last-edit)},
                        element bf:changeDate {$edited}
                      )
    
    let $schemes := 
            element madsrdf:isMemberOfMADSScheme {
                attribute rdf:resource {"http://id.loc.gov/resources/works"}
            }
 	
    return 
        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},            
       
            for $t in fn:distinct-values($types)
            return
              (:  element bf:workCategory {
                    attribute rdf:resource {fn:concat("http://id.loc.gov/test/workCategories/", $t)}
                },:)
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $t)}
                },
             $aLabel,
            $aLabelsWork880,
                 $dissertation,
            if ($uniformTitle/bf:workTitle) then
                $uniformTitle/*
            else
                (),
            $titles/bf:*,
        
            $names,
            $aud521,
            $issuance,             
            $language,
            $langs,
            $findaids,
            $abstract,
            $abstract-annotation,
            $audience,           
            $genre,
            $work3xx, 
            $cartography,
            $subjects,
            $gacs,            
            $work-classes,            
            $work-identifiers,            
            $work-notes,
            $complex-notes,
            $work-relateds,
      (:      $schemes,  removing madsrdf      :)    
            $biblink,
            $changed,
            for $i in $instances 
                return element  bf:hasInstance{$i},
             $instancesfrom856
            
        }
};

(:~
:   This function generates a subject.
:   It takes a specific 6xx as input.
:   It generates a bf:subject as output.
: 
:29 '600': ('subject', {'bibframeType': 'Person'}),
:30 '610': ('subject', {'bibframeType': 'Organization'}), 
:31 '611': ('subject', {'bibframeType': 'Meeting'}),   
:33 '630': ('uniformTitle', {'bibframeType': 'Title'}), 
:34 '650': ('subject', {'bibframeType': 'Topic'}), 
:35 '651': ('subject', {'bibframeType': 'Geographic'}), 

:   @param  $d        element is the marcxml:datafield  
:   @return bf:subject
:)
declare function marcbib2bibframe:get-subject(
    $d as element(marcxml:datafield)
    ) as element()
{
    let $subjectType := fn:string($marc2bfutils:subject-types/subject[@tag=$d/@tag])
    let $details :=
(:630 now handled as relatedwork:)
(:if (fn:matches(fn:string($d/@tag),"(600|610|611|630|648|650|651|655|751)")) then:)
	if (fn:matches(fn:string($d/@tag),"(600|610|611|648|650|651|655|751)")) then	
            let $last2Tag := fn:substring(fn:string($d/@tag), 2)
            (: 
                The controlfields and the leader are bogus, 
                designed purely to ensure it runs without error.
            :)
            let $marcAuthXML := 
                <marcxml:record>
                    <marcxml:leader>01243cz  a2200253n  4500</marcxml:leader>
                    <marcxml:controlfield tag="001">sh0000000</marcxml:controlfield>
                    <marcxml:controlfield tag="003">DLC</marcxml:controlfield>
                    <marcxml:controlfield tag="005">20110524062830.0</marcxml:controlfield>
                    <marcxml:controlfield tag="008">840503n| acannaabn          |a aaa      </marcxml:controlfield>
                    {
                        element marcxml:datafield {
                            attribute tag { fn:concat("1" , $last2Tag) },
                            attribute ind1 { " " },
                            attribute ind2 { "0" },
                            $d/*[@code ne "2"][@code ne "0"]
                        }
                    }
                </marcxml:record>
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($marcAuthXML)
            let $madsrdf := $madsrdf/madsrdf:*[1]
            let $details :=
                ( 
                    element bf:authorizedAccessPoint {fn:string($madsrdf/madsrdf:authoritativeLabel)},
                    element bf:label { fn:string($madsrdf/madsrdf:authoritativeLabel) },
                    element bf:hasAuthority {
                        element madsrdf:Authority {
                            element rdf:type {
                                attribute rdf:resource { 
                                    fn:concat("http://www.loc.gov/mads/rdf/v1#" , fn:local-name($madsrdf))
                                }
                            },
                            $madsrdf/madsrdf:authoritativeLabel
                        }
                    },
                    
                    (:
                    for $cl in $madsrdf/madsrdf:componentList
                    return
                        element bf:hasAuthority {
                        element madsrdf:Authority {                        
                        $madsrdf/madsrdf:authoritativeLabel,
                                element madsrdf:componentList {
                                    attribute rdf:parseType {"Collection"},
                                    for $a in $cl/madsrdf:*
                                    return
                                        element {fn:name($a)} {
                                            $a/rdf:type,
                                           element madsrdf:authoritativeLabel{ fn:string($a/madsrdf:authoritativeLabel)} 
                                        }
                                }
                             }
                        },
                    :)
                    for $sys-num in $d/marcxml:subfield[@code="0"] 
                    return marcbib2bibframe:handle-system-number($sys-num)                    
                )
            return ($details)
            
	   
       else if (fn:matches(fn:string($d/@tag),"(662|752)")) then
            (: 
                Note: 662 can include relator codes/terms, with which something
                will have to be done.
            :)
            let $aLabel := fn:string-join($d/marcxml:subfield[fn:matches(fn:string(@code),"(a|b|c|d|f|g|h)")], ". ") 
            let $components := 
                for $c in $d/marcxml:subfield[fn:matches(fn:string(@code),"(a|b|c|d|f|g|h)")]
                return
                    if ( fn:string($c/@code) eq "a" ) then
                        element madsrdf:Country {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "b" ) then
                        element madsrdf:State {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "c" ) then
                        element madsrdf:County {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "d" ) then
                        element madsrdf:City {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "f" ) then
                        element madsrdf:CitySection {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "g" ) then
                        element madsrdf:Geographic {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else if ( fn:string($c/@code) eq "h" ) then
                        element madsrdf:ExtraterrestrialArea {
                            element madsrdf:authoritativeLabel { fn:string($c) }
                        }
                    else  
                        ()
            let $details :=
                ( 
                    element rdf:type {
                        attribute rdf:resource { "http://www.loc.gov/mads/rdf/v1#HierarchicalGeographic"}
                    },
                    element bf:authorizedAccessPoint { fn:string($aLabel) },
                    element bf:label { fn:string($aLabel) },                    
                    element bf:hasAuthority {
                         element madsrdf:Authority {
                          element madsrdf:authoritativeLabel{fn:string($aLabel)},
                            element madsrdf:componentList {
                                attribute rdf:parseType {"Collection"},
                                $components 
                            }
                        }
                    }
                )
            return $details
            (:656 occupation itoamc in $2? :)
       else
           (
               element bf:label {fn:string-join($d/marcxml:subfield[fn:not(@code="6")], " ")},
               element bf:description {
                   fn:concat(
                       "This is derived from a MARC ",
                       fn:string($d/@tag),
                       " field."
                    )                    
                }
           )
	let $system-number:= 
        for $sys-num in $d/marcxml:subfield[@code="0"] 
                     return marcbib2bibframe:handle-system-number($sys-num)  
    return 
        element bf:subject {
            element {fn:concat("bf:",$subjectType)} { 
                $details,                
                marcbib2bibframe:generate-880-label($d,"subject"),
                $system-number
            }
        }

};
(:~
:   This function generates all languages .
:   It takes 041 and generates a wrapper 
:   It generates a bf:Language's as output.
: 
: $2 - Source of code (NR)
    also 546?
 

:   @param  $d        element is the marcxml:datafield  
:   @return wrap/bf:language* or wrap/bf:Language*

:)
   
declare function marcbib2bibframe:get-languages(
   $d as element(marcxml:record)
    ) as element()*
{
 let $parts:=
 
  <languageObjectParts>
  <sf code="a">text</sf>
    <sf code="b">summary or abstract</sf>
      <sf code="d">sung or spoken text</sf>
    <sf code="e">librettos</sf>
      <sf code="f">table of contents</sf>
     <sf code="g">accompanying material other than librettos</sf>
     <sf code="h">original</sf>
      <sf code="j">subtitles or captions</sf>
      <sf code="k">intermediate translations</sf>
      <sf code="m">original accompanying materials other than librettos</sf>
      <sf code="n">original libretto</sf>
      </languageObjectParts>
    (:if a=3chars and there's no $2, then bf:language, else bf:Language (Entity):)
return 
for $tag in $d/marcxml:datafield[@tag="041"]
	for $sf in $tag/marcxml:subfield 
	return element bf:language {
	           element bf:Language {
	               element bf:resourcePart{
        	           fn:string($parts//sf[@code=$sf/@code])
        	           },	               	            
	                   for $i in 0 to (fn:string-length($sf) idiv 3)-1
		                  let $pos := $i * 3 + 1		
		                      return 
		                          element bf:languageOfPart{
		                            attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , fn:substring($sf, $pos, 3))}
    		                      }                  
                }	
	       }	
};

(:~
:   This function generates a name.
:   It takes a specific datafield as input.
:   It generates a bf:uniformTitle as output.
:
:   @param  $d        element is the marcxml:datafield
:
:   @return bf:creator element OR a more specific relators:* one. 
:)
declare function marcbib2bibframe:get-name(
    $d as element(marcxml:datafield)     
    ) as element()
{
    let $relatorCode := marc2bfutils:clean-string(fn:string($d/marcxml:subfield[@code = "4"][1])) 
    
    let $label := if ($d/@tag!='534') then
    	fn:string-join($d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q'] , ' ')    	
    	else 
    	fn:string($d/marcxml:subfield[@code='a' ])
    	
    let $aLabel :=  marc2bfutils:clean-name-string($label)
    
    let $elementList := if ($d/@tag!='534') then
      element bf:hasAuthority{
         element madsrdf:Authority {
         element madsrdf:authoritativeLabel {$aLabel} (: ,
            element madsrdf:elementList {
            	attribute rdf:parseType {"Collection"},
                for $s in $d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']
                return
                    if ($s/@code eq "a") then
                         element madsrdf:NameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
                    else if ($s/@code eq "b") then
                         element madsrdf:PartNameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
                    else if ($s/@code eq "c") then
                         element madsrdf:TermsOfAddressNameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
                    else if ($s/@code eq "d") then
                         element madsrdf:DateNameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
                    else if ($s/@code eq "q") then
                         element madsrdf:FullNameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
                    else 
                        element madsrdf:NameElement {
                            element madsrdf:elementValue {fn:string($s)}
                         }
               }
               :)
            }   
        }
    else () (: 534 $a is not parsed:)
            
    let $class := 
        if ( fn:ends-with(fn:string($d/@tag), "00") ) then
            "bf:Person"
        else if ( fn:ends-with(fn:string($d/@tag), "10") ) then
            "bf:Organization"
        else if ( fn:ends-with(fn:string($d/@tag), "11") ) then
            "bf:Meeting"
        else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1)="1")  then
            "bf:Person" (:????:)
        else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1)="2")  then
            "bf:Organization" (:may be a meeting:)
        else 
            "bf:Agent"

    let $tag := fn:string($d/@tag)
    let $desc-role:=if (fn:starts-with($tag , "10") or fn:starts-with($tag , "11")) then "primary" else () 
    let $resourceRole := 
        if ($relatorCode ne "") then
            (: 
                k-note, added substring call because of cruddy data.
                record 16963854 had "aut 146781635" in it
                Actually, I'm going to undo this because this is a cataloging error
                and we want those caught.  was fn:substring($relatorCode, 1, 3))
            :)
            fn:concat("relators:" , $relatorCode)
        else if ( fn:starts-with($tag, "1") ) then
            "bf:creator"
        else if ( fn:starts-with($tag, "7") and $d/marcxml:subfield[@code="t"] ) then
            "bf:creator"
        else
            "bf:contributor"
            
    (: resourceRole inside the authority makes it un-re-useable; removed 2013-12-03
    let $resourceRoleTerms := 
        for $r in $d/marcxml:subfield[@code="e"]
        return element bf:resourceRole {fn:string($r)}
:)
    let $bio-links:=
        if ( $d/../marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i")]) then         
        (:set up annotations for each contributor bio link:)    
        for $link in $d/../marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i")]
            return     marcbib2bibframe:generate-instance-from856($link, "person")            
        else 
            ()
    let $system-number:= 
        for $sys-num in $d/marcxml:subfield[@code="0"] 
                     return marcbib2bibframe:handle-system-number($sys-num)            
    return

       element {$resourceRole} {
            element {$class} {  (:$internal-name-link,      :)
                element bf:label { marc2bfutils:clean-name-string($label)},                
                if ($d/@tag!='534') then element bf:authorizedAccessPoint {$aLabel} else (),
                marcbib2bibframe:generate-880-label($d,"name"),
                $elementList,             
             (:   $resourceRoleTerms,:)
                 $system-number,
                 $bio-links
                 (:nate removed this so we can re-use the agent. now we assume that creator is primary and contributors are not:)
                (:element bf:descriptionRole { $desc-role}:)
            }
        }
};

(:~
:   This function generates a name from a Statement of 
:   Responsibility of string.  It's going to take work.
:
:   @param  $c     is the string to parse
:   @param  $prop       is the name of the prop to create   
:   @return element  
:)
declare function marcbib2bibframe:get-name-fromSOR(
        $c as xs:string,
        $prop as xs:string)
{
        let $role :=
            if ( fn:contains($c, " by") ) then
                if ( fn:normalize-space(fn:replace($c, " by", "")) eq "" ) then
                    ""
                else
                    fn:concat(fn:substring-before($c, " by"), " by")
            else
                ""
        let $role := fn:normalize-space($role)
        
        let $name :=
            if ( fn:contains($c, " by") ) then
                fn:substring-after($c, " by")
            else
                $c
        let $name := fn:normalize-space($name)
        return
            element {$prop} {
                element bf:Agent {
                    element bf:label {$name},                  
                    if ($role ne "") then
                        element bf:resourceRole {$role}
                    else
                        ()
                }
            }

}; 
(:~
:   This is the function gets the intendedaudience entity from 521.
:
:   @param  $tag        element is the datafield 521  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:get-521audience(
    $tag as element(marcxml:datafield)
    ) as item()*
{
let $type:=  if ($tag/@ind1=" ") then "Audience: " else if ($tag/@ind1=" 0") then "Reading grade level" else if  ($tag/@ind1="1") then "Interest age level" else if  ($tag/@ind1="2") then "Interest grade level" else if  ($tag/@ind1="3") then "Special audience characteristics" else if  ($tag/@ind1="4") then "Motivation/interest level" else ()
(:if type!=audience then you need entity:)
return if ($type= "Audience: ") then
	if ( fn:not($tag/marcxml:subfield[@code="b"]) ) then
		element bf:intendedAudience {fn:concat($type,": ",$tag/marcxml:subfield[@code="a"])}
	else element bf:intendedAudience {
		  element bf:IntendedAudience {
		      	   element bf:audience {fn:concat($type,": ",$tag/marcxml:subfield[@code="a"])},
			       element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}	
	}}
	else if ($type) then (:you need audienceType:)
	element bf:intendedAudience {
		element bf:IntendedAudience {
			if ($tag/marcxml:subfield[@code="a"]) then
				element bf:audience {fn:string($tag/marcxml:subfield[@code="a"])}
			else (),	
			element bf:audienceLevel {$type},
			if ($tag/marcxml:subfield[@code="b"]) then
				element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}
			else ()	
		}
		}
	else if ($tag/marcxml:subfield[@code="b"]) then
		element bf:intendedAudience {
			element bf:IntendedAudience {
			element bf:audienceType {$type},
			if ($tag/marcxml:subfield[@code="a"]) then
				element bf:audience {fn:string($tag/marcxml:subfield[@code="a"])}
			else (),
				element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}
		}}
	else   if ($tag/marcxml:subfield[@code="a"]) then
	 	element bf:intendedAudience {fn:concat($type,": ",$tag/marcxml:subfield[@code="a"])}
	 else ()

};
(:~
:   This is the function generates a work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:get-resourceTypes(
    $record as element(marcxml:record)
    ) as item()*
{

    let $leader06 := fn:substring(fn:string($record/marcxml:leader), 7, 1)
    (:let $cf007-00 :=:)
    let $types:=
    (	for $cf in $record/marcxml:controlfield[@tag="007"]/fn:substring(text(),1,1)
    		for $t in $marc2bfutils:resourceTypes/type[@cf007]
    			where fn:matches($cf,$t/@cf007) 
    				return fn:string($t)    	
    (:let $sf336a :=:) ,
    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="a"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf336a]
    			where fn:matches(fn:string($field),$t/@sf336a) 
    				return fn:string($t),   				
(:    let $sf336b := :)
    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="b"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf336b]
    			where fn:matches(fn:string($field),$t/@sf336b)
    				return fn:string($t), 
    				
    (:let $sf337a := :)
    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="a"]		
    		for $t in $marc2bfutils:resourceTypes/type[@sf337a]
    			where fn:matches(fn:string($field),$t/@sf337a)
    				return fn:string($t) ,   	
(:let $sf337b := :)
    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="b"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf337b]
    			where fn:matches(fn:string($field),$t/@sf337b)
    				return fn:string($t)  ,  	
    (:let $ldr6 :=:) 
    	for $t in $marc2bfutils:resourceTypes/type
        		where $t/@leader6 eq $leader06
        		return fn:string($t)
        		)
    return $types
    
};

(:~
:   This returns a basic title from 245. 
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:uniformTitle
: drop the $h from the work title????
:)
declare function marcbib2bibframe:get-title(
            $d as element(marcxml:datafield)
        ) 
{
    (: Only $a,b presently - this will have to change :)
    (:??? filter out nonsorting chars???:)
    let $title := fn:replace(fn:string-join($d/marcxml:subfield[fn:matches(@code,"(a|b|h|k|n|p|s)")] ," "),"^(.+)/$","$1")
    let $title := 
        if (fn:ends-with($title, ".")) then
            fn:substring($title, 1, fn:string-length($title) - 1 )
        else
            $title
     let $title := fn:normalize-space($title)
     
     let $element-name :=
            if ($d/@tag eq "246" ) then 
                "bf:variantTitle" 
            else  if ($d/@tag = "222" ) then
                "bf:keyTitle" 
            else  if ($d/@tag ="210" ) then
                "bf:abbreviatedTitle"
            else "bf:title"
       let $lang := if ($d/@tag = "242" and $d/marcxml:subfield[@code = "y"] ne "" ) then                            
                        attribute xml:lang {fn:string($d/marcxml:subfield[@code = "y"][1])}
                    else
                        ()
    
    return 
        ( element bf:title { $lang,             $title         },  
        if ($element-name ne 'bf:title')  then
                element {$element-name} { $lang,      $title          }
        else (),
        
            if ($d/@tag="246") then                  
               element {$element-name} {
                    element bf:Title { 
                          if ($d/@ind2!=" ") then element bf:titleType {
                                 if ($d/@ind2="0") then "title portion"
                                 else if ($d/@ind2="1") then "parallel title"
                                 else if ($d/@ind2="2") then "distinctive title"
                                 else if ($d/@ind2="3") then "other title"
                                 else if ($d/@ind2="4") then "cover title"
                                 else if ($d/@ind2="5") then "added title page title"
                                 else if ($d/@ind2="6") then "caption title"
                                 else if ($d/@ind2="7") then "Running title"
                                 else if ($d/@ind2="8") then "Spine title"                                      
                                else ()
                                }
                           else (),
                          element bf:label {fn:string($d/marcxml:subfield[@code="a"])},
                          if ($d/marcxml:subfield[@code="b"]) then element bf:subtitle {fn:string($d/marcxml:subfield[@code="b"])} else (),
                           if ($d/marcxml:subfield[@code="p"]) then element bf:partTitle {fn:string($d/marcxml:subfield[@code="p"])} else (),
                            if ($d/marcxml:subfield[@code="f"]) then element bf:titleVariationDate {fn:string($d/marcxml:subfield[@code="f"])} else ()                              
                    }
                 } (:end Title:)
                                                
            else (),
             marcbib2bibframe:generate-titleNonsort($d,$title, $element-name),
       
            if ($d/@tag="210" and $d/marcxml:subfield[@code="2"] ) then 
             element bf:titleSource{fn:string($d/marcxml:subfield[@code="2"])} 
            else (),
            marcbib2bibframe:generate-880-label($d,"title")
        )
};
(:~
:   This function generates a related work, as translation of from the 100, 240.
:   It takes a 130 or 240 element.
:   It generates a bf:translationOf/bf:Work
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:translationOf
:)
declare function marcbib2bibframe:generate-translationOf (    $d as element(marcxml:datafield)
    ) as element(bf:translationOf)
    
{
  let $aLabel :=  marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[fn:not(fn:matches(@code,"(0|6|8|l)") ) ]," "))    
    
return element bf:translationOf {
               element bf:Work {
                (:element bf:authorizedAccessPoint{$label},:)                
                element bf:title {$aLabel},
                marcbib2bibframe:generate-titleNonsort($d,$aLabel,"bf:title") ,                                    
                element madsrdf:authoritativeLabel{$aLabel},
                if ($d/../marcxml:datafield[@tag="100"]) then
                    element bf:creator{fn:string($d/../marcxml:datafield[@tag="100"]/marcxml:subfield[@code="a"])}
                else ()
                }
       }
};
(:~
:   This function generates a uniformTitle.
:   It takes a specific datafield as input.
:   It generates a bf:Work as output.
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:workTitle
:)
declare function marcbib2bibframe:get-uniformTitle(
    $d as element(marcxml:datafield)
    ) as element(bf:Work)
{
    (:let $label := fn:string($d/marcxml:subfield["a"][1]):)
    (:??? filter out nonsorting chars???:)
    (:remove $o in musical arrangements???:)
    let $aLabel := marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[@code ne '0' and @code!='6' and @code!='8'] , ' '))       
    let $translationOf :=  
        if ($d/marcxml:subfield[@code="l"]) then marcbib2bibframe:generate-translationOf($d)
                else ()
                
    
    let $elementList := 
        element bf:hasAuthority {
        element madsrdf:Authority {
       element madsrdf:authoritativeLabel{ fn:string($aLabel)},
        element madsrdf:elementList {
        	attribute rdf:parseType {"Collection"},
            for $s in $d/marcxml:subfield
            return
                if ($s/@code eq "a") then
                     element madsrdf:MainTitleElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "p") then
                     element madsrdf:PartNameElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "l") then
                     element madsrdf:LanguageElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "s") then
                     element madsrdf:TitleElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "k") then
                     element madsrdf:GenreFormElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "d") then
                     element madsrdf:TemporalElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else if ($s/@code eq "f") then
                     element madsrdf:TemporalElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
                else
                    element madsrdf:TitleElement {
                        element madsrdf:elementValue {marc2bfutils:clean-title-string(fn:string($s))}
                     }
        }
        }
        }
    return
    
        element bf:Work {
                element bf:label {$aLabel},        
	  		    element bf:title {$aLabel},              
              $elementList,
              $translationOf
            }                    
};

(:~
:   This function takes an ISBN string and 
:   determines if it's 10 or 13, and returns both the 10 and 13 for this one.
:
:   @param  $s        is fn:string
:   @return wrap/bf:isbn element()
:)

declare function marcbib2bibframe:get-isbn($isbn as xs:string ) as element() {
    (:
        let $isbn1:="9780792312307" (:produces 0792312309 ok:)
        let $isbn1:="0792312309" (:produces  9780792312307 ok:)
        let $isbn1:="0-571-08989-5" (:produces 9780571089895  ok:)
        let $isbn1:="0 571 08989 5" (:produces 9780571089895  ok:)
        verify here:http://www.isbn.org/converterpub.asp
        let $isbn:="paperback" (:produces "error"  ok:)
    :) 

    let $clean-isbn:=fn:replace($isbn,"[- ]+","")
    (:let $isbn-num:=replace($clean-isbn,"^[^0-9]*(\d+)[^0-9]*$","$1" ):) 
    (: test on isbn 10, 13, hyphens, empty, strings only :)

    let $isbn-num1:=  fn:replace($clean-isbn,"^[^0-9]*(\d+)[^0-9]*$","$1" ) 
    let $isbn-num:= if (fn:string-length($isbn-num1)=9) then fn:concat($isbn-num1,'X') else $isbn-num1

    (: test on isbn 10, 13, hyphens, empty, strings only :)

    return
        if (fn:number($isbn-num) or fn:number($isbn-num1) ) then
    
	        if ( fn:string-length($isbn-num) = 10  ) then
	            let $isbn12:= fn:concat("978",fn:substring($isbn-num,1,9))
	            let $odds:= fn:number(fn:substring($isbn12,1,1)) + fn:number(fn:substring($isbn12,3,1)) +fn:number(fn:substring($isbn12,5,1)) + fn:number(fn:substring($isbn12,7,1)) +fn:number(fn:substring($isbn12,9,1)) +fn:number(fn:substring($isbn12,11,1))
	            let $evens:= (fn:number(fn:substring($isbn12,2,1)) + fn:number(fn:substring($isbn12,4,1)) +fn:number(fn:substring($isbn12,6,1)) + fn:number(fn:substring($isbn12,8,1)) +fn:number(fn:substring($isbn12,10,1)) +fn:number(fn:substring($isbn12,12,1)) ) * 3      
	            let $chk:= 
	               if (  (($odds + $evens) mod 10) = 0) then 
	                   0 
	               else 
	                   10 - (($odds + $evens) mod 10)
                return
               	    element wrap {
               	       element bf:isbn10 {$isbn-num},
               		   element bf:isbn13 { fn:concat($isbn12,$chk)}
               	    }
                 
            else (: isbn13 to 10 :)
                let $isbn9:=fn:substring($isbn-num,4,9) 
                let $sum:= (fn:number(fn:substring($isbn9,1,1)) * 1) 
                        + (fn:number(fn:substring($isbn9,2,1)) * 2)
                        + (fn:number(fn:substring($isbn9,3,1)) * 3)
                        + (fn:number(fn:substring($isbn9,4,1)) * 4) 
                        + (fn:number(fn:substring($isbn9,5,1)) * 5)
                        + (fn:number(fn:substring($isbn9,6,1)) * 6)
                        + (fn:number(fn:substring($isbn9,7,1)) * 7)
                        + (fn:number(fn:substring($isbn9,8,1)) * 8)
                        + (fn:number(fn:substring($isbn9,9,1)) * 9)
                let $check_dig:= 
                    if ( ($sum mod 11) = 10 ) then 
                        'X'
                    else 
                        ($sum mod 11)
                return
                    element wrap {
                        element bf:isbn10 {fn:concat($isbn9,$check_dig) }, 
                        element bf:isbn13 {$isbn-num}
                    }                     
           
        else 
            element wrap {
                element bf:isbn10 {"error"},
                element bf:isbn13 {"error"}
            }

};
(:~
:   This function processes out the leader and control fields
:
:  $marcxml    is marcxml:record
:  $resource is work or instance
:   @return ??
:)
declare function marcbib2bibframe:generate-class(
       $marcxml as element(marcxml:record),
    $resource as xs:string
    ) as element ()*    
{(: interesting: try this first?
and move this to the function for classif...
For the Classify service at OCLC, when it is LCC we use a regular
expression: "^[a-zA-Z]{1,3}[1-9].*$". For DDC we filter out the truncation symbols, spaces, quotes, etc.

-Steve Meyer 
:)
	  
    let $classes:= 
        if ($resource="instance") then (:no classes currently defined for instance ; this should never happen:)
            $marc2bfutils:classes//property[@domain="Instance"]
        else 
            $marc2bfutils:classes//property[@domain="Work"]
   let $validLCCs:=("DAW","DJK","KBM","KBP","KBR","KBU","KDC","KDE","KDG","KDK","KDZ","KEA","KEB","KEM","KEN","KEO","KEP","KEQ","KES","KEY","KEZ","KFA","KFC","KFD","KFF","KFG","KFH","KFI","KFK","KFL","KFM","KFN","KFO","KFP","KFR","KFS","KFT","KFU","KFV","KFW","KFX","KFZ","KGA","KGB","KGC","KGD","KGE","KGF","KGG","KGH","KGJ","KGK","KGL","KGM","KGN","KGP","KGQ","KGR","KGS","KGT","KGU","KGV","KGW","KGX","KGY","KGZ","KHA","KHC","KHD","KHF","KHH","KHK","KHL","KHM","KHN","KHP","KHQ","KHS","KHU","KHW","KJA","KJC","KJE","KJG","KJH","KJJ","KJK","KJM","KJN","KJP","KJR","KJS","KJT","KJV","KJW","KKA","KKB","KKC","KKE","KKF","KKG","KKH","KKI","KKJ","KKK","KKL","KKM","KKN","KKP","KKQ","KKR","KKS","KKT","KKV","KKW","KKX","KKY","KKZ","KLA","KLB","KLD","KLE","KLF","KLH","KLM","KLN","KLP","KLQ","KLR","KLS","KLT","KLV","KLW","KMC","KME","KMF","KMG","KMH","KMJ","KMK","KML","KMM","KMN","KMP","KMQ","KMS","KMT","KMU","KMV","KMX","KMY","KNC","KNE","KNF","KNG","KNH","KNK","KNL","KNM","KNN","KNP","KNQ","KNR","KNS","KNT","KNU","KNV","KNW","KNX","KNY","KPA","KPC","KPE","KPF","KPG","KPH","KPJ","KPK","KPL","KPM","KPP","KPS","KPT","KPV","KPW","KQC","KQE","KQG","KQH","KQJ","KQK","KQM","KQP","KQT","KQV","KQW","KQX","KRB","KRC","KRE","KRG","KRK","KRL","KRM","KRN","KRP","KRR","KRS","KRU","KRV","KRW","KRX","KRY","KSA","KSC","KSE","KSG","KSH","KSK","KSL","KSN","KSP","KSR","KSS","KST","KSU","KSV","KSW","KSX","KSY","KSZ","KTA","KTC","KTD","KTE","KTF","KTG","KTH","KTJ","KTK","KTL","KTN","KTQ","KTR","KTT","KTU","KTV","KTW","KTX","KTY","KTZ","KUA","KUB","KUC","KUD","KUE","KUF","KUG","KUH","KUN","KUQ","KVB","KVC","KVE","KVH","KVL","KVM","KVN","KVP","KVQ","KVR","KVS","KVU","KVW","KWA","KWC","KWE","KWG","KWH","KWL","KWP","KWQ","KWR","KWT","KWW","KWX","KZA","KZD","AC","AE","AG","AI","AM","AN","AP","AS","AY","AZ","BC","BD","BF","BH","BJ","BL","BM","BP","BQ","BR","BS","BT","BV","BX","CB","CC", "CD","CE","CJ","CN","CR","CS","CT","DA","DB","DC","DD","DE","DF","DG","DH","DJ","DK","DL","DP","DQ","DR","DS","DT","DU","DX","GA","GB","GC","GE","GF","GN","GR","GT","GV","HA","HB","HC","HD","HE","HF","HG","HJ","HM","HN","HQ","HS","HT","HV","HX","JA","JC","JF","JJ","JK","JL","JN","JQ","JS","JV","JX","JZ","KB","KD","KE","KF","KG","KH","KJ","KK","KL","KM","KN","KP","KQ","KR","KS","KT","KU","KV","KW","KZ","LA","LB","LC","LD","LE",  "LF","LG","LH","LJ","LT","ML","MT","NA","NB","NC","ND","NE","NK","NX","PA","PB","PC","PD","PE","PF","PG","PH","PJ","PK","PL","PM","PN","PQ","PR","PS","PT","PZ","QA","QB","QC","QD","QE","QH","QK","QL","QM","QP","QR","RA","RB","RC","RD","RE","RF","RG",   "RJ","RK","RL","RM","RS","RT","RV","RX","RZ","SB","SD","SF","SH","SK","TA","TC","TD","TE","TF","TG","TH","TJ","TK","TL","TN","TP","TR","TS","TT","TX","UA","UB","UC","UD","UE","UF","UG","UH","VA","VB","VC","VD","VE","VF","VG","VK","VM","ZA","A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","Z")
    return
        for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|051|055|060|061|070|071|080|082|083|084|086)")]
                            
                for $cl in $this-tag/marcxml:subfield[@code="a"]           
                	let $valid:=
                	 	if (fn:not(fn:matches($this-tag/@tag,"(050|051|055|060|061|070|071)"))) then
                			fn:string($cl)
                		else (:050 has non-class stuff in it: :)
                  			let $strip := fn:replace(fn:string($cl), "(\s+|\.).+$", "")			
                  			let $subclassCode := fn:replace($strip, "\d", "")			
                  			return                   		            
        			            if (
        			            (: lc classes shouldn't  have a space after the alpha prefix, like DA1 vs "DA 1" ??? don't  enforce this???
        			            :)
        			                (:fn:substring(fn:substring-after(fn:string($cl), $subclassCode),1,1)!=' ' and :) 
        			                $subclassCode = $validLCCs 
        			                ) then   								  
        			                fn:string($strip)
        			            else (:invalid content in sfa:)
        			                () 
        	                
        return 
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
                        element  {fn:concat("bf:",$property)} {          
                     			if ($property="classificationLcc" ) then 
                     				attribute rdf:resource {fn:concat( "http://id.loc.gov/authorities/classification/",fn:string($valid))}
                     			else
                                             		fn:string($cl)                            
                            }
            else if (
                ($valid and fn:matches($this-tag/@tag,"(050|051|055|060|061|070|071)"))
                    or 
                fn:not(fn:matches($this-tag/@tag,"(050|051|055|060|061|070|071)"))
                ) then
                let $assigner:=              
                       if ($this-tag/@tag="050" and $this-tag/@ind2="0") then "dlc"
                       else if (fn:matches($this-tag/@tag,"(051)")) then "dlc"
                       else if (fn:matches($this-tag/@tag,"(060|061)")) then "dnlm"
                       else if (fn:matches($this-tag/@tag,"(070|071)")) then "dnal"
                       else if (fn:matches($this-tag/@tag,"(082|083|084)")  and $this-tag/marcxml:subfield[@code="q"]) then fn:string($this-tag/marcxml:subfield[@code="q"])
                       else ()
	return                       
                element bf:classification {
                    element bf:Classification {                        
                        element bf:classificationScheme {
                            if (fn:matches($this-tag/@tag,"(050|051)")) then "lcc" 
		            		else if (fn:matches($this-tag/@tag,"080")) then "udc"
		            		else if (fn:matches($this-tag/@tag,"082")) then "ddc"
		            		else if (fn:matches($this-tag/@tag,"(084|086)")) then fn:string($this-tag/marcxml:subfield[@code="2"])
		            		else ()
                        },
                        
                        if (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="m"] ) then
                            element bf:classificationSchemePart  {
                                if ($this-tag/marcxml:subfield[@code="m"] ="a") then "standard" 
                                else if ($this-tag/marcxml:subfield[@code="m"] ="b") then "optional" 
                                else ()
                            }
                        else (),                        
            
            	       element bf:classificationNumber {fn:string($cl)},
            	       element bf:label {fn:string($cl)},
             	       if ( $assigner) then 
                         	element bf:classificationAssigner {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/organizations/",fn:encode-for-uri($assigner))}}
                       else (),             			
			            	
           	           if ( 
             		    (fn:matches($this-tag/@tag,"(080|082|083)") and fn:matches($this-tag/@ind1,"(0|1)") ) or 
             		    (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="2"] )
            	 		   ) then  
                            element bf:classificationEdition {
                                if (fn:matches($this-tag/@tag,"(080|082|083)") and $this-tag/@ind1="1") then
								    "abridged"
                                else if (fn:matches($this-tag/@tag,"(080|082|083)") and $this-tag/@ind1="0") then							
								    "full"
								else if (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="2"] ) then
								    fn:string($this-tag/marcxml:subfield[@code="2"] )
								else ()
							}
                        else (),
						
		              for $sfc in $this-tag[fn:matches($classes[@name="classCopy"]/@tag,@tag)]/marcxml:subfield[@code="c"]
                       return 
                            element bf:classificationCopy {fn:string($sfc)},
                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="c"]) then 
								    element bf:classificationSpanEnd {fn:string($this-tag/marcxml:subfield[@code="c"])}
								else (),			
                                
                                if (fn:matches($this-tag/@tag,"086") and $this-tag/marcxml:subfield[@code="z"]) then
							 		element bf:classificationStatus  {"canceled/invalid"} 
                                else (),

                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="z"]) then
								 	element bf:classificationTable  {fn:string( $this-tag/marcxml:subfield[@code="z"])} 
                                else (),

                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="y"]) then
							 		element bf:classificationTableSeq  {fn:string( $this-tag/marcxml:subfield[@code="y"])} 
                                else ()
                    }
            }
            else ()
};
