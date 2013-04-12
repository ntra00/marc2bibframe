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
declare variable $marcbib2bibframe:last-edit :="2013-04-12-T13:00";
declare variable $marcbib2bibframe:resourceTypes := (
    <resourceTypes>
        <type leader6="a">LanguageMaterial</type>
        <type cf007="t">LanguageMaterial</type>       
        <type sf336a="(text|tactile text)">LanguageMaterial</type>
        <type sf336b="(txt|tct)">LanguageMaterial</type>
        <type leader6="c">NotatedMusic</type>
        <type leader6="d">NotatedMusic</type>
        <type cf007="q">NotatedMusic</type>
        <type sf336a="(notated music|tactile notated music)">NotatedMusic</type>
        <type sf336b="(ntm|ccm)">NotatedMusic</type>`        
        <type sf336a="(notated movement|tactile notated movement)">NotatedMovement</type>
        <type sf336b="(ntv|tcn)">NotatedMovement</type>
        <type leader6="d">Manuscript</type>
        <type leader6="f">Manuscript</type>
        <type leader6="t">Manuscript</type>
         <type leader6="e">Cartography</type>
        <type leader6="f">Cartography</type>
        <type cf007="adr">Cartography</type>
        <type sf336a="(cartographic dataset|cartographic image|cartographic moving image|cartographic tactile image|cartographic tactile three-dimensional form|cartographic three-dimensional form)">Cartography</type>
        <type sf336b="(tcrd|cri|crm|crt|crn|crf)">Cartography</type>         
        <type leader6="g">MovingImage</type>
        <type cf007="m">MovingImage</type>
        <type cf007="v">MovingImage</type>
        <type sf336a="(three-dimensional moving image|two-dimensional moving image|cartographic moving image)">MovingImage</type>
        <type sf336b="(tdm|tdi)">MovingImage</type>
        <type leader6="i">Audio</type>
        <type leader6="j">Audio</type>
        <type cf007="s">Audio</type>
        <type sf336a="(performed music|sounds|spoken word)">Audio</type>
        <type sf336b="(prm|snd|spw)">Audio</type>
        <type sf337a="audio">Audio</type>
        <type sf337b="s">Audio</type>
        <type leader6="k">StillImage</type>
        <type sf336a="(still image|tactile image|cartographic image)">StillImage</type>
        <type sf336b="(sti|tci|cri)">StillImage</type>
        <type leader6="m">SoftwareOrMultimedia</type>
        <type sf336a="computer program">SoftwareOrMultimedia</type>
        <type sf336b="cop">SoftwareOrMultimedia</type>
        <type leader6="m">Dataset</type>
        <type sf336a="(cartographic dataset|computer dataset)">Dataset</type>
        <type sf336b="(crd|cod)">Dataset</type>
        <type leader6="o">MixedMaterial</type>
        <type leader6="p">MixedMaterial</type>
        <type cf007="o">MixedMaterial</type>
        <type leader6="r">Three-DimensionalObject</type>
        <type sf336a="(three-dimensional form|tactile three-dimensional form|three-dimensional moving image| cartographic three dimensional form|cartographic tactile three dimensional form)">Three-DimensionalObject</type>
        <type sf336b="(tdf|tcf|tcm|crf|crn )">Three-DimensionalObject</type>
        <type leader6="t">LanguageMaterial</type>        
        <type cf007="f">Tactile</type>
        <type sf336a="(cartographic tactile image|cartographic tactile three-dimensional form|tactile image|tactile notated music|tactile notated movement|tactile text|tactile three-dimensional form)">Dataset</type>
        <type sf336b="(crt|crn|tci|tcm|tcn|tct|tcf)">Dataset</type>
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
		<subject tag="630">Work</subject>
		<subject tag="648">Chronological</subject>
		<subject tag="650">Topic</subject>
		<subject tag="651">Place</subject>
		<subject tag="654">Topical</subject>
		<subject tag="655">Genre</subject>
		<subject tag="656">Occupation</subject>
		<subject tag="657">Function</subject>
		<subject tag="658">Objective</subject>
		<subject tag="662">HierarchicalPlace</subject>		
		<!-- <subject tag="653">UncontrolledTopic</subject> -->
		<subject tag="653">Topic</subject>
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
declare variable $marcbib2bibframe:classes := (
<vocab>
    <class>ClassificationEntity</class>
    <property name="classNumber" label="classification number" domain="Work" marc="050,051,055,060,061,070,071,080,082,083,084,086--/a" tag="(050|051|055|060|061|070|071|080|082|083|084|086)" sfcodes="a"/>
    <property name="classItem" label="classification item number" domain="Holding" marc="050|051,055,060,061,070,071,080,082,083,084,086--/b" tag="(050|051|055|060|061|070|071|080|082|083|084|086)" sfcodes="b"/>
    <property name="classCopy" label="Copy part of call number" domain="Work" marc="051,061,071--/c" tag="(051|061|071)" sfcodes="c"/>
    <property name="classNumberSpanEnd" label="classification span end for class number" domain="Work" marc="083--/c" tag="083" sfcodes="c"/>
    <property name="classTableSeq" label="DDC table sequence number" domain="Work" marc="083--/y" tag="083" sfcodes="y"/>
    <property name="classTable" label="DDC table" domain="" marc="083--/z" tag="083" sfcodes="z"/>
    <property name="classScheme" label="type of classification" domain="Work" marc="086--/2" tag="086" sfcodes="2"/>   
    <property name="classEdition" label="edition of class scheme" domain="Work" marc="If 080,082,083 1- then 'abridged'" tag="(080|082|083)" ind1="1"/>	
    <property name="classEdition" label="edition of class scheme" domain="Work" marc="If 080,082,083 1- then 'full'" tag="080|082|083" ind1="0"/>
    <property name="classAssigner" label="institution assigning classification" domain="Work" marc="if 070,071 then NAL" tag="(050|051|060|061|070|071|082|083|084)"/>
    <property name="classSchemePart" label="Part of class scheme used" domain="Work" marc="if 082,083 --/m=a then'standard', m=b then 'optional'" tag="(082|083)"  sfcodes="m=a then'standard', m=b then 'optional'"/>
    <property name="classStatus" label="status of classification" domain="Work" marc="if 086/z then status=canceled/invalid" tag="if "  sfcodes="z then status=canceled/invalid"/>
    <property name="class-lcc" label="LCC Classification" domain="Work" marc="050,051,055,060,061,070,071--/a" tag="(050|051|055|060|061|070|071)" sfcodes="a" level="property"/>
    <property name="class" label="classification" domain="Work" marc="084,086--/a" tag="(084|086)" ind1="," ind2="0" sfcodes="a" level="property"/>
    <property name="class-ddc" label="DDC Classification" domain="Work" marc="083--/a'hyphen'c" tag="083" sfcodes="a'hyphen'c" level="property"/> 
    <property name="class-ddc" label="DDC Classification" domain="Work" marc="082--/a" tag="082" sfcodes="a" level="property"/>	
    <property name="class-udc" label="UDC Classification" domain="Work" marc="080--/a+c" tag="080" sfcodes="a+c"/>	
</vocab>
);
(:code=a unless specified:)
declare variable $marcbib2bibframe:identifiers :=
(: vocab-identifiers are now used, not these instance and work identifiers. nate 2013-02-22 :)
    ( 
    <identifiers>
        <instance-identifiers>
            <field tag="010" property="bf:derivedFromLccn">Library of Congress Control Number</field>
            <field tag="018" property="bf:copyrightArticleFee">Copyright Article-Fee Code</field>
            <field tag="022" property="identifiers:issn">International Standard Serial Number</field>
            <field tag="024" ind1="0" property="identifiers:isrc">International Standard Recording Code</field>
            <field tag="024" ind1="1" property="identifiers:upc">Universal Product Code</field>
            <field tag="024" ind1="2" property="identifiers:ismn">International Standard Music Number</field>
            <field tag="024" ind1="3" property="identifiers:ean">International Article Number</field>
            <field tag="024" ind1="4" property="identifiers:sici">Serial Item and Contribution Identifier</field>
            <field tag="025" property="identifiers:ovopAcqNum">Overseas Acquisition Number</field>
            <field tag="028" ind1="0" property="identifiers:issue-number">Publisher's Issue Number</field>
            <field tag="028" ind1="1" property="identifiers:matrix-number">Sound Recording Matrix Number</field>
            <field tag="028" ind1="2" property="identifiers:music-plate">Publisher's Music Plate Number</field>
            <field tag="028" ind1="3" property="identifiers:music-publisher">Publisher-assigned Music Number</field>
            <field tag="028" ind1="4" property="identifiers:videorecording-identifier">Publisher-assigned videorecording number</field>
            <field tag="032" property="bf:postalRegistrationNumber">Postal Registration Number</field>
            <field tag="035" property="identifiers:syscontrolID">System Control Number</field>
            <field tag="037" property="identifiers:acqSource">Source of Acquisition</field>
            <field tag="044" property="identifiers:countryofPublisher">Country of Publishing/Producing Entity Code</field>
            <field tag="048" property="bf:musicalInstruments">Number of Musical Instruments or Voices Codes</field>
            <field tag="055" property="bf:canadaClass" codes="ab">Classification Numbers Assigned in Canada</field>
            <field tag="060" property="bf:nlmCall" codes="ab">National Library of Medicine Call Number</field>
            <field tag="070" property="bf:nalCall" codes="ab">National Agricultural Library Call Number</field>
            <field tag="074" property="bf:gpoItemNum">GPO Item Number</field>
            <field tag="080" property="bf:udcNum" codes="ab">Universal Decimal Classification Number</field>
            <field tag="082" property="identifiers:dewey" codes="ab">Dewey Decimal Classification Number</field>
            <field tag="083" property="bf:deweyplus" codes="ab">Additional Dewey Decimal Classification Number</field>
            <field tag="084" property="bf:otherClass" codes="ab">Other Classification Number</field>
            <field tag="088" property="bf:reportNum">Report Number</field>
        </instance-identifiers>
        <work-identifiers>
            <field tag="010" property="identifiers:lccn">Library of Congress Control Number</field>
            <field tag="012" property="identifiers:conser">CONSER Number</field>
            <!--<field tag="013" property="identifiers:patentNum">Patent Control Information</field>-->
            <!--013$b is a location code-->
            <field tag="015" property="bf:natbibliographyNum">National Bibliography Number</field>
            <field tag="016" property="bf:natbibAgencyContrrol">National Bibliographic Agency Control Number</field>
            <field tag="022" property="identifiers:issn-l" sfcodes="l">International Standard Serial Number</field>
            <field tag="024" ind1="0" property="identifiers:isrc">International Standard Recording Code</field>
            <field tag="024" ind1="1" property="identifiers:upc">Universal Product Code</field>
            <field tag="024" ind1="2" property="identifiers:ismn">International Standard Music Number</field>
            <field tag="024" ind1="3" property="identifiers:ean">International Article Number</field>
            <field tag="024" ind1="7" property="identifiers:sici">Serial Item and Contribution Identifier</field>(:!!!:)
            <field tag="027" property="identifiers:strn">Standard Technical Report Number</field>
            <field tag="030" property="bf:coden">CODEN Designation</field>
            <field tag="031" property="bf:musicalIncipits">Musical Incipits Information</field>
            <field tag="033" property="bf:dateTimePlace">Date/Time and Place of an Event</field>
            <field tag="034" property="bf:cartographicData">Coded Cartographic Mathematical Data</field>
            <field tag="036" property="identifiers:studyNumber">Original Study Number for Computer Data files</field>
            <field tag="038" property="bf:licensor">Record Content Licensor</field>
            <field tag="045" property="bf:era">Time Period of content</field>
            <field tag="047" property="bf:musicalGenre">Form of Musical Composition Code</field>
            <field tag="055" property="bf:canadaClass">Classification Numbers Assigned in Canada</field>
            <field tag="060" property="bf:nlmCall">National Library of Medicine Call Number</field>
            <field tag="070" property="bf:nalCall">National Agricultural Library Call Number</field>
            <field tag="072" property="bf:subjectCategory" sfcodes="ax2">Subject Category Code</field>
            <field tag="080" property="identifiers:udcNum">Universal Decimal Classification Number</field>
            <field tag="082" property="identifiers:dewey">Dewey Decimal Classification Number</field>
            <field tag="083" property="bf:deweyplus">Additional Dewey Decimal Classification Number</field>
            <field tag="084" property="bf:otherClass">Other Classification Number</field>
            <field tag="085" property="bf:classComponents">Synthesized Classification Number Components</field>
            <field tag="086" property="bf:govodocsClass">Government Document Classification Number</field>
        </work-identifiers>
   <vocab-identifiers>     
   	<property name="lccn" label="Library of Congress Control Number" domain="Instance"   marc="010--/a,z"   tag="010"   sfcodes="a,z"/>
 <property name="nbn" label="National Bibliography Number" domain="Instance"   marc="015--/a,z"   tag="015"   sfcodes="a,z"/>
 <property name="nban" label="National bibliography agency control number"   domain="Instance"   marc="016--/a,z"   tag="016"   sfcodes="a,z"/>
 <property name="legal-deposit" label="copyright or legal deposit number"   domain="Instance"   marc="017--/a,z"   tag="017"   sfcodes="a,z"/>
 <property name="isbn" label="International Standard Bibliographic Number"   domain="Instance"   marc="020--/a,z"   tag="020"   sfcodes="a,z"/>
 <property name="issn" label="International Standard Serial Number" domain="Instance"   marc="022--/a,z,y"   tag="022"   sfcodes="a,z,y"/>
 <property name="issn-l" label="linking International Standard Serial Number"   domain="Work"   marc="022--/l,m"   tag="022"   sfcodes="l,m"/>
 <property name="isrc" label="International Standard Recording Code" domain="Instance"   marc="0240-/a,z"   tag="024"   ind1="0"   sfcodes="a,z"/>
 <property name="upc" label="Universal Product Code" domain="Instance" marc="0241-/a,z"   tag="024"   ind1="1"   sfcodes="a,z"/>
 <property name="ismn" label="International Standard Music Number" domain="Instance"   marc="0242-/a,z"   tag="024"   ind1="2"   sfcodes="a,z" uri="http://www.loc.gov/ismn/987-10-11110" />
 <property name="ean" label="International Article Identifier (EAN)" domain="Instance"   marc="0243-/a,z,d(sep by -)"   tag="024"   ind1="3"   sfcodes="a,z,d(sep by -)" uri="http://www.ean-search.org/perl/ean-search.pl?q=5099750442227"/>
 <property name="sici" label="Serial Item and Contribution Identifier" domain="Instance"   marc="0244-/a,z"   tag="024"   ind1="4"   sfcodes="a,z"/>
 <property name="ansi" label="American National Standard Institute Number"   domain="Instance"   marc="0247-+2'ansi'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="isan" label="International Standard Audiovisual Number" domain="Work"   marc="0247-+2'isan'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="iso"   label="International Organization for Standardization standard number"   domain="Instance"   marc="0247-+2'iso'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="istc" label="International Standard Text Code" domain="Work"   marc="0247-+2'istc'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="iswc" label="International Standard Musical Work Code" domain="Work"   marc="0247-+2'iswc'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="local" label="local identifier" domain="Instance"   marc="0247-+2'local'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="uri" label="Uniform Resource Identifier" domain="Instance"   marc="0247-+2'uri'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="urn" label="Uniform Resource Number" domain="Instance"   marc="0247-+2'urn'/a,z"   tag="024"   ind1="7"   sfcodes="a,z"/>
 <property name="lc-overseas-acq"   label="Library of Congress Overseas Acquisition Program number"   domain="Instance"   marc="025--/a"   tag="025"   sfcodes="a"/>
 <property name="fingerprint" label="fingerprint identifier" domain="Instance"   marc="026--/e"   tag="026"   sfcodes="e"/>
 <property name="strn" label="Standard Technical Report Number" domain="Instance"   marc="027--/a,z"   tag="027"   sfcodes="a,z"/>
 <property name="issue-number" label="sound recording publisher issue number"   domain="Instance"   marc="0280-/a"   tag="028"   ind1="0"   sfcodes="a"/>
 <property name="matrix-number" label="sound recording publisher matrix master number"   domain="Instance"   marc="0281-/a"   tag="028"   ind1="1"   sfcodes="a"/>
 <property name="music-plate" label="music publication number assigned by publisher"   domain="Instance"   marc="0282-/a"   tag="028"   ind1="2"   sfcodes="a"/>
 <property name="music-publisher" label="other publisher number for music"   domain="Instance"   marc="0283-/a"   tag="028"   ind1="3"   sfcodes="a"/>
 <property name="videorecording-identifier"   label="publisher assigned videorecording number"   domain="Instance"   marc="0284-/a"   tag="028"   ind1="4"   sfcodes="a"/>
 <property name="publisher-number" label="other publisher assigned number"   domain="Instance"   marc="0285-/a"   tag="028"   ind1="5"   sfcodes="a"/>
 <property name="coden" label="CODEN" domain="Instance" marc="030--/a,z" tag="030"   sfcodes="a,z" uri="http://cassi.cas.org/coden/"/>
 <property name="postal-registration" label="postal registration number" domain="Instance"   marc="032--/a"   tag="032"   sfcodes="a"/>
 <property name="system-number" label="system control number" domain="Instance"   marc="035--/a,z"   tag="035"   sfcodes="a,z"/>
 <!--<property name="oclc-number" domain="Instance"   marc="035 - - /a,z prefix 'OCOLC'"   tag="035"   sfcodes="a,z"/> -->
 <property name="study-number"   label="original study number assigned by the producer of a computer file"   domain="Instance"   marc="036--/a"   tag="036"   sfcodes="a"/>
 <property name="stock-number" label="stock number for acquisition" domain="Instance"   marc="037--/a"   tag="037"   sfcodes="a"/>
 <property name="report-number" label="technical report number" domain="Instance"   marc="088--/a,z"   tag="088"   sfcodes="a,z"/>
 <property name="dissertationIdentifier" label="Dissertation Identifier"   domain="Dissertation"   marc="502--/o"   tag="502"   sfcodes="o"/>
 <property name="doi" label="Digital Object Identifier" domain="Instance"   marc="856--/u('doi' in URI)"   tag="856"   sfcodes="u" uri="http://www.crossref.org/guestquery/"/>
 <property name="hdl" label="handle for a resource" domain="Instance"   marc="856--/u('hdl' in URI)"   tag="856"   sfcodes="u('hdl' in URI)"/>
 <property name="isni" label="International Standard Name Identifier" domain="Agent"   marc="authority:0247-+2'isni'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>
 <property name="orcid" label="Open Researcher and Contributor Identifier" domain="Agent"   marc="authority:0247-+2'orcid'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>
 <property name="viaf" label="Virtual International Authority File number" domain="Agent"   marc="authority:0247-+2'via,zf'/a,z"   tag="aut"   ind1="h"   ind2="o"   sfcodes="a,z"/>
             </vocab-identifiers>
    </identifiers>
    );

declare variable $marcbib2bibframe:physdesc-list:= 
    (
        <physdesc>
            <instance-physdesc>
                <field tag="300" codes="3" property="materialsSpecified">Materials specified</field>
                <field tag="300" codes="a" property="extent">Physical Description</field>
<!-- now in notes
           	<field tag="300" codes="b" property="illustrativeContentNote">Illustrative content note</field>-->
	        <field tag="300" codes="c" property="dimensions">Dimensions</field>
   		 <field tag="300" codes="e" property="additionalMaterial"> Accompanying material</field>
        		<field tag="300" codes="f" property="unitType">Type of unit </field>
        		<field tag="300" codes="g" property="unitSize">Size of unit </field>		
        		<field tag="306" codes="a" property="playingTime">Playing Time </field>
        		<field tag="307" codes="ab" property="hoursAvailable"> Hours Available</field>
        		<field tag="310" codes="ab">Current Publication Frequency </field>
        		<field tag="321" codes="ab"> Former Publication Frequency </field>
        		<field tag="337" codes="ab23">Media Type </field>
        		<field tag="338" codes="ab23">Carrier Type </field>
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
	       </work-physdesc>
        </physdesc>
    );
    
declare variable $marcbib2bibframe:notes-list:= (
<notes>
	<work-notes>
		<note tag ="500" sfcodes="3a" property="note">General Note</note>		
		<note tag ="502" property="dissertationNote" domain="Dissertation">Dissertation Note</note>
		<note tag ="504" property="supplementaryContentNote" startwith=". References: " comment="525a,504--/a+b(precede info in b with References:" sfcodes="ab">Supplementary content note</note>
		<note tag ="505" property="contents" ind2="0">Formatted Contents Note</note>	
		<note tag ="513" property="reportType">Type of Report and Period Covered Note</note>
		<note tag ="514" property="dataQuality">Data Quality Note</note>
		<note tag ="516" property="dataType">Type of Computer File or Data Note</note>
		<note tag ="518" property="venue">Date/Time and Place of an Event Note</note>
		<!-- has its own function<note tag ="521" property="targetAudience">Target Audience Note</note>-->
		<note tag ="522" property="geographic">Geographic Coverage Note</note>
		<note tag ="525" property="supplementaryContentNote" sfcodes="a" >Supplement Note</note>		
		<note tag ="526" property="studyProgram">Study Program Information Note</note>
		<note tag ="530" comment="WORK, but needs to be reworked to be an instance or to match with an instance (Delsey - Manifestation)" property="additionalPhysicalForm">Additional Physical Form Available Note </note>
<!-- moved to relateds;			<note tag ="533"  comment="(develop link) (Delsey - Manifestation)" property="reproduction">Reproduction Note</note>
 		<note tag ="534" comment="(develop link)(Delsey - Manifestation)" sfcodes="b" property="originalVersion">Original Version Note</note>-->
		<note tag ="535" property="originalLocation">Location of Originals/Duplicates Note</note>
		<note tag ="536" property="funding">Funding Information Note</note>		
		<note tag ="544" sfcodes="3dea" comment="(develop link?)" property="archiveLocation">Location of Other Archival Materials Note</note>
		<note tag ="545"  comment ="belongs to name???" property="biographicalHistorical">Biographical or Historical Data</note>
		<note tag ="547" property="formerTitleComplexity">Former Title Complexity Note</note>
		<note tag ="552" property="entityInformation">Entity and Attribute Information Note</note>
		<note tag ="555" comment="(link?)" property="findingAids">Cumulative Index/Finding Aids Note </note>
		<note tag ="565" property="caseFile">Case File Characteristics Note</note>
		<note tag ="567" property="methodology">Methodology Note</note>
		<note tag ="580" property="linkingEntryComplexity">Linking Entry Complexity Note</note>
		<note tag ="581" property="publicationsAbout" sfcodes="3a" startswith="Publications about: ">Publications About Described Materials Note</note>
		<note tag ="586" property="awardNote" sfcodes="3a">Awards Note</note>
		<note tag ="588" comment="(actually Annotation? Admin?)" property="source" >Source of Description Note </note>
	
	</work-notes>
	<instance-notes>	
		<note tag ="300" property="illustrativeContentNote" sfcodes="b">Illustrative content note</note>
		<note tag ="501" property="with" sfcodes="a">With Note</note>
		<note tag ="506" property="restrictionsOnAccess">Restrictions on Access Note</note>
		<note tag ="507" property="cartographicNote" sfcodes="a" >Scale Note for Graphic Material</note>
		<note tag ="508" property="creditsNote" startwith="Credits: "  comment="precede text with 'Credits:'" >Creation/Production Credits Note </note>
		<note tag ="511" property="performerNote" comment="precede text with 'Cast:'" startwith="Cast: ">Participant or Performer Note </note>
		<note tag ="515" property="numbering">Numbering Peculiarities Note </note>
		<note tag ="524" property="preferredCitation">Preferred Citation of Described Materials Note</note>
		<note tag ="538" property="systemDetials">System Details Note</note>
		<note tag ="540" comment="(Delsey - Manifestation)" property="useAndReproduction">Terms Governing Use and Reproduction Note </note>
		<note tag ="541" sfcodes="cad" property="acquisition">Immediate Source of Acquisition Note</note>
		<note tag ="542" property="copyrightStatus">Information Relating to Copyright Status</note>
		<note tag ="546" property="languageNote" sfcodes="3a" >Language Note</note>
		<note tag ="550" property="issuers">Issuing Body Note</note>
		<note tag ="556" property="documentation">Information about Documentation Note</note>
		<note tag ="561" property="ownership">Ownership and Custodial History</note>
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
        <work-relateds>
            <type tag="(700|710|711|720)" ind2="2" property="constituent">isIncludedIn</type>
            <type tag="(700|710|711|720)" ind2="( |0|1)" property="relatedWork">relatedWork</type>        		                        
            <type tag="740" ind2=" " property="relatedWork">relatedWork</type>
		    <type tag="740" ind2="2" property="contains">isContainedIn</type>
		    <type tag="760" property="subseriesOf">hasParts</type>	
		    <type tag="762" property="subseries">hasParts</type>	
		    <type tag="765" property="translationOf">hasTranslation</type>
		    <type tag="767" property="translation">translationOf</type>
		    <type tag="770" property="supplement">translationOf</type>
		    <type tag="772" ind2=" " property="supplementTo">isSupplemented</type>
		    <!--<type tag="772" ind2="0" property="hasParent">isParentOf</type>		
		    <type tag="772" property="memberOf">host</type>-->
		    <type tag="773" property="host">hasConstituent</type>
		    <type tag="775" property="otherEdition" >hasOtherEdition</type>
		    <type tag="776" property="otherPhysicalFormat">hasOtherPhysicalFormat</type>
		    <type tag="777" property="issuedWith">issuedWith</type>
		<!--       <type tag="780" property="preceding">continuationOf</type>-->
		    <type tag="780" ind2="0" property="continues">continuationOf</type>
		    <type tag="780" ind2="2" property="continues">continuationOf</type>
		    <type tag="780" ind2="1" property="continuesInPart">partiallyContinuedBy</type>
		    <type tag="780" ind2="3" property="continuesInPart">partiallyContinuedBy</type>
		    <type tag="780" ind2="4" property="unionOf">preceding</type>
		    <type tag="780" ind2="5" property="absorbed">isAbsorbedBy</type>
		    <type tag="780" ind2="7" property="separatedFrom">formerlyIncluded</type>
		<!--    <type tag="785" property="succeeding">continuedBy</type>-->
		   
		 <type tag="785" ind2="0"  property="continuedBy">continues</type>
		    <type tag="785" ind2="1" property="continuedInPartBy">partiallyContinues</type>	
		    <type tag="785" ind2="2"  property="continuedBy">continues</type>
		    <type tag="785" ind2="3" property="continuedInPartBy">partiallyContinues</type>
		    <type tag="785" ind2="4" property="absorbedBy">absorbs</type>
		    <type tag="785" ind2="5"  property="absorbedInPartBy">partiallyAbsorbs</type>
		    <type tag="785" ind2="6"  property="splitInto">splitFrom</type>
		   <type tag="785" ind2="7"  property="mergedInto">mergedFrom</type>	
    		<type pattern="785" ind2="8"  property="changedBackTo">formerlyNamed</type>	
		
		    <type tag="786" property="dataSource"></type>
		    <type tag="533" property="reproduction"></type>
		      <type tag="534" property="originalVersion"></type>
    		<type pattern="787" property="hasRelationship">relatedItem</type>					  	    	  	   
	  	    <type tag="490" ind1="0" property="inSeries">hasParts</type>
	  	    <type pattern ="510" property="references">isReferencedBy</type>
	  	    <type tag="630"  property="subject">isSubjectOf</type>
	  	    <type tag="(400|410|411|440|760|800|810|811|830)" property="series">hasParts</type>	  	    
            <type tag="730"  property="relatedWork">relatedItem</type>
            
              
        </work-relateds>
        <!-- Instance to Work relationships (none!) -->
	  	<instance-relateds>
	  	  
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
            let $holdings := marcbib2bibframe:generate-holdings($marcxml, $about)
            return
                element rdf:RDF {        attribute transformation-edition{$marcbib2bibframe:last-edit},
                    $work,
                    $instances,
                    (:,
                      generate-controlfields($marcxml):)
                      $holdings
                }
        else
            element rdf:RDF {
            	attribute transformation-edition {$marcbib2bibframe:last-edit},
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
        
    
    let $instance-title := 
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
        
    let $publication:=marcbib2bibframe:generate-publication($d)
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
                      marcbib2bibframe:generate-880-label($d,"provider"),
                      element bf:resourceRole {"publisher"}
                }
            }
    
    let $pubdate :=
        for $a in $d/marcxml:subfield[@code eq "c"]
        return element bf:pubDate {marcbib2bibframe:clean-string(xs:string($a))}
    
    

    let $physMapData := 
        (
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "a"]   
            return element bf:scale {
            		if (fn:string($i)="a") then "Linear scale" 
            		else if (fn:string($i)="b") then "Angular scale" else if (fn:string($i)="z") then "Other scale type" else ()
            		},
	for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "b" or @code eq "c"]  
            	return element bf:scale { fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "a"]
            return element bf:scale {xs:string($i)},
                       
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "b"]
            return element bf:projection {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "c"]
            return element bf:latLong {xs:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "d" or @code eq "e" or @code eq "f" or @code eq "g"]  
            return element bf:latLong {xs:string($i)}
        ) 
let             $physBookData:=()
let $physSerialData:=()
let $physResourceData:=()
            (:this is not right yet  :)
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
    (: moved to generate-holdings :)
   (: let $call-num:= 
        if ($d/../marcxml:datafield[@tag eq "050"]) then
	        (: regex for call# "^[a-zA-Z]{1,3}[1-9].*$":)
	         if ($d/../marcxml:datafield[@tag eq "050"][fn:matches(.,"^[a-zA-Z]{1,3}[1-9].*$")]) then	         	
	        			for $call in $d/../marcxml:datafield[@tag eq "050"][fn:matches(.,"^[a-zA-Z]{1,3}[1-9].*$")]        
	            			return fn:normalize-space(fn:string-join($call," ")) 
	            	
		else ()
        else ():)
(:???? trash this???:)
    let $instance-identifiers :=
             (                       
            marcbib2bibframe:generate-identifiers($d/ancestor::marcxml:record,"instance")    
        )
            
    (: all relationships at work level:)
    (:let $related-works:= marcbib2bibframe:related-works($d/ancestor::marcxml:record,$workID,"instance"):) 
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
            $instance-title,
            
            $names,
            $edition,
            $publication,
            $providers,            
            $place,
            $pubdate,       
            $physResourceData,            
            $physMapData,
            $physSerialData,            
            $instance-identifiers,               
            $physdesc,
            element bf:instanceOf {
                attribute rdf:resource {$workID}
            },
            $notes,
         (:   $related-works,:)
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
        
        let $lang := fn:substring(fn:string($d/../marcxml:controlfield[@tag="008"]), 36, 3)     
    
  	
        let $this-tag:= fn:string($d/@tag)
        let $hit-num:=fn:tokenize($d/marcxml:subfield[@code="6"],"-")[2]			
        let $match:=$d/../marcxml:datafield[@tag="880" and fn:starts-with(marcxml:subfield[@code="6"] , fn:concat($this-tag ,"-", $hit-num ))]
	
	let $scr := fn:tokenize($match/marcxml:subfield[@code="6"],"/")[2]

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
	       
        let $xmllang:= if ($script) then fn:concat($lang,"-",$script) else $lang
        
        return 
            if ($node-name="name") then
                element madsrdf:authoritativeLabel {
                    attribute xml:lang {$xmllang},
                    
                     if ($d/@tag!="534") then   
                    marcbib2bibframe:clean-string(fn:string-join($match/marcxml:subfield[@code="a" or @code="b" or @code="c" or @code="d" or @code="q"] , " "))
                    else
                    marcbib2bibframe:clean-string($match/marcxml:subfield[@code="a"])
                }
            else if ($node-name="title") then 
                let $subfs := 
                    if ( fn:matches($d/@tag, "(245|242|243|246|510|630|730|740|830)") ) then
                        "(a|b|f|h|k|n|p)"
                    else
                        "(t|f|k|m|n|p|s)"
                return
                    element madsrdf:authoritativeLabel {
                        attribute xml:lang {$xmllang},   
                        
                        (: marcbib2bibframe:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,"(a|b)")] ," "),"^(.+)/$","$1")) :)
                        marcbib2bibframe:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,$subfs)] ," "),"^(.+)/$","$1"))
                    }
            else if ($node-name="subject") then 
                element madsrdf:authoritativeLabel{
	attribute xml:lang {$xmllang},   
                    marcbib2bibframe:clean-string(fn:string-join($match/marcxml:subfield[fn:not(@code="6")], " "))
                }
            else if ($node-name="place") then 
                for $sf in $match/marcxml:subfield[@code="a"]
                return
                    element  rdfs:label {
                        attribute xml:lang {$xmllang},                         
                        marcbib2bibframe:clean-string(fn:string($sf))
                    }
	else if ($node-name="provider") then 
                for $sf in $match/marcxml:subfield[@code="b"]
                return
                    element rdfs:label {
                        attribute xml:lang {$xmllang},   			
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
        if ($resource="instance") then 
            $marcbib2bibframe:identifiers//vocab-identifiers/property[@domain="Instance"][fn:not(@tag="020")]
        else 
            $marcbib2bibframe:identifiers//vocab-identifiers/property[@domain="Work"]
    let $bfIdentifiers := 
            for $id in $identifiers[fn:not(@ind1)] (:all but 024 and 028:)
            return
                for $this-tag in $marcxml/marcxml:datafield[@tag eq $id/@tag] (:for each matching marc datafield:)          		
                (:if contains subprops, build class for $a else just prop w/$a:)
                return 
                ( 
                    (:first, deal with the $a):) 
                    if ( $this-tag/marcxml:subfield[fn:matches(@code,"(b|q|2)")] or 			
                        (:($this-tag/@tag="020" and fn:contains(fn:string($this-tag/marcxml:subfield[@code="a"]),"(")  )   or:)			
                        ($this-tag[@tag="037"][marcxml:subfield[@code="c"]]) 				
			           ) then 
                        element bf:IdentifierEntity{
                            element bf:identifierScheme {				 
                                fn:string($id/@name)
                            },
                            
                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
                            return element bf:identifierAssigner {fn:string($sub)},

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
                    else
                        (:
                            just the property: should include 035 oclc 
                            ($this-tag[@tag="035"][fn:contains(fn:string(marcxml:subfield[@code="a"]), "(OCoLC)")]) 
                        :)
                        (
                           if ( $this-tag[@tag="010"]/marcxml:subfield[@code="a"] ) then
                            element bf:derivedFromLccn {    
                            attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/identifiers/lccn/",fn:replace(fn:string($this-tag[@tag="010"]/marcxml:subfield[@code="a"])," ",""))}                                         
                            }
		else  if ( $this-tag[@tag="030"]/marcxml:subfield[@code="a"] ) then
                            element bf:coden {    
                            attribute rdf:resource {fn:concat("http://cassi.cas.org/coden/",fn:normalize-space(xs:string($this-tag[@tag="030"]/marcxml:subfield[@code="a"])))}                                         
                            }
		(:else  if ( $this-tag[@tag="020"]/marcxml:subfield[@code="a"] ) then
		let $clean-isbn:=	
			marcbib2bibframe:clean-string(fn:normalize-space(fn:tokenize(fn:string($this-tag/marcxml:subfield[@code="a"]),"\(")[1]))
	
		return    element bf:isbn {    
                            attribute rdf:resource {fn:concat("http://www.lookupbyisbn.com/Search/Book/",fn:normalize-space($clean-isbn),"/1")}         
                                (:fn:normalize-space(xs:string($this-tag[@tag="020"]/marcxml:subfield[@code="a"])):)
                            }:)

                        else if ( fn:contains(fn:string($this-tag[@tag="035"]/marcxml:subfield[@code="a"]), "(OCoLC)" ) ) then
                            element bf:oclc-number {
                            attribute rdf:resource { fn:concat("http://oclc.org/oclc-number/",fn:normalize-space(
                            				fn:replace($this-tag[@tag="035"]/marcxml:subfield[@code="a"], "\(OCoLC\)", "")
                            				)
                            				)                       }
                            				
                            (:    fn:normalize-space(fn:replace($this-tag[@tag="035"]/marcxml:subfield[@code="a"], "\(OCoLC\)", "")):)
                            }
                        else if (fn:contains(fn:string($this-tag[@tag="856"]/marcxml:subfield[@code="u"]),"doi")) then
                            element bf:doi {
                                fn:normalize-space( fn:string($this-tag[@tag="856"]/marcxml:subfield[@code="u"]))
                            }
                        else if (fn:contains(fn:string($this-tag[@tag="856"]/marcxml:subfield[@code="u"]),"hdl" )) then
                            element bf:hdl {
                                fn:normalize-space( fn:string($this-tag[@tag="856"]/marcxml:subfield[@code="u"]))
                            }
                        else (),
	                    
	                    (:then deal with the z's:)
	                    if ( $this-tag/marcxml:subfield[fn:matches(@code,"(y|z)")]) then
                            for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"(y|z)")]     
                            return
                                element bf:IdentifierEntity {
                                    element bf:identifierScheme { fn:string($id/@name) },
                                    marcbib2bibframe:handle-cancels($this-tag, $sf)
                                }
	                    else ()
	                    ),

                    for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(024|028)")]
                    let $this-id:= $identifiers[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1](: i1=7 has several:)   	       	  
                    return
                        if ($this-id) then(: if there are any 024s on this record in this domain (work/instance):) 
                            let $scheme:=   	       	  	
                                if ($this-tag/@ind1="7") then (:use the contents of $2 for the name: :)
                                    fn:string($this-tag[@ind1=$this-id/@ind1]/marcxml:subfield[@code="2"])
                                else (:use the $id name:)
                                    fn:string($this-id[@tag=$this-tag/@tag][@ind1=$this-tag/@ind1]/@name)
                            
                            (:if  024 has a c, it's qualified, needs a class  else just prop w/$a:)
                            return
                            if (
                                fn:contains(fn:string($this-tag/marcxml:subfield[@code="c"]), "(") or 
                                $this-tag/marcxml:subfield[@code="q"] or 
			                     $this-tag/marcxml:subfield[@code="b"]
			                 ) then	
                                element bf:IdentifierEntity{
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
                            else
                                let $property:= (:024 had a z only; no $a: bibid;17332794:)
                                    if ($this-tag/@ind1="7") then
                                        fn:string($this-tag[@ind1=$this-id/@ind1]/marcxml:subfield[@code="2"])								
                                    else 
                                        fn:concat("bf:",fn:string($this-id/@name))					
                                return
                                    (
                                        element {$property} {		                     
                                            fn:normalize-space(fn:string($this-tag/marcxml:subfield[@code="a"]))
                                        },
                                        (:then deal with the z's:)
                                        if ( $this-tag/marcxml:subfield[fn:matches(@code,"(m|y)")]) then
                                            for $sf in $this-tag/marcxml:subfield[fn:matches(@code,"(m|y)")]
                                            return          
                                                element bf:IdentifierEntity{
                                                    element bf:identifierScheme {$scheme},		
                                                    marcbib2bibframe:handle-cancels($this-tag, $sf)
                                                }
                                        else ()
                                    )
                        else ()
		                  (:end 024:)
	           )
	
	return 
        for $bfi in $bfIdentifiers
        return 
            if (fn:name($bfi) eq "bf:IdentifierEntity") then
                element bf:identifier {$bfi}
            else
                $bfi
};

(:~
:   This is the function generates full Identifier classes from m,y,z cancel/invalid identifiers and qualifiers
:   @param  $this-tag       element is the marc data field
:   @param  $sf             subfield element     
:   @return bf:Identifier as element()
:)
declare function marcbib2bibframe:handle-cancels($this-tag, $sf) 
{

    (: Kevin surgery - commenting out because do not know effect :)
    (:
    if ($this-tag[@tag="022"][marcxml:subfield[@code="y"]]) then
        (
            element bf:identifierValue { fn:string($this-tag[@tag="022"][marcxml:subfield[@code="y"]])},
            element bf:identifierStatus{"incorrect"}
        )
    else if  ($this-tag[@tag="022"][marcxml:subfield[@code="z"]]) then 
        (
            element bf:identifierValue { fn:string($this-tag[@tag="022"][marcxml:subfield[@code="z"]])},
            element bf:identifierStatus{"canceled/invalid"}
        ) 
    else if ($this-tag[@tag="022"][marcxml:subfield[@code="m"]]) then
        (
            element bf:identifierValue { fn:string($this-tag[@tag="022"][marcxml:subfield[@code="m"]])},
			element bf:identifierStatus {"canceled/invalid"}
        ) 
    else if ($this-tag[fn:matches(@tag,"(010|015|016|017|020|027|030|024|088)")][marcxml:subfield[@code="z"]] ) then
        (
            element bf:identifierValue { fn:string($this-tag/marcxml:subfield[@code="z"])},
            element bf:identifierStatus{"canceled/invalid"}
        ) 
    else
        ()
	 :)
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
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a
:
::   @param  $marcxml       element is the marcxml record

:   @param  $resource      string is the "work" or "instance"
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-identifiers-old(
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
                if ($id/@sfcodes) then 
                    fn:string($id/@sfcodes)
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
:   This is the function generates publication  data for instance 
:	Returns bf: node of elname 
: abc are repeatable!!! each repetition of b or c is another publication; should it be another instance????
abc and def are parallel, so a and d are treated the same, etc, except the starting property name publication vs manufacture
:   @param  $marcxml       element is the datafield 260
:   @param  $resource      string is the "work" or "instance"
:   @return bf:* 	   element()
:)
declare function marcbib2bibframe:generate-publication
    (
        $d as element(marcxml:datafield)        
    ) as element ()*
{
if ($d/marcxml:subfield[fn:matches(@code,"(b|e)")]) then
(: not sure why this is failing when there's a b and an e: 509288 ; currently set to [1] to move on:)
 for $pub at $x in $d/marcxml:subfield[fn:matches(@code,"(b|e)")][1]
 	return 
	element {if ($pub/@code="b" ) then "bf:publication" else "bf:manufacture " } {
		element bf:ProviderEntity {
	 		element bf:providerName {fn:string($pub)},
			if ($d/marcxml:subfield[fn:matches(@code,"(a|d)")][$x]) then
				element bf:providerPlace {fn:string($d/marcxml:subfield[fn:matches(@code,"(a|d)")][$x])}	
			else (),
			if ($d/marcxml:subfield[@code="c"][$x] and fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") ) then
				element bf:copyrightDate {fn:string($d/marcxml:subfield[@code="c"][$x])}
			else if ($d/marcxml:subfield[@code="c"][$x] and fn:not(fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") )) then
				element bf:providerDate {fn:string($d/marcxml:subfield[@code="c"][$x])}
			else if ($d/marcxml:subfield[fn:matches(@code,"(c|f)")][$x] ) then
				element bf:providerDate {fn:string($d/marcxml:subfield[fn:matches(@code,"(c|f)")][$x])}
			else ()
		}
	}
	
else if ($d/marcxml:subfield[fn:matches(@code,"(a|c)")]) then	
	element bf:publication {
		element bf:ProviderEntity {
	 		for $pl in $d/marcxml:subfield[@code="a"]
				return element bf:providerPlace {fn:string($pl)},
			for $pl in $d/marcxml:subfield[@code="c"]
				return  if (fn:starts-with($pl,"c")) then				
					element bf:providerDate {fn:string($pl)}
				else 
					element bf:copyrightDate {fn:string($pl)}		
		}
	}
else if ($d/marcxml:subfield[fn:matches(@code,"(d|f)")]) then	
	element bf:publication {
		element bf:ProviderEntity {
	 		for $pl in $d/marcxml:subfield[@code="d"]
				return element bf:providerPlace {fn:string($pl)},
			for $pl in $d/marcxml:subfield[@code="f"]							
				return element bf:providerDate {fn:string($pl)}						
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
    $instance as element (bf:Instance),
    $workID as xs:string
    ) as element ()*
    
{
 
                
    let $isbn-extra:=fn:normalize-space(fn:tokenize(fn:string($isbn-set/marcxml:subfield[1]),"\(")[2])
    let $volume:=fn:replace(marcbib2bibframe:clean-string(fn:normalize-space(fn:tokenize($isbn-extra,":")[2])),"\)","")   
    
    let $voume-info:=
        if ($volume ) then		
            for $vol in fn:tokenize(fn:string($d//marcxml:datafield[@tag="505"]/marcxml:subfield[@code="a"]),"--")[fn:contains(.,$volume)][1]           
		  return if  (fn:contains($vol,$volume)) then element bf:partTitle {fn:concat("experimental 505a parsing/matching to isbn:",$vol)} else ()		  
        else ()

    let $carrier:=
        if (fn:tokenize( $isbn-set/marcxml:subfield[1],"\(")[1]) then        
            marcbib2bibframe:clean-string(fn:normalize-space(fn:tokenize($isbn-set/marcxml:subfield[1],"\(")[2]))            
        else () 
    
    let $carrierType:=                                				  	                        
   
            if (fn:matches($carrier,"(pbk|softcover)","i")) then
                "paperback"
            else if (fn:matches($carrier,"(hbk|hdbk|hardcover|hc|hard)","i") ) then 
                "hardback"
            else if (fn:matches($carrier,"(ebook|eresource|e-isbn)","i") ) then
                "electronic resource"
            else if (fn:contains($carrier,"lib. bdg.") ) then
                "library binding"			
            else if (fn:matches($carrier,"(acid-free|acid free|alk)","i")) then
                "acid free"						  		
            else fn:replace($carrier,"\)","")
                                  
    
    let $clean-isbn:= 
        for $item in $isbn-set/bf:isbn
        	return marcbib2bibframe:clean-string(fn:normalize-space(fn:tokenize( fn:string($item),"\(")[1]))

    let $isbn := 
        for $i in $clean-isbn
        let $element-name :=
            if (fn:string-length($i) gt 11  ) then 
                "bf:isbn13" 
            else 
                "bf:isbn10" 
        return element {$element-name} {    
            attribute rdf:resource {fn:concat("http://www.lookupbyisbn.com/Search/Book/",fn:normalize-space($i),"/1")}                                         
	   }    

    (:get the physical details:)
    (: We only ask for the first 260 :)
(: instance is now calculated before this function and passed in
let $instance := 
        for $i in $d/marcxml:datafield[@tag eq "260"][1]
        return marcbib2bibframe:generate-instance-from260($i, $workID)
:)
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
        		$isbn,               	
        		if ($volume) then element bf:partLabel{ $volume} else (),
        		if ($carrierType) then      element bf:carrierType {$carrierType} else (),
        		$voume-info,
   	        		        
   	         if ( fn:exists($instance) ) then
	                (
	                    $instance/@*,
	                    $instance/*
	                )
	            else 
	                $instanceOf           
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
	 if ( $category="resource" ) then (:?? is this ever true? I don't see resource assigned for category above...:)
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
		
                      (:  let $names := :)
                    	    for $datafield in $df 
                    	    return marcbib2bibframe:get-name( $datafield )
                
                    else
                        element bf:annotationAssertedBy {
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
:   This is the function generates holdings resources.
: 
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function marcbib2bibframe:generate-holdings(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()* 
{  
 let $call-num:=  
        if ($marcxml/marcxml:datafield[@tag eq "050"]) then
	        (: regex for call# "^[a-zA-Z]{1,3}[1-9].*$":)
	         if ($marcxml/marcxml:datafield[@tag eq "050"][fn:matches(.,"^[a-zA-Z]{1,3}[1-9].*$")]) then	         	
	        			for $call in $marcxml/marcxml:datafield[@tag eq "050"][fn:matches(.,"^[a-zA-Z]{1,3}[1-9].*$")]        
	            			return fn:normalize-space(fn:string-join($call," ")) 
	            	
		else ()
        else ()
return 
        if ($call-num) then 
         element bf:HoldingsAnnotation {
            element bf:annotates {
                attribute rdf:resource {$workID}
            },
         	for $c in fn:distinct-values($call-num) 
         		return
         			element bf:callNumber {$c}
         }	
         	else ()
    
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
        	(:use the first 260 to set up a book instance:)
            let $instance:= 
                for $i in $marcxml/marcxml:datafield[@tag eq "260"][1]
                return marcbib2bibframe:generate-instance-from260($i, $workID)        

            for $set in $isbn-sets/bf:set
            return marcbib2bibframe:generate-instance-fromISBN($marcxml,$set, $instance, $workID)
                (:
                (
                    for $i in $set/*
                    return marcbib2bibframe:generate-instance-fromISBN($marcxml,$set, $instance, $workID)
	    	      )
	    	    :)	    	      

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
 						fn:concat(fn:string($note/@startwith),$marc-note/marcxml:subfield[@code="b"])
 					else ()
			return
                			element {fn:concat("bf:",fn:string($note/@property))} {						
                    				if ($marc-note/@tag!="504" and $marc-note/marcxml:subfield[fn:contains($return-codes,@code)]) then
                    					fn:normalize-space(fn:concat($precede,fn:string-join($marc-note/marcxml:subfield[fn:contains($return-codes,@code)]," ")))                    
                    				else 
                    					fn:normalize-space(fn:concat($marc-note/marcxml:subfield[@code="a"],$precede))
                			}        
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
let $title:=
fn:string($d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"])
let $carrier:= 
    if ($d/marcxml:subfield[@code="a"]) then 
        fn:string($d/marcxml:subfield[@code="a"]) 
    else if ($d/marcxml:subfield[@code="3"]) then 
        $d/marcxml:subfield[@code="3"] 
    else ()
let $pubPlace:= for  $pl in $d/marcxml:subfield[@code="b"]
			return element bf:pubPlace {fn:string($pl)}
let $agent:= for  $aa in $d/marcxml:subfield[@code="c"] 
			return element bf:associatedAgent {fn:string($aa)}
let $pubDate:= fn:string($d/marcxml:subfield[@code="d"])
let $extent:= fn:string($d/marcxml:subfield[@code="e"])
let $coverage:= fn:string($d/marcxml:subfield[@code="m"])
(:gwu has multiple 533$n:)
let $note:= for $n in $d/marcxml:subfield[@code="n"]
		return element bf:note { fn:string($n)}
return 
	element {fn:concat("bf:",fn:string($type/@property))} {
			element bf:Work{
				element bf:title {$title},
				element bf:label {$title},
				element bf:carrier {$carrier}, 
				if ($pubDate or $pubPlace or $agent or $extent or $coverage or $note) then
				element bf:hasInstance {
					element bf:Instance {
						$pubPlace,
						element bf:pubDate {$pubDate},
						if ($extent) then element bf:extent {$extent} else (),
						if ($coverage) then element bf:coverage {$coverage}  else (),
						$agent,
						if ($note) then  $note  else (),
						(:$3, $c, $b, $d, $e, $f, $m, $n, $5 in that order:)
						element bf:relatedNote {fn:string-join ($d/*[fn:not(@code="a")]," - ")}
					}
				}
				else ()				 							
				}
			}
};


declare function marcbib2bibframe:generate-related-work
    (
        $d as element(marcxml:datafield), 
        $type as element() 
    )
{ 	 

    let $titleFields := 
        if (fn:matches($d/@tag,"(440|630|730|740|830)")) then
            "(a|n|p)"            
        else if (fn:matches($d/@tag,"(534)")) then
            "(t|b|f)"
        else if (fn:matches($d/@tag,"(510)")) then
            "(a|b|c)"
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

               
        else if (  $d/marcxml:subfield[@code="a"]  and fn:not(fn:matches($d/@tag,"(400|410|411|440|800|810|811|510|630|730|740|830)")) ) then
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
                    $combinedLabel
                }
        else
            $aLabelWork880
            
    return 
 	element {fn:concat("bf:",fn:string($type/@property))} {
		element bf:Work {		
            if ($d/marcxml:subfield[@code="w" or @code="x"]) then
                for $s in $d/marcxml:subfield[@code="w" or @code="x" ]
  	              let $iStr := fn:string($s)
           	    return
	                    if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then
	                        element bf:oclc-number {  attribute rdf:resource {fn:concat("http://oclc.org/oclc-number/",marcbib2bibframe:clean-string(fn:replace($iStr, "\(OCoLC\)", ""))) }}
	                    else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
	                        element bf:derivedFromLccn { attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/identifiers/lccn/",fn:replace( fn:replace($iStr, "\(DLC\)", "")," ",""))} }                
	                    else if (fn:string($s/@code="x")) then
	                        element bf:issn {attribute rdf:resource {fn:concat("http://issn.org/issn/", marcbib2bibframe:clean-string($iStr)) } }                           	                	
		        else ()
	   else 
	   (),		
            element madsrdf:authoritativeLabel {$aLabel},
            $aLabelWork880,
            element bf:title {$title},
            $name,
            
            if ($d/marcxml:subfield[@code="w"]) then
                for $s in $d/marcxml:subfield[@code="w"]
                let $iStr := fn:string($s)
                return
                    if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then
                        (:element bf:oclc-number{ fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }:)
                        element bf:oclc-number {  attribute rdf:resource {fn:concat("http://oclc.org/oclc-number/",marcbib2bibframe:clean-string(fn:replace($iStr, "\(OCoLC\)", ""))) }}
                    else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
                        (:element bf:derivedFromLccn {  fn:replace(fn:replace($iStr, "\(DLC\)", "")," ","") }:)
                        element bf:derivedFromLccn { attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/identifiers/lccn/",fn:replace(fn:replace($iStr, "\(DLC\)", "")," ",""))}                   
                        }
                    else 
                        element bf:identifier { fn:normalize-space($iStr) }   	                	
			else ()

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
                marcbib2bibframe:get-isbn( marcbib2bibframe:clean-string( $isbn-str ) )/*
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
                element bf:isbn { xs:string($isbn-set/bf:isbn10) },
                element bf:isbn { xs:string($isbn-set/bf:isbn13) },
            	for $sfa in $marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
            	where fn:contains(xs:string($sfa),xs:string($isbn-set/bf:isbn10)) or fn:contains(xs:string($sfa),xs:string($isbn-set/bf:isbn13))
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
            if ($type/@tag="740") then (: title is in $a :)
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][@ind1=$type/@ind1 or @ind2=$type/@ind2]		
                return marcbib2bibframe:generate-related-work($d,$type)
     	else if (fn:matches($type/@tag,"533")) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))]		
				return marcbib2bibframe:generate-related-reproduction($d,$type)                
            else if ($type/@ind1) then
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][@ind1=$type/@ind1][marcxml:subfield[@code="t"]]	
                return marcbib2bibframe:generate-related-work($d,$type)                
            else if ($type/@ind2) then 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,fn:string($type/@tag))][fn:matches(@ind2,fn:string($type/@ind2))][marcxml:subfield[@code="t"]]		
				return marcbib2bibframe:generate-related-work($d,$type)
            else if (fn:matches($type/@tag,"(510|630|730|830)")) then 
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
    
    let $types := marcbib2bibframe:get-resourceTypes($marcxml)
        
    let $mainType := "Work"
     (:ldr06:   :)    
    
    
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
                    $combinedLabel
                }
        
    let $cf008 := xs:string($marcxml/marcxml:controlfield[@tag='008'])
        
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
            
    let $audience := fn:substring($cf008, 23, 1)
    let $audience := 
        if ($audience ne "") then
            let $aud := xs:string($marcbib2bibframe:targetAudiences/type[@cf008-22 eq $audience]) 
            return
                if (
                    $aud ne ""
                       (: What others would have audience? :)
                    (:??  ntra: I think audience s.b. there regardless of the subclass of work and anyway, mainType is Work
                    and
                    (
                        $mainType eq "LanguageMaterial" or
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
            let $gen := xs:string($marcbib2bibframe:formsOfItems/type[@cf008-23 eq $genre and fn:contains(xs:string(@rType), $mainType)]) 
            return
                if ($gen ne "") then
                    element bf:genre {$gen}
                else ()
        else
            ()
         
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
		for $d in  $marcxml/marcxml:datafield[@tag="520"]
			let $abstract-type:=
				if ($d/@idn1="") then "summary"
             			else if ($d/@idn1="0") then "contentDescription"
				else if ($d/@idn1="1") then "review"
				else if ($d/@idn1="2") then "contentDescription"
				else if ($d/@idn1="3") then "abstract"
				else if ($d/@idn1="4") then "contentAdvice"
				else 				"contentDescription"
			return	
				element {fn:concat("bf:",$abstract-type)} {
					fn:string-join($d/marcxml:subfield[@code="a" or @code="b"],"")
				}      			
			
    let $abstract-annotation:= (: for now, do abstracts both as simple property and annotation:)
        for $d in  $marcxml/marcxml:datafield[@tag="520"]
        let $abstract-type:=
            if ($d/@idn1="") then "Content Description"
            else if ($d/@idn1="0") then "Content Description"
            else if ($d/@idn1="1") then "Review"
            else if ($d/@idn1="2") then "Content Description"
            else if ($d/@idn1="3") then "Abstract"
            else if ($d/@idn1="4") then "Content Advice"
            else                        "Content Description"
        return
            element bf:annotation {
                element bf:Annotation {
                    element rdf:type {
                        attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" , fn:replace($abstract-type, " ", "") ) }
                    },
                        
                    element bf:label { $abstract-type },
                        
                    if (xs:string($d/marcxml:subfield[@code="c"][1]) ne "") then
                        for $sf in $d/marcxml:subfield[@code="c"]
                        return element bf:annotationAssertedBy { xs:string($sf) }
                    else
                        element bf:annotationAssertedBy { 
                            attribute rdf:resource {"http://id.loc.gov/vocabulary/organizations/dlc" }
                        },
                        
                    for $sf in $d/marcxml:subfield[@code="u"]
                    return element bf:annotationBody { xs:string($sf) },
                        
                    element bf:annotationBodyLiteral { fn:string-join($d/marcxml:subfield[@code="a" or @code="b"],"") },
                        
                    element bf:annotates {
                        attribute rdf:resource {$workID}
                    }
                }
            }
            (:this is now all handled in generate-class:)
	(:let $validLCC:=("DAW","DJK","KBM","KBP","KBR","KBU","KDC","KDE","KDG","KDK","KDZ","KEA","KEB","KEM","KEN","KEO","KEP","KEQ","KES","KEY","KEZ","KFA","KFC","KFD","KFF","KFG","KFH","KFI","KFK","KFL","KFM","KFN","KFO","KFP","KFR","KFS","KFT","KFU","KFV","KFW","KFX","KFZ","KGA","KGB","KGC","KGD","KGE","KGF","KGG","KGH","KGJ","KGK","KGL","KGM","KGN","KGP","KGQ","KGR","KGS","KGT","KGU","KGV","KGW","KGX","KGY","KGZ","KHA","KHC","KHD","KHF","KHH","KHK","KHL","KHM","KHN","KHP","KHQ","KHS","KHU","KHW","KJA","KJC","KJE","KJG","KJH","KJJ","KJK","KJM","KJN","KJP","KJR","KJS","KJT","KJV","KJW","KKA","KKB","KKC","KKE","KKF","KKG","KKH","KKI","KKJ","KKK","KKL","KKM","KKN","KKP","KKQ","KKR","KKS","KKT","KKV","KKW","KKX","KKY","KKZ","KLA","KLB","KLD","KLE","KLF","KLH","KLM","KLN","KLP","KLQ","KLR","KLS","KLT","KLV","KLW","KMC","KME","KMF","KMG","KMH","KMJ","KMK","KML","KMM","KMN","KMP","KMQ","KMS","KMT","KMU","KMV","KMX","KMY","KNC","KNE","KNF","KNG","KNH","KNK","KNL","KNM","KNN","KNP","KNQ","KNR","KNS","KNT","KNU","KNV","KNW","KNX","KNY","KPA","KPC","KPE","KPF","KPG","KPH","KPJ","KPK","KPL","KPM","KPP","KPS","KPT","KPV","KPW","KQC","KQE","KQG","KQH","KQJ","KQK","KQM","KQP","KQT","KQV","KQW","KQX","KRB","KRC","KRE","KRG","KRK","KRL","KRM","KRN","KRP","KRR","KRS","KRU","KRV","KRW","KRX","KRY","KSA","KSC","KSE","KSG","KSH","KSK","KSL","KSN","KSP","KSR","KSS","KST","KSU","KSV","KSW","KSX","KSY","KSZ","KTA","KTC","KTD","KTE","KTF","KTG","KTH","KTJ","KTK","KTL","KTN","KTQ","KTR","KTT","KTU","KTV","KTW","KTX","KTY","KTZ","KUA","KUB","KUC","KUD","KUE","KUF","KUG","KUH","KUN","KUQ","KVB","KVC","KVE","KVH","KVL","KVM","KVN","KVP","KVQ","KVR","KVS","KVU","KVW","KWA","KWC","KWE","KWG","KWH","KWL","KWP","KWQ","KWR","KWT","KWW","KWX","KZA","KZD","AC","AE","AG","AI","AM","AN","AP","AS","AY","AZ","BC","BD","BF","BH","BJ","BL","BM","BP","BQ","BR","BS","BT","BV","BX","CB","CC", "CD","CE","CJ","CN","CR","CS","CT","DA","DB","DC","DD","DE","DF","DG","DH","DJ","DK","DL","DP","DQ","DR","DS","DT","DU","DX","GA","GB","GC","GE","GF","GN","GR","GT","GV","HA","HB","HC","HD","HE","HF","HG","HJ","HM","HN","HQ","HS","HT","HV","HX","JA","JC","JF","JJ","JK","JL","JN","JQ","JS","JV","JX","JZ","KB","KD","KE","KF","KG","KH","KJ","KK","KL","KM","KN","KP","KQ","KR","KS","KT","KU","KV","KW","KZ","LA","LB","LC","LD","LE",  "LF","LG","LH","LJ","LT","ML","MT","NA","NB","NC","ND","NE","NK","NX","PA","PB","PC","PD","PE","PF","PG","PH","PJ","PK","PL","PM","PN","PQ","PR","PS","PT","PZ","QA","QB","QC","QD","QE","QH","QK","QL","QM","QP","QR","RA","RB","RC","RD","RE","RF","RG",   "RJ","RK","RL","RM","RS","RT","RV","RX","RZ","SB","SD","SF","SH","SK","TA","TC","TD","TE","TF","TG","TH","TJ","TK","TL","TN","TP","TR","TS","TT","TX","UA","UB","UC","UD","UE","UF","UG","UH","VA","VB","VC","VD","VE","VF","VG","VK","VM","ZA","A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","Z")
	let $lcc:= 	
	 ( for $c in $marcxml/marcxml:datafield[fn:string(@tag)="050"]/marcxml:subfield[@code="a"]
	      let $cl:=fn:string($c)			
	      let $strip := fn:replace(fn:string($cl), "(\s+|\.).+$", "")			
	      let $subclassCode := fn:replace($strip, "\d", "")			
		 (:for each 050:)                 	
	            (: lc classes don't have a space after the alpha prefix, like DA1 vs "DA 1" :)
	          return   if (fn:substring(fn:substring-after(fn:string($cl), $subclassCode),1,1)!=' ' and  $subclassCode = $validLCC 	      ) then   								  
	            element bf:class-lcc {	             								 						
	                        attribute rdf:resource {fn:concat( "http://id.loc.gov/authorities/classification/",fn:string($cl))}														                
	              }
	            else (:invalid content in 050:)
	                ()
	        )        :)
	        
    (:ex:5811630:)
 
(:special condition of $b prevents this from being one of the std identifiers:)
	let $copyright:=  
			for $d in  $marcxml/marcxml:datafield[@tag="017"][fn:starts-with(marcxml:subfield[@code="b"],"U.S. Copyright Off")]
				return element bf:copyrightDocumentID {
				fn:string($d/marcxml:subfield[@code="a"])				
					}
  
	let $work-identifiers := marcbib2bibframe:generate-identifiers($marcxml,"work")
	let $work-classes := marcbib2bibframe:generate-class($marcxml,"work")
	
 	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marcbib2bibframe:subject-types//@tag," "),fn:string(@tag))]		
        			return marcbib2bibframe:get-subject($d)
 	let $work-notes := marcbib2bibframe:generate-notes($marcxml,"work")
 	let $work-relateds := marcbib2bibframe:related-works($marcxml,$workID,"work")
 	(:audio ex:12241297:)
 	let $complex-notes:= 
 		for $marc-note in $marcxml/marcxml:datafield[@tag eq "505"][@ind2="0"]
 			let $sub-codes:= fn:distinct-values($marc-note/marcxml:subfield[@code!="t"]/@code)
			let $return-codes := "gru"			
			let $set:=
				for $title in $marc-note/marcxml:subfield[@code="t"]
				let $t := fn:replace(xs:string($title), " /", "")
              
                let $details := 
                    element details {
                        for $subfield in $title/following-sibling::marcxml:subfield[@code!="t"][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)]                
                        let $elname:=
                            if ($subfield/@code="g") then "bf:note" 
                            else if ($subfield/@code="r") then "bf:creator" 
                            else if ($subfield/@code="u") then "rdf:resource" 
                            else fn:concat("bf:f505c" , fn:string($subfield/@code))
                        let $sfdata := fn:replace(xs:string($subfield), " --", "")
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
                        element madsrdf:authoritativeLabel {
                            fn:string-join( ($details/bf:creator[1]/bf:label, $t), ". " )
                        },
                        element bf:title {$t},
                        element madsrdf:elementList {
                            attribute rdf:parseType {"Collection"},
                            element madsrdf:MainTitleElement {
                                element madsrdf:elementValue {$t}
                            }
                        },                       
                        $details/*                                 
                    }
		return						
	                for $item in $set
	                return
	                    element bf:contains {   
	                        element bf:Work {
	                            element rdf:type {attribute rdf:resource {"http://bibframe.org/vocab/Part"}},
	                            $item/*
	                        }																								
		     }
						
 	let $gacs:= 
            for $d in $marcxml/marcxml:datafield[@tag = "043"]/marcxml:subfield[@code="a"] 
            	let $gac := fn:normalize-space(fn:replace(fn:string($d),"-","")) 
	            return
	                element bf:subject {
	                    attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/geographicAreas/", $gac) }
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
            for $t in fn:distinct-values($types)
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
            $aud521,
            $language,
            $abstract,
            $abstract-annotation,
            $audience,           
            $genre,
            $subjects,
            $gacs,
            $copyright,
            $work-classes,            
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
                    for $cl in $madsrdf/madsrdf:componentList
                    return
                        element madsrdf:componentList {
                            attribute rdf:parseType {"Collection"},
                            for $a in $cl/madsrdf:*
                            return
                                element {fn:name($a)} {
                                    $a/rdf:type,
                                    $a/madsrdf:authoritativeLabel
                                }
                        }          
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
:   This function generates all languages .
:   It takes 041 and generates a wrapper 
:   It generates a bf:subject as output.
: 
: $2 - Source of code (NR)
    also 546?
 

:   @param  $d        element is the marcxml:datafield  
:   @return wrap/bf:language* or wrap/bf:LanguageEntity*

:)
   
declare function marcbib2bibframe:get-languages(
   $d as element(marcxml:record)
    ) as element()
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
    (:if a=3chars and there's no $2, then bf:language, else bf:LanguageEntity:)
return element wrap {    
for $tag in $d/marcxml:datafield[@tag="041"]
	for $sf in $tag/marcxml:subfield 
	return 
	fn:string($sf)
		
	
	(:let $string := fn:string($sf)
	for $i in 0 to string-length($string) idiv 3
		let $pos := $i * 3 + 1		
		return substring($string, $pos, 3) 
	 
	  
	return 
	element {"wrap"} {
		
	}:)
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
    
    let $label := if ($d/@tag!='534') then
    	fn:string-join($d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q'] , ' ')    	
    	else 
    	fn:string($d/marcxml:subfield[@code='a' ])
    	
    let $aLabel := $label
    
    let $elementList := if ($d/@tag!='534') then
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
    else () (: 534 $a is not parsed:)
    
  
        
    let $class := 
        if ( fn:ends-with(xs:string($d/@tag), "00") ) then
            "bf:Person"
        else if ( fn:ends-with(xs:string($d/@tag), "10") ) then
            "bf:Organization"
        else if ( fn:ends-with(xs:string($d/@tag), "11") ) then
            "bf:Meeting"
        else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1)="1")  then
            "bf:Person" (:????:)
        else if ( fn:string($d/@tag)= "720" and fn:string($d/@ind1)="2")  then
            "bf:Organization" (:may be a meeting:)
        else 
            "bf:Agent"

    let $tag := xs:string($d/@tag)
    let $desc-role:=if (fn:starts-with($tag , "10") or fn:starts-with($tag , "11")) then "primary" else "secondary" 
    let $resourceRole := 
        if ($relatorCode ne "") then
            (: 
                k-note, added substring call because of cruddy data.
                record 16963854 had "aut 146781635" in it
                Actually, I'm going to undo this because this is a cataloging error
                and we want those caught.  was fn:substring($relatorCode, 1, 3))
            :)
            fn:concat("bf:" , $relatorCode)
        else if ( fn:starts-with($tag, "1") ) then
            "bf:creator"
        else if ( fn:starts-with($tag, "7") and $d/marcxml:subfield[@code="t"] ) then
            "bf:creator"
        else
            "bf:contributor"
            
    let $resourceRoleTerms := 
        for $r in $d/marcxml:subfield[@code="e"]
        return element bf:resourceRole {fn:string($r)}

    return

       element {$resourceRole} {
            element {$class} {            
                element bf:label {$label},
                element rdfs:label {$aLabel},
                if ($d/@tag!='534') then element madsrdf:authoritativeLabel {$aLabel} else (),
                marcbib2bibframe:generate-880-label($d,"name"),
                $elementList,
             
                $resourceRoleTerms,
                element bf:descriptionRole { $desc-role}
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
                    element rdfs:label {$name},
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
let $type:=  if ($tag/@ind1="0") then "Audience: " else if ($tag/@ind1="0") then "Reading grade level" else if  ($tag/@ind1="1") then "Interest age level" else if  ($tag/@ind1="3") then "Interest grade level" else if  ($tag/@ind1="4") then "Special audience characteristics" else if  ($tag/@ind1="4") then "Motivation/interest level" else ()
(:if type!=audience then you need entity:)
return if ($type= "Audience: ") then
	if ( fn:not($tag/marcxml:subfield[@code="b"]) ) then
		element bf:intendedAudience {fn:concat($type,$tag/marcxml:subfield[@code="a"])}
	else element bf:intendedAudience {
		element bf:IntendedAudienceEntity {
			element bf:audience {fn:concat($type,$tag/marcxml:subfield[@code="a"])},
			element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}	
	}}
	else if ($type!=() ) then (:you need audienceType:)
	element bf:intendedAudience {
		element bf:IntendedAudienceEntity {
			if ($tag/marcxml:subfield[@code="a"]) then
				element bf:audience {fn:string($tag/marcxml:subfield[@code="a"])}
			else (),	
			element bf:audienceType {$type},
			if ($tag/marcxml:subfield[@code="b"]) then
				element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}
			else ()	
		}
		}
	else if ($tag/marcxml:subfield[@code="b"]) then
		element bf:intendedAudience {
			element bf:IntendedAudienceEntity {
			if ($tag/marcxml:subfield[@code="a"]) then
				element bf:audience {fn:string($tag/marcxml:subfield[@code="a"])}
			else (),
				element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}
		}}
	else   if ($tag/marcxml:subfield[@code="a"]) then
	 	element bf:intendedAudience {fn:concat($type,$tag/marcxml:subfield[@code="a"])}
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
    		for $t in $marcbib2bibframe:resourceTypes/type[@cf007]
    			where fn:matches($cf,$t/@cf007) 
    				return fn:string($t)    	
    (:let $sf336a :=:) ,
    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="a"]    		
    		for $t in $marcbib2bibframe:resourceTypes/type[@sf336a]
    			where fn:matches(fn:string($field),$t/@sf336a) 
    				return fn:string($t),   				
(:    let $sf336b := :)
    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="b"]    		
    		for $t in $marcbib2bibframe:resourceTypes/type[@sf336b]
    			where fn:matches(fn:string($field),$t/@sf336b)
    				return fn:string($t), 
    				
    (:let $sf337a := :)
    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="a"]		
    		for $t in $marcbib2bibframe:resourceTypes/type[@sf337a]
    			where fn:matches(fn:string($field),$t/@sf337a)
    				return fn:string($t) ,   	
(:let $sf337b := :)
    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="b"]    		
    		for $t in $marcbib2bibframe:resourceTypes/type[@sf337b]
    			where fn:matches(fn:string($field),$t/@sf337b)
    				return fn:string($t)  ,  	
    (:let $ldr6 :=:) 
    	for $t in $marcbib2bibframe:resourceTypes/type
        		where $t/@leader6 eq $leader06
        		return xs:string($t)
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
:   This function takes an ISBN string and 
:   determines if it's 10 or 13, and returns both the 10 and 13 for this one.
:
:   @param  $s        is xs:String
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
            $marcbib2bibframe:classes//property[@domain="Instance"]
        else 
            $marcbib2bibframe:classes//property[@domain="Work"]
   let $validLCCs:=("DAW","DJK","KBM","KBP","KBR","KBU","KDC","KDE","KDG","KDK","KDZ","KEA","KEB","KEM","KEN","KEO","KEP","KEQ","KES","KEY","KEZ","KFA","KFC","KFD","KFF","KFG","KFH","KFI","KFK","KFL","KFM","KFN","KFO","KFP","KFR","KFS","KFT","KFU","KFV","KFW","KFX","KFZ","KGA","KGB","KGC","KGD","KGE","KGF","KGG","KGH","KGJ","KGK","KGL","KGM","KGN","KGP","KGQ","KGR","KGS","KGT","KGU","KGV","KGW","KGX","KGY","KGZ","KHA","KHC","KHD","KHF","KHH","KHK","KHL","KHM","KHN","KHP","KHQ","KHS","KHU","KHW","KJA","KJC","KJE","KJG","KJH","KJJ","KJK","KJM","KJN","KJP","KJR","KJS","KJT","KJV","KJW","KKA","KKB","KKC","KKE","KKF","KKG","KKH","KKI","KKJ","KKK","KKL","KKM","KKN","KKP","KKQ","KKR","KKS","KKT","KKV","KKW","KKX","KKY","KKZ","KLA","KLB","KLD","KLE","KLF","KLH","KLM","KLN","KLP","KLQ","KLR","KLS","KLT","KLV","KLW","KMC","KME","KMF","KMG","KMH","KMJ","KMK","KML","KMM","KMN","KMP","KMQ","KMS","KMT","KMU","KMV","KMX","KMY","KNC","KNE","KNF","KNG","KNH","KNK","KNL","KNM","KNN","KNP","KNQ","KNR","KNS","KNT","KNU","KNV","KNW","KNX","KNY","KPA","KPC","KPE","KPF","KPG","KPH","KPJ","KPK","KPL","KPM","KPP","KPS","KPT","KPV","KPW","KQC","KQE","KQG","KQH","KQJ","KQK","KQM","KQP","KQT","KQV","KQW","KQX","KRB","KRC","KRE","KRG","KRK","KRL","KRM","KRN","KRP","KRR","KRS","KRU","KRV","KRW","KRX","KRY","KSA","KSC","KSE","KSG","KSH","KSK","KSL","KSN","KSP","KSR","KSS","KST","KSU","KSV","KSW","KSX","KSY","KSZ","KTA","KTC","KTD","KTE","KTF","KTG","KTH","KTJ","KTK","KTL","KTN","KTQ","KTR","KTT","KTU","KTV","KTW","KTX","KTY","KTZ","KUA","KUB","KUC","KUD","KUE","KUF","KUG","KUH","KUN","KUQ","KVB","KVC","KVE","KVH","KVL","KVM","KVN","KVP","KVQ","KVR","KVS","KVU","KVW","KWA","KWC","KWE","KWG","KWH","KWL","KWP","KWQ","KWR","KWT","KWW","KWX","KZA","KZD","AC","AE","AG","AI","AM","AN","AP","AS","AY","AZ","BC","BD","BF","BH","BJ","BL","BM","BP","BQ","BR","BS","BT","BV","BX","CB","CC", "CD","CE","CJ","CN","CR","CS","CT","DA","DB","DC","DD","DE","DF","DG","DH","DJ","DK","DL","DP","DQ","DR","DS","DT","DU","DX","GA","GB","GC","GE","GF","GN","GR","GT","GV","HA","HB","HC","HD","HE","HF","HG","HJ","HM","HN","HQ","HS","HT","HV","HX","JA","JC","JF","JJ","JK","JL","JN","JQ","JS","JV","JX","JZ","KB","KD","KE","KF","KG","KH","KJ","KK","KL","KM","KN","KP","KQ","KR","KS","KT","KU","KV","KW","KZ","LA","LB","LC","LD","LE",  "LF","LG","LH","LJ","LT","ML","MT","NA","NB","NC","ND","NE","NK","NX","PA","PB","PC","PD","PE","PF","PG","PH","PJ","PK","PL","PM","PN","PQ","PR","PS","PT","PZ","QA","QB","QC","QD","QE","QH","QK","QL","QM","QP","QR","RA","RB","RC","RD","RE","RF","RG",   "RJ","RK","RL","RM","RS","RT","RV","RX","RZ","SB","SD","SF","SH","SK","TA","TC","TD","TE","TF","TG","TH","TJ","TK","TL","TN","TP","TR","TS","TT","TX","UA","UB","UC","UD","UE","UF","UG","UH","VA","VB","VC","VD","VE","VF","VG","VK","VM","ZA","A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","Z")
    return
        for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|051|055|060|061|070|071|080|082|083|084|086)")]
            (:to do: 
                need full class:
                any $b
                if 082 083 has $2, or $m
                083 has $y or z(table) or $c
                080, 082 083 $ind=1 or 0
                051 061 071 has $c
                070 or 071
                050,051 
                060 061
                080, 082 083 $q
                084, 086  has $2
                086 has $z  cancel
                :)    
                
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
                            "class"                        	
                    return	 
                        element  {fn:concat("bf:",$property)} {          
			if ($property="class-lcc" ) then attribute rdf:resource {fn:concat( "http://id.loc.gov/authorities/classification/",fn:string($valid))}
			else
                            		($property,fn:string($cl))                            
                        }
            else if (
                ($valid and fn:matches($this-tag/@tag,"(050|051|055|060|061|070|071)"))
                    or 
                fn:not(fn:matches($this-tag/@tag,"(050|051|055|060|061|070|071)"))
                ) then
                let $assigner:=              
                       if ($this-tag/@tag="050" and $this-tag/@ind2="0") then "dlc"
                       else if (fn:matches($this-tag/@tag,"(051)")) then "dlc"
                       else if (fn:matches($this-tag/@tag,"(060|061)")) then "dnln"
                       else if (fn:matches($this-tag/@tag,"(070|071)")) then "dnal"
                       else if (fn:matches($this-tag/@tag,"(082|083|084)")  and $this-tag/marcxml:subfield[@code="q"]) then fn:string($this-tag/marcxml:subfield[@code="q"])
                       else ()
	return                       
                element bf:class {
                    element bf:ClassificationEntity {                        
                        element bf:classScheme {
                            if (fn:matches($this-tag/@tag,"(050|051)")) then "lcc" 
		            		else if (fn:matches($this-tag/@tag,"080")) then "udc"
		            		else if (fn:matches($this-tag/@tag,"082")) then "ddc"
		            		else if (fn:matches($this-tag/@tag,"(084|086)")) then fn:string($this-tag/marcxml:subfield[@code="2"])
		            		else ()
                        },
                        
                        if (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="m"] ) then
                            element bf:classSchemePart  {
                                if ($this-tag/marcxml:subfield[@code="m"] ="a") then "standard" 
                                else if ($this-tag/marcxml:subfield[@code="m"] ="b") then "optional" 
                                else ()
                            }
                        else (),                        
            
            	       element bf:classNumber {fn:string($cl)},
            	       element bf:label {fn:string($cl)},
		       if ( $assigner) then 
            		element bf:classAssigner {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/organizations/",$assigner)}}
                           else (),             			
			            	
           	       if ( 
             		    (fn:matches($this-tag/@tag,"(080|082|083)") and fn:matches($this-tag/@ind1,"(0|1)") ) or 
             		    (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="2"] )
            	 		   ) then  
                            element bf:classEdition {
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
                            element bf:classCopy {fn:string($sfc)},
                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="c"]) then 
								    element bf:classNumberSpanEnd {fn:string($this-tag/marcxml:subfield[@code="c"])}
								else (),			
                                
                                if (fn:matches($this-tag/@tag,"086") and $this-tag/marcxml:subfield[@code="z"]) then
							 		element bf:classStatus  {"canceled/invalid"} 
                                else (),

                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="z"]) then
								 	element bf:classTable  {fn:string( $this-tag/marcxml:subfield[@code="z"])} 
                                else (),

                                if (fn:matches($this-tag/@tag,"083") and $this-tag/marcxml:subfield[@code="y"]) then
							 		element bf:classTableSeq  {fn:string( $this-tag/marcxml:subfield[@code="y"])} 
                                else ()
                    }
            }
            else ()
};

(:~
:   This function processes out the leader and control fields
:
:  $marcxml    is marcxml:record
:   @return ??
:)
declare function marcbib2bibframe:generate-controlfields(
    $r as element(marcxml:record)
    ) 
{
		let $leader:=$r/marcxml:leader
		let $leader6:=fn:substring($leader,7,1)
		let $leader7:=fn:substring($leader,8,1)
		let $leader19:=fn:substring($leader,20,1)
		
		let $cf008 :=fn:string($r/marcxml:controlfield[@tag="008"])
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
				
			let $modscollection:=if ($leader7="c") then "yes" else ()
			let $modsmanuscript:= if (fn:matches($leader6,"(d|f|p|t)")) then "yes" else ()
			let $modstypeOfResource:=						
				if  ($leader6="a" or $leader6="t") then "text" 
				else if ($leader6="e" or $leader6="f") then "cartographic"
				else if  ($leader6="c" or $leader6="d") then "notated music"
				else if  ($leader6="i" ) then "sound recording-nonmusical"
				else if  ($leader6="j") then "sound recording-musical"
				else if  ($leader6="k") then "still image"
				else if  ($leader6="g") then "moving image"
				else if  ($leader6="r") then "three dimensional object"
				else if  ($leader6="m") then "software, multimedia"
				else if  ($leader6="p") then "mixed material"
				else ()
		let $genre008:= 
			if (fn:substring($cf008,26,1)="d") then "globe" else ()
		let $genre007:=  if	($r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)="ar"]) then "remote-sensing image" else ()
		let $genreMP:=
		 	if ($leader67type="MP") then
		 		if  (fn:matches(fn:substring($cf008,26,1),"(a|b|c)") or  $r/marcxml:controlfield[@tag=007][fn:substring(text(),1,2)="aj"]) then "map" 
				else if ($leader67type="MP" and fn:matches(fn:substring($cf008,26,1),"e") or  $r/marcxml:controlfield[@tag=007][fn:substring(text(),1,2)="ad"]) then "atlas" 
				else ()
			else ()
		let $genreSE:=  
			if ($leader67type="SE") then 		
				let$cf008-21 :=fn:substring($cf008,22,1)
				return 			
					if  ($cf008-21="d") then "database"				
						else if  ($cf008-21="l") then "loose-leaf"			
						else if  ($cf008-21="m") then "series"				
						else if ($cf008-21="n") then "newspaper"
						else if ($cf008-21="p") then "periodical"
						else if  ($cf008-21="w") then "web site"
						else ()
			else ()
			
		let $genreBKSE:=
			if ($leader67type="BK" or $leader67type="SE") then 
				let$cf008-24:= fn:substring($cf008,25,4)
				return
					if (fn:contains($cf008-24,'a')) then "abstract or summary"
					else if (fn:contains($cf008-24,'b')) then "bibliography"
					else if (fn:contains($cf008-24,'c')) then "catalog"
					else if (fn:contains($cf008-24,'d')) then "dictionary"
					else if (fn:contains($cf008-24,'e')) then "encyclopedia"
					else if (fn:contains($cf008-24,'f')) then "handbook"
					else if (fn:contains($cf008-24,'g')) then "legal article"
					else if (fn:contains($cf008-24,'i')) then "index"
					else if (fn:contains($cf008-24,'k')) then "discography"
					else if (fn:contains($cf008-24,'l')) then "legislation"
					else if (fn:contains($cf008-24,'m')) then "theses"
					else if (fn:contains($cf008-24,'n')) then "survey of literature"
					else if (fn:contains($cf008-24,'o')) then "review"
					else if (fn:contains($cf008-24,'p')) then "programmed text"
					else if (fn:contains($cf008-24,'q')) then "filmography"
					else if (fn:contains($cf008-24,'r')) then "directory"
					else if (fn:contains($cf008-24,'s')) then "statistics"
					else if (fn:contains($cf008-24,'t')) then "technical report"
					else if (fn:contains($cf008-24,'v')) then "legal case and case notes"
					else if (fn:contains($cf008-24,'w')) then "law report or digest"
					else if (fn:contains($cf008-24,'z')) then "treaty"
					else if (fn:substring($cf008,30,1)="1") then "conference publication"
					else ()
				else ()	
			
	let $genreCF:=
		if ($leader67type="CF") then 
			if (fn:substring($cf008,27,1)="a") then "numeric data"
			else if (fn:substring($cf008,27,1)="e") then "database"
			else if (fn:substring($cf008,27,1)="f") then "font"
			else if (fn:substring($cf008,27,1)="g") then "game"
			else ()
		else ()
			
	let $genreBK:=
		if ($leader67type="BK") then 
			if (fn:substring($cf008,25,1)="j") then "patent"
			else if (fn:substring($cf008,25,1)="2") then "offprint"
			else if (fn:substring($cf008,31,1)="1") then "festschrift"
			else if (fn:matches(fn:substring($cf008,35,1),"(a|b|c|d)")) then "biography"
			else if (fn:substring($cf008,34,1)="e") then "essay"
			else if (fn:substring($cf008,34,1)="d") then "drama"
			else if (fn:substring($cf008,34,1)="c") then "comic strip"
			else if (fn:substring($cf008,34,1)="l") then "fiction"
			else if (fn:substring($cf008,34,1)="h") then "humor, satire"
			else if (fn:substring($cf008,34,1)="i") then "letter"
			else if (fn:substring($cf008,34,1)="f") then "novel"
			else if (fn:substring($cf008,34,1)="j") then "short story"
			else if (fn:substring($cf008,34,1)="s") then "speech"
			else ()
				
		else ()
	let $genreMU:=
		if ($leader67type="MU") then 
			let $cf008-30-31:=fn:substring($cf008,31,2)
			return
			if (fn:contains($cf008-30-31,'b')) then "biography"
			else if (fn:contains($cf008-30-31,'c')) then "conference publication"
			else if (fn:contains($cf008-30-31,'d')) then "drama"
			else if (fn:contains($cf008-30-31,'e')) then "essay"
			else if (fn:contains($cf008-30-31,'f')) then "fiction"
			else if (fn:contains($cf008-30-31,'o')) then "folktale"
			else if (fn:contains($cf008-30-31,'h')) then "history"
			else if (fn:contains($cf008-30-31,'k')) then "humor, satire"
			else if (fn:contains($cf008-30-31,'m')) then "memoir"
			else if (fn:contains($cf008-30-31,'p')) then "poetry"
			else if (fn:contains($cf008-30-31,'r')) then "rehearsal"
			else if (fn:contains($cf008-30-31,'g')) then "reporting"
			else if (fn:contains($cf008-30-31,'s')) then "sound"
			else if (fn:contains($cf008-30-31,'l')) then "speech"
			else ()
		else ()
		let $genreVM:=
		if ($leader67type="VM") then 
			let $cf008-33 :=fn:substring($cf008,34,1)
			return 
				if($cf008-33="a") then "art original"
				else if ($cf008-33="b") then "kit"
				else if ($cf008-33="c") then "art reproduction"
				else if ($cf008-33="d") then "diorama"
				else if ($cf008-33="f") then "filmstrip"
				else if ($cf008-33="g") then "legal article"
				else if ($cf008-33="i") then "picture"
				else if ($cf008-33="k") then "graphic"
				else if ($cf008-33="l") then "technical drawing"
				else if ($cf008-33="m") then "motion picture"
				else if ($cf008-33="n") then "chart"
				else if ($cf008-33="o") then "flash card"
				else if ($cf008-33="p") then "microscope slide"						
				else if ($cf008-33="q" or $r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)="aq"]) then "model"
				else if ($cf008-33="r") then "realia"
				else if ($cf008-33="s") then "slide"
				else if ($cf008-33="t") then "transparency"
				else if ($cf008-33="v") then "videorecording"
				else if ($cf008-33="w") then "toy"
				else ()
			
		else ()
let $edited:=fn:concat(fn:substring(($r/marcxml:controlfield[@tag="005"]),1,4),"-",fn:substring(($r/marcxml:controlfield[@tag="005"]),5,2),"-",fn:substring(($r/marcxml:controlfield[@tag="005"]),7,2),"T",fn:substring(($r/marcxml:controlfield[@tag="005"]),9,2),":",fn:substring(($r/marcxml:controlfield[@tag="005"]),11,2)) 
(:let $date008:=:)
let $cf008-7-10:=fn:normalize-space(fn:substring($cf008, 8, 4))
let $cf008-11-14:=fn:normalize-space(fn:substring($cf008, 12, 4))
let $cf008-6:=fn:normalize-space(fn:substring($cf008, 7, 1))
let $datecreated008:= if (fn:matches($cf008-6,"(e|p|r|s|t)") and fn:matches($leader6,"(d|f|p|t)") and $cf008-7-10 ) then  					
					$cf008-7-10 
				else () 										

	let $dateissued008:=
		if (fn:matches($cf008-6,"(e|p|r|s|t)") and fn:not(fn:matches($leader6,"(d|f|pt)")) and $cf008-7-10 ) then					
					$cf008-7-10 
		else ()
let $dateissued008start:=
			if (fn:matches($cf008-6,"(c|d|i|k|m|u)") and 	$cf008-7-10) then 			
						$cf008-7-10
			else ()
			
let $dateissued008end:=
			if (fn:matches($cf008-6,"(c|d|i|k|m|u)") and 	$cf008-11-14) then 			
						$cf008-11-14
				else ()
			
let $dateissued008start-q:=
			if ($cf008-6="q" and $cf008-7-10) then					
					$cf008-7-10					
			else ()
let $dateissued008end-q:=
			if ($cf008-6="q" and $cf008-11-14) then					
					$cf008-11-14			
			else ()
			
let $datecopyright008 :=
			if ($cf008-6="t" and  $cf008-11-14) then				
					$cf008-11-14		
			else ()
let $issuance:=
	if (fn:matches($leader7,"(a|c|d|m)")) 				then "monographic"
	else if ($leader7="b") 						then "continuing"
	else if ($leader7="m" and  fn:matches($leader19,"(a|b|c)")) 	then "multipart monograph"
	else if ($leader7='m' and $leader19='#') 				then "single unit"
	else if ($leader7='i') 							then "integrating resource"
	else if ($leader7='s') 						then "serial"
	else ()
				
let $frequency:=
	if ($leader67type="SE") then
		if (fn:substring($cf008,19,1)="a") 		     then	"Annual"						
			else if (fn:substring($cf008,19,1)="b") then "Bimonthly"
			else if (fn:substring($cf008,19,1)="c") then "Semiweekly"
			else if (fn:substring($cf008,19,1)="d") then "Daily"
			else if (fn:substring($cf008,19,1)="e") then "Biweekly"
			else if (fn:substring($cf008,19,1)="f") then "Semiannual"
			else if (fn:substring($cf008,19,1)="g") then "Biennial"
			else if (fn:substring($cf008,19,1)="h") then "Triennial"
			else if (fn:substring($cf008,19,1)="i") then "Three times a week"
			else if (fn:substring($cf008,19,1)="j") then "Three times a month"
			else if (fn:substring($cf008,19,1)="k") then "Continuously updated"
			else if (fn:substring($cf008,19,1)="m") then "Monthly"
			else if (fn:substring($cf008,19,1)="q") then "Quarterly"
			else if (fn:substring($cf008,19,1)="s") then "Semimonthly"
			else if (fn:substring($cf008,19,1)="t") then "Three times a year"
			else if (fn:substring($cf008,19,1)="u") then "Unknown"
			else if (fn:substring($cf008,19,1)="w") then "Weekly"
			else if (fn:substring($cf008,19,1)="#") then "Completely irregular"
			else ()
					
		else ()

let $lang008:=
    if (fn:normalize-space(fn:replace(fn:substring($cf008,36,3),"\|#",''))!="") then		
        fn:substring($cf008,36,3)
    else ()		

let $digorigin008:=	
    if ($leader67type='CF' and $r/marcxml:controlfield[@tag=007][fn:substring(.,12,1)='a']) then "reformatted digital"
    else if ($leader67type='CF' and $r/marcxml:controlfield[@tag=007][fn:substring(.,12,1)='b']) then "digitized microfilm"
    else if ($leader67type='CF' and $r/marcxml:controlfield[@tag=007][fn:substring(.,12,1)='d']) then "digitized other analog"
    else ()
		
let $cf008-23 :=fn:substring($cf008,24,1)
let $cf008-29:=fn:substring($cf008,30,1)
let $check008-23:= 
    if (fn:matches($leader67type,"(BK|MU|SE|MM)")) then 
        fn:true()
    else ()
let $check008-29:= 
    if (fn:matches($leader67type,"(MP|VM)")) then 
        fn:true()  	
    else ()
let $form008:=
	if ( ($check008-23 and $cf008-23="f") or ($check008-29 and $cf008-29='f') ) then 			"braille"
				else if (($cf008-23=" " and ($leader6="c" or $leader6="d")) or (($leader67type="BK" or $leader67type="SE") and ($cf008-23=" " or $cf008="r"))) then "print"
				else if ($leader6 = 'm' or ($check008-23 and $cf008-23='s') or ($check008-29 and $cf008-29='s')) then "electronic"				
				else if ($leader6 = "o") then "kit"
				else if (($check008-23 and $cf008-23='b') or ($check008-29 and $cf008-29='b')) then "microfiche"
				else if (($check008-23 and $cf008-23='a') or ($check008-29 and $cf008-29='a')) then "microfilm"
				else ()
let $reformatqual:=			
		if ($r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)='ca']) then "access"
			else if ($r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)='cp']) then "preservation" 
			else if ($r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)='cr']) then "replacement"
		else ()
		
(: use this table: to simplify the ifs below: :)
let $forms:=<set>
<form c007-1-2="ad" marccat="map" marcsmd="atlas"/>
<form c007-1-2="ag" marccat="map" marcsmd="diagram"/>
<form c007-1-2="aj" marccat="map" marcsmd="map"/>
<form c007-1-2="aq" marccat="map" marcsmd="model"/>
<form c007-1-2="ak" marccat="map" marcsmd="profile"/>
<form c007-1-2="rr" marccat="remote-sensing image"/>
<form c007-1-2="as" marccat="map" marcsmd="section"/>
<form c007-1-2="ay" marccat="map" marcsmd="view"/>
<form c007-1-2="cb" marccat="electronic resource" marcsmd="chip cartridge"/>
<form c007-1-2="cc" marccat="electronic resource" marcsmd="computer optical disc cartridge"/>
<form c007-1-2="cj" marccat="electronic resource" marcsmd="magnetic disc"/>
<form c007-1-2="cm" marccat="electronic resource" marcsmd="magneto-optical disc"/>
<form c007-1-2="co" marccat="electronic resource" marcsmd="optical disc"/>
<form c007-1-2="cr" marccat="electronic resource" marcsmd="remote"/>
<form c007-1-2="ca" marccat="electronic resource" marcsmd="tape cartridge"/>
<form c007-1-2="cf" marccat="electronic resource" marcsmd="tape cassette"/>
<form c007-1-2="ch" marccat="electronic resource" marcsmd="tape reel"/>
<form c007-1-2="da" marccat="globe" marcsmd="celestial globe"/>
<form c007-1-2="de" marccat="globe" marcsmd="earth moon globe"/>
<form c007-1-2="db" marccat="globe" marcsmd="planetary or lunar globe"/>
<form c007-1-2="dc" marccat="globe" marcsmd="terrestrial globe"/>
<form c007-1-2="fc" marccat="tactile material" marcsmd="braille"/>
<form c007-1-2="fb" marccat="tactile material" marcsmd="combination"/>
<form c007-1-2="fa" marccat="tactile material" marcsmd="moon"/>
<form c007-1-2="fd" marccat="tactile material" marcsmd="tactile, with no writing system"/>
<form c007-1-2="gd" marccat="projected graphic" marcsmd="filmslip"/>
<form c007-1-2="gc" marccat="projected graphic" marcsmd="filmstrip cartridge"/>
<form c007-1-2="go" marccat="projected graphic" marcsmd="filmstrip roll"/>
<form c007-1-2="gf" marccat="projected graphic" marcsmd="other filmstrip type"/>
<form c007-1-2="gs" marccat="projected graphic" marcsmd="slide"/>
<form c007-1-2="gt" marccat="projected graphic" marcsmd="transparency"/>
<form c007-1-2="ha" marccat="microform" marcsmd="aperture card"/>
<form c007-1-2="he" marccat="microform" marcsmd="microfiche"/>
<form c007-1-2="hf" marccat="microform" marcsmd="microfiche cassette"/>
<form c007-1-2="hb" marccat="microform" marcsmd="microfilm cartridge"/>
<form c007-1-2="hc" marccat="microform" marcsmd="microfilm cassette"/>
<form c007-1-2="hd" marccat="microform" marcsmd="microfilm reel"/>
<form c007-1-2="hg" marccat="microform" marcsmd="microopaque"/>
<form c007-1-2="kn" marccat="nonprojected graphic" marcsmd="chart"/>
<form c007-1-2="kc" marccat="nonprojected graphic" marcsmd="collage"/>
<form c007-1-2="kd" marccat="nonprojected graphic" marcsmd="drawing"/>
<form c007-1-2="ko" marccat="nonprojected graphic" marcsmd="flash card"/>
<form c007-1-2="ke" marccat="nonprojected graphic" marcsmd="painting"/>
<form c007-1-2="kf" marccat="nonprojected graphic" marcsmd="photomechanical print"/>
<form c007-1-2="kg" marccat="nonprojected graphic" marcsmd="photonegative"/>
<form c007-1-2="kh" marccat="nonprojected graphic" marcsmd="photoprint"/>
<form c007-1-2="ki" marccat="nonprojected graphic" marcsmd="picture"/>
<form c007-1-2="kj" marccat="nonprojected graphic" marcsmd="print"/>
<form c007-1-2="kl" marccat="nonprojected graphic" marcsmd="technical drawing"/>
<form c007-1-2="mc" marccat="motion picture" marcsmd="film cartridge"/>
<form c007-1-2="mf" marccat="motion picture" marcsmd="film cassette"/>
<form c007-1-2="mr" marccat="motion picture" marcsmd="film reel"/>
<form c007-1-2="oo" marccat="kit" marcsmd="kit"/>
<form c007-1-2="qq" marccat="notated music" marcsmd="notated music"/>
<form c007-1-2="rr" marccat="remote-sensing image" marcsmd="remote-sensing image"/>
<form c007-1-2="se" marccat="sound recording" marcsmd="cylinder"/>
<form c007-1-2="sq" marccat="sound recording" marcsmd="roll"/>
<form c007-1-2="sg" marccat="sound recording" marcsmd="sound cartridge"/>
<form c007-1-2="ss" marccat="sound recording" marcsmd="sound cassette"/>
<form c007-1-2="sd" marccat="sound recording" marcsmd="sound disc"/>
<form c007-1-2="st" marccat="sound recording" marcsmd="sound-tape reel"/>
<form c007-1-2="si" marccat="sound recording" marcsmd="sound-track film"/>
<form c007-1-2="sw" marccat="sound recording" marcsmd="wire recording"/>
<form c007-1-2="tc" marccat="text" marcsmd="braille"/>
<form c007-1-2="tb" marccat="text" marcsmd="large print"/>
<form c007-1-2="ta" marccat="text" marcsmd="regular print"/>
<form c007-1-2="td" marccat="text" marcsmd="text in looseleaf binder"/>
<form c007-1-2="vc" marccat="videorecording" marcsmd="videocartridge"/>
<form c007-1-2="vf" marccat="videorecording" marcsmd="videocassette"/>
<form c007-1-2="vd" marccat="videorecording" marcsmd="videodisc"/>
<form c007-1-2="vr" marccat="videorecording" marcsmd="videoreel"/>
</set>
let $c007-1-2:=$r/marcxml:controlfield[@tag="007"][fn:substring(text(),1,2)]
let $marccat:=
	$forms//form[@c007-1-2=$c007-1-2]/@marccat
let $marcsmd:=
	$forms//form[@c007-1-2=$c007-1-2]/@smd

let $resourcetp:= 
  if ($leader67type="BK") then "Monographic Text (Book)"
	else if ($leader67type="SE") then "Serial"
	else if ($leader67type="MM") then "Mixed Materials"
	else if ($leader67type="CF") then "Computer File"
	else if ($leader67type="MP") then "Cartographic"
	else if ($leader67type="VM") then "Visual Materials"
	else if ($leader67type="MU") then "Music"
	else $leader67type

		
return 
		element bf:MachineInfo {				
			element bf:leader67type {$leader67type},
			element bf:modsresourcetype {fn:concat($resourcetp,". not fully delineated yet")},
			element bf:modscollection {$modscollection},
			element bf:modsmanuscript {$modsmanuscript},					
			element bf:modstypeOfResource {$modstypeOfResource},			
			if ($genre007) then element bf:genre {$genre007} else (),
			if ($genre008) then element bf:genre {$genre008} else (),
			if ($genreMP) then element bf:genre {$genreMP} else (),
			if ($genreBKSE) then element bf:genre {$genreBKSE} else (),
			if ($genreCF) then element bf:genre {$genreCF} else (),
			if ($genreBK) then element bf:genre {$genreBK} else (),
			if ($genreMU) then element bf:genre {$genreMU} else (),
			if ($genreVM) then element bf:genre {$genreVM} else (),						
			element bf:datecreated{$datecreated008},
			element bf:dateissued {$dateissued008},
			element bf:dateissuedstart{$dateissued008start},
			element bf:dateissuedend{$dateissued008end},
			element bf:dateissuedstart-q{$dateissued008start},
			element bf:dateissuedend-q{$dateissued008end},
			element bf:datecopyright{$datecopyright008},
			element bf:issuance{$issuance},
			element bf:frequency{$frequency},
			element bf:language{$lang008},
			element bf:digitalOrigin{$digorigin008},
			element bf:form{$form008},
			element bf:reformatqual{$reformatqual},			
			element bf:form-category007{$marccat},
			element bf:form-smd007{$marcsmd},
			element bf:edited {$edited}	
			
		}
		
};
