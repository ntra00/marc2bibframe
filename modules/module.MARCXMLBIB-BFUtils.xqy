xquery version "1.0";
(:
:   Module Name: MARCXML BIB-BF Utils
:
:   Module Version: 1.0
:
:   Date: 2013 August 1
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: None
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Utilities for standard functions used in transforming a MARC Bib record
:       into its bibframe parts.  
:
:)
   
(:~
:   Functions are called by the module MARCXMLBIB-2-BIBFRAME
:	
:   @author Kevin Ford (kefo@loc.gov)
:   @author Nate Trail (ntra@loc.gov)
:   @since August 1, 2013
:   @version 1.0
:)

module namespace marc2bfutils  = 'info:lc/id-modules/marc2bfutils#';



(: VARIABLES :)
declare variable $marc2bfutils:resourceTypes := (
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
    declare variable $marc2bfutils:targetAudiences := (
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
    
 declare variable $marc2bfutils:subject-types := (
	 <subjectTypes> 
		<subject tag="600">Person</subject>
		<subject tag="610">Organization</subject>		
		<subject tag="611">Meeting</subject>
		<!--<subject tag="630">Work</subject>-->
		<subject tag="648">TemporalConcept</subject>
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