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

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";

declare namespace bf            = "http://bibframe.org/vocab/";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace relators      = "http://id.loc.gov/vocabulary/relators/";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
declare namespace notes         = "http://id.loc.gov/vocabulary/notes/";

(: VARIABLES :)
declare variable $marcbib2bibframe:resourceTypes := (
    <resourceTypes>
        <type leader6="a">Text</type>
        <type leader6="c">NotatedMusic</type>
        <type leader6="d">NotatedMusic</type>
        <type leader6="d">Manuscript</type>
        <type leader6="e">Cartographic</type>
        <type leader6="f">Cartographic</type>
        <type leader6="f">Manuscript</type>
        <type leader6="g">MovingImage</type>
        <type leader6="i">Audio</type>
        <type leader6="j">MusicRecording</type>
        <type leader6="k">StillImage</type>
        <type leader6="m">SoftwareApplication</type>
        <type leader6="o" marcnote="Kit">Collection</type>
        <type leader6="p">MixedMaterial</type>
        <type leader6="r">Artifact</type>
        <type leader6="t">Text</type>
        <type leader6="t">Manuscript</type>
        <type leader7="c">Collection</type>
    </resourceTypes>
    );
    
declare variable $marcbib2bibframe:targetAudiences := (
    <targetAudiences>
        <type cf008-22="a">pre</type>
        <type cf008-22="b">pri</type>
        <type cf008-22="c">pra</type>
        <type cf008-22="d">ado</type>
        <type cf008-22="e">adu</type>
        <type cf008-22="f">spe</type>
        <type cf008-22="g">gen</type>
        <type cf008-22="j">juv</type>
    </targetAudiences>
    );
    
 declare variable $marcbib2bibframe:subject-types := (
	 <subjectTypes> 
		<subject tag="600">Person</subject>
		<subject tag="610">Organization</subject>
		<subject tag="611">Meeting</subject>
		<subject tag="630">UniformTitle</subject>
		<subject tag="648">Chronological</subject>
		<subject tag="650">Topic</subject>
		<subject tag="651">Place</subject>
		<subject tag="654">Topical</subject>
		<subject tag="655">Genre</subject>
		<subject tag="656">Occupation</subject>
		<subject tag="657">Function</subject>
		<subject tag="658">Objective</subject>
		<subject tag="662">HierarchicalPlace</subject>		
		<subject tag="653">UncontrolledTopic</subject>		
		<subject tag="751">Place</subject>
		<subject tag="752">HierarchicalPlace</subject>
	</subjectTypes>
);

declare variable $marcbib2bibframe:formsOfItems := (
    <formsOfItems>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="a">Microfilm</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="b">Microfiche</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="c">Microopaque</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="d">Large print</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="f">Braille</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial SoftwareApplication" cf008-23="o">Online</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial SoftwareApplication" cf008-23="q">Direct electronic</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="r">Regular print reproduction</type>
        <type rType="Text Book NotatedMusic MusicRecording MixedMaterial" cf008-23="s">Electronic</type>
    </formsOfItems>
    );

(:code=a unless specified:)
declare variable $marcbib2bibframe:identifiers := 
    (
    <identifiers>
        <instance-identifiers>
            <id tag="010" property="identifiers:lccn">Library of Congress Control Number</id>
            <id tag="018" property="bf:copyrightArticleFee">Copyright Article-Fee Code</id>
            <id tag="022" property="identifiers:issn">International Standard Serial Number</id>
            <id tag="024" ind1="0" property="identifiers:isrc">International Standard Recording Code</id>
            <id tag="024" ind1="1" property="identifiers:upc">Universal Product Code</id>
            <id tag="024" ind1="2" property="identifiers:ismn">International Standard Music Number</id>
            <id tag="024" ind1="3" property="identifiers:ean">International Article Number</id>
            <id tag="024" ind1="4" property="identifiers:sici">Serial Item and Contribution Identifier</id>
            <id tag="025" property="identifiers:ovopAcqNum">Overseas Acquisition Number</id>
            <id tag="028" ind1="0" property="identifiers:issue-number">Publisher's Issue Number</id>
            <id tag="028" ind1="1" property="identifiers:matrix-number">Sound Recording Matrix Number</id>
            <id tag="028" ind1="2" property="identifiers:music-plate">Publisher's Music Plate Number</id>
            <id tag="028" ind1="3" property="identifiers:music-publisher">Publisher-assigned Music Number</id>
            <id tag="028" ind1="4" property="identifiers:videorecording-identifier">Publisher-assigned videorecording number</id>
            <id tag="032" property="bf:postalRegistrationNumber">Postal Registration Number</id>
            <id tag="035" property="identifiers:syscontrolID">System Control Number</id>
            <id tag="037" property="identifiers:acqSource">Source of Acquisition</id>
            <id tag="044" property="identifiers:countryofPublisher">Country of Publishing/Producing Entity Code</id>
            <id tag="048" property="bf:musicalInstruments">Number of Musical Instruments or Voices Codes</id>
            <id tag="055" property="bf:canadaClass" codes="ab">Classification Numbers Assigned in Canada</id>
            <id tag="060" property="bf:nlmCall" codes="ab">National Library of Medicine Call Number</id>
            <id tag="070" property="bf:nalCall" codes="ab">National Agricultural Library Call Number</id>
            <id tag="074" property="bf:gpoItemNum">GPO Item Number</id>
            <id tag="080" property="bf:udcNum" codes="ab">Universal Decimal Classification Number</id>
            <id tag="082" property="identifiers:dewey" codes="ab">Dewey Decimal Classification Number</id>
            <id tag="083" property="bf:deweyplus" codes="ab">Additional Dewey Decimal Classification Number</id>
            <id tag="084" property="bf:otherClass" codes="ab">Other Classification Number</id>
            <id tag="088" property="bf:reportNum">Report Number</id>
        </instance-identifiers>
        <work-identifiers>
            <id tag="010" property="identifiers:lccn">Library of Congress Control Number</id>
            <id tag="012" property="identifiers:conser">CONSER Number</id>
            <id tag="013" property="identifiers:patentNum">Patent Control Information</id>
            <!--013$b is a location code-->
            <id tag="015" property="bf:natbibliographyNum">National Bibliography Number</id>
            <id tag="016" property="bf:natbibAgencyContrrol">National Bibliographic Agency Control Number</id>
            <id tag="022" property="identifiers:issn-l" subfields="l">International Standard Serial Number</id>
            <id tag="024" ind1="0" property="identifiers:isrc">International Standard Recording Code</id>
            <id tag="024" ind1="1" property="identifiers:upc">Universal Product Code</id>
            <id tag="024" ind1="2" property="identifiers:ismn">International Standard Music Number</id>
            <id tag="024" ind1="3" property="identifiers:ean">International Article Number</id>
            <id tag="024" ind1="7" property="identifiers:sici">Serial Item and Contribution Identifier</id>(:!!!:)
            <id tag="027" property="identifiers:strn">Standard Technical Report Number</id>
            <id tag="030" property="identifiers:coden">CODEN Designation</id>
            <id tag="031" property="bf:musicalIncipits">Musical Incipits Information</id>
            <id tag="033" property="bf:dateTimePlace">Date/Time and Place of an Event</id>
            <id tag="034" property="bf:cartographicData">Coded Cartographic Mathematical Data</id>
            <id tag="036" property="identifiers:studyNumber">Original Study Number for Computer Data files</id>
            <id tag="038" property="bf:licensor">Record Content Licensor</id>
            <id tag="045" property="bf:era">Time Period of content</id>
            <id tag="047" property="bf:musicalGenre">Form of Musical Composition Code</id>
            <id tag="055" property="bf:canadaClass">Classification Numbers Assigned in Canada</id>
            <id tag="060" property="bf:nlmCall">National Library of Medicine Call Number</id>
            <id tag="070" property="bf:nalCall">National Agricultural Library Call Number</id>
            <id tag="072" property="bf:subjectCategory" subfields="ax2">Subject Category Code</id>
            <id tag="080" property="identifiers:udcNum">Universal Decimal Classification Number</id>
            <id tag="082" property="identifiers:dewey">Dewey Decimal Classification Number</id>
            <id tag="083" property="bf:deweyplus">Additional Dewey Decimal Classification Number</id>
            <id tag="084" property="bf:otherClass">Other Classification Number</id>
            <id tag="085" property="bf:classComponents">Synthesized Classification Number Components</id>
            <id tag="086" property="bf:govodocsClass">Government Document Classification Number</id>
        </work-identifiers>
    </identifiers>
    );

declare variable $marcbib2bibframe:physdesc-list:= 
    (
        <physdesc>
            <instance-physdesc>
                <field tag="300" codes="3" property="materialsSpecified">Materials specified</field>
                <field tag="300" codes="a" property="extent">Physical Description</field>
		        <field tag="300" codes="b" property="otherFeatures">Other Physical Details</field>
		        <field tag="300" codes="c" property="dimensions">Dimensions</field>
   		        <field tag="300" codes="e" property="additionalMaterial"> Accompanying material</field>
        		<field tag="300" codes="f" property="unitType">Type of unit </field>
        		<field tag="300" codes="g" property="unitSize">Size of unit </field>		
        		<field tag="306" codes="a" property="playingTime">Playing Time </field>
        		<field tag="307" codes="ab" property="hoursAvailable"> Hours Available</field>
        		<field tag="310" codes="ab">Current Publication Frequency </field>
        		<field tag="321" codes="ab"> Former Publication Frequency </field>
        		<field tag="337" codes="ab23"> Media Type </field>
        		<field tag="338" codes="ab23"> Carrier Type </field>
        		<field tag="340" codes="abcdefhijkmno023"> Physical Medium </field>
        		<field tag="342" codes="abcdefghijklmnopqrstuvw2"> Geospatial Reference Data </field>
        		<field tag="343" codes="abcdefghi">Planar Coordinate Data </field>
        		<field tag="344" codes="abcdefgh023"> Sound Characteristics </field>
        		<field tag="345" codes="ab023"> Projection Characteristics of Moving Image </field>
	           <field tag="346" codes="ab023"> Video Characteristics </field>
	           <field tag="347" codes="abcdef023"> Digital File Characteristics </field>
	           <field tag="351" codes="abc3"> Organization and Arrangement of Materials </field>
	           <field tag="352" codes="abcdefgiq"> Digital Graphic Representation </field>
	           <field tag="355" codes="abcdefghj"> Security Classification Control </field>
	           <field tag="357" codes="abcg"> Originator Dissemination Control </field>
	           <field tag="362" codes="az"> Dates of Publication and/or Sequential Designation </field>
	           <field tag="363" codes="abcdefghijklmuvxz"> Normalized Date and Sequential Designation </field>
	           <field tag="365" codes="abcdefghijkm2"> Trade Price </field>
	           <field tag="366" codes="abcdefgjkm2"> Trade Availability Information </field>
	           <field tag="377" codes="al2"> Associated Language </field>
    	        <field tag="380" codes="a02"> Form of Work </field>
	           <field tag="381" codes="auv02"> Other Distinguishing Characteristics of Work or Expression </field>
	           <field tag="382" codes="abdnpsv02"> Medium of Performance </field>
	           <field tag="383" codes="abcde2"> Numeric Designation of Musical Work </field>
	           <field tag="384" codes="a"> Key </field>
        	   </instance-physdesc>
	           <work-physdesc>
	           <field tag="336" codes="ab23"> Content Type </field>
	       </work-physdesc>
        </physdesc>
    );
    
declare variable $marcbib2bibframe:notes-list:= (
<notes>
	<work-notes>
		<note tag ="500" property="general">General Note</note>
		
		<note tag ="502" property="thesis">Dissertation Note</note>
		<note tag ="504" property="bibliography">Bibliography, Etc. Note</note>
		<note tag ="505" property="contents" ind2="0">Formatted Contents Note</note>
		<note tag ="510" property="references">Citation/References Note</note>
		<note tag ="513" property="reportType">Type of Report and Period Covered Note</note>
		<note tag ="514" property="dataQuality">Data Quality Note</note>
		<note tag ="516" property="dataType">Type of Computer File or Data Note</note>
		<note tag ="518" property="venue">Date/Time and Place of an Event Note</note>
		<note tag ="521" property="targetAudience">Target Audience Note</note>
		<note tag ="522" property="geographic">Geographic Coverage Note</note>
		<note tag ="525" property="supplement">Supplement Note</note>
		<note tag ="526" property="studyProgram">Study Program Information Note</note>
		<note tag ="530" comment="WORK, but needs to be reworked to
			be an instance or to match with an instance (Delsey - Manifestation)" property="additionalPhysicalForm">Additional Physical Form Available Note 
			</note>
		<note tag ="533"  comment="(develop link) (Delsey - Manifestation)" property="reproduction">Reproduction Note</note>
		<note tag ="534" comment="(develop link)(Delsey - Manifestation)" property="originalVersion">Original Version Note</note>
		<note tag ="535" property="originalLocation">Location of Originals/Duplicates Note</note>
		<note tag ="536" property="funding">Funding Information Note</note>		
		<note tag ="544" subfields="3dea" comment="(develop link?)" property="archiveLocation">Location of Other Archival Materials Note</note>
		<note tag ="545"  comment ="belongs to name???" property="biographicalHistorical">Biographical or Historical Data</note>
		<note tag ="547" property="formerTitleComplexity">Former Title Complexity Note</note>
		<note tag ="552" property="entityInformation">Entity and Attribute Information Note</note>
		<note tag ="555" comment="(link?)" property="findingAids">Cumulative Index/Finding Aids Note </note>
		<note tag ="565" property="caseFile">Case File Characteristics Note</note>
		<note tag ="567" property="methodology">Methodology Note</note>
		<note tag ="580" property="linkingEntryComplexity">Linking Entry Complexity Note</note>
		<note tag ="581" property="publications">Publications About Described Materials Note</note>
		<note tag ="586" property="awards">Awards Note</note>
		<note tag ="588" comment="(actually Annotation? Admin?)" property="source" >Source of Description Note </note>
	</work-notes>
	<instance-notes>
		<note tag ="501" property="with" subfields="a">With Note</note>
		<note tag ="506" property="restrictionsOnAccess">Restrictions on Access Note</note>
		<note tag ="507" property="scale">Scale Note for Graphic Material</note>
		<note tag ="508" property="productionCredits">Creation/Production Credits Note </note>
		<note tag ="511" property="performers">Participant or Performer Note </note>
		<note tag ="515" property="numbering">Numbering Peculiarities Note </note>
		<note tag ="524" property="preferredCitation">Preferred Citation of Described Materials Note</note>
		<note tag ="538" property="systemDetials">System Details Note</note>
		<note tag ="540" comment="(Delsey - Manifestation)" property="useAndReproduction">Terms Governing Use and Reproduction Note </note>
		<note tag ="541" subfields="cad" property="acquisition">Immediate Source of Acquisition Note</note>
		<note tag ="542" property="copyrightStatus">Information Relating to Copyright Status</note>
		<note tag ="546" property="language">Language Note</note>
		<note tag ="550" property="issuers">Issuing Body Note</note>
		<note tag ="556" property="documentation">Information about Documentation Note</note>
		<note tag ="561" property="ownership">Ownership and Custodial History</note>
		<note tag ="562" property="version identification">Copy and Version Identification Note</note>
		<note tag ="563" property="binding">Binding Information</note>
		<note tag ="583" comment="annotation later?" property="exhibitions">Action Note</note>
		<note tag ="584" property="useFrequency">Accumulation and Frequency of Use Note</note>
		<note tag ="585" property="exhibitions">Exhibitions Note</note>	
	</instance-notes>
</notes>
);

(:$related fields must have $t except 630,730,830 , 767? 740 ($a is title),  :)
declare variable $marcbib2bibframe:relationships := 
(    
    <relationships>
        <!-- Work to Work relationships -->
        <work-relateds>
            <type pattern="(700|710|711|720)" ind2="2" property="includes">isIncludedIn</type>
            <type pattern="(700|710|711|720)" ind2="( |0|1)" property="relatedWork">relatedWork</type>        		
            <type pattern="740" ind2=" " property="relatedWork">relatedWork</type>
		    <type pattern="740" ind2="2" property="contains">isContainedIn</type>		
		    <type pattern="762" property="subSeries">hasParts</type>	
		    <type pattern="765" property="translationOf">hasTranslation</type>
		    <type pattern="767" property="hasTranslation">translationOf</type>
		    <type pattern="772" ind2=" " property="supplements">isSupplemented</type>
		    <type pattern="772" ind2="0" property="hasParent">isParentOf</type>		
		    <type pattern="772" property="memberOf">host</type>
		    <type pattern="773" property="collectedIn">collection</type>
		    <type pattern="775" property="hasOtherVersion" ind2=" ">hasOtherVersion</type>
		    <type pattern="776" property="hasOtherFormat">hasOtherFormat</type>
		    <type pattern="780" ind2="0" property="continues">continuationOf</type>
		    <type pattern="780" ind2="2" property="continues">continuationOf</type>
		    <type pattern="780" ind2="1" property="continuesInPart">partiallyContinuedBy</type>
		    <type pattern="780" ind2="3" property="continuesInPart">partiallyContinuedBy</type>
		    <type pattern="780" ind2="4" property="mergerOf">preceding</type>
		    <type pattern="780" ind2="5" property="absorbed">isAbsorbedBy</type>
		    <type pattern="780" ind2="7" property="separatedFrom">formerlyIncluded</type>
		    <type pattern="785" ind2="0"  property="continuedBy">continues</type>
		    <type pattern="785" ind2="1" property="continuedInPartBy">partiallyContinues</type>	
		    <type pattern="785" ind2="2"  property="continuedBy">continues</type>
		    <type pattern="785" ind2="3" property="continuedInPartBy">partiallyContinues</type>
		    <type pattern="785" ind2="4" property="absorbedBy">absorbs</type>
		    <type pattern="785" ind2="5"  property="absorbedInPartBy">partiallyAbsorbs</type>
		    <type pattern="785" ind2="7"  property="mergedInto">mergedFrom</type>	
    		<type pattern="785" ind2="8"  property="changedBackTo">formerlyNamed</type>	
		    <type pattern="785" ind2="6"  property="splitInto">splitFrom</type>	
		    <type pattern="(534|786)" property="originalVersion">hasOtherVersion</type>
    		<type pattern="787" property="hasRelationship">relatedItem</type>				
	  	    <type pattern="(440|760|762|800|810|811|830)" property="inSeries">hasParts</type>
	  	    <type pattern="490" ind1="0" property="inSeries">hasParts</type>
        </work-relateds>
        <!-- Instance to Work relationships -->
	  	<instance-relateds>
	  	    <type pattern="630"  property="subject">isSubjectOf</type>
            <type pattern="(700|710|711|720)" ind2="( |0|1) " property="relatedWork">relatedWork</type>
            <type pattern="(700|710|711|720)" ind2="2" property="contains">isContainedIn</type>
            <type pattern="730"  property="hasRelationship">relatedItem</type>
            <type pattern="830"  property="inSeries">series</type>
	  	</instance-relateds>
	</relationships>
);

(:~
:   This is the main function.  It expects MARCXML as input.
:   It generates bibframe RDF data as output.
:
:   @param  $marcxml        element is the MARCXML  
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
            let $instances := marcbib2bibframe:generate-instances($marcxml, $about)
            return
                element rdf:RDF {        
                    $work,
                    $instances
                }
        else
            element rdf:RDF {
                comment {"No leader - invalid MARC/XML input"}
            }
};

declare function marcbib2bibframe:marcbib2bibframe(
        $marcxml as element(marcxml:record)
        ) as element(rdf:RDF) 
{   
    let $identifier := xs:string(fn:current-time())
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
        
    
    let $title := 
        for $titles in $d/../marcxml:datafield[fn:matches(@tag,"(245|246|222|242)")]
            for $t in $titles
            return marcbib2bibframe:get-title($t)
    
    (:let $title := 
        for $t in $d/../marcxml:datafield[@tag eq "245"]
        return get-title($t):)
        (:700 with $t is a related item, not a contributor:)
    let $names := 
        for $datafield in $d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag,"(700|710|711|720)")][fn:not(marcxml:subfield[@code="t"])]                    
        return marcbib2bibframe:get-name($datafield)
        
        
    let $edition := 
        for $e in $d/../marcxml:datafield[@tag eq "250"]
        return element bf:edition {fn:string-join($e/marcxml:subfield[fn:not(@code="6")], " ")}
        
    let $place :=
        for $a in $d/marcxml:subfield[@code eq "a"]
        let $label:= marcbib2bibframe:clean-string(xs:string($a))        
        return 
            if (fn:not(fn:matches($label,"^n.[ ]?p.$","i"))) then
                element bf:placePub {	            
                    element bf:Place {
                        (: 
                            k-note: added call to clean-str here.  
                            We'll need to figure out where this is and 
                            isn't a problem
                        :)
                        element bf:label { marcbib2bibframe:clean-string(xs:string($a)) },
                        marcbib2bibframe:generate-880-label($d,"place")
                    }
                }
            else ()          
         
    let $providers:=
            (
                $d/marcxml:subfield[@code eq "b"],
         		$d/../marcxml:datafield[@tag="028"]/marcxml:subfield[@code eq "b"]
            )
    
    let $providers :=
        for $a in fn:distinct-values($providers)
        return
            element bf:provider {
                element bf:Organization {
                    element bf:label {marcbib2bibframe:clean-string(fn:string($a))},
                      marcbib2bibframe:generate-880-label($d,"provider")
                }
            }
    
    let $pubdate :=
        for $a in $d/marcxml:subfield[@code eq "c"]
        return element bf:pubDate {marcbib2bibframe:clean-string(xs:string($a))}
        
    let $types := marcbib2bibframe:get-resourcesTypes($d/../marcxml:leader)
    let $mainType := xs:string($types[1])

    let $physResourceData := ()
    (: 
        Commented out the below because it was creating duplicate data.
        marcbib2bibframe:generate-physdesc appears to replace all of the below
    :)
    (:
        if ($mainType eq "Text" or
            $mainType eq "Cartographic" or 
            $mainType eq "Serial" or 
            $mainType eq "NotatedMusic") then
            
            let $extent := 
                for $e in $d/../marcxml:datafield[@tag eq "300"]/marcxml:subfield[@code eq "a"]
                return element bf:extent {clean-string(xs:string($e))}
            
            let $otherPhysicalDetails := 
                for $e in $d/../marcxml:datafield[@tag eq "300"]/marcxml:subfield[@code eq "b"]
                return element bf:otherPhysicalDetails {clean-string(xs:string($e))}
            
            let $dimensions := 
                for $e in $d/../marcxml:datafield[@tag eq "300"]/marcxml:subfield[@code eq "c"]
                return element bf:dimensions {clean-string(xs:string($e))}
                
            return ($extent, $otherPhysicalDetails, $dimensions)
            
        else ()
        :)
        
    let $physBookData := ()
        (:
        for $i in $d/../marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"][1]
        return element bf:isbn {xs:string($i)}
        :)
        
    let $physMapData := 
        (
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "a" or @code eq "b" or @code eq "c"]  
            return element bf:scale {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "a"]
            return element bf:scale {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "a"]
            return element bf:scale {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "b"]
            return element bf:projection {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "c"]
            return element bf:latLong {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "d" or @code eq "e" or @code eq "f" or @code eq "g"]  
            return element bf:latLong {xs:string($i)}
        )           
            
    let $physSerialData := ()
            
    let $instanceType := 
        if ( fn:count($physBookData) > 0 ) then
            "PhysicalBook"
        else if ( fn:count($physMapData) > 0 ) then
            "PhysicalMap"
        else if ( fn:count($physSerialData) > 0 ) then
            "Serial"
        else if ( fn:count($physResourceData) > 0 ) then
            "PhysicalResource"
        else 
            ""
    let $call-num:= 
        if ($d/../marcxml:datafield[@tag eq "050"]) then
            element bf:callNumber { fn:normalize-space(fn:string-join($d/../marcxml:datafield[@tag eq "050"]," ")) }
        else ()

    let $instance-identifiers :=
        (
            (:now handled automatically by $identifiers var 
            element identifiers:lccn { fn:normalize-space($d/../marcxml:datafield[@tag eq "010"]/marcxml:subfield[@code eq "a"]) },:)            
            for $i in $d/../marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
            	let $code := fn:normalize-space($i/parent::node()[1]/marcxml:subfield[@code eq "2"])
            	let $iStr := fn:normalize-space(xs:string($i))
            	where $iStr ne ""
            return
                if ( $code ne "" ) then
                    element {  $code } { $iStr }
                else 
                    element identifiers:id { $iStr },
                    
            for $i in $d/../marcxml:datafield[@tag eq "035"]/marcxml:subfield[@code eq "a"][fn:not( fn:contains(. , "DLC") )]            	
            	let $iStr := xs:string($i)
            	return
                	if ( fn:contains($iStr, "(OCoLC)" ) ) then
                    	element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }
                	else 
                    	element identifiers:id { fn:normalize-space($iStr) },
            marcbib2bibframe:generate-identifiers($d/ancestor::marcxml:record,"instance")            
        )
        
    let $related-works:= marcbib2bibframe:related-works($d/ancestor::marcxml:record,$workID,"instance")
    let $notes := marcbib2bibframe:generate-notes($d/ancestor::marcxml:record,"instance")
    let $physdesc := marcbib2bibframe:generate-physdesc($d/ancestor::marcxml:record,"instance")
        
    return 
        element bf:Instance {
        
            if ($instanceType ne "") then
                element rdf:type {
                    attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" , $instanceType) }
                }
            else
                (),               
            $title,
            $names,
            $edition,
            $providers,
            $place,
            $pubdate,       
            $physResourceData,            
            $physMapData,
            $physSerialData,
            $call-num,    
            $instance-identifiers,
            $physdesc,
            element bf:instanceOf {
                attribute rdf:resource {$workID}
            },
            $notes,
            $related-works,
            $derivedFrom      
            
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
        let $script := fn:tokenize($d/marcxml:subfield[@code="6"],'/')[2]
        let $lang := fn:substring(fn:string($d/../marcxml:controlfield[@tag='008']), 36, 3)     
    
        let $script:=
	       if ($script="(3" ) then "ara"
	       else if ($script="(B" ) then "latin"
	       else if ($script="$l" ) then "cjk"
	       else if ($script="(N" ) then "cyrillic"
	       else if ($script="(S" ) then "greek"
	       else if ($script="(2" ) then "hebrew"
	       else $lang

        let $this-tag:= fn:string($d/@tag)
        let $hit-num:=fn:tokenize($d/marcxml:subfield[@code="6"],"-")[2]			
        let $match:=$d/../marcxml:datafield[@tag="880" and fn:starts-with(marcxml:subfield[@code="6"] , fn:concat($this-tag ,"-", $hit-num ))]
	
        return 
            if ($node-name="name") then
                element madsrdf:authoritativeLabel {
                    attribute xml:lang {$lang},
                    attribute xml:script {$script},
                    marcbib2bibframe:clean-string(fn:string-join($match/marcxml:subfield[@code="a" or @code="b" or @code="c" or @code="d" or @code="q"] , " "))
                }
            else if ($node-name="title") then 
                let $subfs := 
                    if ( fn:matches($d/@tag, "(245|242|243|246|630|730|740|830)") ) then
                        "(a|b|f|h|k|n|p)"
                    else
                        "(t|f|k|m|n|p|s)"
                return
                    element madsrdf:authoritativeLabel {
                        attribute xml:lang {$lang},
                        attribute xml:script {$script},
                        (: marcbib2bibframe:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,"(a|b)")] ," "),"^(.+)/$","$1")) :)
                        marcbib2bibframe:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,$subfs)] ," "),"^(.+)/$","$1"))
                    }
            else if ($node-name="subject") then 
                element madsrdf:authoritativeLabel{
                    attribute xml:lang {$lang},
                    attribute xml:script {$script},
                    marcbib2bibframe:clean-string(fn:string-join($match/marcxml:subfield[fn:not(@code="6")], " "))
                }
            else if ($node-name="place") then 
                for $sf in $match/marcxml:subfield[@code="a"]
                return
                    element  rdfs:label {
                        attribute xml:lang {$lang},
                        attribute xml:script {$script},
                        marcbib2bibframe:clean-string(fn:string($sf))
                    }
			else if ($node-name="provider") then 
                for $sf in $match/marcxml:subfield[@code="b"]
                return
                    element rdfs:label {
                        attribute xml:lang {$lang},
                        attribute xml:script {$script},					
                        marcbib2bibframe:clean-string(fn:string($sf))
                }
            else 
                element rdfs:label {
                    fn:string($match/marcxml:subfield[@code="a"])					
				}				
	else ()
	
};
(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a
:
::   @param  $marcxml       element is the marcxml record

:   @param  $resource      string is the "work" or "instance"
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-identifiers(
   $marcxml as element(marcxml:record),
    $resource as xs:string
    ) as element ()*
{
    let $identifiers:= 
        if ($resource="instance") then 
            $marcbib2bibframe:identifiers/instance-identifiers
        else 
            $marcbib2bibframe:identifiers/work-identifiers

    return 
        (  
            for $id in $identifiers/id[@ind1](:any with ind1 means 024 for now:)
            let $return-codes:=
                if ($id/@subfields) then 
                    fn:string($id/@subfields)
                else 
                    "a"
            
            for $each-id in $marcxml/marcxml:datafield[@tag eq $id/@tag]					
                for $a in $each-id[@ind1=$id/@ind1]/marcxml:subfield[fn:matches(@code,$return-codes)]									
                return 
                    element {fn:string($id/@property)} {
                        fn:normalize-space( fn:string($a))
                    },
                    				
			for $id in $identifiers/id[fn:not(@ind1)]			 
				for $each-id in $marcxml/marcxml:datafield[@tag eq $id/@tag]
					for $a in $each-id/marcxml:subfield[@code eq "a"]
						return
							element {fn:string($id/@property)} {
								if ($each-id/@tag="048") then 
									fn:normalize-space( fn:substring(fn:string($a),1,2))
								else
									fn:normalize-space( fn:string($a))
				}
		)
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

                for $each-field in $marcxml/marcxml:datafield[@tag eq $physdesc/@tag]
                let $codes := 
                    if ($physdesc/@codes) then 
                        fn:string($physdesc/@codes)
                    else 
                        "a"	
                for $subelement in $each-field/marcxml:subfield[fn:matches(@code,$codes)]
                let $elname:=
                    if ($physdesc/@property) then 
                        fn:string($physdesc/@property) 
                    else 
                        fn:string($physdesc/@tag)
                return						
                    element {fn:concat("bf:", $elname)} {								
                        fn:normalize-space( fn:string($subelement))
                    }
		)
};

(:~
:   This is the function generates isbn-based instance resources.
:
:   @param  $d        element is the 020  $a
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-instance-fromISBN(
    $d as element(marcxml:subfield),
    $workID as xs:string
    ) as element ()*
{

    let $isbn := 
        element bf:isbn {
            marcbib2bibframe:clean-string(fn:normalize-space(fn:tokenize(fn:string($d),"\(")[1]))              
        }
        
    let $cancels:=
        for $z in $d/../marcxml:subfield[@code eq "z"]
        return
            element bf:cancelled-isbn {xs:string($z)}                
		
    let $qualifier:=	
        fn:replace(
            fn:tokenize(fn:string($d),"\(")[2],
            "\)",
            ""
        )
    let $qualifier:=
        if ( $qualifier ne "") then 
            element bf:isbnData {$qualifier} 
        else ()

    let $binding:=
        if (fn:matches($qualifier,"(pbk|softcover)")) then
			"paperback"
		else if (fn:matches($qualifier,"(hbk|hardcover|hc)") ) then 
			"hardback"
		else if (fn:matches($qualifier,"(ebook|eresource)") ) then
			"electronic resource"
		else if (fn:contains($qualifier,"lib. bdg.") ) then
			"library binding"
			
		else ""
		
	let $paper:=
		if (fn:matches($qualifier,"(acid-free|acid free|alk)")) then
			"acid free"		
		else ""
    
    (:get the physical details:)
    (: We only ask for the first 260 :)
	let $instance := 
        for $i in $d/../../marcxml:datafield[@tag eq "260"][1]
        return marcbib2bibframe:generate-instance-from260($i, $workID)
        
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
            if ( fn:exists($instance) ) then
                (
                    $instance/@*,
                    $instance/*
                )
            else 
                $instanceOf,
            
            $isbn,				
			$cancels,
			$qualifier,
				
			if ( $binding ne "") then
				element bf:binding {$binding}
			else (),
				
			if ($paper ne "") then
				element bf:paper {$paper}
			else ()
		}
     
};
(:~
:   This is the function generates publisher number-based instance resources.
:
:   @param  $d        element is the 028  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-instance-from-pubnum(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element ()*
{

    (:
        028 ind1=0 $b$a with type="issue-number"    
        028 ind1=1 $a$b  with type="matrix-number"  
        028 ind1=3 $a$b  with type="music-publisher"  
        028 ind1=2 $a$b  with type="music-plate"  
    :)
    
    let $pubnum := 
        element bf:publisherNumber
 			{
            	marcbib2bibframe:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="a"])))              
        	}
    let $pubsource := 
        element bf:publisherNumberSource
 			{
            	marcbib2bibframe:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="b"])))              
        	}
		
     let $pubqual := 
        element bf:publisherNumberQualifier
 			{
            	marcbib2bibframe:clean-string(fn:normalize-space(fn:string($d/marcxml:subfield[@code="q"])))              
        	}
    (:get the physical details:)
    (: We only ask for the first 260 :)
	let $instance :=  marcbib2bibframe:generate-instance-from260($d/../marcxml:datafield[@tag eq "260"][1], $workID)
        
        
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
            if ( fn:exists($instance) ) then
                (
                    $instance/@*,
                    $instance/*
                )
            else 
                $instanceOf,                         
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
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()* 
{
    let $bibid:=$marcxml/marcxml:controlfield[@tag="001"]
    let $biblink:= 
        element bf:derivedFrom {
            attribute rdf:resource{fn:concat("http://id.loc.gov/resources/bibs/",$bibid)}
        } 

    let $result:=
        for $link in $marcxml/marcxml:datafield[@tag="856"]
        let $category:=         
            if (fn:contains( fn:string($link/marcxml:subfield[@code="u"][1]),"hdl.loc.gov") and
                fn:not(fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"finding aid","i") ) 
                ) then
                "instance"
            else if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]) ,"(pdf|page view) ","i"))   then
                "instance"
            else if ($link/@ind1="4" and $link/@ind2="0" ) then
                "instance"
            else if ($link/@ind1="4" and $link/@ind2="1" and fn:not(fn:exists(fn:string($link/marcxml:subfield[@code="3"]) ) ) ) then
                "instance"
            else if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"finding aid","i") ) then
                "findaid"    
            else 
                "annotation"
            
        let $type:= 
            if (fn:matches(fn:string($link/marcxml:subfield[@code="u"][1]),"catdir","i")) then            
                if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"contents","i")) then "contents"
                else if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"sample","i")) then "sample"
                else if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"contributor","i")) then "contributor"
                else if (fn:matches(fn:string($link/marcxml:subfield[@code="3"][1]),"publisher","i")) then "publisher"
                else  ()
            else ()
            
   		return
			 if ( $category="resource" ) then
                element bf:Instance {
                    element bf:label {fn:string($link/marcxml:subfield[@code="3"])},
                    element bf:link {fn:string($link/marcxml:subfield[@code="u"])},
                    element bf:instanceOf {
                        attribute rdf:resource {$workID}
                    },
                    $biblink
                }
             else             	
       			element bf:Annotation {
                    
                    if (fn:string($link/marcxml:subfield[@code="3"]) ne "") then
                        element bf:label {
                            fn:string($link/marcxml:subfield[@code="3"])       					
                        }
                    else (),
                
                    if (
                        $type="contributor" and 
                        $marcxml/marcxml:datafield[
                            fn:starts-with(@tag , "10") or
                            fn:starts-with(@tag , "11") or 
                            fn:starts-with(@tag , "71") or
                            fn:starts-with(@tag , "70") or 
                            fn:starts-with(@tag , "72")]
                        )
                        then
                        let $df :=
                                $marcxml/marcxml:datafield[fn:starts-with(@tag , "10")]|
                                $marcxml/marcxml:datafield[fn:starts-with(@tag , "11")]|
                                $marcxml/marcxml:datafield[fn:starts-with(@tag , "70")]|
                                $marcxml/marcxml:datafield[fn:starts-with(@tag , "71")]|
                                $marcxml/marcxml:datafield[fn:starts-with(@tag , "72")]

                        let $names := 
                    	    for $datafield in $df 
                    	    return marcbib2bibframe:get-name( $datafield )
                        return 
                            for $n in $names
                            return
                                element bf:name {
                                    $names/* 
                                }
                    else
                        element bf:annotationCreator {
                                attribute rdf:resource {"http://id.loc.gov/vocabulary/organizations/dlc"} 
                            },
                    
                    element bf:annotates {
                        attribute rdf:resource {$workID}
                    },
                    
                    (:  
                        Is annotation-service the same as link ($u), basically?
                        11737193 has multiple $u, so that apparently is a thing
                        to deal with.
                    :) 
                    if ($type ne "") then
                        element bf:annotation-service {
                            fn:concat("http://id.loc.gov/resources/bibs/",$bibid,".",$type,".xml")
                        }
                    else (),
                    element bf:annotationBody {fn:string($link/marcxml:subfield[@code="u"][1])},
                    $biblink
              	}
     return $result
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
    (
        if ( $marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"] ) then
            for $i in $marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
	    	return marcbib2bibframe:generate-instance-fromISBN($i, $workID)
	   	(: always have a 260? 028s are handled in $instance-identifiers
	   	else if ( $marcxml/marcxml:datafield[@tag eq "028"] ) then
            for $i in $marcxml/marcxml:datafield[@tag eq "028"]
	    	return marcbib2bibframe:generate-instance-from-pubnum($i, $workID):)
        else 	        		
            for $i in $marcxml/marcxml:datafield[@tag eq "260"]|$marcxml/marcxml:datafield[@tag eq "264"]
            return marcbib2bibframe:generate-instance-from260($i, $workID),
            
        if ( $marcxml/marcxml:datafield[@tag eq "856"]) then
            marcbib2bibframe:generate-instance-from856($marcxml, $workID)
        else 
            ()
            
    )
};
(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a
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
			for $each-note in $marcxml/marcxml:datafield[@tag eq $note/@tag][@ind2=$note/@ind2]
			let $return-codes:=
 				if ($note/@subfields) then fn:string($note/@subfields)
 				else "a"			
			return
                element {fn:concat("bf:",fn:string($note/@property),"Note")} {						
                    fn:normalize-space(fn:string-join($each-note/marcxml:subfield[fn:contains($return-codes,@code)]," "))
                },
                
		for $note in $notes/note[fn:not(@ind2)]
			for $each-note in $marcxml/marcxml:datafield[@tag eq $note/@tag]
			let $return-codes:=
 				if ($note/@subfields) then fn:string($note/@subfields)
 				else "a"			
			return
                element {fn:concat("bf:",fn:string($note/@property),"Note")} {						
                    fn:normalize-space(fn:string-join($each-note/marcxml:subfield[fn:contains($return-codes,@code)]," "))
                }
        
        )
};

declare function marcbib2bibframe:generate-related-work
    (
        $d as element(marcxml:datafield), 
        $type as element() 
    )
{    

    let $titleFields := 
        if (fn:matches($d/@tag,"(630|730|740|830)")) then
            "(a|n|p)"
        else
            "(t|f|k|m|n|o|p|s)"
    let $title := marcbib2bibframe:clean-title-string(fn:string-join($d/marcxml:subfield[fn:matches(@code,$titleFields)] , ' '))
    
    let $name := 
        if (
            $d/marcxml:subfield[@code="a"] and 
            $d/@tag="740" and 
            $d/@ind2="2" and
            $d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag, "(100|110|111)")][1]
           ) then
            marcbib2bibframe:get-name($d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag, "(100|110|111)")][1])
        (:else if (  $d/marcxml:subfield[@code="a"] and $d/@tag!="740") then:)
        else if (  $d/marcxml:subfield[@code="a"]  and fn:not(fn:matches($d/@tag,"(630|730|740|830)")) ) then
            marcbib2bibframe:get-name($d)
        else ()
        
    let $aLabel := 
        fn:concat(
            xs:string($name//bf:label[1]),
            " ",
            $title
        )
    let $aLabel := fn:normalize-space($aLabel)
    
    let $aLabelWork880 := marcbib2bibframe:generate-880-label($d,"title")
    let $aLabelWork880 :=
        if ($aLabelWork880/@xml:lang) then
            let $lang := $aLabelWork880/@xml:lang 
            let $n := $name//madsrdf:authoritativeLabel[@xml:lang=$lang][1]
            let $combinedLabel := fn:normalize-space(fn:concat(xs:string($n), " ", xs:string($aLabelWork880)))
            return
                element madsrdf:authoritativeLabel {
                    $aLabelWork880/@xml:lang,
                    $aLabelWork880/@xml:script,
                    $combinedLabel
                }
        else
            $aLabelWork880
            
    return 
    element {fn:concat("bf:",fn:string($type/@property))} {
        element bf:Work {
        (:inverse relationship could go here, but you need the bibframeWork/@rdf:about
            element {fn:concat("bf:",fn:string($type))} {
                attribute rdf:resource {"/bf:Work/@rdf:about goes here"}
                },:)

        (:    if (fn:matches($d/@tag,"(630|730|740|830)")) then 
                element bf:title {clean-string(fn:string($d/marcxml:subfield[@code="a"]))}
            else
                element bf:title {clean-string(fn:string($d/marcxml:subfield[@code="t"]))},             
                marcbib2bibframe:generate-880-label($d,"title"),
                for $s in $d/marcxml:subfield[@code="p" or @code="n"] 
                return 
                    element bf:subTitle {
                        fn:string($s)
                    },:)

            if ($d/marcxml:subfield[@code="w" or @code="x"]) then
                for $s in $d/marcxml:subfield[@code="w" or @code="x" ]
                  let $iStr := fn:string($s)
                return
                        if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then
                            element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }
                        else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
                            element identifiers:lccn {  fn:normalize-space(fn:replace($iStr, "\(DLC\)", "")) }                
                        else if (fn:string($s/@code="x")) then
                            element identifiers:issn {  fn:normalize-space($iStr) }                                                 
                else ()
       else 
           if ($d/marcxml:subfield[@code="a"] and fn:not(   fn:matches($d/@tag,"(630|730|740|830)") )) then
                     marcbib2bibframe:get-name($d)
                    else (),

            element madsrdf:authoritativeLabel {$aLabel},
            $aLabelWork880,
            element bf:title {$title},
            $name,
            
            if ($d/marcxml:subfield[@code="w"]) then
                for $s in $d/marcxml:subfield[@code="w"]
                let $iStr := fn:string($s)
                return
                    if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then
                        element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }
                    else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
                        element identifiers:lccn {  fn:normalize-space(fn:replace($iStr, "\(DLC\)", "")) }
                    else 
                        element identifiers:id { fn:normalize-space($iStr) }                        
            else ()

            }
        }
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
            if ($type/@pattern="740") then (: title is in $a :)
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@pattern))][@ind1=$type/@ind1 or @ind2=$type/@ind2]		
                return marcbib2bibframe:generate-related-work($d,$type)
                
            else if ($type/@ind1) then
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@pattern))][@ind1=$type/@ind1][marcxml:subfield[@code="t"]]	
                return marcbib2bibframe:generate-related-work($d,$type)
                
            else if ($type/@ind2) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@pattern))][fn:matches(@ind2,fn:string($type/@ind2))][marcxml:subfield[@code="t"]]		
				return marcbib2bibframe:generate-related-work($d,$type)
				
            else if (fn:matches($type/@pattern,"(630|730|830)")) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@pattern))][marcxml:subfield[@code="a"]]       
                return marcbib2bibframe:generate-related-work($d,$type)                             
            
            else 	
                for $d in $marcxml/marcxml:datafield[fn:matches(fn:string($type/@pattern),@tag)][marcxml:subfield[@code="t"]]		
				return marcbib2bibframe:generate-related-work($d,$type)
				
    return $relatedWorks
				
};

(:~
:   This is the function generates a work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element () 
{
    
    let $types := marcbib2bibframe:get-resourcesTypes($marcxml/marcxml:leader)
        
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
        	(:
        	for $t in $titles
        	return marcbib2bibframe:get-title($t)
        	:) 
        
    (: Let's create an authoritativeLabel for this :)
    let $aLabel := 
        if ($uniformTitle[bf:uniformTitle]) then
            fn:concat( xs:string($names[1]/bf:*[1]/bf:label), " ", xs:string($uniformTitle/bf:uniformTitle) )
        else if ($titles) then
            fn:concat( xs:string($names[1]/bf:*[1]/bf:label), " ", xs:string($titles/bf:title[1]) )
        else
            ""
            
    let $aLabel := 
        if (fn:ends-with($aLabel, ".")) then
            fn:substring($aLabel, 1, fn:string-length($aLabel) - 1 )
        else
            $aLabel
            
    let $aLabel := 
        if ($aLabel ne "") then
            element madsrdf:authoritativeLabel { fn:normalize-space($aLabel) }
        else
            ()
            
    let $aLabelsWork880 := $titles/madsrdf:authoritativeLabel
    let $aLabelsWork880 :=
        for $al in $aLabelsWork880
        let $lang := $al/@xml:lang 
        let $n := $names//madsrdf:authoritativeLabel[@xml:lang=$lang][1]
        let $combinedLabel := fn:normalize-space(fn:concat(xs:string($n), " ", xs:string($al)))
        where $al/@xml:lang
        return
            element madsrdf:authoritativeLabel {
                    $al/@xml:lang,
                    $al/@xml:script,
                    $combinedLabel
                }
        
    let $cf008 := xs:string($marcxml/marcxml:controlfield[@tag='008'])
        
    (: 
        Here's a thought. If this Work *isn't* English *and* it does 
        have a uniform title (240), we should probably figure out the 
        lexical value of the language code and append it to the 
        authoritativeLabel, thereby creating a type of expression.
    :)
    
    let $language := fn:substring($cf008, 36, 3)
    let $language := 
        if ($language ne "") then
            element bf:language {
                attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , $language) }
            }
        else
            ()
            
    let $audience := fn:substring($cf008, 23, 1)
    let $audience := 
        if ($audience ne "") then
            let $aud := xs:string($marcbib2bibframe:targetAudiences/type[@cf008-22 eq $audience]) 
            return
                if (
                    $aud ne "" and
                    (
                        $mainType eq "Text" or
                        $mainType eq "SoftwareApplication" or
                        $mainType eq "StillImage" or
                        $mainType eq "NotatedMusic" or
                        $mainType eq "MusicRecording"
                        (: What others would have audience? :)
                    )
                ) then
                    element bf:audience {
                        attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/targetAudiences/" , $aud) }
                    }
                else ()
        else
            ()
            
    (: Don't be surprised when genre turns into "form" :)
    let $genre := fn:substring($cf008, 24, 1)
    let $genre := 
        if ($genre ne "") then
            let $gen := xs:string($marcbib2bibframe:formsOfItems/type[@cf008-23 eq $genre and fn:contains(xs:string(@rType), $mainType)]) 
            return
                if ($gen ne "") then
                    element bf:genre {$gen}
                else ()
        else
            ()
         
	let $abstract:= 
		for $d in  $marcxml/marcxml:datafield[@tag="520"]
			let $abstract-type:=
				if ($d/@idn1="") then "Summary"
					else if ($d/@idn1="0") then "Subject"
					else if ($d/@idn1="1") then "Review"
					else if ($d/@idn1="2") then "Scope"
					else if ($d/@idn1="3") then "Abstract"
					else if ($d/@idn1="4") then "ContentAdvice"
					else 						"Abstract"
				
			return	
			element bf:abstract {
				element {fn:concat("bf:",$abstract-type)} {
					element bf:label {fn:string-join($d/marcxml:subfield[@code="a" or @code="b"],"")}
				}      
			}
	let $lcc:= 
        for $c in $marcxml/marcxml:datafield[fn:string(@tag)="050"]
	        let $cl:=fn:string($c)
			let $validLCC:=("DAW","DJK","KBM","KBP","KBR","KBU","KDC","KDE","KDG","KDK","KDZ","KEA","KEB","KEM","KEN","KEO","KEP","KEQ","KES","KEY","KEZ","KFA","KFC","KFD","KFF","KFG","KFH","KFI","KFK","KFL","KFM","KFN","KFO","KFP","KFR","KFS","KFT","KFU","KFV","KFW","KFX","KFZ","KGA","KGB","KGC","KGD","KGE","KGF","KGG","KGH","KGJ","KGK","KGL","KGM","KGN","KGP","KGQ","KGR","KGS","KGT","KGU","KGV","KGW","KGX","KGY","KGZ","KHA","KHC","KHD","KHF","KHH","KHK","KHL","KHM","KHN","KHP","KHQ","KHS","KHU","KHW","KJA","KJC","KJE","KJG","KJH","KJJ","KJK","KJM","KJN","KJP","KJR","KJS","KJT","KJV","KJW","KKA","KKB","KKC","KKE","KKF","KKG","KKH","KKI","KKJ","KKK","KKL","KKM","KKN","KKP","KKQ","KKR","KKS","KKT","KKV","KKW","KKX","KKY","KKZ","KLA","KLB","KLD","KLE","KLF","KLH","KLM","KLN","KLP","KLQ","KLR","KLS","KLT","KLV","KLW","KMC","KME","KMF","KMG","KMH","KMJ","KMK","KML","KMM","KMN","KMP","KMQ","KMS","KMT","KMU","KMV","KMX","KMY","KNC","KNE","KNF","KNG","KNH","KNK","KNL","KNM","KNN","KNP","KNQ","KNR","KNS","KNT","KNU","KNV","KNW","KNX","KNY","KPA","KPC","KPE","KPF","KPG","KPH","KPJ","KPK","KPL","KPM","KPP","KPS","KPT","KPV","KPW","KQC","KQE","KQG","KQH","KQJ","KQK","KQM","KQP","KQT","KQV","KQW","KQX","KRB","KRC","KRE","KRG","KRK","KRL","KRM","KRN","KRP","KRR","KRS","KRU","KRV","KRW","KRX","KRY","KSA","KSC","KSE","KSG","KSH","KSK","KSL","KSN","KSP","KSR","KSS","KST","KSU","KSV","KSW","KSX","KSY","KSZ","KTA","KTC","KTD","KTE","KTF","KTG","KTH","KTJ","KTK","KTL","KTN","KTQ","KTR","KTT","KTU","KTV","KTW","KTX","KTY","KTZ","KUA","KUB","KUC","KUD","KUE","KUF","KUG","KUH","KUN","KUQ","KVB","KVC","KVE","KVH","KVL","KVM","KVN","KVP","KVQ","KVR","KVS","KVU","KVW","KWA","KWC","KWE","KWG","KWH","KWL","KWP","KWQ","KWR","KWT","KWW","KWX","KZA","KZD","AC","AE","AG","AI","AM","AN","AP","AS","AY","AZ","BC","BD","BF","BH","BJ","BL","BM","BP","BQ","BR","BS","BT","BV","BX","CB","CC", "CD","CE","CJ","CN","CR","CS","CT","DA","DB","DC","DD","DE","DF","DG","DH","DJ","DK","DL","DP","DQ","DR","DS","DT","DU","DX","GA","GB","GC","GE","GF","GN","GR","GT","GV","HA","HB","HC","HD","HE","HF","HG","HJ","HM","HN","HQ","HS","HT","HV","HX","JA","JC","JF","JJ","JK","JL","JN","JQ","JS","JV","JX","JZ","KB","KD","KE","KF","KG","KH","KJ","KK","KL","KM","KN","KP","KQ","KR","KS","KT","KU","KV","KW","KZ","LA","LB","LC","LD","LE",  "LF","LG","LH","LJ","LT","ML","MT","NA","NB","NC","ND","NE","NK","NX","PA","PB","PC","PD","PE","PF","PG","PH","PJ","PK","PL","PM","PN","PQ","PR","PS","PT","PZ","QA","QB","QC","QD","QE","QH","QK","QL","QM","QP","QR","RA","RB","RC","RD","RE","RF","RG",   "RJ","RK","RL","RM","RS","RT","RV","RX","RZ","SB","SD","SF","SH","SK","TA","TC","TD","TE","TF","TG","TH","TJ","TK","TL","TN","TP","TR","TS","TT","TX","UA","UB","UC","UD","UE","UF","UG","UH","VA","VB","VC","VD","VE","VF","VG","VK","VM","ZA","A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","Z")
			let $strip := fn:replace(fn:string($cl), "(\s+|\.).+$", "")			
			let $subclassCode := fn:replace($strip, "\d", "")			
			return 
	            (: lc classes don't have a space after the alpha prefix, like DA1 vs "DA 1" :)
	            if (
	                fn:substring(fn:substring-after(fn:string($cl), $subclassCode),1,1)!=' ' and 
	                $subclassCode = $validLCC 
	                ) then   								  
	                element bf:class {
	                    element bf:LCC {														 							
	                        attribute rdf:about {fn:concat("http://id.loc.gov/authorities/classification/",fn:string($strip))},						
							element bf:label {fn:string($cl)}	
	                    }
	                }
	            else (:invalid content in 050:)
	                ()
    (:ex:5811630:)
    let $other-class:= 
        for $c in $marcxml/marcxml:datafield[fn:string(@tag)="072"]
        return    element bf:otherclass {
	                    	element bf:Classification { 
	                    		attribute rdf:resource {"http://www.loc.gov/standards/sourcelist/subject-category.html"},
	                    		element bf:label {fn:string-join($c/marcxml:subfield[fn:matches(@code,"(a|x)")]," ")},
	                    		element bf:source {fn:string($c/marcxml:subfield[@code="2"])}	                    
	                    	}
	                    }
	(:special condition of $b prevents this from being one of the std identifiers:)
	let $copyright:=  
			for $d in  $marcxml/marcxml:datafield[@tag="017"][fn:starts-with(marcxml:subfield[@code="b"],"U.S. Copyright Off")]
				return element bf:copyrightDocumentID {
				fn:string($d/marcxml:subfield[@code="a"])				
					}
  
	let $work-identifiers := marcbib2bibframe:generate-identifiers($marcxml,"work")
	(:let $physdesc:=generate-physdesc($d/ancestor::marcxml:record,"work"):)
 	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marcbib2bibframe:subject-types//@tag," "),fn:string(@tag))]		
        return marcbib2bibframe:get-subject($d)
 	let $work-notes := marcbib2bibframe:generate-notes($marcxml,"work")
 	let $work-relateds := marcbib2bibframe:related-works($marcxml,$workID,"work")
 	(:audio ex:12241297:)
 	let $complex-notes:= 
 		for $each-note in $marcxml/marcxml:datafield[@tag eq "505"][@ind2="0"]
 			let $sub-codes:= fn:distinct-values($each-note/marcxml:subfield[@code!="t"]/@code)
			let $return-codes := "gru"			
			let $set:=
				for $title in $each-note/marcxml:subfield[@code="t"]				
					return 
						element part {
							element madsrdf:MainTitleElement {element madsrdf:elementValue {fn:string($title)},
							(:get each following sibling that's not a title
					where the first preceding title of it is the same as this title:)
						 	for $subfield in $title/following-sibling::marcxml:subfield[@code!="t"][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)]				
								let $elname:=
								 	if ($subfield/@code="g") then "madsrdf:TitleElement" 
										else if ($subfield/@code="r") then"madsrdf:responsibility" 
										else if ($subfield/@code="u") then "rdf:resource" 
										else fn:string($subfield/@code)
											
								return 
									element {$elname } {
											element madsrdf:elementValue {
											fn:replace(fn:string($subfield),"-","")
											(:$title/following-sibling::marcxml:subfield[@code=$code][1][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)]:)																					
									}
								}						
								}
							}
			return						
				element bf:contains {									
					for $item in $set
						return
							element bf:Work {
								element madsrdf:authoritativeLabel {fn:string-join($item/*," ") },
								element rdf:type {attribute rdf:resource {"http://bibframe.org/vocab/Part"}},
								element madsrdf:elementList {
									attribute  rdf:parseType {"Collection"},												
									$item/*												
									}
								}																								
				}
						
 	let $gacs:= 
            for $d in $marcxml/marcxml:datafield[@tag = "043"]/marcxml:subfield[@code="a"] 
            let $gac:=fn:replace(fn:string($d),"-","") 
            return
                element bf:subject {
                    attribute rdf:about { fn:concat("http://id.loc.gov/vocabulary/geographicAreas/", $gac) }
            }
            		
    let $biblink:= 
        element bf:derivedFrom {
            attribute rdf:resource{fn:concat("http://id.loc.gov/resources/bibs/",fn:string($marcxml/marcxml:controlfield[@tag eq "001"]))}
        }
    
    let $schemes := 
            element madsrdf:isMemberOfMADSScheme {
                attribute rdf:resource {"http://id.loc.gov/resources/works"}
            }
 	
    return 
        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},
            for $t in $types
            return
                element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $t)}
                },
            if ($uniformTitle/bf:uniformTitle) then
                $uniformTitle/*
            else
                (),
            $titles/bf:*,
            $aLabel,
            $aLabelsWork880,
            $names,
            $language,
            $abstract,
            $audience,           
            $genre,
            $subjects,
            $gacs,
            $copyright,
            $lcc,    
            $other-class,
            $work-identifiers,
            $work-notes,
            $complex-notes,
            $work-relateds,
            $schemes,            
            $biblink
        }
};

(:~
:   This function generates a subject.
:   It takes a specific 6xx as input.
:   It generates a bf:subject as output.
: 
29 '600': ('subject', {'bibframeType': 'Person'}),
30 '610': ('subject', {'bibframeType': 'Organization'}), 
31 '611': ('subject', {'bibframeType': 'Meeting'}),   
33 '630': ('uniformTitle', {'bibframeType': 'Title'}), 
34 '650': ('subject', {'bibframeType': 'Topic'}), 
35 '651': ('subject', {'bibframeType': 'Geographic'}), 

:   @param  $d        element is the marcxml:datafield  
:   @return bf:subject
:)
declare function marcbib2bibframe:get-subject(
    $d as element(marcxml:datafield)
    ) as element()
{
    let $subjectType := fn:string($marcbib2bibframe:subject-types/subject[@tag=$d/@tag])
    let $details :=
   
		if (fn:matches(fn:string($d/@tag),"(600|610|611|630|648|650|651|655|751)")) then
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
                            $d/*[@code ne "2"]
                        }
                    }
                </marcxml:record>
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($marcAuthXML)
            let $madsrdf := $madsrdf/madsrdf:*[1]
            let $details :=
                ( 
                    element rdf:type {
                        attribute rdf:resource { 
                            fn:concat("http://www.loc.gov/mads/rdf/v1#" , fn:local-name($madsrdf))
                        }
                    },
                    element bf:label { xs:string($madsrdf/madsrdf:authoritativeLabel) },
                    $madsrdf/madsrdf:authoritativeLabel,
                    $madsrdf/madsrdf:componentList,
                    $madsrdf/madsrdf:elementList                   
                )
            return $details
	   
       else if (fn:matches(fn:string($d/@tag),"(662|752)")) then
            (: 
                Note: 662 can include relator codes/terms, with which something
                will have to be done.
            :)
            let $aLabel := fn:string-join($d/marcxml:subfield[fn:matches(fn:string(@code),"(a|b|c|d|f|g|h)")], ". ") 
            let $components := 
                for $c in $d/marcxml:subfield[fn:matches(fn:string(@code),"(a|b|c|d|f|g|h)")]
                return
                    if ( xs:string($c/@code) eq "a" ) then
                        element madsrdf:Country {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "b" ) then
                        element madsrdf:State {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "c" ) then
                        element madsrdf:County {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "d" ) then
                        element madsrdf:City {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "f" ) then
                        element madsrdf:CitySection {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "g" ) then
                        element madsrdf:Geographic {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else if ( xs:string($c/@code) eq "h" ) then
                        element madsrdf:ExtraterrestrialArea {
                            element madsrdf:authoritativeLabel { xs:string($c) }
                        }
                    else  
                        ()
            let $details :=
                ( 
                    element rdf:type {
                        attribute rdf:resource { "http://www.loc.gov/mads/rdf/v1#HierarchicalGeographic"}
                    },
                    element bf:label { xs:string($aLabel) },
                    element madsrdf:authoritativeLabel { xs:string($aLabel) },
                    element madsrdf:componentList {
                        attribute rdf:parseType {"Collection"},
                        $components 
                    }                   
                )
            return $details
           
       else
           (
               element bf:label {fn:string-join($d/marcxml:subfield[fn:not(@code="6")], " ")},
               element bf:description {
                   fn:concat(
                       "This is derived from a MARC ",
                       xs:string($d/@tag),
                       " field."
                    )                    
                }
           )
	   
    return 
        element bf:subject {
            element {fn:concat("bf:",$subjectType)} { 
                $details,
                marcbib2bibframe:generate-880-label($d,"subject")
            }
        }

};

(:~
:   This function generates a name.
:   It takes a specific datafield as input.
:   It generates a bf:uniformTitle as output.
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:creator element OR a more specific relators:* one. 
:)
declare function marcbib2bibframe:get-name(
    $d as element(marcxml:datafield)
    ) as element()
{
    let $relatorCode := marcbib2bibframe:clean-string(fn:string($d/marcxml:subfield[@code = "4"][1])) 
    
    let $label := fn:string-join($d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q'] , ' ')
    let $aLabel := $label
    
    let $elementList := 
        element madsrdf:elementList {
        	attribute rdf:parseType {"Collection"},
            for $s in $d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']
            return
                if ($s/@code eq "a") then
                     element madsrdf:NameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
                else if ($s/@code eq "b") then
                     element madsrdf:PartNameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
                else if ($s/@code eq "c") then
                     element madsrdf:TermsOfAddressNameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
                else if ($s/@code eq "d") then
                     element madsrdf:DateNameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
                else if ($s/@code eq "q") then
                     element madsrdf:FullNameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
                else 
                    element madsrdf:NameElement {
                        element madsrdf:elementValue {xs:string($s)}
                     }
        }
    
    let $roles := 
        for $r in $d/marcxml:subfield[@code='e']
        return element bf:role {xs:string($r)}
        
    let $class := 
        if ( fn:ends-with(xs:string($d/@tag), "00") ) then
            "bf:Person"
        else if ( fn:ends-with(xs:string($d/@tag), "10") ) then
            "bf:Organization"
        else if ( fn:ends-with(xs:string($d/@tag), "11") ) then
            "bf:Meeting"
            else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1=1))  then
            "bf:Person" (:????:)
            else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1=2))  then
            "bf:Organization" (:may be a meeting:)
        else 
            "bf:name"

    let $tag := xs:string($d/@tag)
    let $property := 
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
            

    return
        element {$property} {
            element {$class} {            
                element bf:label {$label},
                element rdfs:label {$aLabel},
                element madsrdf:authoritativeLabel {$aLabel},
                marcbib2bibframe:generate-880-label($d,"name"),
                $elementList,
                $roles
            }
        }

};

(:~
:   This is the function generates a work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:get-resourcesTypes(
    $leader as element(marcxml:leader)
    ) as item()*
{
    let $leader06 := fn:substring(xs:string($leader), 7, 1)
    
    let $types := 
        for $t in $marcbib2bibframe:resourceTypes/type
        where $t/@leader6 eq $leader06
        return xs:string($t)

    return $types
};

(:~
:   This returns a basic title from 245. 
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:uniformTitle
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
    return 
        (
            if ($d/@tag eq "246") then
                (: "Varying Form of Title" :)
                element bf:variantTitle {$title}
            else if ($d/@tag eq "242") then
                (: " Translation of Title by Cataloging Agency" :)
                let $lang := xs:string($d/marcxml:subfield[@code eq "y"][1])
                let $lang := 
                    if ($lang ne "") then
                        attribute xml:lang {$lang}
                    else
                        ()
                return
                    element bf:variantTitle {
                        $lang,
                        $title
                    }
            else
                element bf:title {$title},
            
            marcbib2bibframe:generate-880-label($d,"title")
        )
};


(:~
:   This function generates a uniformTitle.
:   It takes a specific datafield as input.
:   It generates a bf:Work as output.
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:uniformTitle
:)
declare function marcbib2bibframe:get-uniformTitle(
    $d as element(marcxml:datafield)
    ) as element(bf:Work)
{
    (:let $label := xs:string($d/marcxml:subfield["a"][1]):)
    (:??? filter out nonsorting chars???:)
    (:remove $o in musical arrangements???:)
    let $label := marcbib2bibframe:clean-title-string(fn:string-join($d/marcxml:subfield[@code ne '0' and @code!='6' and @code!='8'] , ' '))
    let $aLabel := marcbib2bibframe:clean-title-string(fn:string-join($d/marcxml:subfield[@code ne '0' and @code!='6' and @code!='8' ] , ' '))    
    let $elementList := 
        element madsrdf:elementList {
        	attribute rdf:parseType {"Collection"},
            for $s in $d/marcxml:subfield
            return
                if ($s/@code eq "a") then
                     element madsrdf:MainTitleElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "p") then
                     element madsrdf:PartNameElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "l") then
                     element madsrdf:LanguageElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "s") then
                     element madsrdf:TitleElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "k") then
                     element madsrdf:GenreFormElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "d") then
                     element madsrdf:TemporalElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else if ($s/@code eq "f") then
                     element madsrdf:TemporalElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
                else
                    element madsrdf:TitleElement {
                        element madsrdf:elementValue {marcbib2bibframe:clean-title-string(xs:string($s))}
                     }
        }
    return
    
        element bf:Work {    
	  		  element bf:uniformTitle {$label},
              element rdfs:label {$aLabel},
              $elementList
            }        
            
};

(:~
:   This function takes a string and 
:   attempts to clean it up 
:   ISBD punctuation. based on 260 cleaning 
:
:   @param  $s        is xs:String
:   @return xs:string
:)
declare function marcbib2bibframe:clean-string(
    $s as xs:string?
    ) as xs:string
{ 

	if (fn:exists($s)) then
		let $s:= fn:replace($s,"from old catalog","","i")
	    let $s := fn:replace($s, "([\[\];]+)", "")
	    let $s := fn:replace($s, " :", "")
	    let $s := fn:normalize-space($s)
	    return 
	        if ( fn:ends-with($s, ",") ) then
	            fn:substring($s, 1, (fn:string-length($s) - 1) )
	        else
	            $s
	
	else ""



};
(:~
:   This function takes a string and 
:   attempts to clean it up 
:   ISBD punctuation. based on title cleaning: you dont' want to strip out ";" 
:
:   @param  $s        is xs:String
:   @return xs:string
:)
declare function marcbib2bibframe:clean-title-string(
    $s as xs:string
    ) as xs:string
{
	let $s:= fn:replace($s,"from old catalog","","i")
    let $s := fn:replace($s, "([\[\]]+)", "")
    let $s := fn:replace($s, " :", "")
    let $s := fn:normalize-space($s)
    let $s := 
        if ( fn:ends-with($s, ",") ) then
            fn:substring($s, 1, (fn:string-length($s) - 1) )
        else
            $s
    return $s

};
