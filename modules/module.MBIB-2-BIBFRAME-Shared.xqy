xquery version "1.0";
(:
:   Module Name: MARCXML BIB to bibframe Shared functions
:
:   Module Version: 1.0
:
:   Date: 2014 Jan 30
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
:   Here are shared functions called by other modules in building bibframe resources
:	
:   @author Kevin Ford (kefo@loc.gov)
:   @author Nate Trail (ntra@loc.gov)
:   @since January 14, 2014
:   @version 1.0
:)
 
module namespace mbshared  = 'info:lc/id-modules/mbib2bibframeshared#';

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
declare namespace hld              = "http://www.loc.gov/opacxml/holdings/" ;

(: VARIABLES :)
declare variable $mbshared:last-edit :="2014-10-01-T10:00:00";

(:rules have a status of "on" or "off":)
declare variable $mbshared:transform-rules :=(
<rules>
<rule status="on" id="1" label="isbn" category="instance-splitting">New instances on secondary unique ISBNs</rule>
<rule status="on" id="2" label="issn" category="instance-splitting">New instances on secondary unique ISSNs</rule>
<rule status="on" id="3" label="260" category="instance-splitting">New instances on multiple 260s (not serials)</rule>
<rule status="on" id="4" label="250" category="instance-splitting">New instances on multiple 250s</rule>
<rule status="on" id="4" label="300" category="instance-splitting">New instances on multiple 300s</rule>
<rule status="on" id="5" label="246" category="instance-node">246 domain is instance</rule>
<rule status="on" id="6" label="247" category="instance-node">247 domain is instance</rule>
<!--<rule status="on" id="7" label="856" category="instance-splitting">New instances on multiple856s that are resources (ind2=0)</rule>??? -->
</rules>
);
declare variable $mbshared:named-notes:=("(502|505|506|507|508|511|513|518|522|524|525|541|546|555)");
(:"(500|501|502|504|505|506|507|508|510|511|513|514|515|516|518|520|521|522|524|525|526|530|533|534|535|536|538|540|541|542|544|545|546|547|550|552|555|556|562|563|565|567|580|581|583|584|585|586|588|59X)":)
(: this var plus all the simple-properties nodes are used to generate standalone 880s:)
declare variable $mbshared:addl-880-nodes:= (
	<properties>
	 <node domain="work" 		property="note"			    	    tag="500" sfcodes="a">General Note</node>
	 <node domain="instance" 	property="note"			    	    tag="500" sfcodes="a">General Note</node>
	 <node domain="work" 		property="note"			    	    tag="505" sfcodes="t">complex note work title</node>
	</properties>
);

    (:these properties are transformed as either literals or appended to the @uri parameter inside their @domain:)
declare variable $mbshared:simple-properties:= (
	<properties>
       	 <node domain="instance"    property="lccn"	   			  	           tag="010" sfcodes="a"		uri="http://id.loc.gov/authorities/test/identifiers/lccn/"	group="identifiers"			>Library of Congress Control Number</node>
         <node domain="instance" 	property="nbn" 				    	       tag="015" sfcodes="a"		group="identifiers"          >National Bibliography Number</node>
         <node domain="instance" 	property="nban" 			          	    tag="016" sfcodes="a"	    group="identifiers"       	>National bibliography agency control number</node>
         <node domain="instance" 	property="legalDeposit" 		            tag="017" sfcodes="a"		group="identifiers"          >copyright or legal deposit number</node>
         <node domain="instance" 	property="issn" 			    	        tag="022" sfcodes="a"	group="identifiers"	uri="http://issn.example.org/"	        >International Standard Serial Number</node>
         <node domain="work" 		property="issnL"			           	    tag="022" sfcodes="l"		group="identifiers"   uri="http://issn.example.org/"  >linking International Standard Serial Number</node>
         <node domain="instance" 	property="isrc" 			   				tag="024" sfcodes="a"   ind1="0"	group="identifiers">International Standard Recording Code</node>
         <node domain="instance" 	property="upc" 				   				tag="024" sfcodes="a"   ind1="1"	group="identifiers">Universal Product Code</node>
         <node domain="instance" 	property="ismn"					 			tag="024" sfcodes="a"    ind1="2" group="identifiers">International Standard Music Number</node>
         <node domain="instance" 	property="ean"					 			tag="024" sfcodes="a,z,d" ind1="3" group="identifiers" comment="(sep by -)"	>International Article Identifier (EAN)</node>
         <node domain="instance" 	property="sici"				   				tag="024" sfcodes="a"   ind1="4" group="identifiers">Serial Item and Contribution Identifier</node>
         <node domain="instance" 	property="$2"					   			tag="024" sfcodes="a"   ind1="7" group="identifiers">contents of $2</node> 
         <node domain="instance" 	property="identifier"					   	tag="024" sfcodes="a"   ind1="8" group="identifiers">unspecified</node>
         <node domain="instance" 	property="lcOverseasAcq"					tag="025" sfcodes="a"		       group="identifiers"   >Library of Congress Overseas Acquisition Program number</node>
         <node domain="instance" 	property="fingerprint"						tag="026" sfcodes="e"		       group="identifiers"   >fingerprint identifier</node>
         <node domain="instance"	property="strn"					        	tag="027" sfcodes="a"		       group="identifiers" >Standard Technical Report Number</node>
    <node domain="instance"	property="issueNumber"						tag="028" sfcodes="a" ind1="0"		group="identifiers">sound recording publisher issue number</node>
         <node domain="instance"	property="matrixNumber"						tag="028" sfcodes="a" ind1="1"		group="identifiers">sound recording publisher matrix master number</node>
         <node domain="instance"	property="musicPlate"					  	tag="028" sfcodes="a" ind1="2"	group="identifiers"	>music publication number assigned by publisher</node>
         <node domain="instance"	property="musicPublisherNumber"		tag="028" sfcodes="a" ind1="3"	  group="identifiers">other publisher number for music</node>
         <node domain="instance"		property="videorecordingNumber"		tag="028" sfcodes="a" ind1="4" group="identifiers"	 	>publisher assigned videorecording number</node>
         <node domain="instance"		property="publisherNumber"				tag="028" sfcodes="a" ind1="5"	 group="identifiers"	>other publisher assigned number</node>
         <node domain="instance"		property="coden"					      	tag="030" sfcodes="a"	     group="identifiers"     >CODEN</node>
         <node domain="7xx"		   property="systemNumber"					      	tag="776" sfcodes="w"	     group="identifiers"  uri="http://www.worldcat.org/oclc/"   >system number</node>
         <node domain="7xx"		property="issn"					      	tag="776" sfcodes="x"	     group="identifiers"     >issn</node>
         <node domain="7xx"		property="coden"					      	tag="776" sfcodes="y"	     group="identifiers"     >CODEN</node>
         <node domain="7xx"		property="isbn"					      	tag="776" sfcodes="z"	     group="identifiers"     >issn</node>
         <node domain="instance"		property="postalRegistration"			tag="032" sfcodes="a"		     group="identifiers"     >postal registration number</node>
         <node domain="instance"		property="systemNumber"						tag="035" sfcodes="a"      group="identifiers"  uri="http://www.worldcat.org/oclc/"  	>system control number</node>
         <node domain="instance"		property="studyNumber"						tag="036" sfcodes="a"		 group="identifiers"         >original study number assigned by the producer of a computer file</node>
         <node domain="instance"		property="stockNumber"						tag="037" sfcodes="a"		 group="identifiers"         >stock number for acquisition</node>
         <node domain="instance"	property="reportNumber"						tag="088" sfcodes="a"       	 group="identifiers" >technical report number</node>
         <node domain="annotation"	property="descriptionSource"			tag="040" sfcodes="a"  uri="http://id.loc.gov/vocabulary/organizations/" group="identifiers"        >Description source</node>
         <node domain="annotation"	property="descriptionConventions"   tag="040" sfcodes="e"     uri="http://id.loc.gov/vocabulary/descriptionConventions/"           >Description conventions</node>
         <node domain="annotation"  property="descriptionLanguage"		tag="040" sfcodes="b"    uri="http://id.loc.gov/vocabulary/languages/"      >Description Language </node>
         
         <node domain="classification"		property="classificationSpanEnd"	tag="083" sfcodes="c"	          >classification span end for class number</node>
         <node domain="classification"		property="classificationTableSeq"	tag="083" sfcodes="y"	     	    >DDC table sequence number</node>
         <node domain="classification"		property="classificationTable"		tag="083" sfcodes="z"	         	>DDC table</node>
         <node domain="classification"		property="classificationAssigner"   tag="083" sfcodes=""	        	>various orgs assigner</node><!-- uri="http://id.loc.gov/vocabulary/organizations/"--> 
         <node domain="classification"		property="classificationEdition"   tag="082" sfcodes=""	         	>classificationEdition</node>
         <node domain="classification"		property="classificationEdition"   tag="083" sfcodes=""	         	>classificationEdition</node>
         <node domain="classification"		property="classificationLcc"   tag="052" sfcodes="ab"	stringjoin="."  uri="http://id.loc.gov/authorities/classification/G"	>geo class</node>
         <node domain="title"		property="titleQualifier"			tag="210" sfcodes="b"          >title qualifier</node>
         <node domain="title"		property="titleQualifier"			tag="222" sfcodes="b"          >title qualifier</node>
         <node domain="title"		property="partNumber"					tag="245" sfcodes="n"          >part number</node>
         <node domain="title"		property="partNumber"					tag="246" sfcodes="n"          >part number</node>
         <node domain="title"		property="partNumber"					tag="247" sfcodes="n"          >part number</node>
         
         <node domain="title"		property="titleValue"					tag="130" sfcodes="a"          >title itself</node>
         <node domain="title"		property="titleValue"					tag="730" sfcodes="a"          >title itself</node>
         <node domain="title"		property="titleValue"					tag="240" sfcodes="a"          >title itself</node>
         <node domain="title"		property="partNumber"					tag="130" sfcodes="n"          >part number</node>
         <node domain="title"		property="partNumber"					tag="240" sfcodes="n"          >part number</node>
         
         <node domain="title"		property="titleValue"					tag="210" sfcodes="a"          > title itself</node>
         <node domain="title"		property="titleValue"					tag="222" sfcodes="a"          > title itself</node>
         
         <node domain="title"		property="titleValue"					tag="242" sfcodes="a"          >title itself</node>
         <node domain="title"		property="titleValue"					tag="245" sfcodes="a"          > title itself</node>                  
         <node domain="title"		property="titleValue"					tag="246" sfcodes="a"          >title itself</node>
         <node domain="title"		property="titleValue"					tag="247" sfcodes="a"          >title itself</node>         
         <node domain="title"		property="subtitle"					    tag="245" sfcodes="b"          > subtitle </node>
         <node domain="title"		property="subtitle"				        tag="246" sfcodes="b"          >subtitle</node>
         <node domain="title"		property="subtitle"					    tag="247" sfcodes="b"          >subtitle</node>
         
         <node domain="title"		property="partTitle"					tag="245" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="246" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="247" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="242" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="130" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="730" sfcodes="p"          >part title</node>
         <node domain="title"		property="partTitle"					tag="240" sfcodes="p"          >part title</node>
         <node domain="title"		property="titleVariationDate"			tag="246" sfcodes="f"          >title variation date</node>
         <node domain="title"		property="titleVariationDate"			tag="247" sfcodes="f"          >title variation date</node>
         <node domain="title"		property="titleSource"			        tag="210" sfcodes="2"      >title source</node>
                         
         <node domain="title"		property="titleAttribute"			     tag="130" sfcodes="g"      >title attributes</node>         
         <node domain="title"		property="titleAttribute"			     tag="240" sfcodes="g"      >Miscellaneous </node>         
         
         <!--<node domain="title"		property="titleAttribute"			     tag="240" sfcodes="o"      >arrangement</node>-->
         <node domain="work"		property="musicVersion"			     tag="130" sfcodes="s"      >version</node>
         <node domain="work"		property="musicVersion"			     tag="240" sfcodes="s"      >version</node>
         <node domain="instance"	property="titleStatement"		    	tag="245" sfcodes="ab"         >title Statement</node>
         
         <node domain="instance"	property="responsibilityStatement"		tag="245" sfcodes="c"         >responsibility Statement</node>
         <node domain="work"	    property="treatySignator"		    	tag="710" sfcodes="g"         >treaty Signator</node>
         <node domain="instance"	property="edition"					      tag="250"        sfcodes="a"	             >Edition</node>
         
         <node domain="instance"	property="editionResponsibility"	      tag="250" sfcodes="b"        >Edition Responsibility</node>
         <node domain="cartography"	property="cartographicScale"			  tag="255" sfcodes="a"		   >cartographicScale</node>
         <node domain="cartography"	property="cartographicScale"			  tag="034" sfcodes=""		   >cartographicScale</node>         
         <node domain="cartography"	property="cartographicProjection"		  tag="255" sfcodes="b"		   >cartographicProjection</node>
         <node domain="cartography"	property="cartographicCoordinates"		  tag="255" sfcodes="c"		   >cartographicCoordinates</node>
         <node domain="cartography"	property="cartographicAscensionAndDeclination"		tag="255" sfcodes="d"		   >cartographicAscensionAndDeclination</node>
         <node domain="cartography"	property="cartographicEquinox"			   tag="255" sfcodes="e"		   >cartographicEquinox</node>
         <node domain="cartography"	property="cartographicOuterGRing"		   tag="255" sfcodes="f"		   >cartographicOuterGRing</node>
         <node domain="cartography"	property="cartographicExclusionGRing"		tag="255" sfcodes="g"		  >CartographicExclusionGRing</node>
         <node domain="instance"	property="providerStatement"			tag="260" sfcodes="abc"		   >Provider statement</node>
         <node domain="instance"	property="extent"					        tag="300" sfcodes="3aef"				    >Physical Description</node>
         
         <node domain="specialinstnc"	property="mediaCategory"					        tag="337" sfcodes="a"	uri="http://id.loc.gov/vocabulary/mediaTypes/"		    >Media Category</node>
         <node domain="specialinstnc"	property="mediaCategory"					        tag="337" sfcodes="b"	uri="http://id.loc.gov/vocabulary/mediaTypes/"		    >Media Category</node>
         <node domain="specialinstnc"	property="carrierCategory"					        tag="338" sfcodes="b"	uri="http://id.loc.gov/vocabulary/carriers/"		    >Physical Description</node>
         <node domain="specialinstnc"	property="carrierCategory"					        tag="338" sfcodes="a"	uri="http://id.loc.gov/vocabulary/carriers/"		    >Physical Description</node>
         <node domain="work"				property="musicKey"					      tag="384" sfcodes="a"		    		> Key </node>
         <node domain="work"				property="musicKey"					      tag="130" sfcodes="r"				    > Key </node>
         <node domain="work"				property="musicKey"					      tag="240" sfcodes="r"			 	    > Key </node>
         <node domain="work"		property="formDesignation"			     tag="130" sfcodes="k"      >Form subheading from title</node>         
         <node domain="work"		property="formDesignation"			     tag="240" sfcodes="k"      >Form subheading from title</node>         
         <node domain="work"				property="formDesignation"				tag="730" sfcodes="k"						>Form Designation</node>
         <node domain="work"				property="musicMediumNote"				tag="382" sfcodes="adp"		    	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="130" sfcodes="m"				    > Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="730" sfcodes="m"			     	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="240" sfcodes="m"			     	> Music medium note </node>
         <node domain="work"				property="musicMediumNote"				tag="243" sfcodes="m"	     			> Music medium note </node>
         <node domain="instance"		property="dimensions"					    tag="300" sfcodes="c"			     	>Physical Size</node>
         <node domain="work"				property="duration"					    tag="306" sfcodes="a"			     	>Playing time</node>
         <node domain="instance"				property="frequencyNote"				tag="310" sfcodes="ab"					>Issue frequency</node>
         <!--<node domain="instance"				property="frequencyNote"				tag="321" sfcodes="ab"					>Issue frequency</node>-->
         <node domain="arrangement"			property="materialPart"			        tag="351" sfcodes="3"					>material Organization</node>
         <node domain="arrangement"			property="materialOrganization"			tag="351" sfcodes="a"					>material Organization</node>
         <node domain="arrangement"			property="materialArrangement"			tag="351" sfcodes="b"					>ImaterialArrangement</node>
         <node domain="arrangement"			property="materialHierarchicalLevel"	tag="351" sfcodes="c"					>materialHierarchicalLevel</node>
         
         <node domain="contentcategory"		property="carrierCategory"				tag="130" sfcodes="h"					>Nature of content</node>
         <node domain="contentcategory"				property="carrierCategory"				tag="240" sfcodes="h"						>Nature of content</node>
         <node domain="contentcategory"				property="carrierCategory"				tag="243" sfcodes="h"						>Nature of content</node>
         
         <node domain="contentcategory"				property="contentCategory"				tag="245" sfcodes="k"						>Nature of content</node>         
         <node domain="contentcategory"				property="genre"				tag="513" sfcodes="a"						>Nature of content</node>
         <node domain="contentcategory"				property="genre"				tag="516" sfcodes="a"						>Nature of content</node>
         
         <node domain="related"				property="carrierCategory"				tag="730" sfcodes="h"						>Nature of content</node>
         
         <node domain="related"				property="carrierCategory"				tag="700" sfcodes="h"						>Nature of content</node>
         <node domain="related"				property="carrierCategory"				tag="710" sfcodes="h"						>Nature of content</node>
         <node domain="related"				property="carrierCategory"				tag="711" sfcodes="h"						>Nature of content</node>
         <node domain="work"				property="originDate"					tag="130" sfcodes="f"						>Date of origin</node>
         <node domain="related"				property="originDate"					tag="730" sfcodes="f"						>Date of origin</node>
         <node domain="work"				property="originDate"					tag="046" sfcodes="kl" stringjoin="-"					>Date of origin</node>

         <node domain="instance"				property="formDesignation"				tag="245" sfcodes="h"						>Form Designation</node>
         <node domain="instance"				property="formDesignation"				tag="245" sfcodes="k"						>Form Designation</node>
         
         <node domain="work"				property="musicNumber"       			tag="130" sfcodes="n"						>Music Number</node>
         <node domain="work"				property="musicNumber"					tag="730" sfcodes="n"						>Music Number</node>
         <node domain="work"				property="musicVersion"					tag="130" sfcodes="o"						>Music Version</node>
         <node domain="work"				property="musicVersion"					tag="240" sfcodes="o"						>Music Version</node>
         <node domain="work"				property="legalDate"					tag="130" sfcodes="d"						>Legal Date</node>         
         <node domain="work"				property="legalDate"					tag="730" sfcodes="d"						>Legal Date</node>                 
         <node domain="work"				property="dissertationNote"				tag="502" sfcodes="a"		                >Dissertation Note</node>
         <node domain="work"				property="dissertationDegree"			tag="502" sfcodes="b"			                >Dissertation Note</node>
         <node domain="work"				property="dissertationYear"				tag="502" sfcodes="d"				                >Dissertation Note</node>        
         <node domain="instance"				property="contentsNote"					  tag="505" sfcodes="agrtu" ind2=" ">Formatted Contents Note</node>
         
         <node domain="work"				property="temporalCoverageNote"		tag="513" sfcodes="b"						>Period Covered Note</node>
         <node domain="event"			    property="eventDate"					    tag="518" sfcodes="d"						>Event Date</node>
         <node domain="work"			    property="note"					    tag="518" sfcodes="a"						>Event Date</node>
         <node domain="work"				property="geographicCoverageNote"	tag="522"				                >Geographic Coverage Note</node>
         <node domain="work"				property="supplementaryContentNote"	tag="525" sfcodes="a"					>Supplement Note</node>
         <node domain="findingAid"			property="findingAidNote"			tag="555"	 sfcodes="3abc"                 >Cumulative Index/Finding Aids Note </node>                  
         <node domain="helditem"			property="custodialHistory"			tag="561"	 sfcodes="a"                 >Copy specific custodial history</node>
         <node domain="work"		        property="awardNote"			    		tag="586" sfcodes="3a"					>Awards Note</node>
         <node domain="instance"    	property="copyrightDate"		  tag="264" sfcodes="c" ind2="4">Copyright Date</node>
         <node domain="instance"		property="philatelicDataNote"			tag="258" sfcodes="ab"					>Philatelic data note</node>
         <node domain="instance"		property="illustrationNote"				tag="300" sfcodes="b"			      >Illustrative content note</node>
         <node domain="instance"		property="aspectRatio"				    tag="345" sfcodes="a"			      >Aspect Ratio</node>
         
         <node domain="instance"		property="accessCondition"				tag="506"		 sfcodes="3a"		                >Restrictions on Access Note</node>
         <node domain="instance"		property="graphicScaleNote"				tag="507" sfcodes="a"						>Scale Note for Graphic Material</node>
         <node domain="instance"		property="creditsNote"					  tag="508" startwith="Credits: " >Creation/Production Credits Note </node>
         <node domain="instance"		property="performerNote"					tag="511" startwith="Cast: " 		>Participant or Performer Note </node>
         <node domain="instance"		property="preferredCitation"			tag="524"				                >Preferred Citation of Described Materials Note</node>
         <node domain="instance"		property="immediateAcquisition"		tag="541" sfcodes="3abcdfhno"					>Immediate Source of Acquisition Note</node>
         541--/3+a (sep 3 by :)+b+c+d+f+h+n+o (sep by ;)

         <node domain="instance"		property="languageNote"					  tag="546" sfcodes="3a"  		stringjoin=": "		>Language Note</node>
         <node domain="instance"		property="notation"					      tag="546" sfcodes="b"				    >Language Notation(script)</node>
         <node domain="related" 	property="edition"					      tag="534"        sfcodes="b"	             >Edition</node>
         <node domain="related" 	property="note"					      tag="534"        sfcodes="n"	             >Note</node>        
  </properties>
	)	;


(:$related fields must have $t except 510 630,730,830 , 767? 740 ($a is title),  :)
declare variable $mbshared:relationships := 
(
    <relationships>
        <!-- Work to Work relationships -->
        <work-relateds all-tags="(400|410|411|430|440|490|510|533|534|630|700|710|711|730|740|760|762|765|767|770|772|773|774|775|777|780|785|787|800|810|811|830)">
            <type tag="(700|710|711|730)" ind2="2" property="hasPart">isIncludedIn</type>            
            <type tag="(700|710|711|730|787)" ind2="( |0|1)" property="relatedResource">relatedWork</type>        		                        
            <type tag="740" ind2=" " property="relatedWork">relatedWork</type>            
		    <type tag="740" property="partOf"  ind2="2">hasPart</type>
		    <type tag="760" property="subseriesOf">hasParts</type>	
		    <type tag="762" property="subseries">hasParts</type>	
		    <type tag="765" property="translationOf">hasTranslation</type>
		    <type tag="767" property="translation">translationOf</type>
		    <type tag="770" property="supplement">supplement</type>
		    <type tag="772" ind2=" " property="supplementTo">isSupplemented</type>		    	
		
		    <type tag="773" property="partOf">hasConstituent</type>
		     <type tag="774" property="hasPart">has Part</type>
		    <type tag="775" property="otherEdition" >hasOtherEdition</type>
		   
		   
		   <!--???the generic preceeding and succeeding may not be here -->
		    <type tag="780" ind2="0" property="continues">continuationOf</type>		    
		    <type tag="780" ind2="1" property="continuesInPart">partiallyContinuedBy</type>
		    <type tag="780" ind2="2" property="supersedes">continuationOf</type>
		    <type tag="780" ind2="3" property="supersedesInPartBy">partiallyContinuedBy</type>
		    <type tag="780" ind2="4" property="unionOf">preceding</type>
		    <type tag="780" ind2="5" property="absorbed">isAbsorbedBy</type>
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
    	    <type tag="785" ind2="8"  property="continuedBy">formerlyNamed</type>
		    <type tag="786" property="dataSource"></type>
		    <type tag="533" property="reproduction"></type>
		    <type tag="534" property="originalVersion"></type>
    		<!--<type tag="787" property="relatedResource">relatedItem</type>-->					  	    	  	   	  	    	  	    
	  	    <type tag="630"  property="subject">isSubjectOf</type>
	  	    <type tag="(400|410|411|430|440|490|800|810|811|830)" property="series">hasParts</type>
            
        </work-relateds>
        <!--
        <type tag="490" ind1="0" property="inSeries">hasParts</type>
        <type tag="510" property="describedIn">isReferencedBy</type>
        -->
        <!-- Instance to Work relationships (none!) -->
	  	<instance-relateds all-tags="(530|776|777)">
	  	  <!--<type tag="6d30"  property="subject">isSubjectOf</type>-->
	  	  <type tag="530" property="otherPhysicalFormat">hasOtherPhysicalFormat</type>
         <type tag="776" property="otherPhysicalFormat">hasOtherPhysicalFormat</type>	  	  
	  	  <type tag="777" property="issuedWith">issuedWith</type>
	  	</instance-relateds>
	</relationships>
);

(:~
:   This is the function generates an annotation from 520 u
:
:   @param  $marcxml       element is the MARCXML record   
:   @return bf:*           hasAnnotation element
:)
declare function mbshared:generate-abstract-annotation(
    $marcxml as element(marcxml:record)   ,
    $workID as xs:string
    ) as element (bf:hasAnnotation) 
{
for $d in  $marcxml/marcxml:datafield[@tag="520"][marcxml:subfield[fn:matches(@code,"(c|u)")]]
    
        let $abstract-type:=
            if ($d/@ind1="") then "Summary" (:Summary:)
            else if ($d/@ind1="0") then "Summary"(:Content Description:) 
            else if ($d/@ind1="1") then "Review"
            else if ($d/@ind1="2") then "Summary" (:Scope and Content:)
            else if ($d/@ind1="3") then "Summary" (:Abstract:)
            else if ($d/@ind1="4") then "Summary" (:Content advice:)
            else                        "Summary"
       
        return (:link direction is  reversed in nested2flat module, hasAnnotation becomes reviewOf, summaryOf:)
            element bf:hasAnnotation {
                element {fn:concat("bf:", $abstract-type)} {
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
                                                                
                    let $property-name:= 
                        if  ($abstract-type="Summary") then "bf:summaryOf" 
                         else   if  ($abstract-type="Review") then "bf:reviewOf"
                         else "bf:annotates"
                    return element {$property-name} {
                        attribute rdf:resource {$workID}
                    }
                }
            }
        };
(:~
:   This is the function generates administrative metadata about the record
:
:   @param  $marcxml       element is the MARCXML record   
:   @return bf:*           hasAnnotation element
:)
declare function mbshared:generate-admin-metadata(
    $marcxml as element(marcxml:record)   ,
    $workID as xs:string
    ) as element (bf:hasAnnotation) 
{
    (:let $biblink:=fn:concat(                    
                    $workID,
                    fn:normalize-space(fn:string($marcxml/marcxml:controlfield[@tag eq "001"]))                   
                 ):)
    let $derivedFrom := 
        element bf:derivedFrom {
            attribute rdf:resource {
                fn:concat($workID,    ".marcxml.xml")                 
            }
        }
      let $edited:= if ($marcxml/marcxml:controlfield[@tag="005"]) then
                             fn:concat(fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),1,4),"-",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),5,2),"-",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),7,2),"T",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),9,2),":",fn:substring(($marcxml/marcxml:controlfield[@tag="005"]),11,2))
                        else
                            ()
      let $changed:= (  element bf:generationProcess {fn:concat("DLC transform-tool:",$mbshared:last-edit)},
                        if ($edited) then
                            element bf:changeDate {$edited}
                        else ()
                      )
      
let $leader18:=fn:substring($marcxml/marcxml:leader,19,1)
      let $cataloging-meta:=
            (for $d in $marcxml/marcxml:datafield[@tag="040"]
                return mbshared:generate-simple-property($d,"annotation")
                ,
                if ($leader18="a") then element bf:descriptionConventions { attribute rdf:resource {"http://id.loc.gov/vocabulary/descriptionConventions/aacr2"} }
                else if ($leader18=" ") then element  bf:descriptionConventions { attribute rdf:resource {"http://id.loc.gov/vocabulary/descriptionConventions/nonisbd"} }
                else if ($leader18="c" or $leader18="i") then element  bf:descriptionConventions { attribute rdf:resource {"http://id.loc.gov/vocabulary/descriptionConventions/isbd"}}
                else ()
                )
                
    let $annotates:= element bf:annotates {attribute rdf:resource {$workID}}
        return
            element bf:hasAnnotation {
                element bf:Annotation {
               $derivedFrom,
               $cataloging-meta,
               $changed,                          
               $annotates
               
                }
            }
};
(:~
:   This is the function generates secondary instances from multiple 260/264
:
:   @param  $d        element is the MARCXML 260/264{position>1]
:   @param  $workID   uri for the derivedfrom
:   @param  $position nth position of  the 260 in the record; match to 321s
:   @return bf:* as element()
:)
declare function mbshared:generate-additional-instance(
          $d as element(marcxml:datafield),
    $workID as xs:string,
    $position as xs:integer
    ) as element () 
{

     let $derivedFrom:= 
        element bf:derivedFrom {                
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }
    let $instance-title := 
       fn:concat(fn:string( $d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"]), " " ,fn:string($d/marcxml:subfield[@code="3"]))
    let $pub:=          mbshared:generate-publication($d)
    let $freq:= for $s in $d/../marcxml:datafield[@tag="321"][fn:position()=$position - 1]
            return element bf:frequencyNote {fn:string-join($s/marcxml:subfield[@code="a" or @code="b"], " ")}
return element bf:Instance {element bf:instanceTitle{
            element bf:Title{ element bf:titleValue{$instance-title}}},
            $freq,
            $pub,
            $derivedFrom
    }
};
(:~
:   This is the function generates instance resources when there are multiple 300s
:
:   @param  $d        element is the MARCXML 300
:   @param  $workID   uri for the derivedfrom
:   @return bf:* as element()
:)
declare function mbshared:generate-addl-physical(
          $d as element(marcxml:datafield),
    $workID as xs:string,
    $position as xs:integer
    ) as element () 
{

     let $derivedFrom:= 
        element bf:derivedFrom {                
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }
    let $instance-title := 
        (   element bf:titleValue {marc2bfutils:clean-title-string($d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"])},
            element bf:titleQualifier {fn:string($d/marcxml:subfield[@code="3"])}
        )
    let $instance-types1:= mbshared:get-instanceTypes($d/ancestor::marcxml:record)                  
  
    let $instance-types:= 
        for $i in fn:distinct-values($instance-types1)
                return    element rdf:type {   attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" ,$i)}}
                
return element bf:Instance {element bf:instanceTitle{
            $instance-types,$instance-types1,
            element bf:Title{ element bf:titleValue{$instance-title}}},
              mbshared:generate-simple-property($d, "instance"),
            $derivedFrom
    }
};

(:~
:   This is the function generates instance resources.
:
:   @param  $d        element is the MARCXML 260
:   @param  $workID   uri for the derivedfrom
:   @return bf:* as element()
:)
declare function mbshared:generate-instance-from260(
    $d as element(marcxml:datafield),
    $workID as xs:string 
    ) as element () 
{
     let $derivedFrom:= 
        element bf:derivedFrom {
        
        (:    attribute rdf:resource{fn:concat($workID,fn:normalize-space(fn:string($d/../marcxml:controlfield[@tag eq "001"])))}:)
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }
    let $instance-title := 
        for $titles in $d/../marcxml:datafield[fn:matches(@tag,"(245|246|247|222|242|210)")]
            for $t in $titles
            return mbshared:get-title($t,"instance")
            
   let $resp-statement880:= mbshared:generate-880-label($d/../marcxml:datafield[@tag = "245"][marcxml:subfield[@code="c"]],"responsibilityStatement")
   
    let $edition-instances:= 
    for $e in $d/../marcxml:datafield[@tag eq "250"][fn:not(1)]
        return 
           (mbshared:generate-instance-from250($e,$workID),
           element bf:relatedInstance {
                element bf:Instance {
                   $instance-title,
                   
                    $derivedFrom    ,            
                    (element bf:edition {marc2bfutils:clean-string($e/marcxml:subfield[@code="a"])},        
                        if ($e/marcxml:subfield[@code="b"]) then element bf:editionResponsibility {fn:string($e/marcxml:subfield[@code="b"])}
                        else ()
                    )
                }
            }
            )
    let $edition-880:= mbshared:generate-880-label($d/../marcxml:datafield[@tag = "250"][marcxml:subfield[@code="a"]],"edition")                
    let $publication:= 
            if (fn:matches($d/@tag, "(260|264)")) then mbshared:generate-publication($d)
            else if (fn:matches($d/@tag, "(261|262)")) then mbshared:generate-26x-pub($d)
            else ()
    

    let $physMapData := 
        (
            for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "a"]
                
            return element bf:cartographicScale {
            		  if (fn:string($i)="a") then "Linear scale" 
            		else if (fn:string($i)="b") then "Angular scale" else if (fn:string($i)="z") then "Other scale type" else "invalid" 
            		}
            		,
	for $i in $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "b" or @code eq "c"]  
            	return element bf:cartographicScale { fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "a"]
            return element bf:cartographicScale {fn:string($i)},
                                              
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "b"]
            return element bf:cartographicProjection {fn:string($i)},
            
            for $i in $d/../marcxml:datafield[@tag eq "255"]/marcxml:subfield[@code eq "c"]
            return element bf:cartographicCoordinates  {fn:string($i)},
            
            if ( $d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "d" or @code eq "e" or @code eq "f" or @code eq "g"] ) then  
                  element bf:cartographicCoordinates {fn:concat(fn:string-join($d/../marcxml:datafield[@tag eq "034"]/marcxml:subfield[@code eq "d" or @code eq "e" or @code eq "f" or @code eq "g"], '° '),'°')}
            else ()
        ) 
        
let $leader:=fn:string($d/../marcxml:leader) 

let $leader7:=fn:substring($leader,8,1)

let $leader19:=fn:substring($leader,20,1)
let $instance-types:= mbshared:get-instanceTypes($d/ancestor::marcxml:record)                  
    (: (if ($leader7="m" and 
           	         fn:matches($leader19,"(a|b|c)")) 	then "MultipartMonograph"
           	else if (fn:matches($leader7,"(a|c|d|m)"))	then "Monograph"
            else if ($leader7='s')           		then "Serial"           	
           	else if ($leader7='i') 				   	then "Integrating"           	
           	else (),
    if (fn:matches($leader7,"(c|d)"))	then "Collection" else (),
    if (fn:matches($leader6,"(d|f|t)"))	then "Manuscript" else (),
    if ($leader8="a")	then "Archival" else (),
 
    ):)
  let $instance-types:= 
        for $i in fn:distinct-values($instance-types)
                return    element rdf:type {   attribute rdf:resource { fn:concat("http://bibframe.org/vocab/" ,$i)}}
   
let $issuance:=
           	if (fn:matches($leader7,"(a|c|d)")) 		            then "monographic"
           	else if ($leader7="b") 						            then "continuing"
           	else if ($leader7="m" and  fn:matches($leader19,"(a|b|c)")) 	then "multipart monograph"
           	else if ($leader7='m' and $leader19=' ') 				then "single unit"
           	else if ($leader7='i') 						           	then "integrating resource"
           	else if ($leader7='s')           						then "serial"
           	else ()
     let $issuance := 
                if ($issuance) then 
                   element bf:modeOfIssuance {$issuance}                  
                else ()
            
            
      let $holdings := mbshared:generate-holdings($d/ancestor::marcxml:record, $workID)
 
    let $instance-identifiers :=
             (                       
            mbshared:generate-identifiers($d/ancestor::marcxml:record,"instance")    
        )    
    
    let $general-notes := mbshared:generate-500notes($d/ancestor::marcxml:record)
   let $standalone-880s:=mbshared:generate-standalone-880( $d/ancestor::marcxml:record ,"instance") 
    (:337, 338::)
    let $physdesc := mbshared:generate-physdesc($d/ancestor::marcxml:record,"instance")
  
  let $i504:= 
    for $i in $d/../marcxml:datafield[@tag="504"] 
        let $b:= if ($i/marcxml:subfield[@code="b"]) then
            fn:concat("References: ", fn:string($i/marcxml:subfield[@code="b"]))
        else ()
    return 
        element bf:supplementaryContentNote {
        fn:normalize-space(
                fn:concat(fn:string($i/marcxml:subfield[@code="a"])," ",  $b)
                )
        }
   let $instance-relateds := mbshared:related-works($d/ancestor::marcxml:record,$workID,"instance") 
  let $instance-simples:= (:all but identifiers:)  
 	  ( mbshared:generate-simple-property($d/../marcxml:datafield[@tag="300"][1],"instance"),
 	      for $i in $d/../marcxml:datafield[fn:not(fn:matches(@tag,"^0[1-9]")) ][@tag!="300"] 
 	          return mbshared:generate-simple-property($i,"instance") 	            
 	    )
 
 
    return 
        element bf:Instance {        
           $instance-types,                            
            $instance-title,
      
            $resp-statement880,
            $publication,   
            $edition-880,
            $physMapData,
          $issuance,
          $instance-relateds,
            $instance-simples,
            $general-notes,            
            $i504,             
            $instance-identifiers,            
            $physdesc,
            $standalone-880s,
            element bf:instanceOf {
                attribute rdf:resource {$workID}
                }, 
            $derivedFrom,           
            $holdings
        }
};

(:~
:   This is the function generates other language labels from non-parallel 880s
:	880 with $6 containing 00:  [tag]-00
:   @param  $marcxml        element is the whole record tag *
:   @return bf:* as element()
:	
:)
declare function mbshared:generate-standalone-880
    (
   $marcxml as element(marcxml:record),
    $domain as xs:string    
    ) as element ()*
{

if ($marcxml/marcxml:datafield[@tag='880'][fn:matches(marcxml:subfield[@code="6"],"^[0-9]{3}-00")] ) then
    let $nodes:=         ($mbshared:simple-properties//node[@domain=$domain],
                            $mbshared:addl-880-nodes//node[@domain=$domain])
    let $taglist := fn:concat("(",fn:string-join(fn:distinct-values($nodes//@tag),"|"),")")
    let $lang := fn:substring(fn:string($marcxml/marcxml:controlfield[@tag="008"]), 36, 3)     
    let $scr := fn:tokenize($marcxml/marcxml:subfield[@code="6"],"/")[2]
    let $xmllang:= mbshared:generate-xml-lang($scr, $lang)

    return
        
        for $d in $marcxml/marcxml:datafield[@tag='880'][fn:matches(marcxml:subfield[@code="6"],"^[0-9]{3}-00$")]            
            let $tag-to-convert:= fn:substring($d/marcxml:subfield[@code="6"],1,3)
            
            for $node880 in $nodes[fn:string(@tag)= $tag-to-convert]
                let $return-codes:=
 			            if ($node880/@sfcodes) then fn:string($node880/@sfcodes) 		else "a"
                        
                return element {fn:concat("bf:",fn:string($node880/@property))} {
                                    if ($xmllang) then         attribute xml:lang {$xmllang} else (),                    
                                    fn:string($d/marcxml:subfield[fn:matches(@code,$return-codes)]),
                                    fn:string($d/marcxml:subfield[@code="a"])
                                } 
        
else 
        ()

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
declare function mbshared:generate-880-label
    (
        $d as element(marcxml:datafield)*, 
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
        let $xmllang:= mbshared:generate-xml-lang($scr, $lang)

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
                    if ( fn:matches($d/@tag, "(130|245|242|243|246|490|510|630|730|740|830)") ) then
                        "(a|b|f|h|k|n|p)"
                    else
                        "(t|f|k|m|n|p|s)"
                return
                    element bf:titleValue {
                        attribute xml:lang {$xmllang},                                                   
                        marc2bfutils:clean-title-string(fn:replace(fn:string-join($match/marcxml:subfield[fn:matches(@code,$subfs)] ," "),"^(.+)/$","$1"))
                    }
            else if ($node-name="subject") then 
                element bf:authorizedAccessPoint{
	                   attribute xml:lang {$xmllang},   
                        marc2bfutils:clean-string(fn:string-join($match/marcxml:subfield[fn:not(@code="6")], " "))
                }
            else if ($node-name="place") then 
                for $sf in $match/marcxml:subfield[@code="a"]
                let $text:=         marc2bfutils:clean-string(fn:string($sf))
                
                return (:inside bf:Place:)
                            element bf:label { 
                                     attribute xml:lang {$xmllang} ,
                                    $text
                            }                        
                    
	       else if ($node-name="provider") then 
                for $sf in $match/marcxml:subfield[@code="b"]
                return                 
                            element bf:label {
                                attribute xml:lang {$xmllang},   			
                                marc2bfutils:clean-string(fn:string($sf))
                            }
                 
          else if ($node-name="responsibilityStatement") then
                 for $sf in $match/marcxml:subfield[@code="c"]
                     return
                         element bf:responsibilityStatement {                      
                             attribute xml:lang {$xmllang},   			
                             marc2bfutils:clean-string(fn:string($sf))
                         }    
          else if ($node-name="providerDate") then
                 for $sf in $match/marcxml:subfield[@code="c"]
                     return
                         element bf:providerDate {  
                            attribute xml:lang {$xmllang},   			
                             marc2bfutils:clean-string(fn:string($sf))
                         }                        
        else 
            element { fn:concat("bf:",$node-name)} {  attribute xml:lang {$xmllang} ,
                fn:string($match/marcxml:subfield[@code="a"])					
            }				
	(:not 880:)
	else ()


	
};


(:~
:   This is the function generates 0xx  data for instance or work, based on mappings in $work-identifiers 
:    and $instance-identifiers. Returns subfield $a,y,z,m,l,2,b,q
:
::   @param  $marcxml       element is the marcxml record
:   @param  $domain      string is the "work" or "instance"
: skip isbn; do it on generate-instance from isbn, since it's a splitter and yo udon't want multiple per instance
:   @return bf:* as element()
:)
declare function mbshared:generate-identifiers(
   $marcxml as element(marcxml:record),
    $domain as xs:string    
    ) as element ()*
{ 
      let $identifiers:=         
             $mbshared:simple-properties//node[@domain=$domain][@group="identifiers"]
      let $taglist:= fn:concat("(",fn:string-join(fn:distinct-values($identifiers//@tag),"|"),")")
                    
                    
    let $bfIdentifiers := 
         (:for $id in $identifiers[fn:not(@ind1)][@domain=$domain] (\:all but 024 and 028:\)                        	 
               	return
               	for $this-tag in $marcxml/marcxml:datafield[@tag eq $id/@tag] :)
               	(:for each matching marc datafield:)          		
         
         (:invert the for loops for speed: 2014-03-20 :)
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
                                or  	$this-tag[@tag="040"][fn:starts-with(fn:normalize-space(fn:string(marcxml:subfield[@code="a"])),'Ca')])
                   	    	    then 
		                          (element {fn:concat("bf:",fn:string($id/@property)) }{		                              
               		                       element bf:Identifier{		                          
               		                            element bf:identifierScheme {				 
               		                                fn:string($id/@property)
               		                            },	                            
               		                            element bf:identifierValue { 		                               
               		                                    fn:string($this-tag/marcxml:subfield[@code="a"][1])
               		                            },
               		                            for $sub in $this-tag/marcxml:subfield[@code="b" or @code="2"]
               		                            	return element bf:identifierAssigner { 	fn:string($sub)},		
               		                            for $sub in $this-tag/marcxml:subfield[@code="q" ][$this-tag/@tag!="856"]
               		                            	return element bf:identifierQualifier {fn:string($sub)},
               	                                for $sub in $this-tag[@tag="037"]/marcxml:subfield[@code="c"]
               		                            	return element bf:identifierQualifier {fn:string($sub)}	                          		                           
               	                        	}
               	                       },
	                        	$cancels	                        			                              
		                        )
	                    	else 	(: not    @code,"(b|q|2) :)                
	                        ( mbshared:generate-simple-property($this-tag,$domain ) ,	                        
	                        $cancels	                  	                           
			                 )(: END OF not    @code,"(b|q|2), end of tags matching ids without @ind1:)
               
               (:----------------------------------------   024 and 028 , where ind1 counts----------------------------------------:)
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
        			                 let $value:=
        			                     if ($this-tag/marcxml:subfield[@code="d"]) then 
        			                           fn:string-join($this-tag/marcxml:subfield[fn:matches(@code,"(a|d)")],"-")
        			                         else
        			                            fn:string($this-tag/marcxml:subfield[@code="a"])        			                           
	                                 return 
	                                   element {$property-name} {
	                                    element bf:Identifier{
       	                                    element bf:identifierScheme {$scheme},
       	                                    element bf:identifierValue {$value},
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
                                                            element bf:identifierValue { fn:normalize-space(fn:string($s))        }
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
:   This is the function that handles $0 in various fields
:   @param  $sys-num       element is the marc subfield $0
     
:   @return  element() either bf:systemNumber or bf:hasAuthority with uri
:)

declare function mbshared:handle-system-number( $sys-num as element(marcxml:subfield)  ) 
{
if (fn:starts-with(fn:normalize-space($sys-num),"(uri)")) then
         let $id:=fn:normalize-space(fn:tokenize(fn:string($sys-num),"\)")[2] )
         return  element bf:hasAuthority {attribute rdf:resource{$id} }
 else
 if (fn:contains(fn:normalize-space($sys-num),"http://")) then
         let $id:=fn:normalize-space(fn:concat("http://",fn:substring-after(fn:string($sys-num),"http://")  ) )
         return element bf:hasAuthority {attribute rdf:resource{$id} }
 else
 if (fn:starts-with(fn:normalize-space($sys-num),"(DE-588")) then
         let $id:=fn:normalize-space(fn:tokenize(fn:string($sys-num),"\)")[2] )
         return element bf:hasAuthority {attribute rdf:resource{fn:concat("http://d-nb.info/gnd/",$id)} }
  else   if ( fn:matches(fn:normalize-space($sys-num), "$\(OCoLC\)" ) ) then
                                                          
	      let $iStr :=  marc2bfutils:clean-string(fn:replace($sys-num, "\(OCoLC\)", ""))                
	      return       element bf:systemNumber {  attribute rdf:resource {fn:concat("http://www.worldcat.org/oclc/",fn:replace($iStr,"(^ocm|^ocn)","")) }}
else 	                      
       element bf:systemNumber { element bf:Identifier { 
                element bf:identifierValue {fn:string($sys-num)}
            }
       }
};
(:~
:   This is the function generates full Identifier classes from m,y,z cancel/invalid identifiers 
:   @param  $this-tag       element is the marc data field
:   @param  $sf             subfield element
:   @param  $scheme         identifier name (lccn etc.)
:   @return bf:Identifier as element()
:)
declare function mbshared:handle-cancels($this-tag, $sf, $scheme) 
{
 if (($this-tag[fn:matches(@tag,"(010|015|016|017|020|022|027|030|024|088)")] and $sf[@code="z"])  or
        ($this-tag[@tag="022"] and $sf[fn:matches(@code,"m|y")])) then
         element bf:Identifier {
  		  element bf:identifierScheme { $scheme },
  		  element bf:identifierValue { fn:normalize-space(fn:string($sf))},
              if ($this-tag[@tag="022"] and $sf[@code="y"]) then                               
                      element bf:identifierStatus{"incorrect"}          
              else if ($this-tag[@tag="022"] and $sf[@code="z"]) then                 
                      element bf:identifierStatus{"canceled/invalid"}                
              else if ($this-tag[@tag="022"] and $sf[@code="m"]) then
                      element bf:identifierStatus {"canceled/invalid"}                
              else if ($this-tag[fn:matches(@tag,"(010|015|016|017|020|027|030|024|088)")] and $sf[@code="z"] ) then               
                      element bf:identifierStatus{"canceled/invalid"}                  
              else
                  ()
          }
        else ()
};
(:~
:   This is the function generates publication  data for 261, 262 
:

:)
declare function mbshared:generate-26x-pub
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
	                    element bf:providerDate {marc2bfutils:chopPunctuation(fn:string($pub),".")}	                    	                  
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

!!! work on ab abc bibid 468476
!!! work on 880s in 260abc, efg
:)
declare function mbshared:generate-publication
    (
        $d as element(marcxml:datafield)        
    ) as element ()*
{ (:first handle abc, for each b, set up a publication with any associated A's and Cs:)
    if ($d/marcxml:subfield[@code="b"]) then
    
        for $pub at $x in $d/marcxml:subfield[@code="b"]
	        let $propname :=  
	           if ($d/@tag="264" and $d/@ind2="3" ) then
	               "bf:manufacture"
               else if ($d/@tag="264" and $d/@ind2="2" ) then
	               "bf:distribution"
	           else
	                "bf:publication"
	           (:if there's only one c, it applies to multiple ab's:) 
             let $date:=      if ($d/marcxml:subfield[@code="c"][$x]) then
                                    $d/marcxml:subfield[@code="c"][$x]
                             else if ( $x gt 1 and $d/marcxml:subfield[@code="c"][$x - 1]) then
                             $d/marcxml:subfield[@code="c"][$x - 1]
                             else ()
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
	                           element bf:label {marc2bfutils:clean-string(fn:string($pub))},
	                           mbshared:generate-880-label($d,"provider")
	                       }
	                    }
	                    ,
	                    if ( $d/marcxml:subfield[@code="a"][$x]) then
	                        element bf:providerPlace {
	                           element bf:Place {
	                               element bf:label {
	                                   marc2bfutils:clean-string($d/marcxml:subfield[@code="a"][$x])},
	                                      mbshared:generate-880-label($d,"place")
	                           }
                           }
	                          
	                    else (),
	                    if (fn:starts-with($date,"c")) then
	                    (:\D filters out "c" and other non-digits, but also ?, so switch to clean-string for now. may want "clean-date??:)
	                        element bf:copyrightDate {marc2bfutils:clean-string($date)}
	                     else if ( fn:not(fn:starts-with($date,"c") )) then
	                       ( element bf:providerDate {marc2bfutils:chopPunctuation($date,".")},
	                            mbshared:generate-880-label($d,"providerDate")
	                            )
	                    else ()
	                    (:if ($d/marcxml:subfield[@code="c"][$x] and fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") ) then 
	                       
	                        element bf:copyrightDate {marc2bfutils:clean-string($d/marcxml:subfield[@code="c"][$x])}
	                    else if ($d/marcxml:subfield[@code="c"][$x] and fn:not(fn:starts-with($d/marcxml:subfield[@code="c"][$x],"c") )) then
	                        element bf:providerDate {marc2bfutils:chopPunctuation($d/marcxml:subfield[@code="c"][$x],".")}                 
	                    else ():)
	                }
		}   
		(:there is no $b:)
        else if ($d/marcxml:subfield[fn:matches(@code,"(a|c)")]) then	
	            element bf:publication {
	                element bf:Provider {
	                    for $pl in $d/marcxml:subfield[@code="a"]
	                    return element bf:providerPlace {
	                                   element bf:Place {
	                                       element bf:label {fn:string($pl)},
	                                       mbshared:generate-880-label($d,"place")  
	                                   }
	                               },
	                    		     
	                    for $pl in $d/marcxml:subfield[@code="c"]
	                    	return 
	                        if (fn:starts-with($pl,"c")) then				
				       element bf:providerDate {marc2bfutils:chopPunctuation($pl,".")}
	                        else 
				       element bf:copyrightDate {marc2bfutils:chopPunctuation($pl,".")}		
		      }
	        }
	    else (),    
        (:handle $e,f,g like abc :)
        if ($d/marcxml:subfield[@code="e"]) then
            for $pub at $x in $d/marcxml:subfield[@code="e"]
	           let $propname := "bf:manufacture"   
	           return 
	                element {$propname} {
	                    element bf:Provider {
	                       element bf:providerName {
	                        element bf:Organization {
	                           element bf:label {marc2bfutils:clean-string(fn:string($pub))},
	                            mbshared:generate-880-label($d,"provider") 
	                           }
	                           }
	                    ,
	                    if ( $d/marcxml:subfield[@code="f"][$x]) then
	                        element bf:providerPlace {
	                               element bf:Place {
	                                   element bf:label {                      fn:string($d/marcxml:subfield[@code="f"][$x])},
	                                   mbshared:generate-880-label($d,"place") 
	                                   }
	                                   }	                        
	                    else (),
	                    if ($d/marcxml:subfield[@code="g"][$x]) then
	                        (element bf:providerDate {marc2bfutils:chopPunctuation($d/marcxml:subfield[@code="g"][$x],".")},
	                                   mbshared:generate-880-label($d,"providerDate") 
	                           )
	                    else if ($d/marcxml:subfield[@code="c"][$x]) then
	                      ( element bf:providerDate {marc2bfutils:chopPunctuation($d/marcxml:subfield[@code="c"][$x],".")},
	                      mbshared:generate-880-label($d,"providerDate") 
	                      )
	                       else ()
	                }
		}   
		(:there is no $b:)       
        else if ($d/marcxml:subfield[fn:matches(@code,"(e|f)")]) then	
            element bf:publication {
                element bf:Provider {
                    for $pl in $d/marcxml:subfield[@code="e"]
                    	return element bf:providerPlace {
                    	           element bf:Place {
	                                           element bf:label {fn:string($pl)},
	                       	                   mbshared:generate-880-label($d,"place")
	                                   }
	                       },
                    for $pl in $d/marcxml:subfield[@code="g"]							
                    	return (element bf:providerDate {marc2bfutils:chopPunctuation($pl,".")},
                    	mbshared:generate-880-label($d,"providerDate") ) 
                }
            }
    
    else ()

};
(:~
:   This is the function generates 337,338  data for instance or work, based on mappings in $physdesc-list
:	Returns bf: node of elname 
:
:   @param  $marcxml       element is the marcxml record
:   @param  $resource      string is the "work" or "instance"
:   @return bf:* 	   element()
:)
declare function mbshared:generate-physdesc
    (
        $marcxml as element(marcxml:record),
        $resource as xs:string
    ) as element ()*
{ 
        (          
             (:---337,338:)
             if ($resource="instance") then 
              (  (:-------------337----------------:)
              for $d in $marcxml/marcxml:datafield[@tag="337" ]
                let $src:=fn:string($d/marcxml:subfield[@code="2"])
                
                return
                    if (   $src="rdamedia"  and $d/marcxml:subfield[@code="a"]) then
                    for $s in $d/marcxml:subfield[@code="a"]
                            let $media-code:=marc2bfutils:generate-mediatype-code(fn:string($s))
                           return element bf:mediaCategory {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/mediaTypes/",fn:encode-for-uri($media-code))}	
                                }
                     else if ($d/marcxml:subfield[@code="a"]) then
                           for $s in $d/marcxml:subfield[@code="a"]
                             return element bf:mediaCategory { 
                                 element bf:Category {
                                         element bf:label{fn:string($s)},		
                                         element bf:categoryValue{fn:string($s)},
                                         element bf:categoryType{"media category"}
                                         } 
                                     }
                        else   if (   $src="rdamedia"  and $d/marcxml:subfield[@code="b"]) then
                                    for $s in $d/marcxml:subfield[@code="b"]
                                        return element bf:mediaCategory {attribute rdf:type {fn:concat("http://id.loc.gov/vocabulary/mediaTypes/",fn:encode-for-uri(fn:string($s)))}		
                        } 
                     else  (),  
                      (:----------338-------------------:)
               for $d in $marcxml/marcxml:datafield[@tag="338"]
                let $src:=fn:string($d/marcxml:subfield[@code="2"])
                
                return
                    if (   $src="rdacarrier"  and $d/marcxml:subfield[@code="a"]) then
                        for $s in $d/marcxml:subfield[@code="a"]
                        let $carrier-code:= marc2bfutils:generate-carrier-code(fn:string($s))                        
                           return if ($carrier-code) then                           
                                element bf:carrierCategory {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/carriers/",fn:encode-for-uri($carrier-code))}		
                                }
                                else element bf:carrierCategory { element bf:Category { element bf:categoryValue {fn:string($s)}}}
                     else if  ($d/marcxml:subfield[@code="a"]) then
                            for $s in $d/marcxml:subfield[@code="a"]
                              return  element bf:carrierCategory {                           
                                      attribute rdf:resource {fn:concat("http://somecarrier.example.org/",
                                          fn:encode-for-uri(fn:string($s)))}
                                  }
                        else   if (  $src="rdacarrier"  and $d/marcxml:subfield[@code="b"]) then
                            for $s in $d/marcxml:subfield[@code="b"]
                            return  element bf:carrierCategory {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/carriers/",fn:string($s))}		
                        } 
                     else  (),  
              (:---337, 338 end ---:)
             (: hyphens may also be inside the range! ex:
                        (Mar. 21-27, 1996)- no. 30(Apr. 4-9, 1997) :)
              for $issuedate in $marcxml/marcxml:datafield[@tag="362"]
                let $subelement:=fn:string($issuedate/marcxml:subfield[@code="a"])
                return
                    if (   $issuedate/@ind1="0" and fn:contains($subelement,"-") ) then
                        let $first:=
                            if ( fn:matches($subelement,"(.+\(.+-.+)-(.+\(.+\).+)") ) then
                                    fn:replace($subelement,"(.+\(.+-.+)-(.+\(.+\).+)","$1")
                               else if (fn:contains($subelement,"-")) then       
                                    fn:normalize-space( fn:substring-before($subelement,"-"))
                               else $subelement
                        let $last:=  if ( fn:matches($subelement,"(.+\(.+-.+)-(.+\(.+\).+)")) then
                                        fn:replace($subelement,"(.+\(.+-.+)-(.+\(.+\).+)","$2")
                               else if (fn:contains($subelement,"-")) then          
                                    fn:normalize-space( fn:substring-after($subelement,"-"))
                               else ()
                        return (  
                                if ($first!="") then
                                    element bf:serialFirstIssue {$first   }
                                  else (),
                                        
                                if ( $last!="") then 
                                    element bf:serialLastIssue{	$last   }
                                else ()
                            )
                    else  (:no hyphen or it's ind1=1:)
                        (element bf:serialFirstIssue {
                            fn:normalize-space( $subelement)
                        },
                         mbshared:generate-880-label($issuedate,"serialFirstIssue")                           
                        ),
                        for $d in $marcxml/marcxml:datafield[@tag="351"]                              
                             return                             
                                 element bf:arrangement {		                                    
                                        element bf:Arrangement {
                                            mbshared:generate-simple-property($d,"arrangement")
                                        }
                                     }
                 ) (:instance end:)
                 else  (: work-------------336----------------:)
              for $d in $marcxml/marcxml:datafield[@tag="336" ]
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
                     else  (),                   
                      for $node in  $mbshared:simple-properties//node[fn:string(@domain)="contentcategory"]
                        let $return-codes:=
 			                    if ($node/@sfcodes) then fn:string($node/@sfcodes) 		else "a"
                         for $s in $marcxml/marcxml:datafield[@tag=$node/@tag]/marcxml:subfield[fn:matches(@code,$return-codes)]
                               return element bf:contentCategory { 
                                 element bf:Category {                                      
                                         element bf:categoryValue{fn:string($s)},
                                         element bf:categoryType{"content category"}
                                         } 
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
:
:work with this example, bibid 13891080
:
:)
declare function mbshared:generate-instance-fromISBN(
    $d as element(marcxml:record),
    $isbn-set as element (bf:set),   
    (:something needed to be a null instance???:)
    $instance as element (bf:Instance)?,
    
    $workID as xs:string
    ) as element ()*
    
{
                
    let $isbn-extra:=fn:normalize-space(fn:tokenize(fn:string($isbn-set/marcxml:subfield[1]),"\(")[2])
    let $volume:= 
       (:too hard to parse :)
      (:  if (fn:contains($isbn-extra,":")) then    
            fn:replace(marc2bfutils:clean-string(fn:normalize-space(fn:tokenize($isbn-extra,":")[2])),"\)","")
        else:)
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
            (:else if (fn:matches($carrier,"(acid-free|acid free|alk)","i")) then
                "acid free":)					           
            else 
                ""
            (:else fn:replace($carrier,"\)",""):)
    (:9781555631185 (v. 4. print):)
    let $i-title :=  (:this already exists in the output?:)
        if ($d/marcxml:datafield[@tag = "245"]) then
            mbshared:get-title($d/marcxml:datafield[@tag = "245"], "instance")
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
           ()
            
        
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
                attribute rdf:resource {fn:concat("http://isbn.example.org/",fn:normalize-space($i))}
                },                                        
                    
                if ($element-name ="bf:isbn10" and $physicalForm!="" ) then
                    element bf:isbn10 {
                        element bf:Identifier {
                            element bf:identifierValue {fn:normalize-space($i)},
                            element bf:identifierScheme {"isbn"},
                            element bf:identifierQualifier {fn:normalize-space($physicalForm)}
                        }                                    
                    }
                    else ()
                    
               )
     
    let $instanceOf :=  
        element bf:instanceOf {
            attribute rdf:resource {$workID}
        }

    return 
        element bf:Instance {
        		
        		(: See extent-title above :)
        		(: if ($volume) then element bf:title{ $volume} else (), :)
        	    $extent-title,
                $isbn,
        		(:for $t in $extent-title
        		return 
                    element bf:label { 
                        $t/@*,
                        xs:string($t)
                    },:)
        		if ($physicalForm) then      element bf:format {$physicalForm} else (),
        		$volume-info,
        		
        (:not done yet:  2013-05-21 :)
      (:  element bf:testvtest{$v-test},
        element bf:testvolume{$volume},
        element bf:testvolumetest{   $volume-test},:)
   	        		        
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
: Makes a duplicate? I don't see anything different from the 260
:   @param  $d        element is each 250 after the first  
:   @return bf:* as element()
:)
declare function mbshared:generate-instance-from250(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element ()*
{

    (:get the physical details:)
    (: We only ask for the first 260 :)
	let $instance := mbshared:generate-instance-from260($d/../marcxml:datafield[fn:matches(@tag, "(260|261|262|264|300)")][1], $workID)        
        
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
                $instanceOf)
	
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
declare function mbshared:generate-instance-from856(
    $d as element(marcxml:datafield),
    $workID as xs:string
    ) as element ()* 
{
    (:let $bibid:=$d/../marcxml:controlfield[@tag="001"]:)
        let $category:=         
            if (      fn:contains(
            		fn:string-join($d/marcxml:subfield[@code="u"],""),"hdl.") and(:u is repeatable:)
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
                if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"contents","i")) then "table of contents"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"sample","i")) then "sample text"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"contributor","i")) then "contributor biography"
                else if (fn:matches(fn:string($d/marcxml:subfield[@code="3"]),"publisher","i")) then "publisher summary"
                else  ()
            else ()
            
 	return 
	 if ( $category="instance" ) then 
                element bf:hasInstance {
                	element bf:Instance {               	      
                	        element rdf:type {attribute rdf:resource {"http://bibframe.org/vocab/Electronic"}},
                    		element bf:label {
                    			if ($d/marcxml:subfield[@code="3"]) then fn:normalize-space(fn:string($d/marcxml:subfield[@code="3"]))
                    			else "Electronic Resource"
                    		},                    		
               		        mbshared:handle-856u($d)           		       ,
	                    element bf:instanceOf {
	                        attribute rdf:resource {$workID}
	                  	},                    		
                    		$annotates
                	}
                }
             else   
                let $property-name:= if ($type="table of contents") then "bf:TableOfContents"
                                        else if ($type="publisher summary") then "bf:Summary"
                                       else "bf:Annotation"
                  return   element bf:hasAnnotation {                   
                                 
            	 	element {$property-name}{
            	 	
            	 	 if (fn:string($d/marcxml:subfield[@code="3"]) ne "" or $type) then
                 	 	 element bf:label {
                         		if (fn:string($d/marcxml:subfield[@code="3"]) ne "") then                        		
                                 			fn:string($d/marcxml:subfield[@code="3"])       					                        		
                         		else if ($type) then
                         	           $type
                         	           else ()
                         		}
                    else (),
	                    	                    
	                    for $u in $d/marcxml:subfield[@code="u"]
	                      let $property-name:= if ($type="table of contents") then "bf:tableOfContents"
                                        else if ($type="publisher summary") then "bf:review"
                                       else "bf:annotationBody"
	                    	return element {$property-name} { 
	                    	                  attribute rdf:resource {                  	
	                    		                 fn:normalize-space(fn:string($u))
	                    		                }
	                    		},
	                    		
	                    for $s in $d/marcxml:subfield[@code="z"]
                    		  return element bf:copyNote {fn:string($s)},
	                    $annotates
              		}
              	}

};
(:~
:   This is the function generates dissertation on Work from 502.
: (dissertation is no longer a subclass of Work
:   @param  $marcxml        element is the 502 datafield  
:   @return bf:* as element()
:)
declare function mbshared:generate-dissertation(
    $d as element(marcxml:datafield)   
    ) as element ()* 
{

(

    if ($d/marcxml:subfield[@code="c"] ) then
        element bf:dissertationInstitution {element bf:Organization {
                element bf:label {fn:string($d/marcxml:subfield[@code="c"])}}
                }
                
    else (), 

	if ($d/marcxml:subfield[@code="o"]) then
			element bf:dissertationIdentifier  { element bf:Identifier {
			     element bf:identifierValue{fn:string($d/marcxml:subfield[@code="o"])}			   
			     }
			     }
			     
		else ()

   )
};

(:~
:   This is the function generates holdings properties from hld:holdings.
: 
:   @param  $marcxml        element is the MARCXML
:                           may also contain hld:holdings
:   @return bf:* as element()
:)
declare function mbshared:generate-holdings-from-hld(
    $marcxml as element(marcxml:record)?,
    
    $workId as xs:string
    
    ) as element ()* 
{
let $holdings:=$marcxml//hld:holdings
let $heldBy:= if ($marcxml/marcxml:datafield[@tag="852"]/marcxml:subfield[@code="a"]) then
                    fn:string($marcxml/marcxml:datafield[@tag="852"][1]/marcxml:subfield[@code="a"])
                else ""
let $custodialHistory:=mbshared:generate-simple-property($marcxml/marcxml:datafield[@tag="561"], "helditem")
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
                                for $circulation in $circs/hld:circulation[fn:normalize-space(fn:string(hld:enumAndChron ))=$enum]
                                    let $status:= if ($circulation/hld:availableNow/@value="1") then "available" else  "not available" 
                                        return element circ {element bf:circulationStatus {$status},
                                                if ($circulation/hld:itemId) then element bf:itemId  {fn:string($circulation/hld:itemId )} else ()
                                                }
                                                
                                              
                           return            
                              element bf:heldItem {
                                element bf:HeldItem {
                                    if ($circ/bf:itemId!='') then 
                                         attribute rdf:about {fn:concat($workId,"/item",fn:string($circ/bf:itemId))}
                                    else (),
                                    element bf:label {fn:string($vol/hld:enumAndChron)},
                                    element bf:enumerationAndChronology  {$enum },     
                                     element bf:enumerationAndChronology {fn:string($vol/hld:enumeration)},
                                     $circ/*
                                  }
                               }
             else  (: no volumes,  just add circ  to the summary heldmaterial:)              
                        let $status:= if ($hold/hld:circulations/hld:circulation/hld:availableNow/@value="1") then "available" else  "not available" 
                        return  element bf:heldItem {
                                    element bf:HeldItem {
                                        if ($hold/hld:circulations/hld:circulation/hld:itemId) then
                                            attribute rdf:about {fn:concat($workId,"/item",fn:string($hold/hld:circulations/hld:circulation/hld:itemId))}                                        
                                        else (),
                                        element bf:circulationStatus {$status},                                
                                            element bf:itemId  {fn:string($hold/hld:circulations/hld:circulation/hld:itemId )}
                                        }                                
                                    }
         
            
     return (
      if ($elm = "HeldItem" ) then
         element bf:heldItem {                               
            element bf:HeldItem {            
            $item-set/bf:HeldItem/@rdf:about,        
             $summary-set, $item-set//bf:HeldItem/*[fn:not(fn:local-name()='label')],
             $custodialHistory,             
             if ($heldBy!="") then element bf:heldBy {element bf:Organization {element bf:label {$heldBy}}} else ()
            }
            }
                     
      else
        element bf:heldMaterial{   
               element bf:HeldMaterial {
                     $summary-set,                      
                     $item-set,
                     if ($heldBy!="") then element bf:heldBy {element bf:Organization {element bf:label {$heldBy}}} else ()
                    }
            }
    )
        
};
(:~
:   This is the function generates holdings resources.
: 
:   @param  $marcxml        element is the MARCXML
:                           may also contain hld:holdings
:   @return bf:* as element()
:)
declare function mbshared:generate-holdings(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element ()* 
{

let $hld:= if ($marcxml//hld:holdings) then mbshared:generate-holdings-from-hld($marcxml, $workID) else ()

(:udc is subfields a,b,c; the rest are ab:) 
(:call numbers: if a is a class and b exists:)
 let $shelfmark:=  (: regex for call# "^[a-zA-Z]{1,3}[1-9].*$" :)        	        	         	         
	for $tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|051|055|060|070|080|082|084)")]
(:	multiple $a is possible: 2017290 use $i to handle :)
		for $class at $i in $tag[marcxml:subfield[@code="b"]]/marcxml:subfield[@code="a"]
       		let $element:= 
       			if (fn:matches($class/../@tag,"(050|051|055|070)")) then "bf:shelfMarkLcc"
       			else if (fn:matches($class/../@tag,"060")) then "bf:shelfMarkNlm"
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
let $custodialHistory:=mbshared:generate-simple-property($marcxml/marcxml:datafield[@tag="561"], "helditem")
let $d852:= 
    if ($marcxml/marcxml:datafield[@tag="852"]) then
        for $d in $marcxml/marcxml:datafield[@tag="852"]
        return 
            (
            for $s in $d/marcxml:subfield[@code="a"] return element bf:heldBy{fn:string($s)},
            for $s in $d/marcxml:subfield[@code="b"] return element bf:subLocation{fn:string($s)},
            
            if ($d/marcxml:subfield[fn:matches(@code,"(k|h|l|i|m|t)")]) then 
                    element bf:shelfMark{fn:string-join($d/marcxml:subfield[fn:matches(@code,"(k|h|i|l|m|t)")]," ")}
            else (),
                    mbshared:handle-856u($d) 		      ,
            
            for $s in $d/marcxml:subfield[@code="z"] return element  bf:copyNote{fn:string($s)},
            for $s in $d/../marcxml:datafield[fn:matches(@tag,"(051|061|071)")]
                return element bf:copyNote {fn:string($s/marcxml:subfield[@code="c"]) }
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
         	    $custodialHistory,
         	    $d852         	     	
                }
            }
            
      	else if ($hld) then $hld else ()
    
};
(:~
:   This is the function generates bf:uri or bf:doi or bf:hdl from856u
: 
:   @param  $marcxml        element is the MARCXML  datafield 856
:   @return bf:* as element()
:)
declare function mbshared:handle-856u(
    $marcxml as element(marcxml:datafield)
    
    ) as element ()* 
{  
for $s in $marcxml/marcxml:subfield[@code="u"] return
                let $elm:=if (fn:contains(fn:string($s) ,"doi")) then "bf:doi"
                            else if (fn:contains(fn:string($s),"hdl")) then "bf:hdl" else "bf:uri"
                return element {$elm} { 
                            attribute rdf:resource{fn:string($s)}
                        }
};
(:~
:   This is the function generates instance resources.
: 
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function mbshared:generate-instances(
    $marcxml as element(marcxml:record),
    $typeOf008 as xs:string,
    $workID as xs:string
    ) as element ()* 
{  
let $isbn-sets:=
	if ($marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]) then
		mbshared:process-isbns($marcxml) 
	else ()

    return    
        (
        if ( $isbn-sets//bf:set) then           
        	(:use the first 260 to set up a book instance... what else is an instance in other formats?:)
            let $instance:= 
                for $i in $marcxml/marcxml:datafield[fn:matches(@tag, "(260|261|262|264|300)")][1]
          		      return mbshared:generate-instance-from260($i, $workID)        
                    
            for $set in $isbn-sets/bf:set
          	  return mbshared:generate-instance-fromISBN($marcxml,$set, $instance, $workID)
	   	
        else 	        (: $isbn-sets//bf:set is false use the first edition, etc:)		
            (:for $i in $marcxml/marcxml:datafield[@tag eq "260"]|$marcxml/marcxml:datafield[@tag eq "264"]:)
            for $i in $marcxml/marcxml:datafield[fn:matches(@tag, "(260|261|262|264|300)")][1]
     	       return mbshared:generate-instance-from260($i, $workID)   
   ,
        if ($typeOf008!="SE") then
            for $i at $x in $marcxml/marcxml:datafield[@tag="260"][fn:position() != 1]
                return  mbshared:generate-additional-instance($i, $workID , $x)
        else (),
        for $i at $x in $marcxml/marcxml:datafield[@tag="300"][fn:position() != 1]
                return   mbshared:generate-addl-physical($i, $workID , $x)
   )
};
(:~
:   This is the function generates general notes for all marc notes not in vocabulary
: 
:   @param  $marcxml        element is the MARCXML  
:   @return bf:note as element()?
:)
declare function mbshared:generate-500notes(
 $marcxml as element(marcxml:record)
   
    ) as element ()*
{

for $marc-note in $marcxml/marcxml:datafield[fn:starts-with(@tag, "5") and fn:not(fn:matches(@tag,$mbshared:named-notes))]
        return if ($marc-note[@tag !='504']) then
 			        let $note-text:= fn:string-join($marc-note/marcxml:subfield[@code="3" or @code="a"]," ")
			         return (element bf:note {$note-text},			                
			                 mbshared:generate-880-label($marc-note,"note")
			                 )
                else ()
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
declare function mbshared:generate-titleNonsort(
   $d  as element(marcxml:datafield),   
    $title as xs:string, 
    $property as xs:string 
    ) as element ()*
{
if (fn:matches($d/@tag,"(222|242|243|245|440|240)" ) and fn:number($d/@ind2) gt 0 ) then
                (:need to sniff for begin and end nonsort codes also:)                
                element bf:title {attribute xml:lang {"x-bf-sort"},
                       fn:substring($title, fn:number($d/@ind2)+1)
                             }
else if (fn:matches($d/@tag,"(130|630)" ) and fn:number($d/@ind1) gt 0 ) then
                (:need to sniff for begin and end nonsort codes also:)                
                element bf:title {attribute xml:lang {"x-bf-sort"},
                        fn:substring($title, fn:number($d/@ind1)+1)
                             }

else ()

};
(:530, 776, 777 related instances
ex bib:12821255
:)
declare function mbshared:generate-related-instance
    (
        $d as element(marcxml:datafield) ,
        $property     as xs:string  
    ) as element()*
{ 
let $title:=if ($d/marcxml:subfield[@code="t"]) then
        fn:string($d/marcxml:subfield[@code="t"])
        else if ($d/marcxml:subfield[@code="a"]) then
        fn:string($d/marcxml:subfield[@code="a"])
        else if ($d/marcxml:subfield[@code="c"] and $d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"]) then
            fn:concat(fn:string($d/../marcxml:datafield[@tag="245"]/marcxml:subfield[@code="a"]),fn:string($d/marcxml:subfield[@code="c"]))
            else fn:string($d/marcxml:subfield[@code="c"])
let $uri:=mbshared:handle-856u($d)
(:fn:string($d/marcxml:subfield[@code="u"]):)
let $ids:=mbshared:generate-simple-property($d,"7xx")
(:let $id:=if ($d/marcxml:subfield[@code="w"]) then
                mbshared:handle-system-number( $d/marcxml:subfield[@code="w"])
        else ():)

    return 
        element {fn:concat("bf:",$property)} {
            element bf:Instance{ 
                element bf:title {$title},
                $uri,
                $ids
            }
        }
    
};
(:533 to reproduction
sample bib 723007
:)
declare function mbshared:generate-related-reproduction
    (
        $d as element(marcxml:datafield) ,
        $type      
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
let $pubDate:=marc2bfutils:chopPunctuation($d/marcxml:subfield[@code="d"],".")
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
						element bf:instanceTitle {element bf:Title {element bf:label{$title}}},
						element bf:publication {
							element bf:Provider {
								$pubPlace,
								element bf:providerDate{$pubDate},								
								$agent
							}
						},
					
						if ($extent) then element bf:extent {$extent} else (),
						if ($coverage) then element bf:temporalCoverageNote {$coverage}  else (),						
						if ($carrier!="" ) then	element bf:carrierCategory {element bf:Category {element bf:categoryValue {marc2bfutils:chopPunctuation($carrier,".")}}}   else (),
						
						if ($note) then  $note  else ()						
						
					}
				}
				else ()				 							
				}
			}
};
(:033 events
@since 2014-05-16
example bib 11785748
@param $d as datafield 033
:)
declare function mbshared:generate-event
    (
        $d as element(marcxml:datafield) 
    )
{ 
    let $dates:= element bf:eventDate { 
                    if ($d/@ind1="2") then (:range:)
                        fn:string-join($d/marcxml:subfield[@code="a"]," - ")                        
                    else if ($d/@ind1="1") then (:multiple consecutive dates:)
                        fn:string-join($d/marcxml:subfield[@code="a"],", ")
                    else (attribute rdf:datatype {"xsd:dateTime"},fn:string($d/marcxml:subfield[@code="a"]))
                    }
                    
                    
    let $placesCodes:=
        for $s in $d/marcxml:subfield[@code="b"]
            let $subcode:=if ($s/following-sibling::marcxml:subfield[@code="c"]) then
                            fn:normalize-space(fn:string($s/following-sibling::marcxml:subfield[@code="c"][1]))
                            else ()
           let $base:=fn:concat("http://id.loc.gov/authorities/classification/G", fn:normalize-space(fn:string($s)))
           let $uri:= if ($subcode) then
                            fn:concat($base,".", $subcode)
                        else $base
                        
            return (: this in not really right; the g class is not a place :)
                element bf:eventPlace {          attribute rdf:resource {$uri}
                                }
      let $placesStrings:=
        for $s in $d/marcxml:subfield[@code="p"]
            return (: this in not really right; the g class is not a place :)
                element bf:eventPlace { element bf:Place{  
                                        element bf:label {fn:string($d/marcxml:subfield[@code="p"]) },
                                        for $sys-num in $d/marcxml:subfield[@code="0"] 
                                            return mbshared:handle-system-number($sys-num)
                                        }                             
                        }
return element bf:event { element bf:Event {
            $dates,
            $placesCodes,
            $placesStrings
            }
        }
};
(:555 finding aids note may be related work link or a simple property
sample bib 14923309
consider linking 555 w/856 on $u!
@param $d as datafield 555
:)
declare function mbshared:generate-finding-aid-work
    (
        $d as element(marcxml:datafield) 
    )
{ 	 
let $property-name := if ($d/@ind1="0") then "bf:findingAid"
                        else "bf:index"
 return element {$property-name}     
    {
        element bf:Work{ 
            element bf:authorizedAccessPoint {fn:string($d/marcxml:subfield[@code="a"])},
            element bf:title {fn:string($d/marcxml:subfield[@code="a"])},            
            if ($d/marcxml:subfield[@code="u"]) then
                    element bf:hasInstance {
                                element bf:Instance {
                                mbshared:handle-856u($d)           		        
                            }
                     }
             else ()
          }
     }  
   
};
(:
For RDA:   040$e = rda
For AACR2:  Leader/18 = a

Under AACR2, when two works were published together the first work in the compilation was given the 1XX/240, and the second work was given a 700 analytic (name/title).  This essentially resulted in identifying the aggregate work by only the first work in the compilation.
Under RDA, we identify the aggregate work in the 240 (not just one of the works), and provide analytical added entries (name/title) for the works in the compilation.
(245 would be the instance title, 240 the UT)
@param $d       as the datafield iwth the related work
@param $type    as the crosswalk node with instructions on what to match, output
@param $workID  as the main Work resource ID
:)
declare function mbshared:generate-related-work
    (
        $d as element(marcxml:datafield), 
        $type as element(),
        $workID as xs:string
    )
{ 	 

    let $titleFields := 
        if (fn:matches($d/@tag,"(630|730|740)")) then
            "(a|n|p)"            
        else if  (fn:matches($d/@tag,"(440|490|830)")) then
            "(a|n|p|v)"
        else if (fn:matches($d/@tag,"(534)")) then
            "(t|b|f|k)"
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
             mbshared:get-name($d/ancestor::marcxml:record/marcxml:datafield[fn:matches(@tag, "(100|110|111)")][1])               
        else if (  $d/marcxml:subfield[@code="a"]  and fn:not(fn:matches($d/@tag,"(400|410|411|440|490|800|810|811|510|630|730|740|830)")) ) then
        
                mbshared:get-name($d)
        else ()
    let $related-props:=mbshared:generate-simple-property($d,"related")
    
        
    let $aLabel := 
        fn:concat(
            fn:string(($name//bf:label)[1]),
            " ",
            $title
        )
    let $aLabel := fn:normalize-space($aLabel)
    
    let $aLabelWork880 := mbshared:generate-880-label($d,"title")
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
    
    let $inverse:= if  (fn:string($d/@tag)="774" ) then 
                        element bf:partOf { attribute rdf:resource  {$workID}
                        }
                    else ()
    return 
 	  element {fn:concat("bf:",fn:string($type/@property))} {
		element bf:Work {				
		element bf:title {$title},
            element bf:authorizedAccessPoint {$aLabel},
            $aLabelWork880,
            if ($d/marcxml:subfield[@code="w" or @code="x"] and fn:not($d/@tag="630")) then (:(identifiers):)
                for $s in $d/marcxml:subfield[@code="w" or @code="x" ]
  	              let $iStr :=  marc2bfutils:clean-string(fn:replace($s, "\(OCoLC\)", ""))
           	    return 
	                    if ( fn:contains(fn:string($s), "(OCoLC)" ) ) then	                                
	                           element bf:systemNumber {  attribute rdf:resource {fn:concat("http://www.worldcat.org/oclc/",fn:replace($iStr,"(^ocm|^ocn)","")) }}	                      
	                    else if ( fn:contains(fn:string($s), "(DLC)" ) ) then
	                        element bf:lccn { attribute rdf:resource {fn:concat("http://id.loc.gov/authorities/test/identifiers/lccn/",fn:replace( fn:replace($iStr, "\(DLC\)", "")," ",""))} }                	                    
	                    else if ($s/@code="x") then
	                       element bf:hasInstance{ 
	                               element bf:Instance{ 
	                               element bf:label {$title},
	                                   element bf:title {$title},
	                                   element bf:issn {attribute rdf:resource {fn:concat("urn:issn:", fn:replace(marc2bfutils:clean-string($iStr)," ","")) } }
	                              }
	                       }
		               else ()		               
     	   else 
     	       (),		            
            mbshared:generate-titleNonsort($d,$title, "bf:title"),            
            $name,
            $related-props,
            $inverse
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
declare function mbshared:process-isbns (
	$marcxml as element (marcxml:record)
) as element() {
    
    (:for books with isbns, generate all isbn10 and 13s from the data, list each pair on individual instances:)
    let $isbns:=$marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
    let $isbn-sets:=
        for $str in $isbns 
        let $isbn-str:=fn:normalize-space(fn:tokenize(fn:string($str),"\(")[1])
        return 
            element bf:isbn-pair {
                mbshared:get-isbn( marc2bfutils:clean-string( $isbn-str ) )/*
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
};
(:~
:   This is the function generates related item works.
: ex 710 constituent title with 880 : 15015234
:   @param  $marcxml        element is the MARCXML
:   @param  $workID        element is the main Work resource ID
:	@param  $resource      string is the "work" or "instance"
:   @return bf:* as element()
:)
declare function mbshared:related-works
    (
        $marcxml as element(marcxml:record),
        $workID as xs:string,
        $resource as xs:string
    ) as element ()*  
{ 
    
    let $relateds:= 
        if ($resource="instance") then 
            $mbshared:relationships/instance-relateds
        else 
            $mbshared:relationships/work-relateds
    
    let $relationship-source-tags:=$marcxml/marcxml:datafield[fn:matches(@tag,$relateds/@all-tags)]
    
    let $relateds :=     
        (:for $tagnum in $relationship-source-tags:)
            (:for $type in $relateds/type[@tag=$d/@tag]:)            
        	 (:return:)
        	if ($resource="instance" ) then
        	 for $d in $marcxml/marcxml:datafield[fn:matches(@tag,$relateds/@all-tags)]
        	   let $property:=$relateds/type[@tag=$d/@tag]/@property
        	    return mbshared:generate-related-instance($d,$property)
        	else
        	       (: title is in $a , @ind2 needs attention:)                
                ( 
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(730|740|780|785)")]
                return (
                    for $type in $relateds/type[fn:matches($d/@tag,@tag)][fn:matches(@ind2,$d/@ind2)] 
                        return mbshared:generate-related-work($d,$type, $workID)   )
                ,     	    
     	        for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(533)")]
     	          for $type in $relateds/type[@tag=$d/@tag]                		
			         return mbshared:generate-related-reproduction($d,$type)                                         
			    ,    
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(700|710|711,787)")][marcxml:subfield[@code="t"]]                                                       
                  for $type in $relateds/type[fn:matches($d/@tag,@tag)][fn:matches($d/@ind2,@ind2)] 
                     return      mbshared:generate-related-work($d,$type, $workID)                                                 
                ,                       
                for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(490|630|830)")][marcxml:subfield[@code="a"]]
                    for $type in $relateds/type[@tag=$d/@tag]                     	
			          return mbshared:generate-related-work($d,$type, $workID)
            ,
            (:else if ($marcxml/marcxml:datafield[@tag="534"][marcxml:subfield[@code="f"]]) then:)
            for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(534|775)")][marcxml:subfield[@code="t"]] 
                for $type in $relateds/type[@tag=$d/@tag]                    
			  	  return mbshared:generate-related-work($d,$type, $workID)      
			  	  )
            (:else, what's left??? need to figure out!! 2014-08-11
                for $type in $relateds/type[@tag=$marcxml/marcxml:datafield/@tag]
                    for $d in $marcxml/marcxml:datafield[fn:matches(fn:string($type/@tag),@tag)][marcxml:subfield[@code="t" or @code="s"]]                
			   	return mbshared:generate-related-work($d,$type, $workID)
			:)	
    return 
				$relateds
};
(:~
:   This is the function that generates an xml:lang attribute from the script and language
:
:   @param  $scr         string is from the subfield $6
:   @param  $lang         string is the from the 008 (or 040?)
:   @return bf:* as element()
:)
declare function mbshared:generate-xml-lang(
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
	       else ""
	    return   
            if ($script) then fn:concat($xml-lang,"-",$script) else $xml-lang
        };
(:~
:   This is the function that generates a work resource.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function mbshared:generate-work(
    $marcxml as element(marcxml:record),
    $workID as xs:string
    ) as element () 
{ (:2013-05-01 ntra moved instances inside work;  :)
     
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
				
    let $instances := mbshared:generate-instances($marcxml, $typeOf008, $workID)
    let $instancesfrom856:=
     if ( $marcxml/marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:not(fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i"))]) then         
        (:set up instances/annotations for each non-contributor bio link:)    
        for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:not(fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i"))]
            return mbshared:generate-instance-from856($d, $workID)            
        else 
            ()
    let $types := mbshared:get-resourceTypes($marcxml)
        
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
   
   let $events:= for $d in $marcxml/marcxml:datafield[@tag="033"]
                    return mbshared:generate-event($d)
    
    (: 
        Here's a thought. If this Work *isn't* English *and* it does 
        have a uniform title (240), we should probably figure out the 
        lexical value of the language code and append it to the 
        authoritativeLabel, thereby creating a type of expression.
    :)
                    
   let $langs := mbshared:get-languages ($marcxml)
   let $dissertation:= 
   	    for $diss in $marcxml/marcxml:datafield[@tag="502"]
      		return mbshared:generate-dissertation($diss)
    let $audience := fn:substring($cf008, 23, 1)
    let $audience := (: untorture this!   :)
        if ($audience ne "" and fn:matches($typeOf008, "(BK|CF|MU|V)")) then
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
            
     let $aud521:= 
     			for $tag in $marcxml/marcxml:datafield[@tag eq "521"]
     				return mbshared:get-521audience($tag) 
     			
     
    (: Don't be surprised when genre turns into "form" :)
    let $genre := fn:substring($cf008, 24, 1)
    (:$genre isn't working because $mainType=Work:)
    let $genre := 
        if ($genre ne "") then
            let $gen := fn:string($marc2bfutils:formsOfItems/type[@cf008-23 eq $genre and fn:contains(fn:string(@rType), $mainType)]) 
            return
                if ($gen ne "") then
                    element bf:genre {$gen}
                else ()
        else
            ()
                        
      let $work3xx := mbshared:generate-physdesc($marcxml,"work") (:336:)
      let $cartography:=  
                for $d in $marcxml/marcxml:datafield[@tag="255"] 
      			   return mbshared:generate-simple-property($d,"cartography")      				          
      				          

    let $abstract:= (:contentsNote:)
        for $d in  $marcxml/marcxml:datafield[@tag="520"][fn:not(marcxml:subfield[@code="c"]) and fn:not(marcxml:subfield[@code="u"])]
            return mbshared:generate-simple-property($d,"work")
	
    let $abstract-annotation:= 
        if    ($marcxml/marcxml:datafield[@tag="520"][marcxml:subfield[fn:matches(@code,"(c|u)")]] ) then
         mbshared:generate-abstract-annotation($marcxml,$workID)
            else ()
    
	let $work-identifiers := mbshared:generate-identifiers($marcxml,"work")
	let $general-notes := mbshared:generate-500notes($marcxml)
	let $work-classes := mbshared:generate-classification($marcxml,"work")
	
 	let $subjects:= 		 
 		for $d in $marcxml/marcxml:datafield[fn:matches(fn:string-join($marc2bfutils:subject-types//@tag," "),fn:string(@tag))]		
        			return mbshared:get-subject($d)
 	 	
 	let $findaids:= for $d in $marcxml/marcxml:datafield[fn:matches(@tag,"555")]
 	                  return if ($d/marcxml:subfield[@code="u"]) then 	                      
 	                              mbshared:generate-finding-aid-work($d)
 	                         else
 	                              mbshared:generate-simple-property($d,"findingaid")
 	let $work-relateds := mbshared:related-works($marcxml,$workID,"work") 	
 	
 	let $complex-notes:=              
 		 for $d in $marcxml/marcxml:datafield[@tag eq "505"][@ind2="0"]
 		     return mbshared:generate-complex-notes($d)
 	let $standalone-880s:=mbshared:generate-standalone-880( $marcxml ,"work")    
    
 	let $gacs:= 
            for $d in $marcxml/marcxml:datafield[@tag = "043"]/marcxml:subfield[@code="a"]
            (:filter out trailing hyphens:)
            	let $gac :=  fn:replace(fn:normalize-space(fn:string($d)),"-+$","")            	
	            return
	                element bf:subject { 	                
	                    attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/geographicAreas/", $gac) }	                
                   }
            		
    let $derivedFrom:= 
         element bf:derivedFrom {           
            attribute rdf:resource{fn:concat($workID,".marcxml.xml")}
        }
   
 	let $work-simples:=
 	  for $d in $marcxml/marcxml:datafield
 	      return mbshared:generate-simple-property($d,"work")
 	      
 	let $admin:=mbshared:generate-admin-metadata($marcxml, $workID) 
    return 
        element {fn:concat("bf:" , $mainType)} {
            attribute rdf:about {$workID},            
         
            for $t in fn:distinct-values($types)
            return             
                  element rdf:type {
                    attribute rdf:resource {fn:concat("http://bibframe.org/vocab/", $t)}
                },
             $aLabel,
            $aLabelsWork880,           
            $dissertation,             
            if ($uniformTitle/bf:workTitle) then
                $uniformTitle/*
            else
                $titles/bf:workTitle,                
       
            $names,            
            (:$addl-names,:)
            $events,
            $work-simples,
            $aud521,         
            $langs,
            $findaids,
            $abstract,
            $abstract-annotation,
            $audience,         
            $genre,       
            $general-notes,
            $cartography,
            $subjects,
            $gacs,            
            $work-classes,            
            $work-identifiers,                        
            $complex-notes,
            $standalone-880s,
            $work-relateds,      
            $derivedFrom,
            $hashable,
            $admin,
          
            for $i in $instances
                return element  bf:hasInstance{$i},
             $instancesfrom856
             
        }
        
};
(:~
:   This function generates  constituent (hasPart) works from 505
: 
:   LC often uses only $a, but stanford has  $g$t, and dave reser says he's seen [$g]$t[$r][$u] and $u is always last.
:   @param  $d        element is the marcxml:datafield  505
:   @return bf:hasPart*
:)
declare function mbshared:generate-complex-notes( 
  $d as element(marcxml:datafield)   
    ) as element()*
{
 			let $vernacular:= $d/ancestor::marcxml:record/marcxml:datafield[@tag="880"][fn:matches(marcxml:subfield[@code="6"],"^505-")]
 			    
 			let $sub-codes:= fn:distinct-values($d/marcxml:subfield[@code!="t"]/@code)
			let $return-codes := "gru"			
			let $set:=
				for $title at $x in $d/marcxml:subfield[@code="t"]
				    let $t := fn:replace(fn:string($title), " /", "")
                    let $vernacular-title:=
                        if ($vernacular) then                            
                            let $lang := fn:substring(fn:string($d/ancestor::marcxml:record/marcxml:controlfield[@tag="008"]), 36, 3)     
                            let $scr := fn:tokenize($vernacular/marcxml:subfield[@code="6"],"/")[2]
                            let $xmllang:= mbshared:generate-xml-lang($scr, $lang)
                           
                            return element bf:title {if ($xmllang) then attribute xml:lang{$lang} else (),
                                        fn:string($vernacular/marcxml:subfield[@code="t"][fn:position()=$x])
                                        }
                        else ()
                    let $details := 
                        element details {
                        (://for the set of subfields after this $t, up until there's a new $t
                        problem is, $g precedes $t? 
                        for each title t, get the immediate preceding $gs, if there, and the following $rs if it's there, and $u ??.
                        :)
                            for $subfield in ($title/preceding-sibling::marcxml:subfield[@code="g"][following-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)] 
                                | $title/following-sibling::marcxml:subfield[@code="r" or @code="u"][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)])
                                        (: the following is wrong, I think: assumes $t is first:
                                            for $subfield in $title/following-sibling::marcxml:subfield[@code!="t"][preceding-sibling::marcxml:subfield[@code="t"][1]=fn:string($title)]
                                        :)                
                                let $elname:=
                                    if ($subfield/@code="g") then "bf:note" 
                                    else if ($subfield/@code="r") then "bf:creator" 
                                    else if ($subfield/@code="u") then "rdf:resource" 
                                    else "bf:note" 
                                let $sfdata := fn:replace(fn:string($subfield), " --", "")
                                return
                                    if ($elname eq "rdf:resource") then
                                        element {$elname} { attribute rdf:resource {$sfdata} }
                                    else if ($elname eq "bf:creator") then
                                        if ( fn:contains($sfdata, ";") ) then
                                            (: we have multiples :)
                                            for $c in fn:tokenize($sfdata, ";")
                                            return mbshared:get-name-fromSOR($c,"bf:creator")
                                        else
                                            mbshared:get-name-fromSOR($sfdata,"bf:creator")
                                    else
                                        element {$elname} {$sfdata}
                            }
                  
                return 
                    element part {                   
                        $details/*       ,
                        element bf:title {$t},
                  
                         $vernacular-title
                                                  
                    }
		return						
                for $item in $set
                return
	                    element bf:hasPart {   
	                        element bf:Work {	                            
	                            $item/*
	                        }																								
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
:       1) Look for a title - take the 130 or 240 if it exists, otherwise use the 245.
:       2) Use only select subfields from 130, 240, or 245.  For example, only subfields a and b
:           used when evaluating the 245.
:       3) Grab all the names from the 1XX field and the 7XX fields.  Only use a given 7XX field if 
:           it represents a name (name/title 7XX fields, therefore, are not included)
:       4) Sort all the names alphabetically to help control for variation in how the data were 
:           originally entered.
:       5) Include the langauge from the 008.
:       6) Include the type of MARC resource (Text, Audio, etc)
:       7) Concatenate and normalize.  Normalization includes forcing the string to be all lower 
:           case, removing spaces, and removing all special characters.
: 

:   @param  $marcxml        element is the marcxml:datafield  
:   @return bf:authorizedAccessPoint
:)
declare function mbshared:generate-hashable(
    $marcxml as element(marcxml:record),
    $mainType as xs:string,
    $types as item()*
    ) as element( bf:authorizedAccessPoint)
{
let $hashableTitle := 
        let $uniform := ($marcxml/marcxml:datafield[@tag eq "130"]|$marcxml/marcxml:datafield[@tag eq "240"])[1]
        let $primary := $marcxml/marcxml:datafield[@tag eq "245"]
        let $t := 
            if ($uniform/marcxml:subfield[fn:not(fn:matches(@code,"(g|h|k|l|m|n|o|p|r|s|0|6|8)"))]) then
                (: We have a uniform title that contains /only/ a title and a date of work. :)
                fn:string-join($uniform/marcxml:subfield, " ")
            else
                (:  Otherwise, let's just use the 245 for now.  For example, 
                    we cannot create an uber work for Leaves of Grass. Selections.
                :)
                let $tstr := fn:string-join($primary/marcxml:subfield[fn:matches(@code, "a|b")], " ")
                let $tstr := 
                    if (fn:number($primary/@ind2) gt 0 ) then
                        (: Yep, there's a nonfiling marker. :)
                        fn:substring($tstr, fn:number($primary/@ind2)+1)
                    else
                        $tstr
                return $tstr
        let $t := marc2bfutils:clean-title-string($t)    
        return $t
    let $hashableNames := 
        (
            let $n := (:fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)") and marcxml:subfield[fn:not(fn:matches(@code,"(e|0|4|6|8)"))]][1]/marcxml:subfield, " "):)
            fn:string-join($marcxml/marcxml:datafield[fn:matches(@tag,"(100|110|111)")]/marcxml:subfield[fn:not(fn:matches(@code,"(e|0|4|6|8)"))] , " ")
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
    let $hashableLang := fn:normalize-space(fn:substring(fn:string($marcxml/marcxml:controlfield[@tag='008']), 36, 3))
    (:let $hashableTypes := fn:concat($mainType, fn:string-join($types, "")):)
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
(:~
:   This function generates a subject.
:   It takes a specific 6xx as input.
:   It generates a bf:subject as output.
: 
,

-:29 '600': ('subject', {'bibframeType': 'Person'}),
-:30 '610': ('subject', {'bibframeType': 'Organization'}),
-:31 '611': ('subject', {'bibframeType': 'Meeting'}),
-:33 '630': ('uniformTitle', {'bibframeType': 'Title'}),
-:34 '650': ('subject', {'bibframeType': 'Topic'}),
-:35 '651': ('subject', {'bibframeType': 'Geographic'}),



:   @param  $d        element is the marcxml:datafield  
:   @return bf:subject
:)
declare function mbshared:get-subject(
    $d as element(marcxml:datafield)
    ) as element()
{
    let $subjectType := fn:string($marc2bfutils:subject-types/subject[@tag=$d/@tag])
    let $subjectType:= if ($d[@tag="600"][marcxml:subfield[@code="t"]]) then "Work" else $subjectType
    let $details :=

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
                            $d/*[@code ne "2"][@code ne "0"][@code ne "8"]
                        }
                    }
                </marcxml:record>
            let $madsrdf := marcxml2madsrdf:marcxml2madsrdf($marcAuthXML)
            let $madsrdf := $madsrdf/madsrdf:*[1]
            let $details :=
                ( 
                    element bf:authorizedAccessPoint {fn:string($madsrdf/madsrdf:authoritativeLabel)},
                    element bf:label { fn:string($madsrdf/madsrdf:authoritativeLabel) },
                 if (   fn:not(fn:matches(fn:string-join($d/marcxml:subfield[@code="0"]," "),"(http://|\(uri\)|\(DE-588\))" ) ) ) then
                        element bf:hasAuthority {                                
                            element madsrdf:Authority {
                                element rdf:type {
                                    attribute rdf:resource { 
                                        fn:concat("http://www.loc.gov/mads/rdf/v1#" , fn:local-name($madsrdf))
                                    }
                                },                                
                                $madsrdf/madsrdf:authoritativeLabel                
                            }
                        }
                else ()
                                    
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
                    if (   fn:not(fn:matches(fn:string-join($d/marcxml:subfield[@code="0"]," "),"(http://|\(uri\)|\(DE-588\))" ) ) ) then                    
                        element bf:hasAuthority {
                             element madsrdf:Authority {
                              element madsrdf:authoritativeLabel{fn:string($aLabel)},
                                element madsrdf:componentList {
                                    attribute rdf:parseType {"Collection"},
                                    $components 
                                }
                            }
                        }
                    else ()
                )
            return $details
            (:656 occupation itoamc in $2? :)
       else
           (
               element bf:label {fn:string-join($d/marcxml:subfield[fn:not(@code="6")], " ")                                 
                            
                }
           )
	let $system-number:= 
        for $sys-num in $d/marcxml:subfield[@code="0"] 
                     return mbshared:handle-system-number($sys-num)  
    return 
        element bf:subject {
            element {fn:concat("bf:",$subjectType)} { 
                $details,                
                mbshared:generate-880-label($d,"subject"),
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
 

:   @param $marcxml       element is the marcxml:record  
:   @return wrap/bf:language* or wrap/bf:Language*

:)
   
declare function mbshared:get-languages(
   $marcxml as element(marcxml:record)
    ) as element()*
{
let $cf008 := fn:string($marcxml/marcxml:controlfield[@tag='008'])
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
      
    let $simple-a:=
        for $sfa in $marcxml/marcxml:datafield[@tag="041"]/marcxml:subfield[@code="a"]	     
           for $i in 0 to (fn:string-length($sfa) idiv 3)-1
                let $pos := $i * 3 + 1		
                return 
                    element bf:language{
                      attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , fn:substring($sfa, $pos, 3))}
                    }
     let $first-041a:= fn:string($simple-a[1]/@rdf:resource)
                        
    let $lang008 := fn:normalize-space(fn:substring($cf008, 36, 3))
    let $lang008 := 
        if ($lang008 ne "" and $lang008 ne "|||" and $lang008 ne fn:substring-after($first-041a,"/languages/")) then
            element bf:language {
                attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , $lang008) }
            }
        else
            ()
	let $parts:=
       	for $sf in $marcxml/marcxml:datafield[@tag="041"]/marcxml:subfield[fn:matches(@code,"(b|d|e|f|g|h|j|k|m|n)")] 
       	    return element bf:language {
	           element bf:Language {
	               element bf:resourcePart{
        	           fn:string($parts//sf[@code=$sf/@code])
        	           },	               	            
	                   for $i in 0 to (fn:string-length($sf) idiv 3)-1
		                  let $pos := $i * 3 + 1		
		                      return 
		                          element bf:languageOfPartUri{
		                            attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/" , fn:substring($sf, $pos, 3))}
    		                      },
                          if ($sf/../marcxml:subfield[@code="2"]) then
                            element bf:languageSource {fn:string($sf/../marcxml:subfield[@code="2"])}
                          else ()
                }	
	       }      
return 
    ($lang008,
    $simple-a,    
    $parts

   )
	       
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
declare function mbshared:get-name(
    $d as element(marcxml:datafield)     
    ) as element()*
{
    (:let $relatorCode := 
        if ($d/marcxml:subfield[@code = "4"]!="") then            
            marc2bfutils:chopPunctuation(marc2bfutils:clean-string(fn:string($d/marcxml:subfield[@code = "4"][1])),".")
        else 
            marc2bfutils:generate-role-code(fn:string($d/marcxml:subfield[@code = "e"][1]))
    :)  
    let $relatorCodes := 
        for $role in $d/marcxml:subfield[@code = "4" or @code = "e"]
          return 
            if (fn:string($role/@code) = "4" and fn:string($role)!="") then            
                marc2bfutils:chopPunctuation(marc2bfutils:clean-string(fn:string($role)),".")
            else 
                marc2bfutils:generate-role-code(marc2bfutils:clean-string(fn:string($role))) 
    
    let $label := if ($d/@tag!='534') then
    	fn:string-join($d/marcxml:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q' or @code='n'] , ' ')    	
    	else 
    	fn:string($d/marcxml:subfield[@code='a' ])
    	
    let $aLabel :=  marc2bfutils:clean-name-string($label)
    
    let $elementList := if ($d/@tag!='534'
    and   
    fn:not(fn:matches(fn:string-join($d/marcxml:subfield[@code="0"]," "),"(http://|\(uri\)|\(DE-588\))" ) ) ) then
    (:if there's a $0 uri, then we don't need the madsrdf:)
      element bf:hasAuthority{
         element madsrdf:Authority {
         element madsrdf:authoritativeLabel {$aLabel}
            }   
        }
    else () (: 534 $a is not parsed:)
            
    let $class := 
    if ( fn:ends-with(fn:string($d/@tag), "00")  and fn:string($d/@ind1)="3") then
            "bf:Family"
        else if ( fn:ends-with(fn:string($d/@tag), "00") ) then    
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
    let $resourceRoles :=    
        (:if ($relatorCode ne "") then:)
       ( if (fn:string-join($relatorCodes,"") = "") then        
            (: 
                k-note, added substring call because of cruddy data.
                record 16963854 had "aut 146781635" in it
                Actually, I'm going to undo this because this is a cataloging error
                and we want those caught.  was fn:substring($relatorCode, 1, 3))
            :)
           (: fn:concat("relators:" , $relatorCode):)
            if ( fn:starts-with($tag, "1") ) then
                "bf:creator"
            else if ( fn:starts-with($tag, "7") and $d/marcxml:subfield[@code="t"] ) then
                "bf:creator"
            else
                "bf:contributor"
        else    
            for $role in $relatorCodes[fn:string(.) !=""]
                    return fn:concat("relators:" , $role) 
        ) 
        
    (: resourceRole inside the authority makes it un-re-useable; removed 2013-12-03
    let $resourceRoleTerms := 
        for $r in $d/marcxml:subfield[@code="e"]
        return element bf:resourceRole {fn:string($r)}
:)
    let $bio-links:=
        if ( $d/../marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i")]) then         
        (:set up annotations for each contributor bio link:)    
        for $link in $d/../marcxml:datafield[fn:matches(@tag,"(856|859)")][fn:matches(fn:string(marcxml:subfield[@code="3"]),"contributor","i")]
            return     mbshared:generate-instance-from856($link, "person")            
        else 
            ()
    let $system-number:= 
        for $sys-num in $d/marcxml:subfield[@code="0"] 
                     return mbshared:handle-system-number($sys-num)            
    return
      
      for $role in  $resourceRoles
       return element {fn:string($role)} {
            element {$class} { 
                element bf:label { marc2bfutils:clean-name-string($label)},                
                if ($d/@tag!='534') then element bf:authorizedAccessPoint {$aLabel} else (),
                mbshared:generate-880-label($d,"name"),
                $elementList,                          
                 $system-number,                 
                 $bio-links                 
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
declare function mbshared:get-name-fromSOR(
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
                    element bf:label {$name}
                  (:  ,                  
                   resource role has got to be on the resource, in a note or something!  
                  if ($role ne "") then
                        element bf:resourceRole {$role}
                    else
                        ():)
                }
            }

}; 
(:~
:   This is the function gets the intendedaudience entity from 521.
:
:   @param  $tag        element is the datafield 521  
:   @return bf:* as element()
:)
declare function mbshared:get-521audience(
    $tag as element(marcxml:datafield)
    ) as item()*
{
element bf:intendedAudience {
		  element bf:IntendedAudience {
		      	   element bf:audience {fn:string($tag/marcxml:subfield[@code="a"])},
			     if ($tag/marcxml:subfield[@code="b"]) then  element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])} else ()	
	       }
	}
	(:
let $type:=  if ($tag/@ind1=" ") then "Audience: " else if ($tag/@ind1=" 0") then "Reading grade level" else if  ($tag/@ind1="1") then "Interest age level" else if  ($tag/@ind1="2") then "Interest grade level" else if  ($tag/@ind1="3") then "Special audience characteristics" else if  ($tag/@ind1="4") then "Motivation/interest level" else ()

return if ($type= "Audience: ") then
	if ( fn:not($tag/marcxml:subfield[@code="b"]) ) then
		element bf:intendedAudience {fn:concat($type,": ",$tag/marcxml:subfield[@code="a"])}
	else element bf:intendedAudience {
		  element bf:IntendedAudience {
		      	   element bf:audience {fn:concat($type,": ",$tag/marcxml:subfield[@code="a"])},
			       element bf:audienceAssigner{fn:string($tag/marcxml:subfield[@code="b"])}	
	}}
	else if ($type) then 
	element bf:intendedAudience {
		element bf:IntendedAudience {
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
:)
};
(:~
:   This is the function generates an Instance subclass.
:
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function mbshared:get-instanceTypes(
    $record as element(marcxml:record)
    ) as item()*
{
let $leader:=fn:string($record/marcxml:leader) 
let $leader06:=fn:substring($leader,7,1)
let $leader07:=fn:substring($leader,8,1)
let $leader08:=fn:substring($leader,9,1)
let $leader19:=fn:substring($leader,20,1)
    
let $types:=
    (	for $cf in $record/marcxml:controlfield[@tag="007"]/fn:substring(text(),1,1)
    		for $t in $marc2bfutils:instanceTypes/type[@cf007]
    			where fn:matches($cf,$t/@cf007) 
    				return fn:string($t),    	

    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="a"]    		
    		for $t in $marc2bfutils:instanceTypes/type[@sf336a]
    			where fn:matches(fn:string($field),$t/@sf336a) 
    				return fn:string($t),   				

    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="b"]    		
    		for $t in $marc2bfutils:instanceTypes/type[@sf336b]
    			where fn:matches(fn:string($field),$t/@sf336b)
    				return fn:string($t),     				
    
    	for $t in $marc2bfutils:instanceTypes/type
        		where $t/@leader6 eq $leader06
        		return fn:string($t),
        for $t in $marc2bfutils:instanceTypes/type
        		where $t/@leader8 eq $leader08
        		return fn:string($t),
        if (fn:matches($leader07,"(a|m)") and fn:not($leader19="a")) then "Monograph" 
            else if (fn:matches($leader07,"(a|m)") and $leader19="a") then "Multipart monograph"
            else (),                 
        if ($leader07='s')           		then "Serial"           	
           	else if ($leader07='i') 				   	then "Integrating"           	
           	else (),
            if (fn:matches($leader07,"(c|d)"))	then "Collection" else (),
            if (fn:matches($leader06,"(d|f|t)"))	then "Manuscript" else (),
            if ($leader08="a")	then "Archival" else ()                        
         
	)
    return $types
    
};
(:~
:   This is the function generates a work subclass.
: test on this bib id : 11510969
:   @param  $marcxml        element is the MARCXML  
:   @return bf:* as element()
:)
declare function mbshared:get-resourceTypes(
    $record as element(marcxml:record)
    ) as item()*
{

    let $leader06 := fn:substring(fn:string($record/marcxml:leader), 7, 1)   
    let $types:=
    (	for $cf in $record/marcxml:controlfield[@tag="007"]/fn:substring(text(),1,1)
    (:00 - Category of material :)
    		for $t in $marc2bfutils:resourceTypes/type[@cf007]
    			where fn:matches($cf,$t/@cf007) 
    				return fn:string($t)    ,	

    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="a"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf336a]
    			where fn:matches(fn:string($field),$t/@sf336a) 
    				return fn:string($t),   				

    	for $field in $record/marcxml:datafield[@tag="336"]/marcxml:subfield[@code="b"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf336b]
    			where fn:matches(fn:string($field),$t/@sf336b)
    				return fn:string($t), 
    				
    
    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="a"]		
    		for $t in $marc2bfutils:resourceTypes/type[@sf337a]
    			where fn:matches(fn:string($field),$t/@sf337a)
    				return fn:string($t) ,   	

    	for $field in $record/marcxml:datafield[@tag="337"]/marcxml:subfield[@code="b"]    		
    		for $t in $marc2bfutils:resourceTypes/type[@sf337b]
    			where fn:matches(fn:string($field),$t/@sf337b)
    				return fn:string($t)  ,  	    
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
:   @param  $domain   "work" or "instance" to name the property
:
:   @return  sequence of bf:title, workTitle, instanceTitle, nonsort, sysnum etc.
: drop the $h from the work title????
:)
declare function mbshared:get-title(
            $d as element(marcxml:datafield),
            $domain as xs:string
        ) 
{
        
    let $title := fn:replace(fn:string($d/marcxml:subfield[@code="a"]),"^(.+)/$","$1")
    let $title := 
        if (fn:ends-with($title, ".")) then
            fn:substring($title, 1, fn:string-length($title) - 1 )
        else
            $title
     let $title := fn:normalize-space($title)
     
     let $element-name :=
            if (fn:matches(fn:string($d/@tag),"(246|247|242)" )) then 
                "bf:titleVariation" 
            else  if ($d/@tag = "222" ) then
                "bf:keyTitle" 
            else  if ($d/@tag ="210" ) then
                "bf:abbreviatedTitle"
            else if ($domain="work") then
                "bf:workTitle"
            else (:245:)
                "bf:instanceTitle"
                
       let $lang-attribute := if ($d/@tag = "242" and $d/marcxml:subfield[@code = "y"] ne "" ) then                            
                        attribute xml:lang {fn:string($d/marcxml:subfield[@code = "y"][1])}
                    else
                        ()
        let $title-type:=            
            if (fn:matches($d/@tag , "(242|246|247)")) then
              if ($d/@tag="242") then "Translated title"
              else if ($d/@tag="247") then "Former title"
              else  (:246 :)        
                if ($d/@ind2=" "  and $d/marcxml:subfield[@code = "i"]) then
                    fn:string($d/marcxml:subfield[@code = "i"])
                 else if ($d/@ind2="0") then "portion"
                 else if ($d/@ind2="1") then "parallel"
                 else if ($d/@ind2="2") then "distinctive"                 
                 else if ($d/@ind2="4") then "cover"                 
                 else if ($d/@ind2="6") then "caption"
                 else if ($d/@ind2="7") then "running"
                 else if ($d/@ind2="8") then "spine"    
                 else ()
            else
                ""
       let $constructed-title:=
       element {$element-name} {
                element bf:Title { 
                 if ($title-type ne "") then                      
                      element bf:titleType {$title-type}                                                      
                 else (),                     
                 mbshared:generate-simple-property($d,"title"),                 
                 mbshared:generate-880-label($d,"title")
                }
             } (:end Title:)
             
    return 
        ( (:element bf:title {  $lang-attribute, $title },  :)
            (:this is wasteful if there's only an $a, but there is no simple string property for keytitle etc.:)
            $constructed-title,
            mbshared:generate-titleNonsort($d,$title, $element-name),       
            (:mbshared:generate-880-label($d,"title"),:)
              for $sys-num in $d/marcxml:subfield[@code="0"] 
                     return mbshared:handle-system-number($sys-num)  
        )
};
(:~
:   This function generates a related work (rda expression?), as translation of from the 100, 240.
:   It takes a 130 or 240 element.
:   It generates a bf:translationOf/bf:Work
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:translationOf
:)
declare function mbshared:generate-translationOf (    $d as element(marcxml:datafield)
    ) as element( bf:translationOf)
    
{
  (:let $aLabel :=  marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[fn:not(fn:matches(@code,"(0|6|8|l)") ) ]," ")):)    
  let $aLabel :=  marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[fn:matches(@code,"(a|d|f|g|h|k)")  ]," "))
  return    element bf:translationOf {     
            element bf:Work {
                              
                element bf:title {$aLabel},
                mbshared:generate-titleNonsort($d,$aLabel,"bf:title") ,                                    
                element madsrdf:authoritativeLabel{$aLabel},                               
                element bf:authorizedAccessPoint {$aLabel},
                
                if ($d/../marcxml:datafield[@tag="100"]) then
                    element bf:creator{ 
                            element bf:Agent {
                                element bf:label {fn:string($d/../marcxml:datafield[@tag="100"]/marcxml:subfield[@code="a"])}
                            }
                    }                    
                else ()
             }
       }
       
               
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
declare function mbshared:generate-simple-property(
    $d as element(marcxml:datafield)*,
    $domain as xs:string
    )
{
(:all the nodes in this domain with this datafield's tag, where there's no @ind1 or it matches the datafield's, and no ind2 or it matches the datafields:)
  for $node in  $mbshared:simple-properties//node[fn:string(@domain)=$domain][@tag=$d/@tag][ fn:not(@ind1) or @ind1=$d/@ind1][ fn:not(@ind2) or @ind2=$d/@ind2]
    let $return-codes:=	if ($node/@sfcodes) then fn:string($node/@sfcodes)	else "a"
    let $startwith:=fn:string($node/@startwith) 
 
    return 
      if ( $d/marcxml:subfield[fn:contains($return-codes,@code)] ) then
        let $text:= if (fn:string-length($return-codes) > 1) then 
                        let $stringjoin:= if ($node/@stringjoin) then fn:string($node/@stringjoin) else " "
                        return   element wrap{ marc2bfutils:clean-string(fn:string-join($d/marcxml:subfield[fn:contains($return-codes,@code)],$stringjoin))}
                    else
                        for $s in $d/marcxml:subfield[fn:contains($return-codes,@code)]
                            return element wrap{ marc2bfutils:clean-string(fn:string($s))}
                 
       return
           for $i in $text
                     return  
                     element {fn:concat("bf:",fn:string($node/@property))} {
                                (:for identifiers, if it's oclc and there's an oclc id (035a) return attribute/uri, else return bf:Id:)
                         if (fn:string($node/@group)="identifiers") then
                                if (fn:starts-with($i,"(OCoLC)") and fn:contains($node/@uri,"worldcat") ) then
                                    let $s :=  marc2bfutils:clean-string(fn:replace($i, "\(OCoLC\)", ""))
                                    return attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($s,"(^ocm|^ocn)",""))  }
                                else
                                     element bf:Identifier { 
                                                element bf:identifierValue {fn:normalize-space(fn:concat($startwith,  $i) )},
                                                element bf:identifierScheme {fn:string($node/@property)}
                                                }                        
                         (:non-identifiers:)
                         else if (fn:not($node/@uri)) then 
                              fn:normalize-space(fn:concat($startwith,  $i) )    	                
                         (:nodes with uris: :)
                         else if (fn:contains(fn:string($node/@uri),"loc.gov/vocabulary/organizations")) then                         
                                let $s:=fn:lower-case(fn:normalize-space($i))
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
        
     else (:no matching nodes for this datafield:)
        ()      
   
};
(:~
:   This is the function generates a literal property or simple uri from a string, using the nodes xml
:   Example of usage: you need to convert the content of a subfield  before treating it like it's supposed to be treated.
:    338 $a is the literal string, but you need the code, so you have to look it up.
let $code :=marc2bfutils:generate-carrier-code("volume")
mbshared:generate-property-from-text("338","a",$code,"work")
   
:       Options in this function are a prefix, (@startwith), indicator2, and concatenation of multiple @sfcodes.
:       If @ind2 is absent on the node, there is no test, otherwise it must match the datafield @ind2
:   <node domain="work" tag ="505" property="contents" ind2=" " sfcodes="agrtu" >Formatted Contents Note</note>
:
:   @param  $d        element is the MARCXML tag
:   @param  $sfcodes       element is the marcxml subfield set that are included
:   @param  $domain       element is the domain for this element.
:                         
:   @return bf:* as element()
: 
:)
declare function mbshared:generate-property-from-text(
    $tag as xs:string,
    $sfcodes as xs:string,
    $text as xs:string,
    $domain as xs:string
    ) as element ()*
{
for $node in  $mbshared:simple-properties//node[fn:string(@domain)=$domain][@tag=$tag][fn:contains(fn:string(@sfcodes),$sfcodes) or @sfcodes="" or $sfcodes=""]
    let $return-codes:=
 			if ($node/@sfcodes) then fn:string($node/@sfcodes) 		else "a"
    let $startwith:=fn:string($node/@startwith) 
 
    return            
       element {fn:concat("bf:",fn:string($node/@property))} {	               
                 if (fn:not($node/@uri)) then
                      fn:normalize-space(fn:concat($startwith,  $text)     )    	                
                 else if (fn:contains(fn:string($node/@uri),"loc.gov/vocabulary/organizations")) then
                        let $text:=fn:lower-case(fn:normalize-space($text))
                        return attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($text,"-",""))}
                 else if (fn:contains(fn:string($node/@property),"lccn")) then
                         attribute rdf:resource{fn:concat(fn:string($node/@uri),fn:replace($text," ",""))
                         }                 
                 else
                         attribute rdf:resource{fn:concat(fn:string($node/@uri),$text)}
       } 
};
(:~
:   This function generates a Work based on the uniformTitle.
:   It takes a specific datafield (130 or 240) as input.
:   It generates a bf:Work as output.
:
:   @param  $d        element is the marcxml:datafield  
:   @return bf:Work
:)
declare function mbshared:get-uniformTitle(
    $d as element(marcxml:datafield)
    ) as element(bf:Work)
{
    (:let $label := fn:string($d/marcxml:subfield["a"][1]):)
    (:??? filter out nonsorting chars??? 880s?:)
    
    let $aLabel := marc2bfutils:clean-title-string(fn:string-join($d/marcxml:subfield[@code ne '0' and @code!='6' and @code!='8'] , ' '))       
    let $translationOf := 
        if ($d/marcxml:subfield[@code="l"]) then
            (for $s in  $d/marcxml:subfield[@code="l"]
                  let $lang:= (:some have 2 codes german = deu, ger :)
                    $marc2bfutils:lang-xwalk/language[@language-name=marc2bfutils:chopPunctuation($s,".")]/iso6392[1]
                  return if ($lang!="") then element bf:language { 
                                                attribute rdf:resource { fn:concat("http://id.loc.gov/vocabulary/languages/",$lang)}
                                              }
         else element bf:languageNote {marc2bfutils:clean-string($s)},
          mbshared:generate-880-label($d,"title"),
   
         mbshared:generate-translationOf($d)
        )
                else ()
                   
    let $title-nonsort:=mbshared:generate-titleNonsort($d,$aLabel,"bf:title")
    let $ut-local-id:=if ($d/marcxml:subfield[@code = '0' ]) then
                        element bf:identifier {
                            element bf:Identifier {
                                element bf:identifierValue {fn:string($d/marcxml:subfield[@code = '0' ])},
                                element bf:identifierScheme {"local"}
                                }
                        }
                        
    else ()
  
    return
    
        element bf:Work {
                   (:element bf:label {$aLabel},:)
                     element madsrdf:authoritativeLabel{ fn:string($aLabel)},
	  		       $title-nonsort,                      
                   element bf:workTitle {element bf:Title{ mbshared:generate-simple-property($d,"title")}},               
                   $ut-local-id,
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

declare function mbshared:get-isbn($isbn as xs:string ) as element() {
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
            }

};
(:~
:   This function validates lc class  content
:
:  $string    is the string content of the 050a as stripped to be compared
:   @return xs:string content or null
:)
declare function mbshared:validate-lcc(
       $string  as xs:string    
    ) as xs:boolean 
{
let $validLCCs:=("DAW","DJK","KBM","KBP","KBR","KBU","KDC","KDE","KDG","KDK","KDZ","KEA","KEB","KEM","KEN","KEO","KEP","KEQ","KES","KEY","KEZ","KFA","KFC","KFD","KFF","KFG","KFH","KFI","KFK","KFL","KFM","KFN","KFO","KFP","KFR","KFS","KFT","KFU","KFV","KFW","KFX","KFZ","KGA","KGB","KGC","KGD","KGE","KGF","KGG","KGH","KGJ","KGK","KGL","KGM","KGN","KGP","KGQ","KGR","KGS","KGT","KGU","KGV","KGW","KGX","KGY","KGZ","KHA","KHC","KHD","KHF","KHH","KHK","KHL","KHM","KHN","KHP","KHQ","KHS","KHU","KHW","KJA","KJC","KJE","KJG","KJH","KJJ","KJK","KJM","KJN","KJP","KJR","KJS","KJT","KJV","KJW","KKA","KKB","KKC","KKE","KKF","KKG","KKH","KKI","KKJ","KKK","KKL","KKM","KKN","KKP","KKQ","KKR","KKS","KKT","KKV","KKW","KKX","KKY","KKZ","KLA","KLB","KLD","KLE","KLF","KLH","KLM","KLN","KLP","KLQ","KLR","KLS","KLT","KLV","KLW","KMC","KME","KMF","KMG","KMH","KMJ","KMK","KML","KMM","KMN","KMP","KMQ","KMS","KMT","KMU","KMV","KMX","KMY","KNC","KNE","KNF","KNG","KNH","KNK","KNL","KNM","KNN","KNP","KNQ","KNR","KNS","KNT","KNU","KNV","KNW","KNX","KNY","KPA","KPC","KPE","KPF","KPG","KPH","KPJ","KPK","KPL","KPM","KPP","KPS","KPT","KPV","KPW","KQC","KQE","KQG","KQH","KQJ","KQK","KQM","KQP","KQT","KQV","KQW","KQX","KRB","KRC","KRE","KRG","KRK","KRL","KRM","KRN","KRP","KRR","KRS","KRU","KRV","KRW","KRX","KRY","KSA","KSC","KSE","KSG","KSH","KSK","KSL","KSN","KSP","KSR","KSS","KST","KSU","KSV","KSW","KSX","KSY","KSZ","KTA","KTC","KTD","KTE","KTF","KTG","KTH","KTJ","KTK","KTL","KTN","KTQ","KTR","KTT","KTU","KTV","KTW","KTX","KTY","KTZ","KUA","KUB","KUC","KUD","KUE","KUF","KUG","KUH","KUN","KUQ","KVB","KVC","KVE","KVH","KVL","KVM","KVN","KVP","KVQ","KVR","KVS","KVU","KVW","KWA","KWC","KWE","KWG","KWH","KWL","KWP","KWQ","KWR","KWT","KWW","KWX","KZA","KZD","AC","AE","AG","AI","AM","AN","AP","AS","AY","AZ","BC","BD","BF","BH","BJ","BL","BM","BP","BQ","BR","BS","BT","BV","BX","CB","CC", "CD","CE","CJ","CN","CR","CS","CT","DA","DB","DC","DD","DE","DF","DG","DH","DJ","DK","DL","DP","DQ","DR","DS","DT","DU","DX","GA","GB","GC","GE","GF","GN","GR","GT","GV","HA","HB","HC","HD","HE","HF","HG","HJ","HM","HN","HQ","HS","HT","HV","HX","JA","JC","JF","JJ","JK","JL","JN","JQ","JS","JV","JX","JZ","KB","KD","KE","KF","KG","KH","KJ","KK","KL","KM","KN","KP","KQ","KR","KS","KT","KU","KV","KW","KZ","LA","LB","LC","LD","LE",  "LF","LG","LH","LJ","LT","ML","MT","NA","NB","NC","ND","NE","NK","NX","PA","PB","PC","PD","PE","PF","PG","PH","PJ","PK","PL","PM","PN","PQ","PR","PS","PT","PZ","QA","QB","QC","QD","QE","QH","QK","QL","QM","QP","QR","RA","RB","RC","RD","RE","RF","RG",   "RJ","RK","RL","RM","RS","RT","RV","RX","RZ","SB","SD","SF","SH","SK","TA","TC","TD","TE","TF","TG","TH","TJ","TK","TL","TN","TP","TR","TS","TT","TX","UA","UB","UC","UD","UE","UF","UG","UH","VA","VB","VC","VD","VE","VF","VG","VK","VM","ZA","A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","Z")
return  
    if ($string = $validLCCs)  then   								  
           fn:true()
        else (:invalid content in sfa:)
            fn:false() 
};
(:~
:   This function generates uris to ddc, nlm,lcc classifications or a Classification node
:    classificationItem is retained, even though it looks like holdings data.
:  $marcxml    is marcxml:record
:  $resource is work or instance
:   @return ??
:)
declare function mbshared:generate-classification(
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
   
    return
       ( for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(060|061)")]
             for $cl in $this-tag/marcxml:subfield[@code="a"]
                let $class:= fn:tokenize(fn:string($cl),' ')[1]
                return	 
                    element  bf:classificationNlm{                            			
                        attribute rdf:resource {fn:concat( "http://nlm.example.org/classification/",fn:normalize-space($class))
                        }
                    },
            for $this-tag in $marcxml/marcxml:datafield[@tag="052"] return mbshared:generate-simple-property($this-tag ,"classification")     ,
           for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"086")][marcxml:subfield[@code="z"]]
             return
                   element bf:classification {
                               element bf:Classification {                        
                                 	if ($this-tag[@ind1=" "] and $this-tag/marcxml:subfield[@code="2"] ) then
                                 	       element bf:classificationScheme {fn:string($this-tag/marcxml:subfield[@code="2"])}
                                 	else if ($this-tag[@ind1="0"]  ) then  
                                 	      element bf:classificationScheme {"SUDOC"}
                                 	else if ($this-tag[@ind1="1"]  ) then  
                                 	      element bf:classificationScheme {"Government of Canada classification"}
                                 	  else (),
                                 	element bf:classificationNumber {  fn:string($this-tag/marcxml:subfield[@code="z"])},
					 		        element bf:classificationStatus  {"canceled/invalid"}
					 		}
					}
                 ,
                     
        (:for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|055|070|080|082|083|084|086)")]                            
                for $cl in $this-tag/marcxml:subfield[@code="a"]           
                	let $valid:=
                	 	if (fn:not(fn:matches($this-tag/@tag,"(050|055)"))) then
                			fn:string($cl)
                		else 
                  			let $strip := fn:replace(fn:string($cl), "(\s+|\.).+$", "")			
                  			let $subclassCode := fn:replace($strip, "\d", "")			
                  			return                   		            
        			            
        			            if ( mbshared:validate-lcc($subclassCode))        			              
        			                 then   								  
        			                fn:string($strip)
        			            else 
        			                ():) 
        	  for $this-tag in $marcxml/marcxml:datafield[fn:matches(@tag,"(050|055|070|080|082|083|084|086|090)")]                            
                for $cl in $this-tag/marcxml:subfield[@code="a"]           
                	let $valid:=
                	 	if (fn:not(fn:matches($this-tag/@tag,"(050|055)"))) then
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
                     		    else	if ($property="classificationDdc" ) then 
                     		             attribute rdf:resource {fn:concat("http://dewey.info/class/",fn:normalize-space(fn:encode-for-uri($this-tag/marcxml:subfield[@code="a"])),"/about")}
                     		    else element bf:Classification {
                                        element bf:classificationNumber {fn:string($cl)},
                                if ($this-tag[@tag="086"] and $this-tag[@ind1=" "] and $this-tag/marcxml:subfield[@code="2"] ) then
                                 	       element bf:classificationScheme {fn:string($this-tag/marcxml:subfield[@code="2"])}
                                 	else if ($this-tag[@tag="086"] and $this-tag[@ind1="0"]  ) then  
                                 	      element bf:classificationScheme {"SUDOC"}
                                 	else if ($this-tag[@tag="086"] and $this-tag[@ind1="1"]  ) then  
                                 	      element bf:classificationScheme {"Government of Canada classification"}
                                 	  else 
                                        element bf:classificationScheme {fn:string($classes[@level="property"][fn:contains(@tag,$this-tag/@tag)]/@name)}                                        
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
                                if (fn:matches($this-tag/@tag,"(050|090)"))     then element bf:classificationScheme {"lcc"} 
                                   else if (fn:matches($this-tag/@tag,"080"))      then element bf:classificationScheme {"nlm"}
                                   else if (fn:matches($this-tag/@tag,"080"))      then element bf:classificationScheme {"udc"}                                   
                                   else if (fn:matches($this-tag/@tag,"082"))      then element bf:classificationScheme {"ddc"}
                                   (:nal??:)
                                   else if (fn:matches($this-tag/@tag,"(084|086)") and $this-tag/marcxml:subfield[@code="2"] ) then element bf:classificationScheme {fn:string($this-tag/marcxml:subfield[@code="2"])}
                                   else ()
                               ,                        
                                if (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="m"] ) then
                                    element bf:classificationDesignation  {
                                        if ($this-tag/marcxml:subfield[@code="m"] ="a") then "standard" 
                                        else if ($this-tag/marcxml:subfield[@code="m"] ="b") then "optional" 
                                        else ()
                                    }
                                else (),                                    
                     	       element bf:classificationNumber {fn:string($cl)},
                     	       element bf:label {fn:string($cl)},
                      	       if ( $assigner) then 
                      	         (:assigner is string, not uri:)
                                  	(:(element bf:classificationAssigner {attribute rdf:resource {fn:concat("http://id.loc.gov/vocabulary/organizations/",fn:encode-for-uri($assigner))}}:)
                                  	(element bf:classificationAssigner {$assigner}
                                  	(: does this work ? can't find example:
                                  	,mbshared:generate-property-from-text($this-tag,"",$assigner,"classification"):)
                                  	)
                                else (),             			
         			            	
                    	       if ( 
                      		    (fn:matches($this-tag/@tag,"(080|082|083)") and fn:matches($this-tag/@ind1,"(0|1)") ) or 
                      		    (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="2"] )
                     	 		   ) then  
                     	 		       let $this-edition:=                                     
                                         if (fn:matches($this-tag/@tag,"(080|082|083)") and $this-tag/@ind1="1") then
         								    "abridged"
                                         else if (fn:matches($this-tag/@tag,"(080|082|083)") and $this-tag/@ind1="0") then							
         								    "full"
         								else if (fn:matches($this-tag/@tag,"(082|083)") and $this-tag/marcxml:subfield[@code="2"] ) then
         								    fn:string($this-tag/marcxml:subfield[@code="2"] )
         								else ()
         							  return if ($this-edition ne "") then
         								   mbshared:generate-property-from-text(fn:string($this-tag/@tag),"",$this-edition,"classification")
         								   else ()
         							
                                 else (),
         						 for $d in $this-tag[@tag="083"] return mbshared:generate-simple-property($d,"classification")                           
                    }
            }
     else ()
                        
   )                        
};
