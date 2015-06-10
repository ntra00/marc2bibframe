xquery version "1.0";

(:
:   Module Name: MARCXML to 2MADSRDF
:
:   Module Version: 1.0
:
:   Date: 2010 Oct 18
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Primary purpose is to transform MARCXML 
:       authority to MADSRDF.  This will result in a verbose 
:       MADS/RDF record, and one without any linked relationships.
:
: Change Log:
	2012 Aug 28 Nate Trail added collection for undifferentiated names (008/32='b') 
	2012 Sep 12 Nate Trail added collection for FRBR Work and FRBR Expression, and changed the "may subdivide Geographically" label and name
	2012 Sep 20 Nate Trail added collection for FRBR Expression for musical arrangements
	2012 Oct 16 Nate Trail suppressed $6 from labels (880 mapping)
:)
   
(:~
:   This module transforms a MARCXML authority to MADSRDF.  This
:   will result in a verbose MADS/RDF record, and one without any
:   linked relationships.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since October 18, 2010
:   @version 1.0
:)
module namespace  marcxml2madsrdf      = "info:lc/id-modules/marcxml2madsrdf#";


(: MODULES :)
import module namespace marcxml2recordinfo = "info:lc/id-modules/recordInfoRDF#" at "module.MARCXML-2-RecordInfoRDF.xqy";


(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace madsrdf       = "http://www.loc.gov/mads/rdf/v1#";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace owl           = "http://www.w3.org/2002/07/owl#";
declare namespace identifiers   = "http://id.loc.gov/vocabulary/identifiers/";
(:declare namespace xdmp      = "http://marklogic.com/xdmp";:)


(: VARIABLES :)
declare variable $marcxml2madsrdf:authSchemeMap := (
        <authSchemeMaps>
            <authScheme abbrev="subjects">authorities/subjects/</authScheme>
            <authScheme abbrev="childrensSubjects">authorities/childrensSubjects/</authScheme>
            <authScheme abbrev="genreForms">authorities/genreForms/</authScheme>
            <authScheme abbrev="names">authorities/names/</authScheme>
            <authScheme abbrev="empty">authorities/empty/</authScheme>
        </authSchemeMaps>
    );
(:http://id.loc.gov/authorities/names/no2007025470.marcxml.xml:)
declare variable $marcxml2madsrdf:authTypeMap := (<authTypeMaps>
        <type tag="100" count="1" code="a" variant="madsrdf:PersonalName">madsrdf:PersonalName</type>
        <type tag="100" count="2" code="cdgq" variant="madsrdf:PersonalName">madsrdf:PersonalName</type>
        <type tag="100" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type> (: Would title ever not be in the second position?  Is it still an NT when there is a third term, a form subdivision? :)                  
        <type tag="100" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="110" count="1" code="a" variant="madsrdf:CorporateName">madsrdf:CorporateName</type>
        <type tag="110" count="2" code="bcdg" variant="madsrdf:CorporateName">madsrdf:CorporateName</type>
        <type tag="110" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type> (: this implies that t is the second component :)
        <type tag="110" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="111" count="1" code="a" variant="madsrdf:ConferenceName">madsrdf:ConferenceName</type>
        <type tag="111" count="2" code="cdgq" variant="madsrdf:ConferenceName">madsrdf:ConferenceName</type>
        <type tag="111" count="2" code="t" variant="madsrdf:NameTitle">madsrdf:NameTitle</type>
        <type tag="111" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="130" equivalent="t" count="1" code="a" variant="madsrdf:Title">madsrdf:Title</type> (: UniformTitle - this could have any number of code fields in it :)
        <type tag="130" count="2" code="d" variant="madsrdf:Title">madsrdf:Title</type> (: UniformTitle - this could have any number of code fields in it :)
        <type tag="130" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: UniformTitle - this could have any number of code fields in it :)
        
        <type tag="148" equivalent="y" count="1" code="a" variant="madsrdf:Temporal">madsrdf:Temporal</type>
        <type tag="148" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type> (: loads of codes :)
        
        <type tag="150" equivalent="x" count="1" code="a" variant="madsrdf:Topic">madsrdf:Topic</type>
        <type tag="150" count="2" code="bvxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="151" equivalent="z" count="1" code="a" variant="madsrdf:Geographic">madsrdf:Geographic</type>
        <type tag="151" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="155" equivalent="v" count="1" code="a" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="155" equivalent="p" count="1" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="155" count="2" code="vxyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="180" count="1" code="x" variant="madsrdf:Topic">madsrdf:Topic</type>
        <type tag="180" count="2" code="vyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>

        <type tag="181" count="1" code="z" variant="madsrdf:Geographic">madsrdf:Geographic</type>
        <type tag="181" count="2" code="vxy" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="182" count="1" code="y" variant="madsrdf:Temporal">madsrdf:Temporal</type>
        <type tag="182" count="2" code="vxz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
        
        <type tag="185" count="1" code="v" variant="madsrdf:GenreForm">madsrdf:GenreForm</type>
        <type tag="185" count="2" code="xyz" variant="madsrdf:ComplexSubject">madsrdf:ComplexSubject</type>
    </authTypeMaps>);
    
declare variable $marcxml2madsrdf:elementTypeMap := (
    <elementTypeMaps>
        <elementType tag_suffix="00" code="a">madsrdf:FullNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="c">madsrdf:TermsOfAddressNameElement</elementType>
        <elementType tag_suffix="00" code="a" ancillary="q">madsrdf:FullNameElement</elementType>
        <elementType tag_suffix="00" code="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="r">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="g">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="f">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="m">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="o">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="00" code="t" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="00" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="00" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="00" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="00" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="10" code="a">madsrdf:NameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="b">madsrdf:NameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="10" code="a" ancillary="k">madsrdf:NamePartElement</elementType>
        <elementType tag_suffix="10" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="r">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="g">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="10" code="t" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="10" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="10" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="10" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="10" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="11" code="a">madsrdf:NameElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="c">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="d">madsrdf:DateNameElement</elementType>
        <elementType tag_suffix="11" code="a" ancillary="e">madsrdf:NameElement</elementType>
        <elementType tag_suffix="11" code="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="c">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="11" code="t" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="11" code="p">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="11" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="11" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="11" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="30" code="a">madsrdf:MainTitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="d">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="f">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="n">madsrdf:PartNumberElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="p">madsrdf:PartNameElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="t">madsrdf:TitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="l">madsrdf:LanguageElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="s">madsrdf:SubTitleElement</elementType>
        <elementType tag_suffix="30" code="a" ancillary="k">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="30" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="30" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="30" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="30" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="48" code="a">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="48" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="48" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="48" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="48" code="z">madsrdf:GeographicElement</elementType>
                
        <elementType tag_suffix="50" code="a">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="a" ancillary="b">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="50" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="50" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="50" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="51" code="a">madsrdf:GeographicElement</elementType>
        <elementType tag_suffix="51" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="51" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="51" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="51" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="55" code="a">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="55" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="55" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="55" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="55" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="80" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="80" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="80" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="80" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="81" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="81" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="81" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="81" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="82" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="82" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="82" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="82" code="z">madsrdf:GeographicElement</elementType>
        
        <elementType tag_suffix="85" code="x">madsrdf:TopicElement</elementType>
        <elementType tag_suffix="85" code="v">madsrdf:GenreFormElement</elementType>
        <elementType tag_suffix="85" code="y">madsrdf:TemporalElement</elementType>
        <elementType tag_suffix="85" code="z">madsrdf:GeographicElement</elementType>      
    </elementTypeMaps>);

declare variable $marcxml2madsrdf:marc2madsMap := (<marc2madsMap>
        <map tag_suffix="00" count="1" subfield="a">
            <authority>madsrdf:PersonalName</authority>
            <variant>madsrdf:PersonalName</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="cdgq">
            <authority>madsrdf:PersonalName</authority>
            <variant>madsrdf:PersonalName</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="00" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="10" count="1" subfield="a">
            <authority>madsrdf:CorporateName</authority>
            <variant>madsrdf:CorporateName</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="bcdg">
            <authority>madsrdf:CorporateName</authority>
            <variant>madsrdf:CorporateName</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="10" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="11" count="1" subfield="a">
            <authority>madsrdf:ConferenceName</authority>
            <variant>madsrdf:ConferenceName</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="cdgq">
            <authority>madsrdf:ConferenceName</authority>
            <variant>madsrdf:ConferenceName</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="t">
            <authority>madsrdf:NameTitle</authority>
            <variant>madsrdf:NameTitle</variant>
        </map>
        <map tag_suffix="11" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="30" count="1" subfield="a" variant_subfield="t"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:Title</authority>
            <variant>madsrdf:Title</variant>
        </map>
        <map tag_suffix="30" count="2" subfield="d"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:Title</authority>
            <variant>madsrdf:Title</variant>
        </map>
        <map tag_suffix="30" count="2" subfield="vxyz"> (: UniformTitle - this could have any number of code fields in it :)
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="48" count="1" subfield="a" variant_subfield="y">
            <authority>madsrdf:Temporal</authority>
            <variant>madsrdf:Temporal</variant>
        </map>
        <map tag_suffix="48" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="50" count="1" subfield="a" variant_subfield="x">
            <authority>madsrdf:Topic</authority>
            <variant>madsrdf:Topic</variant>
        </map>
        <map tag_suffix="50" count="2" subfield="bvxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="51" count="1" subfield="a" variant_subfield="z">
            <authority>madsrdf:Geographic</authority>
            <variant>madsrdf:Geographic</variant>
        </map>
        <map tag_suffix="51" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="55" count="1" subfield="a" variant_subfield="vpk">
            <authority>madsrdf:GenreForm</authority>
            <variant>madsrdf:GenreForm</variant>
        </map>
        <map tag_suffix="55" count="2" subfield="vxyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="80" count="1" subfield="x">
            <authority>madsrdf:Topic</authority>
            <variant>madsrdf:Topic</variant>
        </map>
        <map tag_suffix="80" count="2" subfield="vyz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="81" count="1" subfield="z">
            <authority>madsrdf:Geographic</authority>
            <variant>madsrdf:Geographical</variant>
        </map>
        <map tag_suffix="81" count="2" subfield="vxy">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="82" count="1" subfield="y">
            <authority>madsrdf:Temporal</authority>
            <variant>madsrdf:Temporal</variant>
        </map>
        <map tag_suffix="82" count="2" subfield="vxz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
        <map tag_suffix="85" count="1" subfield="v">
            <authority>madsrdf:GenreForm</authority>
            <variant>madsrdf:GenreForm</variant>
        </map>
        <map tag_suffix="85" count="2" subfield="yxz">
            <authority>madsrdf:ComplexSubject</authority>
            <variant>madsrdf:ComplexSubject</variant>
        </map>
        
    </marc2madsMap>);    
    
declare variable $marcxml2madsrdf:noteTypeMap := (
    <noteTypeMaps>
        <type tag="667">madsrdf:editorialNote</type>
        <type tag="678">madsrdf:note</type>
        <type tag="680">madsrdf:note</type>
        <type tag="681">madsrdf:exampleNote</type>
        <type tag="682">madsrdf:changeNote</type>
        <type tag="688">madsrdf:historyNote</type>     
    </noteTypeMaps>);
    
    
declare variable $marcxml2madsrdf:relationTypeMap := (
    <relationTypeMaps>
        <type tag_prefix="5" pos="1" w="a">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="b">madsrdf:hasLaterEstablishedForm</type>
        <type tag_prefix="5" pos="1" w="d">madsrdf:hasAcronymVariant</type>
        <type tag_suffix="5" pos="1" w="g">madsrdf:hasBroaderAuthority</type>
        <type tag_suffix="5" pos="1" w="h">madsrdf:hasNarrowerAuthority</type>
        <type tag_prefix="5" pos="1" w="_">madsrdf:hasRelation</type>
        
        <type tag_prefix="5" pos="2" w="a">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="b">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="c">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="d">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="e">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="2" w="f">madsrdf:hasRelatedAuthority</type>
        <type tag_suffix="5" pos="2" w="g">madsrdf:hasRelatedAuthority</type>
        <type tag_suffix="5" pos="2" w="h">madsrdf:hasRelatedAuthority</type>
        <type tag_prefix="5" pos="1" w="_">madsrdf:hasRelatedAuthority</type>
        
        <type tag_suffix="5" pos="3" w="a">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_suffix="5" pos="3" w="e">madsrdf:hasEarlierEstablishedForm</type>
        <type tag_suffix="5" pos="3" w="o">madsrdf:hasEarlierEstablishedForm</type>
        
        <type tag_suffix="5" pos="3" w="b">INVALID</type>
        
        <type tag_prefix="5" pos="4" w="b">madsrdf:see</type>
        <type tag_prefix="5" pos="4" w="c">madsrdf:see</type>
        <type tag_prefix="5" pos="4" w="d">madsrdf:see</type>
       
    </relationTypeMaps>);
    
declare variable $marcxml2madsrdf:variantTypeMap := (
    <variantTypeMaps>        
        <type tag="400" count="1">madsrdf:PersonalName</type>
        <type tag="400" count="2" code="cdgq">madsrdf:PersonalName</type>
        <type tag="400" count="2" code="t">madsrdf:NameTitle</type> (: Would title ever not be in the second position?  Is it still an NT when there is a third term, a form subdivision? :) :)
        <type tag="400" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="410" count="1">madsrdf:CorporateName</type>
        <type tag="410" count="2" code="t">madsrdf:NameTitle</type> (: this implies that t is the second component :)
        <type tag="410" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="411" count="1">madsrdf:ConferenceName</type>
        <type tag="411" count="2" code="t">madsrdf:NameTitle</type>
        <type tag="411" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: Name Could be a name followed by a general, form, etc subdivision :)
        
        <type tag="430" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: UniformTitle - this could have any number of code fields in it :)
        
        <type tag="448" equivalent="y" count="1" code="a">madsrdf:Temporal</type>
        <type tag="448" count="2" code="vxyz">madsrdf:ComplexSubject</type> (: loads of codes :)
        
        <type tag="450" equivalent="x" count="1" code="a">madsrdf:Topic</type>
        <type tag="450" count="2" code="vxyz">madsrdf:ComplexSubject</type>
       
        <type tag="451" equivalent="z" count="1" code="a">madsrdf:Geographic</type>
        <type tag="451" count="2" code="vxyz">madsrdf:ComplexSubject</type>
        
        <type tag="455" equivalent="v" count="1" code="a">madsrdf:GenreForm</type>
        <type tag="455" count="2" code="vxyz">madsrdf:ComplexSubject</type>
        
        <type tag="480" count="1" code="a">madsrdf:Topic</type>
        <type tag="480" count="2" code="vxyz">madsrdf:ComplexSubject</type>
    </variantTypeMaps>);
 

(:~
:   This is the main function.  It converts MARCXML to MADSRDF.
:   It takes the MARCXML as the first argument.
:
:   @param  $marcxml        node() is the MARC XML
:   @return rdf:RDF element of MADS RDF/XML
:)
declare function marcxml2madsrdf:marcxml2madsrdf($marcxml)
as element(rdf:RDF)
{
    let $marc001 := fn:replace( $marcxml/marcxml:controlfield[@tag='001'] , ' ', '')
    (: LC Specific :)
    let $scheme :=
        if (fn:substring($marc001, 1, 1) eq 's') then
            "subjects"
        else if (fn:substring($marc001, 1, 1) eq 'n') then
            "names"
        else if (fn:substring($marc001, 1, 1) eq 'g') then
            "genreForms"
        else
            "empty"
    let $owlSameAs := 
        if ($scheme eq "subjects") then
            (
                element owl:sameAs {
                    attribute rdf:resource { fn:concat("info:lc/authorities/" , $marc001) }
                },
                element owl:sameAs {
                    attribute rdf:resource { fn:concat("http://id.loc.gov/authorities/" , $marc001 , "#concept") }
                }
            )
        else ()
    (: LC Specific :)         
    let $df682 := $marcxml/marcxml:datafield[@tag='682'][1] (: can there every be more than one? :)
    let $leader_pos05 := fn:substring($marcxml/marcxml:leader, 6 ,1)
    let $deleted := 
        if ($leader_pos05 eq "d") then
            fn:true()
        else
            fn:false()
    let $df1xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'1')] (: should only be one? :)
    let $df1xx_suffix := fn:substring($df1xx/@tag, 2, 2)
    let $df1xx_sf_counts := fn:count($df1xx/marcxml:subfield)
    let $df1xx_sf_two_code := $df1xx/marcxml:subfield[2]/@code
    let $authoritativeLabel := marcxml2madsrdf:generate-label($df1xx,$df1xx_suffix)
                
    let $authorityType := 
		if ($scheme="demographicTerms") then "madsrdf:Authority"
				else
					marcxml2madsrdf:get-authority-type($df1xx, fn:true())
            
    let $components := 
        if ($deleted) then
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:false())
        else
            marcxml2madsrdf:create-components-from-DFxx($df1xx, fn:true())
    let $componentList := 
        if ($components and $deleted) then marcxml2madsrdf:create-component-list($components, fn:false()) 
        else if ($components) then marcxml2madsrdf:create-component-list($components, fn:true())
        else ()
        
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($df1xx)
    let $elementList := 
        if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
        else ()

    let $marc053 := $marcxml/marcxml:datafield[@tag='053']
    let $classification := 
        if ($marc053) then
            for $df in $marc053
                return marcxml2madsrdf:create-classifications($df)
        else ()
    
    let $df4xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'4')]
    let $variants := 
        if ($df4xx) then
            for $df in $df4xx
                return 
                    element madsrdf:hasVariant { marcxml2madsrdf:create-variant($df) }
        else ()

    let $df4xx_w := $marcxml/marcxml:datafield[fn:starts-with(@tag,'4') and marcxml:subfield[1]/@code="w"]
    let $relations_df4xx := 
        if ($df4xx_w) then
            for $df in $df4xx_w
                return marcxml2madsrdf:create-relation($df)
        else ()
                
    let $df5xx := $marcxml/marcxml:datafield[fn:starts-with(@tag,'5')]
    let $relations := 
        if ($df5xx) then
            for $df in $df5xx
                return marcxml2madsrdf:create-relation($df)
        else ()

    let $hasLater_relation := 
        if ($deleted and $df682) then
            marcxml2madsrdf:create-hasLaterForm-relation($df682, $authorityType)
        else ()
        
    let $dfSources := $marcxml/marcxml:datafield[fn:matches(@tag , '670|675')]
    let $sources := 
        if ($dfSources) then
            for $df in $dfSources
                return element madsrdf:hasSource { marcxml2madsrdf:create-source($df) }
        else ()
        
    let $dfNotes := $marcxml/marcxml:datafield[fn:matches(@tag , '667|678|680|681|688')]
    let $notes := 
        if ($dfNotes) then
            for $df in $dfNotes
                return marcxml2madsrdf:create-notes($df)
        else ()
        
    let $delNote :=
        if ($deleted and $df682) then
             marcxml2madsrdf:create-deletion-note($df682)
        else ()
        
    let $rwoClass := marcxml2madsrdf:create-rwoClass( $marcxml )
    
    let $identifiers :=
        (
            element identifiers:lccn { fn:normalize-space($marcxml/marcxml:datafield[@tag eq "010"]/marcxml:subfield[@code eq "a"]) },
            
            for $i in $marcxml/marcxml:datafield[@tag eq "020"]
            let $code := fn:normalize-space($i/marcxml:subfield[@code eq "2"])
            let $iStr := fn:normalize-space(xs:string($i/marcxml:subfield[@code eq "a"]))
            where $iStr ne ""
            return
                if ( $code ne "" ) then
                    element { fn:concat("identifiers:" , $code) } { $iStr }
                else 
                    element identifiers:id { $iStr },
                    
            for $i in $marcxml/marcxml:datafield[@tag eq "035"]/marcxml:subfield[@code eq "a"][fn:not( fn:contains(. , "DLC") )]
            let $iStr := xs:string($i)
            return
                if ( fn:contains($iStr, "(OCoLC)" ) ) then
                    element identifiers:oclcnum { fn:normalize-space(fn:replace($iStr, "\(OCoLC\)", "")) }
                else 
                    element identifiers:id { fn:normalize-space($iStr) }
        )
        
    let $ri := marcxml2recordinfo:recordInfoFromMARCXML($marcxml)
    let $adminMetadata := 
        for $r in $ri
        return element madsrdf:adminMetadata { $r }
    
    let $marc008_pos6 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 7 ,1)
    let $geo_sub := 
        if ($marc008_pos6 eq "d" or $marc008_pos6 eq "i") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_SubdivideGeographically'}
                
            }        
        else ()
        
    let $marc008_pos9 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 10 ,1)
    let $kind_of_record := 
        if ($marc008_pos9 eq 'a' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesAuthorizedHeadings'}
        }
        else if ($marc008_pos9 eq 'a' and $scheme eq "subjects") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSHAuthorizedHeadings'}
            }
        else if ($marc008_pos9 eq 'a' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesAuthorizedHeadings'}
            }
        else if ($marc008_pos9 eq 'd') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_Subdivisions'}
            }
        else if ($marc008_pos9 eq 'f') then
            (: this does not seem to apply to names :)
            (
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSHAuthorizedHeadings'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_Subdivisions'}
                }
            )
        else ()
        
    let $marc008_pos17 := fn:substring($marcxml/marcxml:controlfield[@tag='008'], 18 ,1)
    let $subdivision_type := 
        if ($marc008_pos17 eq 'a') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TopicSubdivisions'}
            }
        else if ($marc008_pos17 eq 'b') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GenreFormSubdivisions'}
            }
        else if ($marc008_pos17 eq 'c') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TemporalSubdivisions'}
            }
        else if ($marc008_pos17 eq 'd') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions'}
            }
        else if ($marc008_pos17 eq 'e') then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LanguageSubdivisions'}
            }
        else ()
        
     let $frbr_kind:= (:100, 110, 100 with $t is a title or nametitle 130 with anything is a title. if it has a language or arrangement, it's an expression, otherwise, it's a work:)
            if ($authorityType="madsrdf:Title" or $authorityType="madsrdf:NameTitle") then (:its at least a work:)         	    	
                ( (:$l=language, $o=arrangment for music:) 
                    if ($df1xx/marcxml:subfield[@code="l" or @code="o"]) then (:expression:)
                        element madsrdf:isMemberOfMADSCollection { 
			                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_FRBRExpression'}
			            }
			        else
			        	element madsrdf:isMemberOfMADSCollection { 
			                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_FRBRWork'}
			            }
                )
            else () 
    (: commenting out for the time being :)
    (:
    let $df100_subdivision_type := 
        if ($df1xx_suffix='80') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_TopicalSubdivisions'}
            }
        else if ($df1xx_suffix='85') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GenreSubdivisions'}
            }
        else if ($df1xx_suffix='82') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_ChronologicalSubdivisions'}
            }
        else if ($df1xx_suffix='81') then
            element madsrdf:isMemberOf { 
                attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions'}
            }
        else ()
    :)
    let $undiff :=
        if ( fn:substring($marcxml/marcxml:controlfield[@tag='008'], 33 ,1) eq 'b' and $scheme eq "names") then
            element madsrdf:isMemberOfMADSCollection { 
                attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_NamesUndifferentiated'}
        }
        else ()

    let $marc001_prefix := fn:substring( $marc001 , 1 , 2 )        
    let $marc001_prefix_type := 
        if ($marc001_prefix='sh') then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSH_General'}
                }
            )
        else if ($marc001_prefix='sj') then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/childrensSubjects'}
                },
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/subjects/collection_LCSH_Childrens'}
                }
            )
        else if ( fn:contains($marc001_prefix, "n") ) then
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/names'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/names/collection_LCNAF'}
                }
            )
        else if ( fn:contains($marc001_prefix, "g") ) then
            (: should this also be a part of genreForm concept scheme.  Yes.  But it will break something. :)
            (
                element madsrdf:isMemberOfMADSScheme { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/genreForms'}
                },
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {'http://id.loc.gov/authorities/genreForms/collection_LCGFT_General'}
                }
            )
        else ()
        
    let $pattern_headings := 
        for $ph in $marcxml/marcxml:datafield[@tag='073' and marcxml:subfield[@code='z']='lcsh']/marcxml:subfield[@code='a']
            return
                element madsrdf:isMemberOfMADSCollection { 
                    attribute rdf:resource {fn:concat('http://id.loc.gov/authorities/subjects/collection_PatternHeading' , fn:replace($ph , ' ' , ''))}
                }
                
    let $scheme := 
        if ($marc001_prefix='sj') then
            "childrensSubjects"
        else
            $scheme
    
    let $rdf := 
        if ($deleted) then
            let $variant := 
                element {$authorityType} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $marcxml2madsrdf:authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Variant") }
                    },
                    (: all "deleted" or "cancelled" records are Variants AND DeprecatedAuthorities :) 
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "DeprecatedAuthority") }
                    },
                (:
                This makes Variant the root element, and the MADSType part of rdf:type
                element {"Variant"} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($authorityType, "madsrdf:", "") ) }
                    },
                :)
                    element madsrdf:variantLabel {
                        text {$authoritativeLabel} 
                    },
                    $componentList,
                    $elementList,
                    $hasLater_relation,
                    $delNote,
                    $notes,
                    (: $marc001_prefix_type, :) (: Scheme and membership associations.  Not desirable for "cancelled" authorities :)
                    $owlSameAs,
                    
                    $adminMetadata
                }
            return $variant
        else 
            let $authority := 
                element {$authorityType} {
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $marcxml2madsrdf:authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Authority" ) }
                    },
                (:
                    This makes Authority the root element, and the MADSType part of rdf:type
                    attribute rdf:about { fn:concat("http://id.loc.gov/" , $authSchemeMap/authScheme[@abbrev=$scheme] , $marc001) },
                    element rdf:type {
                        attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($authorityType, "madsrdf:", "") ) }
                    },
                :)    
                    element madsrdf:authoritativeLabel {
                        text {$authoritativeLabel} 
                    },
                    $componentList,
                    $elementList,
                    $classification,
                    $kind_of_record,
                    $subdivision_type,
                    (: $df100_subdivision_type, :)
                    $marc001_prefix_type,
                    $geo_sub,
                    $pattern_headings,
                    $undiff,
                    $frbr_kind,
                    $rwoClass,
                    $variants,
                    $relations_df4xx,
                    $relations,
                    $sources,
                    $notes,
                    $identifiers,
                    $owlSameAs,
                    $adminMetadata
                }
            return $authority

    return <rdf:RDF>{$rdf}</rdf:RDF>

};




(:
-------------------------

    Creates Classification Properties:
    
        $marc053 as element() is the marc 053 datafield 

-------------------------
:)
declare function marcxml2madsrdf:create-classifications($marc053 as element()) as element() {
    let $lc := 
        if ($marc053/@ind2 eq '0') then
            (: LC assigned means LC Classification :)
            xs:boolean(1)
        else xs:boolean(0)
        
    let $textparts :=
        for $sf at $pos in $marc053/marcxml:subfield
            let $class_str := 
                if ($sf/@code eq 'a') then
                    $sf
                else if ($sf/@code eq 'b') then
                    fn:concat('- ',$sf)
                else ""
            return $class_str
    let $text := fn:replace( fn:string-join($textparts , '') , ' ' , '' )

    let $classifications := 
        element madsrdf:classification { 
            text { $text }
       }
        
    return $classifications
};



(:~
:   Creates a Component, aka an Authority.
:
:   @param  $sf        element() is the subfield
:   @param  $pos       as xs:integer is the position in the loop
:   @param  $authority as xs:boolean denotes whether this is an Authority or Variant    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component(
        $sf as element(), 
        $pos as xs:integer, 
        $authority as xs:boolean) as element()*
{
    let $c := $sf/@code
    let $df_suffix := fn:substring($sf/../@tag , 2 , 2)
    let $aORv := 
        if ($authority) then
            "Authority"
        else
            "Variant"
    let $type :=
        if ($authority) then
            if ($pos lt 2) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']/authority
            else
                $marcxml2madsrdf:marc2madsMap/map[fn:contains(@variant_subfield , $c) and @count='1']/authority
        else
            if ($pos lt 2) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']/variant
            else
                $marcxml2madsrdf:marc2madsMap/map[fn:contains(@variant_subfield , $c) and @count='1']/variant
    (: let $label := $sf/text() :)
            
    let $labelProperty := 
        if ($authority) then
            "madsrdf:authoritativeLabel"
        else
            "madsrdf:variantLabel"
    
    let $elements := marcxml2madsrdf:create-element($sf, 1)
    let $elementList := 
        if ($elements) then marcxml2madsrdf:create-element-list($elements) 
        else ()
      
    let $label := fn:string-join($elements, ' ')
    let $label := 
        if ( fn:ends-with($label, ".") and fn:not(fn:contains($type, "Name")) ) then
            fn:substring($label, 1, (fn:string-length($label) - 1))
        else 
            $label
    (: let $nodeID := marcxml2madsrdf:generate-nodeID($label,$authority) :)
    
        
    (:
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($sf/parent::node()[1])
    let $elementList := 
        if ($elements) then marcxml2madsrdf:create-element-list($elements) 
        else ()
    :)
    
    (: fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($type, "madsrdf:", "") ) :)
            
    let $component := 
        if ($type ne "") then
            element {$type} {
                (: attribute rdf:nodeID {$nodeID}, :)
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                }, 
                element {$labelProperty} { 
                    text {$label} 
                },
                $elementList
            }
        else ()
    return $component
};


(:~
:   Creates a componentList
:
:   @param  $component_elementlist  as element() holds the component
:   @param  $counts                 as xs:integer is the number of subfields
:   @param  $authority              as xs:boolean denotes whether this is an Authority or Variant    
:   @return component Authority record/element
:)
declare function marcxml2madsrdf:create-component-list($component_elementlist, $authority as xs:boolean) {
    let $component_list :=   
        element {"madsrdf:componentList"} {
            attribute rdf:parseType {"Collection"},
            $component_elementlist
        }
    return $component_list
};



(:
-------------------------

    Returns Component from a 1xx or 4xx marcxml:datafield
    
        $df as element() is the relevant marcxml:datafield
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-components-from-DFxx($df as element(), $authority as xs:boolean) {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $components := 
        if ( 
                ( $df/marcxml:subfield[@code eq 'a'] 
                and ($df/marcxml:subfield[fn:matches(@code , "t|v|x|y|z")]) )
                or
                ( fn:matches($df/@tag , '80|81|82|85') and
                fn:count($df/marcxml:subfield[@code ne "w"]) gt 1 ) 
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|t|v|x|y|z")]
                let $component := marcxml2madsrdf:create-component($f, $pos, $authority)
                return $component
        else ()
    return $components
};




(:
-------------------------

    Creates MADS Deletion Note:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-deletion-note($df as element()) as element() {
    
    let $textparts :=
        for $sf in $df/marcxml:subfield
            let $str := 
                if ($sf/@code eq 'a') then
                    fn:concat('{' , $sf/text() , '}')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
            
    let $note := element madsrdf:deletionNote { 
            text {$text} 
        }
        
    return $note
};





(:
-------------------------

    Creates Element:
    
        $sf as element() is the subfield
        $pos as xs:integer is the position in the loop

-------------------------
:)
declare function marcxml2madsrdf:create-element($sf, $pos) {
    let $tag_suffix := fn:substring($sf/../@tag , 2 , 2)
    let $tag_prefix := fn:substring($sf/../@tag , 1 , 1)
    let $label := $sf/../text()
    let $code := xs:string($sf/@code)
    let $element :=
        if ($sf/@code ne 'w') then
            let $el := $marcxml2madsrdf:elementTypeMap/elementType[@tag_suffix=$tag_suffix and @code=$sf/@code and fn:not(@ancillary)]/text()
            let $label := xs:string($sf)
            return
                element {$el} {
                    element madsrdf:elementValue { 
                        $label 
                    }
                }
        else ()
    let $extras := 
        if ($pos=1) then
            for $dfc in $sf/following-sibling::node()
                let $el := $marcxml2madsrdf:elementTypeMap/elementType[@tag_suffix=$tag_suffix and @code=$sf/@code and @ancillary=$dfc/@code]/text()
                return 
                    if ($el and ($sf/@code="t" or ($dfc/@code!="t" and fn:not($dfc/preceding-sibling::node()[@code="t"])))) then
                        (: this seems a little forced, but we need to seperate the the name and title parts :) 
                        element {$el} {
                            element madsrdf:elementValue { 
                                text {$dfc} 
                            }
                        }
                    else ()
        else ()

    return ($element , $extras)
};



(:
-------------------------

    Creates ElementList:
    
        $component_elementlist as element() holds the component
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-element-list($elementlist) {
    let $e_list :=
            element madsrdf:elementList {
                attribute rdf:parseType {"Collection"},
                $elementlist
            }
    return $e_list
};



(:
-------------------------

    Returns Element from a 1xx or 5xx marcxml:datafield
    
        $df as element() is the relevant marcxml:datafield
        $counts as is the number of subfields
        $authority as xs:boolean denotes whether this is an Authority or Variant

-------------------------
:)
declare function marcxml2madsrdf:create-elements-from-DFxx($df as element()) {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $elements := 
        if ( 
                ($df/marcxml:subfield[@code eq 'a'] or fn:matches($df_suffix , '80|81|82|85'))
            ) then
            for $f at $pos in $df/marcxml:subfield[fn:matches(@code , "a|v|x|y|z")]
                let $element := marcxml2madsrdf:create-element($f, $pos)
                return $element
        else ()
    return $elements
};


(:~
:   Returns Elements for hasLaterEstablishedForm relationships
:   This, rightly or wrongly, assumes that the later Authority
:   is of the same MADSType as this Variant
:
:   @param  $df             element() is the 682 datafield for parsing
:   @param  $authorityType  xs:string of MADSType
:   @return zero or more madsrdf:hasLaterEstablishedForm elements
:)
declare function marcxml2madsrdf:create-hasLaterForm-relation(
    $df as element(), 
    $authorityType as xs:string
    ) as element()* 
{
    let $elements := 
        for $s at $pos in $df/marcxml:subfield
            return
                if ($s/@code eq "a") then
                    (:  if code eq "a" then it is a replacement heading, but 
                        what type of replacement is it?
                    :)
                    let $objprop := 
                        if ( fn:matches( xs:string($df) , 'covered by' ) ) then
                            "madsrdf:useInstead"
                        else
                            "madsrdf:hasLaterEstablishedForm"
                    return
                        element {$objprop} {
                            element {$authorityType} {
                            if ($s/following-sibling::node()[@code!=""][1]/@code eq "i") then
                                (: this will require a little massaging, how do we know it is "lcsh" :)
                                (: Answer, from the LCCN prefix :)
                                let $relatedlccn := fn:replace( $s/following-sibling::node()[@code!=""][1]/text(), "\(|\)| |\.|and|,", "")
                                let $relatedscheme := 
                                    if ( fn:starts-with($relatedlccn, "sh") ) then
                                        (: presume this is LCSH :)
                                        "subjects"
                                    else if ( fn:starts-with($relatedlccn, "sj") ) then
                                        (: presume this is LCSH :)
                                        "childrensSubjects"
                                    else if ( fn:starts-with($relatedlccn, "n") ) then
                                        "names"
                                    else
                                        "empty"
                                return 
                                    attribute rdf:about { 
                                        fn:concat( "http://id.loc.gov/authorities/" , $relatedscheme , "/" , $relatedlccn )
                                    }
                            else (),
                            element rdf:type { 
                                attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Authority" ) }
                            },
                            element madsrdf:authoritativeLabel {
                                $s/text()
                                }
                            }
                        }
                else ()
    return $elements
};


(:
-------------------------

    Creates MADS Notes:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-notes($df as element()) as element() {
    
    let $tag := $df/@tag
    let $type := $marcxml2madsrdf:noteTypeMap/type[@tag=$tag]/text()
    
    let $textparts :=
        for $sf in $df/marcxml:subfield
            let $str := 
                if ($sf/@code eq 'a') then
                     (: must have had a spectacularly good reason for this :)
                     (: too bad I cannot remember :)
                    fn:concat('[' , $sf/text() , ']')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
            
    let $note := element {$type} {$text}
        
    return $note
};



(:~
:   Creates MADS Relation
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-relation($df as element()) as element()* {
    
    let $tag := $df/@tag
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_counts := fn:count($df/marcxml:subfield[@code ne 'w'])
    let $df_sf_two_code := $df/marcxml:subfield[2]/@code
    let $label := marcxml2madsrdf:generate-label($df,$df_suffix)           
    
    let $wstr := xs:string($df/marcxml:subfield[@code='w']/text())
    let $ws := fn:tokenize($wstr , "[a-z]")
    return
        if (fn:normalize-space($wstr) eq "" and $df/marcxml:subfield[@code='a']) then
            (: reciprocal relations :)
            let $type := "madsrdf:hasReciprocalAuthority"
            let $auth := fn:true()
            let $aORv := "Authority"
            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth)
            let $labelProp := "madsrdf:authoritativeLabel" 
            let $nodeID := marcxml2madsrdf:generate-nodeID($label,$auth)
            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth)
            let $componentList := 
                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                else ()
            
            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
            let $elementList := 
                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                else ()
        
            let $relation := 
                element {$type} {
                    element {$authorityType} {
                        (: attribute rdf:nodeID {$nodeID}, :)
                        element rdf:type {
                            attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                        },
                        element {$labelProp} { 
                            text {$label} 
                        },
                        $componentList,
                        $elementList
                    }                    
                }
            return $relation
        else 
            for $c at $pos in fn:string-to-codepoints($wstr)
                let $w := fn:codepoints-to-string($c)
                return 
                if ($w ne "n" and $pos != 4) then
                    let $type := $marcxml2madsrdf:relationTypeMap/type[@pos eq xs:string($pos) and @w eq $w]/text()
                    return
                        if ($type ne "INVALID") then
                            let $auth :=
                                if ($type eq "madsrdf:hasEarlierEstablishedForm" or 
                                    $type eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            let $aORv :=
                                if ($auth) then
                                    "Authority"
                                else
                                    "Variant"     
                    
                            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth)
                            let $labelProp := 
                                if ($auth) then
                                    "madsrdf:authoritativeLabel"
                                else
                                    "madsrdf:variantLabel"
                                    
                            let $nodeID := marcxml2madsrdf:generate-nodeID($label,$auth)
                        
                            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth)
                            let $componentList := 
                                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                                else ()
                    
                            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
                            let $elementList := 
                                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                                else ()
        
                            let $relation := 
                                    element {$type} {
                                        element {$authorityType} {
                                            (: attribute rdf:nodeID {$nodeID}, :)
                                            element rdf:type {
                                                attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                                            },
                                            element {$labelProp} { 
                                                text {$label} 
                                            },
                                            $componentList,
                                            $elementList
                                        }                    
                                    }
                            return $relation
                        else 
                            ()
                else if ($w ne "n" and $pos = 4) then
                    let $type := $marcxml2madsrdf:relationTypeMap/type[@pos eq xs:string($pos) and @w eq $w]/text()
                    return
                        if ($type ne "INVALID") then
                            let $auth :=
                                if ($type eq "madsrdf:hasEarlierEstablishedForm" or 
                                    $type eq "madsrdf:hasAcronymVariant") then
                                    fn:false()
                                else
                                    fn:true()
                            let $aORv :=
                                if ($auth) then
                                    "Authority"
                                else
                                    "Variant"     
                    
                            let $authorityType := marcxml2madsrdf:get-authority-type($df,$auth)
                            let $labelProp := 
                                if ($auth) then
                                    "madsrdf:authoritativeLabel"
                                else
                                    "madsrdf:variantLabel"
                                    
                            let $nodeID := marcxml2madsrdf:generate-nodeID($label,$auth)
                        
                            let $components := marcxml2madsrdf:create-components-from-DFxx($df, $auth)
                            let $componentList := 
                                if ($components) then marcxml2madsrdf:create-component-list($components, $auth) 
                                else ()
                    
                            let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
                            let $elementList := 
                                if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
                                else ()
        
                            let $relation := 
                                    element {$type} {
                                        element {$authorityType} {
                                            (: attribute rdf:nodeID {$nodeID}, :)
                                            element rdf:type {
                                                attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , $aORv ) }
                                            },
                                            element {$labelProp} { 
                                                text {$label} 
                                            },
                                            $componentList,
                                            $elementList
                                        }                    
                                    }
                            return $relation
                        else 
                            ()
                else ()
};

(:~
:   Creates MADS RWO Class
:
:   @param  $df        element() the relevant marcxml:datafield 
:   @return relation as element()
:)
declare function marcxml2madsrdf:create-rwoClass($record as element()) as element()* {
    let $df046 := $record/marcxml:datafield[@tag='046']
    let $df371 := $record/marcxml:datafield[@tag='371'] 
    let $df372 := $record/marcxml:datafield[@tag='372'] 
    let $df373 := $record/marcxml:datafield[@tag='373'] 
    let $df374 := $record/marcxml:datafield[@tag='374'] 
    let $df375 := $record/marcxml:datafield[@tag='375']  
    let $types := (
            if ($record/marcxml:datafield[@tag='100'] and 
                fn:not($record/marcxml:datafield[@tag='100']/marcxml:subfield[fn:matches(@code , '[efhklmnoprstvxyz]')])
                ) then
                <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Person"/>
            else (),
            if ($record/marcxml:datafield[@tag='110'] and 
                fn:not($record/marcxml:datafield[@tag='110']/marcxml:subfield[fn:matches(@code , '[efhklmnoprstvxyz]')])
                ) then
                <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Organization"/>
            else ()
            )
    let $properties := 
        (
            if ($df046) then
                (
                if ($df046/marcxml:subfield[@code='f']) then
                    <madsrdf:birthdate>{$df046/marcxml:subfield[@code='f']/text()}</madsrdf:birthdate>
                else (),
                if ($df046/marcxml:subfield[@code='g']) then
                    <madsrdf:deathdate>{$df046/marcxml:subfield[@code='g']/text()}</madsrdf:deathdate>
                else ()
                )
            else (),
            for $df in $df373
                return
                    element madsrdf:hasAffiliation {
                        element madsrdf:Affiliation {
                            for $a in $df/marcxml:subfield[@code='a']
                                return
                                    element madsrdf:affiliatedWith {$a/text()},
                            if ($df/marcxml:subfield[@code='s']) then
                                element madsrdf:affiliationBegan {$df/marcxml:subfield[@code='s']/text()}
                            else (),
                            if ($df/marcxml:subfield[@code='t']) then
                                element madsrdf:affiliationEnded {$df/marcxml:subfield[@code='t']/text()}
                            else (),
                            if ($df/marcxml:subfield[@code='v']) then
                                element madsrdf:informationSource {$df/marcxml:subfield[@code='v']/text()}
                            else (),
                            if ($df371) then
                                element madsrdf:hasAffiliationAddress {
                                    element madsrdf:AffiliationAddress {
                                        if ($df371/marcxml:subfield[@code='a'][1]) then
                                            element madsrdf:streetAddress {$df371/marcxml:subfield[@code='a'][1]/text()}
                                        else (),
                                        (: this should probably be a for loop :)
                                        if ($df371/marcxml:subfield[@code='a'][2]) then
                                            element madsrdf:extendedAddress {$df371/marcxml:subfield[@code='a'][2]/text()}
                                        else (),
                                        if ($df371/marcxml:subfield[@code='b']) then
                                            element madsrdf:city {$df371/marcxml:subfield[@code='b']/text()}
                                        else (),
                                        if ($df371/marcxml:subfield[@code='d']) then
                                            element madsrdf:country {$df371/marcxml:subfield[@code='d']/text()}
                                        else (),    
                                        if ($df371/marcxml:subfield[@code='e']) then
                                            element madsrdf:postcode {$df371/marcxml:subfield[@code='e']/text()}
                                        else (),
                                        if ($df371/marcxml:subfield[@code='m']) then
                                            element madsrdf:email {$df371/marcxml:subfield[@code='m']/text()}
                                        else ()
                                    }
                                }   
                            else ()
                       }
                   },
            for $df in $df372
                return 
                    for $sf in $df/marcxml:subfield[@code='a']
                        return element madsrdf:fieldOfActivity {$sf/text()},
            for $df in $df374
                return ()
                    (:
                    element madsrdf:hasOccupation {
                        element madsrdf:Occupation {
                            for $a in $df/marcxml:subfield[@code='a']
                                return
                                    element madsrdf:positionTitle {$a/text()},
                            if ($df/marcxml:subfield[@code='s']) then
                                element madsrdf:positionBegan {$df/marcxml:subfield[@code='s']/text()}
                            else (),
                            if ($df/marcxml:subfield[@code='t']) then
                                element madsrdf:positionEnded {$df/marcxml:subfield[@code='t']/text()}
                            else (),
                            if ($df/marcxml:subfield[@code='v']) then
                                element madsrdf:informationSource {$df/marcxml:subfield[@code='v']/text()}
                            else ()
                        }
                    }
                    :)
        )
    let $rwo := 
        if ($types) then
            element madsrdf:identifiesRWO {
                element madsrdf:RWO {$types,$properties}
            }
        else ()
    return $rwo
};



(:
-------------------------

    Creates MADS Sources:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:create-source($df as element()) as element() {
    
    let $tag := $df/@tag
        
    let $citation_source_element := 
        if ($df/marcxml:subfield[@code eq 'a']/text()) then
            <madsrdf:citation-source>{$df/marcxml:subfield[@code eq 'a']/text()}</madsrdf:citation-source>
        else ()
    let $status_element := 
        if ($tag eq '670') then
            <madsrdf:citation-status>found</madsrdf:citation-status>
        else 
            <madsrdf:citation-status>notfound</madsrdf:citation-status>    
    let $textparts :=
        for $sf in $df/marcxml:subfield[@code ne 'a']
            let $str := 
                if ($sf/@code eq 'u') then
                    fn:concat('{' , $sf/text() , '}')
                else
                    $sf/text()
            return $str
    let $text := fn:string-join($textparts, ' ')
    let $text_element := 
        if (fn:normalize-space($text)) then
            <madsrdf:citation-note>{$text}</madsrdf:citation-note>
        else ()
               
    let $source := 
            element madsrdf:Source {
                $citation_source_element,
                $text_element,
                $status_element
            }
    return $source
};


(:~
:   Creates a Variant.
:
:   @param  $df        element() is the subfield   
:   @return madsrdf:hasVariant/child::node()[1] as element()
:)
declare function marcxml2madsrdf:create-variant($df as element()) as element() {
    
    let $tag := $df/@tag
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_counts := fn:count($df/marcxml:subfield[@code ne 'w'])
    let $df_sf_two_code := $df/marcxml:subfield[2]/@code
    let $label := marcxml2madsrdf:generate-label($df,$df_suffix)
            
    let $type := marcxml2madsrdf:get-authority-type($df, fn:false())
            
    let $components := marcxml2madsrdf:create-components-from-DFxx($df, fn:false())
    let $componentList := 
        if ($components) then marcxml2madsrdf:create-component-list($components, fn:false()) 
        else ()
        
    let $elements := marcxml2madsrdf:create-elements-from-DFxx($df)
    let $elementList := 
        if ($elements and fn:not($componentList)) then marcxml2madsrdf:create-element-list($elements) 
        else ()
        
    let $nodeID := marcxml2madsrdf:generate-nodeID($label,fn:false())
            
    let $variant := 
            element {$type} {
                (: attribute rdf:nodeID {$nodeID}, :)
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , "Variant" ) }
                },
            (:
            This makes the MADSType the parent element; Variant is part of rdf:type
            element {"Variant"} {
                attribute rdf:nodeID {$nodeID},
                element rdf:type {
                    attribute rdf:resource { fn:concat( xs:string( fn:namespace-uri-for-prefix("madsrdf", <madsrdf:blah/>) ) , fn:replace($type, "madsrdf:", "") ) }
                },
            :)
                element madsrdf:variantLabel { 
                    text {$label} 
                },
                $componentList,
                $elementList     
            }
        
    return $variant
};


(:
-------------------------

    Determines, and returns, the appropriate MADS Authority or Variant type:
    
        $df as element() is the relevant marcxml:datafield

-------------------------
:)
declare function marcxml2madsrdf:get-authority-type($df as element(), $authority as xs:boolean) as xs:string {
    let $df_suffix := fn:substring($df/@tag, 2, 2)
    let $df_sf_two_code := $df/marcxml:subfield[fn:matches(@code , "[tvxyz]")][1]/@code
    let $df682 := $df/parent::node()/marcxml:datafield[@tag='682'][1] (: only one, no? :)
    let $authority_test :=
        if ($df682) then
            fn:false()
        else 
            $authority
            
    let $union := 
        if (
            $df/marcxml:subfield[@code='a'] and 
            fn:matches( fn:string-join($df/marcxml:subfield[@code!="a"]/@code, ''), '[tvxyz]')
            ) then
                fn:true()
        else if (
                fn:matches($df_suffix , '80|81|82|85') and
                $df/marcxml:subfield[1][fn:matches(@code, 'v|x|y|z')] and
                $df/marcxml:subfield[2][fn:matches(@code, 'v|x|y|z')]
            ) then
            fn:true()
        else 
            fn:false()
            
    let $t := $df/marcxml:subfield[@code="t"]
    let $not_hg := fn:matches( fn:string-join($df/marcxml:subfield/@code , ''), '[a-f|h-z]')
    let $type_element := 
        if ($union) then
            if (fn:matches($df_suffix , '00|10|11') and $t) then
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2' and fn:contains(@subfield , 't') ] 
            else if (
                fn:matches($df_suffix , '80|81|82|85') and
                $df/marcxml:subfield[2][fn:matches(@code, 'v|x|y|z')]
                ) then
                 $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2']
            else 
                $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='2' and fn:contains(@subfield , $df_sf_two_code) ]
        else
            $marcxml2madsrdf:marc2madsMap/map[@tag_suffix=$df_suffix and @count='1']

    let $type := 
        if ($authority_test) then
            $type_element/authority/text()
        else
            $type_element/variant/text()
            
    return $type

};

(:~
:   This function creates a proper nodeID value
:
:   @param  $df         marcxml datafield element
:   @param  $df_suffix  last two characters of marc/datafield tag value 
:   @return specially formatted string for use as lexical label
:)
declare function marcxml2madsrdf:generate-label($df as element(), $df_suffix as xs:string) as xs:string {
    let $label := 
        if (fn:matches($df_suffix, ("00|10|11|30"))) then
            fn:concat(
                fn:string-join($df/marcxml:subfield[@code ne 'w' and @code!='v' and @code!='x' and @code!='y' and @code!='z' and @code!='6'] , ' '),
                if ( $df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] ) then
                    fn:concat("--",fn:string-join($df/marcxml:subfield[@code='v' or @code='x' or @code='y' or @code='z'] , '--'))
                else ""
            )   
        else
            let $label := fn:string-join($df/marcxml:subfield[@code ne 'w' and @code ne '6'] , '--')
            let $label := 
                if ( fn:ends-with($label, ".") ) then
                    fn:substring($label, 1, (fn:string-length($label) - 1))
                else 
                    $label
            return $label

    return fn:normalize-space($label)
};

(:~
:   This function creates a proper nodeID value
:
:   @param  $label       lexical authority or variant label 
:   @param  $authority   boolean, true if authority, false if variant
:   @return specially formatted string for use as an RDF/XML nodeID/bnode
:)
declare function marcxml2madsrdf:generate-nodeID($label as xs:string, 
                                      $authority as xs:boolean) 
as xs:string
{
    let $firstLetter := if ($authority) then "a" else "v"
    let $str := fn:replace( $label ,' ','-')
    let $str := fn:replace( $str ,'(,|\.|\s|\(|\)|"|&apos;|&amp;|;|:)','')
    let $str_codepoints := fn:string-to-codepoints($str)
    let $str := fn:string-join(
            for $x in $str_codepoints
            return
                if ($x gt 122) then "X" else fn:codepoints-to-string($x),
            '')
    let $nodeID := fn:concat($firstLetter,$str)
    return $nodeID
};
