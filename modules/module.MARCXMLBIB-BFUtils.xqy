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
declare namespace marcxml      = "http://www.loc.gov/MARC21/slim";
declare namespace bf           	= "http://bibframe.org/vocab/";

(: VARIABLES :)
declare variable $marc2bfutils:resourceTypes := (
    <resourceTypes>
        <type leader6="a">Text</type>
        <type cf007="t">Text</type>       
        <type sf336a="(text|tactile text)">Text</type>
        <type sf336b="(txt|tct)">Text</type>
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
        <type leader6="m">Multimedia</type>
        <type sf336a="computer program">Multimedia</type>
        <type sf336b="cop">Multimedia</type>
        <type leader6="m">Dataset</type>
        <type sf336a="(cartographic dataset|computer dataset)">Dataset</type>
        <type sf336b="(crd|cod)">Ddataset</type>
        <type leader6="o">MixedMaterial</type>
        <type leader6="p">MixedMaterial</type>
        <type cf007="o">MixedMaterial</type>
        <type leader6="r"></type>
        <type sf336a="(three-dimensional form|tactile three-dimensional form|three-dimensional moving image| cartographic three dimensional form|cartographic tactile three dimensional form)"></type>
        <type sf336b="(tdf|tcf|tcm|crf|crn )"></type>
        <type leader6="t">Text</type>        
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
		<subject tag="648">Temporal</subject>
		<subject tag="650">Topic</subject>
		<subject tag="651">Place</subject>
		<subject tag="654">Topic</subject>
		<subject tag="655">Topic</subject>
		<!--<subject tag="655">Genre</subject>		
		<subject tag="656">Occupation</subject>		
		<subject tag="657">Function</subject>
		<subject tag="658">Objective</subject>-->
		
		<subject tag="656">Topic</subject>		
		<subject tag="657">Topic</subject>
		<subject tag="658">Topic</subject>
		<subject tag="662">Place</subject>		
		<!--<subject tag="662">HierarchicalPlace</subject>-->
		<subject tag="653">Topic</subject>
		<subject tag="751">Place</subject>
		<subject tag="752">Topic</subject>
		<!--<subject tag="752">HierarchicalPlace</subject>-->
	</subjectTypes>
);
declare variable $marc2bfutils:formsOfItems := (
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
declare variable $marc2bfutils:classes := (
<vocab>
    <class>ClassificationEntity</class>
    <property name="classificationNumber" label="classification number" domain="Work" marc="050,051,055,060,061,070,071,080,082,083,084,086--/a" tag="(050|051|055|060|061|070|071|080|082|083|084|086)" sfcodes="a"/>
    <property name="classificationItem" label="classification item number" domain="Holding" marc="050|051,055,060,061,070,071,080,082,083,084,086--/b" tag="(050|051|055|060|061|070|071|080|082|083|084|086)" sfcodes="b"/>
    <!--<property name="classificationCopy" label="Copy part of call number" domain="Work" marc="051,061,071- -/c" tag="(051|061|071)" sfcodes="c"/>-->
    <property name="classificationSpanEnd" label="classification span end for class number" domain="Work" marc="083--/c" tag="083" sfcodes="c"/>
    <property name="classificationTableSeq" label="DDC table sequence number" domain="Work" marc="083--/y" tag="083" sfcodes="y"/>
    <property name="classificationTable" label="DDC table" domain="" marc="083--/z" tag="083" sfcodes="z"/>
    <property name="classificationScheme" label="type of classification" domain="Work" marc="086--/2" tag="086" sfcodes="2"/>   
    <property name="classificationEdition" label="edition of class scheme" domain="Work" marc="If 080,082,083 1- then 'abridged'" tag="(080|082|083)" ind1="1"/>	
    <property name="classificationEdition" label="edition of class scheme" domain="Work" marc="If 080,082,083 1- then 'full'" tag="080|082|083" ind1="0"/>
    <property name="classificationAssigner" label="institution assigning classification" domain="Work" marc="if 070,071 then NAL" tag="(050|051|060|061|070|071|082|083|084)"/>
    
    <property name="classificationDesignation" label="Part of class scheme used" domain="Work" marc="if 082,083 --/m=a then'standard', m=b then 'optional'" tag="(082|083)"  sfcodes="m=a then'standard', m=b then 'optional'"/>
    <property name="classificationStatus" label="status of classification" domain="Work" marc="if 086/z then status=canceled/invalid" tag="if "  sfcodes="z then status=canceled/invalid"/>
    <property name="classificationLcc" label="LCC Classification" domain="Work" marc="050,051,055,070,071--/a" tag="(050|051|055||070|071)" sfcodes="a" level="property"/>
    <property name="classificationNlm" label="NLM Classification" domain="Work" marc="060,061--/a" tag="(060|061)" sfcodes="a" level="property"/>
    <property name="classification" label="classification" domain="Work" marc="084,086--/a" tag="(084|086)" ind1="," ind2="0" sfcodes="a" level="property"/>
    <property name="classificationDdc" label="DDC Classification" domain="Work" marc="083--/a'hyphen'c" tag="083" sfcodes="a'hyphen'c" level="property"/> 
    <property name="classificationDdc" label="DDC Classification" domain="Work" marc="082--/a" tag="082" sfcodes="a" level="property"/>	
    <property name="classificationUdc" label="UDC Classification" domain="Work" marc="080--/a+c" tag="080" sfcodes="a+c" level="property"/>	
</vocab>
);

declare variable $marc2bfutils:lang-xwalk:=

(

<xml-langs edited="January 11, 2013">
<!--from http://www.loc.gov/standards/iso639-2/php/code_list.php-->
<language language-name="Afar" iso6391="aa" xmllang="aa">
      <iso6392>aar</iso6392>
   </language>
   <language language-name="Abkhazian" iso6391="ab" xmllang="ab">
      <iso6392>abk</iso6392>
   </language>
   <language language-name="Achinese" iso6391="" xmllang="ace">
      <iso6392>ace</iso6392>
   </language>
   <language language-name="Acoli" iso6391="" xmllang="ach">
      <iso6392>ach</iso6392>
   </language>
   <language language-name="Adangme" iso6391="" xmllang="ada">
      <iso6392>ada</iso6392>
   </language>
   <language language-name="Adyghe; Adygei" iso6391="" xmllang="ady">
      <iso6392>ady</iso6392>
   </language>
   <language language-name="Afro-Asiatic languages" iso6391="" xmllang="afa">
      <iso6392>afa</iso6392>
   </language>
   <language language-name="Afrihili" iso6391="" xmllang="afh">
      <iso6392>afh</iso6392>
   </language>
   <language language-name="Afrikaans" iso6391="af" xmllang="af">
      <iso6392>afr</iso6392>
   </language>
   <language language-name="Ainu" iso6391="" xmllang="ain">
      <iso6392>ain</iso6392>
   </language>
   <language language-name="Akan" iso6391="ak" xmllang="ak">
      <iso6392>aka</iso6392>
   </language>
   <language language-name="Akkadian" iso6391="" xmllang="akk">
      <iso6392>akk</iso6392>
   </language>
   <language language-name="Albanian" iso6391="sq" xmllang="sq">
      <iso6392>sqi</iso6392>
      <iso6392>alb</iso6392>
   </language>
   <language language-name="Aleut" iso6391="" xmllang="ale">
      <iso6392>ale</iso6392>
   </language>
   <language language-name="Algonquian languages" iso6391="" xmllang="alg">
      <iso6392>alg</iso6392>
   </language>
   <language language-name="Southern Altai" iso6391="" xmllang="alt">
      <iso6392>alt</iso6392>
   </language>
   <language language-name="Amharic" iso6391="am" xmllang="am">
      <iso6392>amh</iso6392>
   </language>
   <language language-name="English, Old (ca.450-1100)" iso6391="" xmllang="ang">
      <iso6392>ang</iso6392>
   </language>
   <language language-name="Angika" iso6391="" xmllang="anp">
      <iso6392>anp</iso6392>
   </language>
   <language language-name="Apache languages" iso6391="" xmllang="apa">
      <iso6392>apa</iso6392>
   </language>
   <language language-name="Arabic" iso6391="ar" xmllang="ar">
      <iso6392>ara</iso6392>
   </language>
   <language language-name="Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)"
             iso6391=""
             xmllang="arc">
      <iso6392>arc</iso6392>
   </language>
   <language language-name="Aragonese" iso6391="an" xmllang="an">
      <iso6392>arg</iso6392>
   </language>
   <language language-name="Armenian" iso6391="hy" xmllang="hy">
      <iso6392>hye</iso6392>
      <iso6392>arm</iso6392>
   </language>
   <language language-name="Mapudungun; Mapuche" iso6391="" xmllang="arn">
      <iso6392>arn</iso6392>
   </language>
   <language language-name="Arapaho" iso6391="" xmllang="arp">
      <iso6392>arp</iso6392>
   </language>
   <language language-name="Artificial languages" iso6391="" xmllang="art">
      <iso6392>art</iso6392>
   </language>
   <language language-name="Arawak" iso6391="" xmllang="arw">
      <iso6392>arw</iso6392>
   </language>
   <language language-name="Assamese" iso6391="as" xmllang="as">
      <iso6392>asm</iso6392>
   </language>
   <language language-name="Asturian; Bable; Leonese; Asturleonese" iso6391="" xmllang="ast">
      <iso6392>ast</iso6392>
   </language>
   <language language-name="Athapascan languages" iso6391="" xmllang="ath">
      <iso6392>ath</iso6392>
   </language>
   <language language-name="Australian languages" iso6391="" xmllang="aus">
      <iso6392>aus</iso6392>
   </language>
   <language language-name="Avaric" iso6391="av" xmllang="av">
      <iso6392>ava</iso6392>
   </language>
   <language language-name="Avestan" iso6391="ae" xmllang="ae">
      <iso6392>ave</iso6392>
   </language>
   <language language-name="Awadhi" iso6391="" xmllang="awa">
      <iso6392>awa</iso6392>
   </language>
   <language language-name="Aymara" iso6391="ay" xmllang="ay">
      <iso6392>aym</iso6392>
   </language>
   <language language-name="Azerbaijani" iso6391="az" xmllang="az">
      <iso6392>aze</iso6392>
   </language>
   <language language-name="Banda languages" iso6391="" xmllang="bad">
      <iso6392>bad</iso6392>
   </language>
   <language language-name="Bamileke languages" iso6391="" xmllang="bai">
      <iso6392>bai</iso6392>
   </language>
   <language language-name="Bashkir" iso6391="ba" xmllang="ba">
      <iso6392>bak</iso6392>
   </language>
   <language language-name="Baluchi" iso6391="" xmllang="bal">
      <iso6392>bal</iso6392>
   </language>
   <language language-name="Bambara" iso6391="bm" xmllang="bm">
      <iso6392>bam</iso6392>
   </language>
   <language language-name="Balinese" iso6391="" xmllang="ban">
      <iso6392>ban</iso6392>
   </language>
   <language language-name="Basque" iso6391="eu" xmllang="eu">
      <iso6392>eus</iso6392>
      <iso6392>baq</iso6392>
   </language>
   <language language-name="Basa" iso6391="" xmllang="bas">
      <iso6392>bas</iso6392>
   </language>
   <language language-name="Baltic languages" iso6391="" xmllang="bat">
      <iso6392>bat</iso6392>
   </language>
   <language language-name="Beja; Bedawiyet" iso6391="" xmllang="bej">
      <iso6392>bej</iso6392>
   </language>
   <language language-name="Belarusian" iso6391="be" xmllang="be">
      <iso6392>bel</iso6392>
   </language>
   <language language-name="Bemba" iso6391="" xmllang="bem">
      <iso6392>bem</iso6392>
   </language>
   <language language-name="Bengali" iso6391="bn" xmllang="bn">
      <iso6392>ben</iso6392>
   </language>
   <language language-name="Berber languages" iso6391="" xmllang="ber">
      <iso6392>ber</iso6392>
   </language>
   <language language-name="Bhojpuri" iso6391="" xmllang="bho">
      <iso6392>bho</iso6392>
   </language>
   <language language-name="Bihari languages" iso6391="bh" xmllang="bh">
      <iso6392>bih</iso6392>
   </language>
   <language language-name="Bikol" iso6391="" xmllang="bik">
      <iso6392>bik</iso6392>
   </language>
   <language language-name="Bini; Edo" iso6391="" xmllang="bin">
      <iso6392>bin</iso6392>
   </language>
   <language language-name="Bislama" iso6391="bi" xmllang="bi">
      <iso6392>bis</iso6392>
   </language>
   <language language-name="Siksika" iso6391="" xmllang="bla">
      <iso6392>bla</iso6392>
   </language>
   <language language-name="Bantu languages" iso6391="" xmllang="bnt">
      <iso6392>bnt</iso6392>
   </language>
   <language language-name="Tibetan" iso6391="bo" xmllang="bo">
      <iso6392>bod</iso6392>
      <iso6392>tib</iso6392>
   </language>
   <language language-name="Bosnian" iso6391="bs" xmllang="bs">
      <iso6392>bos</iso6392>
   </language>
   <language language-name="Braj" iso6391="" xmllang="bra">
      <iso6392>bra</iso6392>
   </language>
   <language language-name="Breton" iso6391="br" xmllang="br">
      <iso6392>bre</iso6392>
   </language>
   <language language-name="Batak languages" iso6391="" xmllang="btk">
      <iso6392>btk</iso6392>
   </language>
   <language language-name="Buriat" iso6391="" xmllang="bua">
      <iso6392>bua</iso6392>
   </language>
   <language language-name="Buginese" iso6391="" xmllang="bug">
      <iso6392>bug</iso6392>
   </language>
   <language language-name="Bulgarian" iso6391="bg" xmllang="bg">
      <iso6392>bul</iso6392>
   </language>
   <language language-name="Burmese" iso6391="my" xmllang="my">
      <iso6392>mya</iso6392>
      <iso6392>bur</iso6392>
   </language>
   <language language-name="Blin; Bilin" iso6391="" xmllang="byn">
      <iso6392>byn</iso6392>
   </language>
   <language language-name="Caddo" iso6391="" xmllang="cad">
      <iso6392>cad</iso6392>
   </language>
   <language language-name="Central American Indian languages" iso6391="" xmllang="cai">
      <iso6392>cai</iso6392>
   </language>
   <language language-name="Galibi Carib" iso6391="" xmllang="car">
      <iso6392>car</iso6392>
   </language>
   <language language-name="Catalan; Valencian" iso6391="ca" xmllang="ca">
      <iso6392>cat</iso6392>
   </language>
   <language language-name="Caucasian languages" iso6391="" xmllang="cau">
      <iso6392>cau</iso6392>
   </language>
   <language language-name="Cebuano" iso6391="" xmllang="ceb">
      <iso6392>ceb</iso6392>
   </language>
   <language language-name="Celtic languages" iso6391="" xmllang="cel">
      <iso6392>cel</iso6392>
   </language>
   <language language-name="Czech" iso6391="cs" xmllang="cs">
      <iso6392>ces</iso6392>
      <iso6392>cze</iso6392>
   </language>
   <language language-name="Chamorro" iso6391="ch" xmllang="ch">
      <iso6392>cha</iso6392>
   </language>
   <language language-name="Chibcha" iso6391="" xmllang="chb">
      <iso6392>chb</iso6392>
   </language>
   <language language-name="Chechen" iso6391="ce" xmllang="ce">
      <iso6392>che</iso6392>
   </language>
   <language language-name="Chagatai" iso6391="" xmllang="chg">
      <iso6392>chg</iso6392>
   </language>
   <language language-name="Chinese" iso6391="zh" xmllang="zh">
      <iso6392>zho</iso6392>
      <iso6392>chi</iso6392>
   </language>
   <language language-name="Chuukese" iso6391="" xmllang="chk">
      <iso6392>chk</iso6392>
   </language>
   <language language-name="Mari" iso6391="" xmllang="chm">
      <iso6392>chm</iso6392>
   </language>
   <language language-name="Chinook jargon" iso6391="" xmllang="chn">
      <iso6392>chn</iso6392>
   </language>
   <language language-name="Choctaw" iso6391="" xmllang="cho">
      <iso6392>cho</iso6392>
   </language>
   <language language-name="Chipewyan; Dene Suline" iso6391="" xmllang="chp">
      <iso6392>chp</iso6392>
   </language>
   <language language-name="Cherokee" iso6391="" xmllang="chr">
      <iso6392>chr</iso6392>
   </language>
   <language language-name="Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic"
             iso6391="cu"
             xmllang="cu">
      <iso6392>chu</iso6392>
   </language>
   <language language-name="Chuvash" iso6391="cv" xmllang="cv">
      <iso6392>chv</iso6392>
   </language>
   <language language-name="Cheyenne" iso6391="" xmllang="chy">
      <iso6392>chy</iso6392>
   </language>
   <language language-name="Chamic languages" iso6391="" xmllang="cmc">
      <iso6392>cmc</iso6392>
   </language>
   <language language-name="Coptic" iso6391="" xmllang="cop">
      <iso6392>cop</iso6392>
   </language>
   <language language-name="Cornish" iso6391="kw" xmllang="kw">
      <iso6392>cor</iso6392>
   </language>
   <language language-name="Corsican" iso6391="co" xmllang="co">
      <iso6392>cos</iso6392>
   </language>
   <language language-name="Creoles and pidgins, English based" iso6391="" xmllang="cpe">
      <iso6392>cpe</iso6392>
   </language>
   <language language-name="Creoles and pidgins, French-based" iso6391="" xmllang="cpf">
      <iso6392>cpf</iso6392>
   </language>
   <language language-name="Creoles and pidgins, Portuguese-based" iso6391="" xmllang="cpp">
      <iso6392>cpp</iso6392>
   </language>
   <language language-name="Cree" iso6391="cr" xmllang="cr">
      <iso6392>cre</iso6392>
   </language>
   <language language-name="Crimean Tatar; Crimean Turkish" iso6391="" xmllang="crh">
      <iso6392>crh</iso6392>
   </language>
   <language language-name="Creoles and pidgins" iso6391="" xmllang="crp">
      <iso6392>crp</iso6392>
   </language>
   <language language-name="Kashubian" iso6391="" xmllang="csb">
      <iso6392>csb</iso6392>
   </language>
   <language language-name="Cushitic languages" iso6391="" xmllang="cus">
      <iso6392>cus</iso6392>
   </language>
   <language language-name="Welsh" iso6391="cy" xmllang="cy">
      <iso6392>cym</iso6392>
      <iso6392>wel</iso6392>
   </language>
   <language language-name="Dakota" iso6391="" xmllang="dak">
      <iso6392>dak</iso6392>
   </language>
   <language language-name="Danish" iso6391="da" xmllang="da">
      <iso6392>dan</iso6392>
   </language>
   <language language-name="Dargwa" iso6391="" xmllang="dar">
      <iso6392>dar</iso6392>
   </language>
   <language language-name="Land Dayak languages" iso6391="" xmllang="day">
      <iso6392>day</iso6392>
   </language>
   <language language-name="Delaware" iso6391="" xmllang="del">
      <iso6392>del</iso6392>
   </language>
   <language language-name="Slave (Athapascan)" iso6391="" xmllang="den">
      <iso6392>den</iso6392>
   </language>
   <language language-name="German" iso6391="de" xmllang="de">
      <iso6392>deu</iso6392>
      <iso6392>ger</iso6392>
   </language>
   <language language-name="Dogrib" iso6391="" xmllang="dgr">
      <iso6392>dgr</iso6392>
   </language>
   <language language-name="Dinka" iso6391="" xmllang="din">
      <iso6392>din</iso6392>
   </language>
   <language language-name="Divehi; Dhivehi; Maldivian" iso6391="dv" xmllang="dv">
      <iso6392>div</iso6392>
   </language>
   <language language-name="Dogri" iso6391="" xmllang="doi">
      <iso6392>doi</iso6392>
   </language>
   <language language-name="Dravidian languages" iso6391="" xmllang="dra">
      <iso6392>dra</iso6392>
   </language>
   <language language-name="Lower Sorbian" iso6391="" xmllang="dsb">
      <iso6392>dsb</iso6392>
   </language>
   <language language-name="Duala" iso6391="" xmllang="dua">
      <iso6392>dua</iso6392>
   </language>
   <language language-name="Dutch, Middle (ca.1050-1350)" iso6391="" xmllang="dum">
      <iso6392>dum</iso6392>
   </language>
   <language language-name="Dutch; Flemish" iso6391="nl" xmllang="nl">
      <iso6392>nld</iso6392>
      <iso6392>dut</iso6392>
   </language>
   <language language-name="Dyula" iso6391="" xmllang="dyu">
      <iso6392>dyu</iso6392>
   </language>
   <language language-name="Dzongkha" iso6391="dz" xmllang="dz">
      <iso6392>dzo</iso6392>
   </language>
   <language language-name="Efik" iso6391="" xmllang="efi">
      <iso6392>efi</iso6392>
   </language>
   <language language-name="Egyptian (Ancient)" iso6391="" xmllang="egy">
      <iso6392>egy</iso6392>
   </language>
   <language language-name="Ekajuk" iso6391="" xmllang="eka">
      <iso6392>eka</iso6392>
   </language>
   <language language-name="Greek, Modern (1453-)" iso6391="el" xmllang="el">
      <iso6392>ell</iso6392>
      <iso6392>gre</iso6392>
   </language>
   <language language-name="Elamite" iso6391="" xmllang="elx">
      <iso6392>elx</iso6392>
   </language>
   <language language-name="English" iso6391="en" xmllang="en">
      <iso6392>eng</iso6392>
   </language>
   <language language-name="English, Middle (1100-1500)" iso6391="" xmllang="enm">
      <iso6392>enm</iso6392>
   </language>
   <language language-name="Esperanto" iso6391="eo" xmllang="eo">
      <iso6392>epo</iso6392>
   </language>
   <language language-name="Estonian" iso6391="et" xmllang="et">
      <iso6392>est</iso6392>
   </language>
   <language language-name="Ewe" iso6391="ee" xmllang="ee">
      <iso6392>ewe</iso6392>
   </language>
   <language language-name="Ewondo" iso6391="" xmllang="ewo">
      <iso6392>ewo</iso6392>
   </language>
   <language language-name="Fang" iso6391="" xmllang="fan">
      <iso6392>fan</iso6392>
   </language>
   <language language-name="Faroese" iso6391="fo" xmllang="fo">
      <iso6392>fao</iso6392>
   </language>
   <language language-name="Persian" iso6391="fa" xmllang="fa">
      <iso6392>fas</iso6392>
      <iso6392>per</iso6392>
   </language>
   <language language-name="Fanti" iso6391="" xmllang="fat">
      <iso6392>fat</iso6392>
   </language>
   <language language-name="Fijian" iso6391="fj" xmllang="fj">
      <iso6392>fij</iso6392>
   </language>
   <language language-name="Filipino; Pilipino" iso6391="" xmllang="fil">
      <iso6392>fil</iso6392>
   </language>
   <language language-name="Finnish" iso6391="fi" xmllang="fi">
      <iso6392>fin</iso6392>
   </language>
   <language language-name="Finno-Ugrian languages" iso6391="" xmllang="fiu">
      <iso6392>fiu</iso6392>
   </language>
   <language language-name="Fon" iso6391="" xmllang="fon">
      <iso6392>fon</iso6392>
   </language>
   <language language-name="French" iso6391="fr" xmllang="fr">
      <iso6392>fra</iso6392>
      <iso6392>fre</iso6392>
   </language>
   <language language-name="French, Middle (ca.1400-1600)" iso6391="" xmllang="frm">
      <iso6392>frm</iso6392>
   </language>
   <language language-name="French, Old (842-ca.1400)" iso6391="" xmllang="fro">
      <iso6392>fro</iso6392>
   </language>
   <language language-name="Northern Frisian" iso6391="" xmllang="frr">
      <iso6392>frr</iso6392>
   </language>
   <language language-name="Eastern Frisian" iso6391="" xmllang="frs">
      <iso6392>frs</iso6392>
   </language>
   <language language-name="Western Frisian" iso6391="fy" xmllang="fy">
      <iso6392>fry</iso6392>
   </language>
   <language language-name="Fulah" iso6391="ff" xmllang="ff">
      <iso6392>ful</iso6392>
   </language>
   <language language-name="Friulian" iso6391="" xmllang="fur">
      <iso6392>fur</iso6392>
   </language>
   <language language-name="Ga" iso6391="" xmllang="gaa">
      <iso6392>gaa</iso6392>
   </language>
   <language language-name="Gayo" iso6391="" xmllang="gay">
      <iso6392>gay</iso6392>
   </language>
   <language language-name="Gbaya" iso6391="" xmllang="gba">
      <iso6392>gba</iso6392>
   </language>
   <language language-name="Germanic languages" iso6391="" xmllang="gem">
      <iso6392>gem</iso6392>
   </language>
   <language language-name="Georgian" iso6391="ka" xmllang="ka">
      <iso6392>kat</iso6392>
      <iso6392>geo</iso6392>
   </language>
   <language language-name="Geez" iso6391="" xmllang="gez">
      <iso6392>gez</iso6392>
   </language>
   <language language-name="Gilbertese" iso6391="" xmllang="gil">
      <iso6392>gil</iso6392>
   </language>
   <language language-name="Gaelic; Scottish Gaelic" iso6391="gd" xmllang="gd">
      <iso6392>gla</iso6392>
   </language>
   <language language-name="Irish" iso6391="ga" xmllang="ga">
      <iso6392>gle</iso6392>
   </language>
   <language language-name="Galician" iso6391="gl" xmllang="gl">
      <iso6392>glg</iso6392>
   </language>
   <language language-name="Manx" iso6391="gv" xmllang="gv">
      <iso6392>glv</iso6392>
   </language>
   <language language-name="German, Middle High (ca.1050-1500)" iso6391="" xmllang="gmh">
      <iso6392>gmh</iso6392>
   </language>
   <language language-name="German, Old High (ca.750-1050)" iso6391="" xmllang="goh">
      <iso6392>goh</iso6392>
   </language>
   <language language-name="Gondi" iso6391="" xmllang="gon">
      <iso6392>gon</iso6392>
   </language>
   <language language-name="Gorontalo" iso6391="" xmllang="gor">
      <iso6392>gor</iso6392>
   </language>
   <language language-name="Gothic" iso6391="" xmllang="got">
      <iso6392>got</iso6392>
   </language>
   <language language-name="Grebo" iso6391="" xmllang="grb">
      <iso6392>grb</iso6392>
   </language>
   <language language-name="Greek, Ancient (to 1453)" iso6391="" xmllang="grc">
      <iso6392>grc</iso6392>
   </language>
   <language language-name="Guarani" iso6391="gn" xmllang="gn">
      <iso6392>grn</iso6392>
   </language>
   <language language-name="Swiss German; Alemannic; Alsatian" iso6391="" xmllang="gsw">
      <iso6392>gsw</iso6392>
   </language>
   <language language-name="Gujarati" iso6391="gu" xmllang="gu">
      <iso6392>guj</iso6392>
   </language>
   <language language-name="Gwich'in" iso6391="" xmllang="gwi">
      <iso6392>gwi</iso6392>
   </language>
   <language language-name="Haida" iso6391="" xmllang="hai">
      <iso6392>hai</iso6392>
   </language>
   <language language-name="Haitian; Haitian Creole" iso6391="ht" xmllang="ht">
      <iso6392>hat</iso6392>
   </language>
   <language language-name="Hausa" iso6391="ha" xmllang="ha">
      <iso6392>hau</iso6392>
   </language>
   <language language-name="Hawaiian" iso6391="" xmllang="haw">
      <iso6392>haw</iso6392>
   </language>
   <language language-name="Hebrew" iso6391="he" xmllang="he">
      <iso6392>heb</iso6392>
   </language>
   <language language-name="Herero" iso6391="hz" xmllang="hz">
      <iso6392>her</iso6392>
   </language>
   <language language-name="Hiligaynon" iso6391="" xmllang="hil">
      <iso6392>hil</iso6392>
   </language>
   <language language-name="Himachali languages; Western Pahari languages" iso6391=""
             xmllang="him">
      <iso6392>him</iso6392>
   </language>
   <language language-name="Hindi" iso6391="hi" xmllang="hi">
      <iso6392>hin</iso6392>
   </language>
   <language language-name="Hittite" iso6391="" xmllang="hit">
      <iso6392>hit</iso6392>
   </language>
   <language language-name="Hmong; Mong" iso6391="" xmllang="hmn">
      <iso6392>hmn</iso6392>
   </language>
   <language language-name="Hiri Motu" iso6391="ho" xmllang="ho">
      <iso6392>hmo</iso6392>
   </language>
   <language language-name="Croatian" iso6391="hr" xmllang="hr">
      <iso6392>hrv</iso6392>
   </language>
   <language language-name="Upper Sorbian" iso6391="" xmllang="hsb">
      <iso6392>hsb</iso6392>
   </language>
   <language language-name="Hungarian" iso6391="hu" xmllang="hu">
      <iso6392>hun</iso6392>
   </language>
   <language language-name="Hupa" iso6391="" xmllang="hup">
      <iso6392>hup</iso6392>
   </language>
   <language language-name="Iban" iso6391="" xmllang="iba">
      <iso6392>iba</iso6392>
   </language>
   <language language-name="Igbo" iso6391="ig" xmllang="ig">
      <iso6392>ibo</iso6392>
   </language>
   <language language-name="Icelandic" iso6391="is" xmllang="is">
      <iso6392>isl</iso6392>
      <iso6392>ice</iso6392>
   </language>
   <language language-name="Ido" iso6391="io" xmllang="io">
      <iso6392>ido</iso6392>
   </language>
   <language language-name="Sichuan Yi; Nuosu" iso6391="ii" xmllang="ii">
      <iso6392>iii</iso6392>
   </language>
   <language language-name="Ijo languages" iso6391="" xmllang="ijo">
      <iso6392>ijo</iso6392>
   </language>
   <language language-name="Inuktitut" iso6391="iu" xmllang="iu">
      <iso6392>iku</iso6392>
   </language>
   <language language-name="Interlingue; Occidental" iso6391="ie" xmllang="ie">
      <iso6392>ile</iso6392>
   </language>
   <language language-name="Iloko" iso6391="" xmllang="ilo">
      <iso6392>ilo</iso6392>
   </language>
   <language language-name="Interlingua (International Auxiliary Language Association)"
             iso6391="ia"
             xmllang="ia">
      <iso6392>ina</iso6392>
   </language>
   <language language-name="Indic languages" iso6391="" xmllang="inc">
      <iso6392>inc</iso6392>
   </language>
   <language language-name="Indonesian" iso6391="id" xmllang="id">
      <iso6392>ind</iso6392>
   </language>
   <language language-name="Indo-European languages" iso6391="" xmllang="ine">
      <iso6392>ine</iso6392>
   </language>
   <language language-name="Ingush" iso6391="" xmllang="inh">
      <iso6392>inh</iso6392>
   </language>
   <language language-name="Inupiaq" iso6391="ik" xmllang="ik">
      <iso6392>ipk</iso6392>
   </language>
   <language language-name="Iranian languages" iso6391="" xmllang="ira">
      <iso6392>ira</iso6392>
   </language>
   <language language-name="Iroquoian languages" iso6391="" xmllang="iro">
      <iso6392>iro</iso6392>
   </language>
   <language language-name="Italian" iso6391="it" xmllang="it">
      <iso6392>ita</iso6392>
   </language>
   <language language-name="Javanese" iso6391="jv" xmllang="jv">
      <iso6392>jav</iso6392>
   </language>
   <language language-name="Lojban" iso6391="" xmllang="jbo">
      <iso6392>jbo</iso6392>
   </language>
   <language language-name="Japanese" iso6391="ja" xmllang="ja">
      <iso6392>jpn</iso6392>
   </language>
   <language language-name="Judeo-Persian" iso6391="" xmllang="jpr">
      <iso6392>jpr</iso6392>
   </language>
   <language language-name="Judeo-Arabic" iso6391="" xmllang="jrb">
      <iso6392>jrb</iso6392>
   </language>
   <language language-name="Kara-Kalpak" iso6391="" xmllang="kaa">
      <iso6392>kaa</iso6392>
   </language>
   <language language-name="Kabyle" iso6391="" xmllang="kab">
      <iso6392>kab</iso6392>
   </language>
   <language language-name="Kachin; Jingpho" iso6391="" xmllang="kac">
      <iso6392>kac</iso6392>
   </language>
   <language language-name="Kalaallisut; Greenlandic" iso6391="kl" xmllang="kl">
      <iso6392>kal</iso6392>
   </language>
   <language language-name="Kamba" iso6391="" xmllang="kam">
      <iso6392>kam</iso6392>
   </language>
   <language language-name="Kannada" iso6391="kn" xmllang="kn">
      <iso6392>kan</iso6392>
   </language>
   <language language-name="Karen languages" iso6391="" xmllang="kar">
      <iso6392>kar</iso6392>
   </language>
   <language language-name="Kashmiri" iso6391="ks" xmllang="ks">
      <iso6392>kas</iso6392>
   </language>
   <language language-name="Kanuri" iso6391="kr" xmllang="kr">
      <iso6392>kau</iso6392>
   </language>
   <language language-name="Kawi" iso6391="" xmllang="kaw">
      <iso6392>kaw</iso6392>
   </language>
   <language language-name="Kazakh" iso6391="kk" xmllang="kk">
      <iso6392>kaz</iso6392>
   </language>
   <language language-name="Kabardian" iso6391="" xmllang="kbd">
      <iso6392>kbd</iso6392>
   </language>
   <language language-name="Khasi" iso6391="" xmllang="kha">
      <iso6392>kha</iso6392>
   </language>
   <language language-name="Khoisan languages" iso6391="" xmllang="khi">
      <iso6392>khi</iso6392>
   </language>
   <language language-name="Central Khmer" iso6391="km" xmllang="km">
      <iso6392>khm</iso6392>
   </language>
   <language language-name="Khotanese; Sakan" iso6391="" xmllang="kho">
      <iso6392>kho</iso6392>
   </language>
   <language language-name="Kikuyu; Gikuyu" iso6391="ki" xmllang="ki">
      <iso6392>kik</iso6392>
   </language>
   <language language-name="Kinyarwanda" iso6391="rw" xmllang="rw">
      <iso6392>kin</iso6392>
   </language>
   <language language-name="Kirghiz; Kyrgyz" iso6391="ky" xmllang="ky">
      <iso6392>kir</iso6392>
   </language>
   <language language-name="Kimbundu" iso6391="" xmllang="kmb">
      <iso6392>kmb</iso6392>
   </language>
   <language language-name="Konkani" iso6391="" xmllang="kok">
      <iso6392>kok</iso6392>
   </language>
   <language language-name="Komi" iso6391="kv" xmllang="kv">
      <iso6392>kom</iso6392>
   </language>
   <language language-name="Kongo" iso6391="kg" xmllang="kg">
      <iso6392>kon</iso6392>
   </language>
   <language language-name="Korean" iso6391="ko" xmllang="ko">
      <iso6392>kor</iso6392>
   </language>
   <language language-name="Kosraean" iso6391="" xmllang="kos">
      <iso6392>kos</iso6392>
   </language>
   <language language-name="Kpelle" iso6391="" xmllang="kpe">
      <iso6392>kpe</iso6392>
   </language>
   <language language-name="Karachay-Balkar" iso6391="" xmllang="krc">
      <iso6392>krc</iso6392>
   </language>
   <language language-name="Karelian" iso6391="" xmllang="krl">
      <iso6392>krl</iso6392>
   </language>
   <language language-name="Kru languages" iso6391="" xmllang="kro">
      <iso6392>kro</iso6392>
   </language>
   <language language-name="Kurukh" iso6391="" xmllang="kru">
      <iso6392>kru</iso6392>
   </language>
   <language language-name="Kuanyama; Kwanyama" iso6391="kj" xmllang="kj">
      <iso6392>kua</iso6392>
   </language>
   <language language-name="Kumyk" iso6391="" xmllang="kum">
      <iso6392>kum</iso6392>
   </language>
   <language language-name="Kurdish" iso6391="ku" xmllang="ku">
      <iso6392>kur</iso6392>
   </language>
   <language language-name="Kutenai" iso6391="" xmllang="kut">
      <iso6392>kut</iso6392>
   </language>
   <language language-name="Ladino" iso6391="" xmllang="lad">
      <iso6392>lad</iso6392>
   </language>
   <language language-name="Lahnda" iso6391="" xmllang="lah">
      <iso6392>lah</iso6392>
   </language>
   <language language-name="Lamba" iso6391="" xmllang="lam">
      <iso6392>lam</iso6392>
   </language>
   <language language-name="Lao" iso6391="lo" xmllang="lo">
      <iso6392>lao</iso6392>
   </language>
   <language language-name="Latin" iso6391="la" xmllang="la">
      <iso6392>lat</iso6392>
   </language>
   <language language-name="Latvian" iso6391="lv" xmllang="lv">
      <iso6392>lav</iso6392>
   </language>
   <language language-name="Lezghian" iso6391="" xmllang="lez">
      <iso6392>lez</iso6392>
   </language>
   <language language-name="Limburgan; Limburger; Limburgish" iso6391="li" xmllang="li">
      <iso6392>lim</iso6392>
   </language>
   <language language-name="Lingala" iso6391="ln" xmllang="ln">
      <iso6392>lin</iso6392>
   </language>
   <language language-name="Lithuanian" iso6391="lt" xmllang="lt">
      <iso6392>lit</iso6392>
   </language>
   <language language-name="Mongo" iso6391="" xmllang="lol">
      <iso6392>lol</iso6392>
   </language>
   <language language-name="Lozi" iso6391="" xmllang="loz">
      <iso6392>loz</iso6392>
   </language>
   <language language-name="Luxembourgish; Letzeburgesch" iso6391="lb" xmllang="lb">
      <iso6392>ltz</iso6392>
   </language>
   <language language-name="Luba-Lulua" iso6391="" xmllang="lua">
      <iso6392>lua</iso6392>
   </language>
   <language language-name="Luba-Katanga" iso6391="lu" xmllang="lu">
      <iso6392>lub</iso6392>
   </language>
   <language language-name="Ganda" iso6391="lg" xmllang="lg">
      <iso6392>lug</iso6392>
   </language>
   <language language-name="Luiseno" iso6391="" xmllang="lui">
      <iso6392>lui</iso6392>
   </language>
   <language language-name="Lunda" iso6391="" xmllang="lun">
      <iso6392>lun</iso6392>
   </language>
   <language language-name="Luo (Kenya and Tanzania)" iso6391="" xmllang="luo">
      <iso6392>luo</iso6392>
   </language>
   <language language-name="Lushai" iso6391="" xmllang="lus">
      <iso6392>lus</iso6392>
   </language>
   <language language-name="Macedonian" iso6391="mk" xmllang="mk">
      <iso6392>mkd</iso6392>
      <iso6392>mac</iso6392>
   </language>
   <language language-name="Madurese" iso6391="" xmllang="mad">
      <iso6392>mad</iso6392>
   </language>
   <language language-name="Magahi" iso6391="" xmllang="mag">
      <iso6392>mag</iso6392>
   </language>
   <language language-name="Marshallese" iso6391="mh" xmllang="mh">
      <iso6392>mah</iso6392>
   </language>
   <language language-name="Maithili" iso6391="" xmllang="mai">
      <iso6392>mai</iso6392>
   </language>
   <language language-name="Makasar" iso6391="" xmllang="mak">
      <iso6392>mak</iso6392>
   </language>
   <language language-name="Malayalam" iso6391="ml" xmllang="ml">
      <iso6392>mal</iso6392>
   </language>
   <language language-name="Mandingo" iso6391="" xmllang="man">
      <iso6392>man</iso6392>
   </language>
   <language language-name="Maori" iso6391="mi" xmllang="mi">
      <iso6392>mri</iso6392>
      <iso6392>mao</iso6392>
   </language>
   <language language-name="Austronesian languages" iso6391="" xmllang="map">
      <iso6392>map</iso6392>
   </language>
   <language language-name="Marathi" iso6391="mr" xmllang="mr">
      <iso6392>mar</iso6392>
   </language>
   <language language-name="Masai" iso6391="" xmllang="mas">
      <iso6392>mas</iso6392>
   </language>
   <language language-name="Malay" iso6391="ms" xmllang="ms">
      <iso6392>msa</iso6392>
      <iso6392>may</iso6392>
   </language>
   <language language-name="Moksha" iso6391="" xmllang="mdf">
      <iso6392>mdf</iso6392>
   </language>
   <language language-name="Mandar" iso6391="" xmllang="mdr">
      <iso6392>mdr</iso6392>
   </language>
   <language language-name="Mende" iso6391="" xmllang="men">
      <iso6392>men</iso6392>
   </language>
   <language language-name="Irish, Middle (900-1200)" iso6391="" xmllang="mga">
      <iso6392>mga</iso6392>
   </language>
   <language language-name="Mi'kmaq; Micmac" iso6391="" xmllang="mic">
      <iso6392>mic</iso6392>
   </language>
   <language language-name="Minangkabau" iso6391="" xmllang="min">
      <iso6392>min</iso6392>
   </language>
   <language language-name="Uncoded languages" iso6391="" xmllang="mis">
      <iso6392>mis</iso6392>
   </language>
   <language language-name="Mon-Khmer languages" iso6391="" xmllang="mkh">
      <iso6392>mkh</iso6392>
   </language>
   <language language-name="Malagasy" iso6391="mg" xmllang="mg">
      <iso6392>mlg</iso6392>
   </language>
   <language language-name="Maltese" iso6391="mt" xmllang="mt">
      <iso6392>mlt</iso6392>
   </language>
   <language language-name="Manchu" iso6391="" xmllang="mnc">
      <iso6392>mnc</iso6392>
   </language>
   <language language-name="Manipuri" iso6391="" xmllang="mni">
      <iso6392>mni</iso6392>
   </language>
   <language language-name="Manobo languages" iso6391="" xmllang="mno">
      <iso6392>mno</iso6392>
   </language>
   <language language-name="Mohawk" iso6391="" xmllang="moh">
      <iso6392>moh</iso6392>
   </language>
   <language language-name="Mongolian" iso6391="mn" xmllang="mn">
      <iso6392>mon</iso6392>
   </language>
   <language language-name="Mossi" iso6391="" xmllang="mos">
      <iso6392>mos</iso6392>
   </language>
   <language language-name="Multiple languages" iso6391="" xmllang="mul">
      <iso6392>mul</iso6392>
   </language>
   <language language-name="Munda languages" iso6391="" xmllang="mun">
      <iso6392>mun</iso6392>
   </language>
   <language language-name="Creek" iso6391="" xmllang="mus">
      <iso6392>mus</iso6392>
   </language>
   <language language-name="Mirandese" iso6391="" xmllang="mwl">
      <iso6392>mwl</iso6392>
   </language>
   <language language-name="Marwari" iso6391="" xmllang="mwr">
      <iso6392>mwr</iso6392>
   </language>
   <language language-name="Mayan languages" iso6391="" xmllang="myn">
      <iso6392>myn</iso6392>
   </language>
   <language language-name="Erzya" iso6391="" xmllang="myv">
      <iso6392>myv</iso6392>
   </language>
   <language language-name="Nahuatl languages" iso6391="" xmllang="nah">
      <iso6392>nah</iso6392>
   </language>
   <language language-name="North American Indian languages" iso6391="" xmllang="nai">
      <iso6392>nai</iso6392>
   </language>
   <language language-name="Neapolitan" iso6391="" xmllang="nap">
      <iso6392>nap</iso6392>
   </language>
   <language language-name="Nauru" iso6391="na" xmllang="na">
      <iso6392>nau</iso6392>
   </language>
   <language language-name="Navajo; Navaho" iso6391="nv" xmllang="nv">
      <iso6392>nav</iso6392>
   </language>
   <language language-name="Ndebele, South; South Ndebele" iso6391="nr" xmllang="nr">
      <iso6392>nbl</iso6392>
   </language>
   <language language-name="Ndebele, North; North Ndebele" iso6391="nd" xmllang="nd">
      <iso6392>nde</iso6392>
   </language>
   <language language-name="Ndonga" iso6391="ng" xmllang="ng">
      <iso6392>ndo</iso6392>
   </language>
   <language language-name="Low German; Low Saxon; German, Low; Saxon, Low" iso6391=""
             xmllang="nds">
      <iso6392>nds</iso6392>
   </language>
   <language language-name="Nepali" iso6391="ne" xmllang="ne">
      <iso6392>nep</iso6392>
   </language>
   <language language-name="Nepal Bhasa; Newari" iso6391="" xmllang="new">
      <iso6392>new</iso6392>
   </language>
   <language language-name="Nias" iso6391="" xmllang="nia">
      <iso6392>nia</iso6392>
   </language>
   <language language-name="Niger-Kordofanian languages" iso6391="" xmllang="nic">
      <iso6392>nic</iso6392>
   </language>
   <language language-name="Niuean" iso6391="" xmllang="niu">
      <iso6392>niu</iso6392>
   </language>
   <language language-name="Norwegian Nynorsk; Nynorsk, Norwegian" iso6391="nn" xmllang="nn">
      <iso6392>nno</iso6392>
   </language>
   <language language-name="Bokmål, Norwegian; Norwegian Bokmål" iso6391="nb" xmllang="nb">
      <iso6392>nob</iso6392>
   </language>
   <language language-name="Nogai" iso6391="" xmllang="nog">
      <iso6392>nog</iso6392>
   </language>
   <language language-name="Norse, Old" iso6391="" xmllang="non">
      <iso6392>non</iso6392>
   </language>
   <language language-name="Norwegian" iso6391="no" xmllang="no">
      <iso6392>nor</iso6392>
   </language>
   <language language-name="N'Ko" iso6391="" xmllang="nqo">
      <iso6392>nqo</iso6392>
   </language>
   <language language-name="Pedi; Sepedi; Northern Sotho" iso6391="" xmllang="nso">
      <iso6392>nso</iso6392>
   </language>
   <language language-name="Nubian languages" iso6391="" xmllang="nub">
      <iso6392>nub</iso6392>
   </language>
   <language language-name="Classical Newari; Old Newari; Classical Nepal Bhasa" iso6391=""
             xmllang="nwc">
      <iso6392>nwc</iso6392>
   </language>
   <language language-name="Chichewa; Chewa; Nyanja" iso6391="ny" xmllang="ny">
      <iso6392>nya</iso6392>
   </language>
   <language language-name="Nyamwezi" iso6391="" xmllang="nym">
      <iso6392>nym</iso6392>
   </language>
   <language language-name="Nyankole" iso6391="" xmllang="nyn">
      <iso6392>nyn</iso6392>
   </language>
   <language language-name="Nyoro" iso6391="" xmllang="nyo">
      <iso6392>nyo</iso6392>
   </language>
   <language language-name="Nzima" iso6391="" xmllang="nzi">
      <iso6392>nzi</iso6392>
   </language>
   <language language-name="Occitan (post 1500)" iso6391="oc" xmllang="oc">
      <iso6392>oci</iso6392>
   </language>
   <language language-name="Ojibwa" iso6391="oj" xmllang="oj">
      <iso6392>oji</iso6392>
   </language>
   <language language-name="Oriya" iso6391="or" xmllang="or">
      <iso6392>ori</iso6392>
   </language>
   <language language-name="Oromo" iso6391="om" xmllang="om">
      <iso6392>orm</iso6392>
   </language>
   <language language-name="Osage" iso6391="" xmllang="osa">
      <iso6392>osa</iso6392>
   </language>
   <language language-name="Ossetian; Ossetic" iso6391="os" xmllang="os">
      <iso6392>oss</iso6392>
   </language>
   <language language-name="Turkish, Ottoman (1500-1928)" iso6391="" xmllang="ota">
      <iso6392>ota</iso6392>
   </language>
   <language language-name="Otomian languages" iso6391="" xmllang="oto">
      <iso6392>oto</iso6392>
   </language>
   <language language-name="Papuan languages" iso6391="" xmllang="paa">
      <iso6392>paa</iso6392>
   </language>
   <language language-name="Pangasinan" iso6391="" xmllang="pag">
      <iso6392>pag</iso6392>
   </language>
   <language language-name="Pahlavi" iso6391="" xmllang="pal">
      <iso6392>pal</iso6392>
   </language>
   <language language-name="Pampanga; Kapampangan" iso6391="" xmllang="pam">
      <iso6392>pam</iso6392>
   </language>
   <language language-name="Panjabi; Punjabi" iso6391="pa" xmllang="pa">
      <iso6392>pan</iso6392>
   </language>
   <language language-name="Papiamento" iso6391="" xmllang="pap">
      <iso6392>pap</iso6392>
   </language>
   <language language-name="Palauan" iso6391="" xmllang="pau">
      <iso6392>pau</iso6392>
   </language>
   <language language-name="Persian, Old (ca.600-400 B.C.)" iso6391="" xmllang="peo">
      <iso6392>peo</iso6392>
   </language>
   <language language-name="Philippine languages" iso6391="" xmllang="phi">
      <iso6392>phi</iso6392>
   </language>
   <language language-name="Phoenician" iso6391="" xmllang="phn">
      <iso6392>phn</iso6392>
   </language>
   <language language-name="Pali" iso6391="pi" xmllang="pi">
      <iso6392>pli</iso6392>
   </language>
   <language language-name="Polish" iso6391="pl" xmllang="pl">
      <iso6392>pol</iso6392>
   </language>
   <language language-name="Pohnpeian" iso6391="" xmllang="pon">
      <iso6392>pon</iso6392>
   </language>
   <language language-name="Portuguese" iso6391="pt" xmllang="pt">
      <iso6392>por</iso6392>
   </language>
   <language language-name="Prakrit languages" iso6391="" xmllang="pra">
      <iso6392>pra</iso6392>
   </language>
   <language language-name="Provençal, Old (to 1500);Occitan, Old (to 1500)" iso6391=""
             xmllang="pro">
      <iso6392>pro</iso6392>
   </language>
   <language language-name="Pushto; Pashto" iso6391="ps" xmllang="ps">
      <iso6392>pus</iso6392>
   </language>
   <language language-name="Reserved for local use" iso6391="" xmllang="qaa-qtz">
      <iso6392>qaa-qtz</iso6392>
   </language>
   <language language-name="Quechua" iso6391="qu" xmllang="qu">
      <iso6392>que</iso6392>
   </language>
   <language language-name="Rajasthani" iso6391="" xmllang="raj">
      <iso6392>raj</iso6392>
   </language>
   <language language-name="Rapanui" iso6391="" xmllang="rap">
      <iso6392>rap</iso6392>
   </language>
   <language language-name="Rarotongan; Cook Islands Maori" iso6391="" xmllang="rar">
      <iso6392>rar</iso6392>
   </language>
   <language language-name="Romance languages" iso6391="" xmllang="roa">
      <iso6392>roa</iso6392>
   </language>
   <language language-name="Romansh" iso6391="rm" xmllang="rm">
      <iso6392>roh</iso6392>
   </language>
   <language language-name="Romany" iso6391="" xmllang="rom">
      <iso6392>rom</iso6392>
   </language>
   <language language-name="Romanian; Moldavian; Moldovan" iso6391="ro" xmllang="ro">
      <iso6392>ron</iso6392>
      <iso6392>rum</iso6392>
   </language>
   <language language-name="Rundi" iso6391="rn" xmllang="rn">
      <iso6392>run</iso6392>
   </language>
   <language language-name="Aromanian; Arumanian; Macedo-Romanian" iso6391="" xmllang="rup">
      <iso6392>rup</iso6392>
   </language>
   <language language-name="Russian" iso6391="ru" xmllang="ru">
      <iso6392>rus</iso6392>
   </language>
   <language language-name="Sandawe" iso6391="" xmllang="sad">
      <iso6392>sad</iso6392>
   </language>
   <language language-name="Sango" iso6391="sg" xmllang="sg">
      <iso6392>sag</iso6392>
   </language>
   <language language-name="Yakut" iso6391="" xmllang="sah">
      <iso6392>sah</iso6392>
   </language>
   <language language-name="South American Indian languages" iso6391="" xmllang="sai">
      <iso6392>sai</iso6392>
   </language>
   <language language-name="Salishan languages" iso6391="" xmllang="sal">
      <iso6392>sal</iso6392>
   </language>
   <language language-name="Samaritan Aramaic" iso6391="" xmllang="sam">
      <iso6392>sam</iso6392>
   </language>
   <language language-name="Sanskrit" iso6391="sa" xmllang="sa">
      <iso6392>san</iso6392>
   </language>
   <language language-name="Sasak" iso6391="" xmllang="sas">
      <iso6392>sas</iso6392>
   </language>
   <language language-name="Santali" iso6391="" xmllang="sat">
      <iso6392>sat</iso6392>
   </language>
   <language language-name="Sicilian" iso6391="" xmllang="scn">
      <iso6392>scn</iso6392>
   </language>
   <language language-name="Scots" iso6391="" xmllang="sco">
      <iso6392>sco</iso6392>
   </language>
   <language language-name="Selkup" iso6391="" xmllang="sel">
      <iso6392>sel</iso6392>
   </language>
   <language language-name="Semitic languages" iso6391="" xmllang="sem">
      <iso6392>sem</iso6392>
   </language>
   <language language-name="Irish, Old (to 900)" iso6391="" xmllang="sga">
      <iso6392>sga</iso6392>
   </language>
   <language language-name="Sign Languages" iso6391="" xmllang="sgn">
      <iso6392>sgn</iso6392>
   </language>
   <language language-name="Shan" iso6391="" xmllang="shn">
      <iso6392>shn</iso6392>
   </language>
   <language language-name="Sidamo" iso6391="" xmllang="sid">
      <iso6392>sid</iso6392>
   </language>
   <language language-name="Sinhala; Sinhalese" iso6391="si" xmllang="si">
      <iso6392>sin</iso6392>
   </language>
   <language language-name="Siouan languages" iso6391="" xmllang="sio">
      <iso6392>sio</iso6392>
   </language>
   <language language-name="Sino-Tibetan languages" iso6391="" xmllang="sit">
      <iso6392>sit</iso6392>
   </language>
   <language language-name="Slavic languages" iso6391="" xmllang="sla">
      <iso6392>sla</iso6392>
   </language>
   <language language-name="Slovak" iso6391="sk" xmllang="sk">
      <iso6392>slk</iso6392>
      <iso6392>slo</iso6392>
   </language>
   <language language-name="Slovenian" iso6391="sl" xmllang="sl">
      <iso6392>slv</iso6392>
   </language>
   <language language-name="Southern Sami" iso6391="" xmllang="sma">
      <iso6392>sma</iso6392>
   </language>
   <language language-name="Northern Sami" iso6391="se" xmllang="se">
      <iso6392>sme</iso6392>
   </language>
   <language language-name="Sami languages" iso6391="" xmllang="smi">
      <iso6392>smi</iso6392>
   </language>
   <language language-name="Lule Sami" iso6391="" xmllang="smj">
      <iso6392>smj</iso6392>
   </language>
   <language language-name="Inari Sami" iso6391="" xmllang="smn">
      <iso6392>smn</iso6392>
   </language>
   <language language-name="Samoan" iso6391="sm" xmllang="sm">
      <iso6392>smo</iso6392>
   </language>
   <language language-name="Skolt Sami" iso6391="" xmllang="sms">
      <iso6392>sms</iso6392>
   </language>
   <language language-name="Shona" iso6391="sn" xmllang="sn">
      <iso6392>sna</iso6392>
   </language>
   <language language-name="Sindhi" iso6391="sd" xmllang="sd">
      <iso6392>snd</iso6392>
   </language>
   <language language-name="Soninke" iso6391="" xmllang="snk">
      <iso6392>snk</iso6392>
   </language>
   <language language-name="Sogdian" iso6391="" xmllang="sog">
      <iso6392>sog</iso6392>
   </language>
   <language language-name="Somali" iso6391="so" xmllang="so">
      <iso6392>som</iso6392>
   </language>
   <language language-name="Songhai languages" iso6391="" xmllang="son">
      <iso6392>son</iso6392>
   </language>
   <language language-name="Sotho, Southern" iso6391="st" xmllang="st">
      <iso6392>sot</iso6392>
   </language>
   <language language-name="Spanish; Castilian" iso6391="es" xmllang="es">
      <iso6392>spa</iso6392>
   </language>
   <language language-name="Sardinian" iso6391="sc" xmllang="sc">
      <iso6392>srd</iso6392>
   </language>
   <language language-name="Sranan Tongo" iso6391="" xmllang="srn">
      <iso6392>srn</iso6392>
   </language>
   <language language-name="Serbian" iso6391="sr" xmllang="sr">
      <iso6392>srp</iso6392>
   </language>
   <language language-name="Serer" iso6391="" xmllang="srr">
      <iso6392>srr</iso6392>
   </language>
   <language language-name="Nilo-Saharan languages" iso6391="" xmllang="ssa">
      <iso6392>ssa</iso6392>
   </language>
   <language language-name="Swati" iso6391="ss" xmllang="ss">
      <iso6392>ssw</iso6392>
   </language>
   <language language-name="Sukuma" iso6391="" xmllang="suk">
      <iso6392>suk</iso6392>
   </language>
   <language language-name="Sundanese" iso6391="su" xmllang="su">
      <iso6392>sun</iso6392>
   </language>
   <language language-name="Susu" iso6391="" xmllang="sus">
      <iso6392>sus</iso6392>
   </language>
   <language language-name="Sumerian" iso6391="" xmllang="sux">
      <iso6392>sux</iso6392>
   </language>
   <language language-name="Swahili" iso6391="sw" xmllang="sw">
      <iso6392>swa</iso6392>
   </language>
   <language language-name="Swedish" iso6391="sv" xmllang="sv">
      <iso6392>swe</iso6392>
   </language>
   <language language-name="Classical Syriac" iso6391="" xmllang="syc">
      <iso6392>syc</iso6392>
   </language>
   <language language-name="Syriac" iso6391="" xmllang="syr">
      <iso6392>syr</iso6392>
   </language>
   <language language-name="Tahitian" iso6391="ty" xmllang="ty">
      <iso6392>tah</iso6392>
   </language>
   <language language-name="Tai languages" iso6391="" xmllang="tai">
      <iso6392>tai</iso6392>
   </language>
   <language language-name="Tamil" iso6391="ta" xmllang="ta">
      <iso6392>tam</iso6392>
   </language>
   <language language-name="Tatar" iso6391="tt" xmllang="tt">
      <iso6392>tat</iso6392>
   </language>
   <language language-name="Telugu" iso6391="te" xmllang="te">
      <iso6392>tel</iso6392>
   </language>
   <language language-name="Timne" iso6391="" xmllang="tem">
      <iso6392>tem</iso6392>
   </language>
   <language language-name="Tereno" iso6391="" xmllang="ter">
      <iso6392>ter</iso6392>
   </language>
   <language language-name="Tetum" iso6391="" xmllang="tet">
      <iso6392>tet</iso6392>
   </language>
   <language language-name="Tajik" iso6391="tg" xmllang="tg">
      <iso6392>tgk</iso6392>
   </language>
   <language language-name="Tagalog" iso6391="tl" xmllang="tl">
      <iso6392>tgl</iso6392>
   </language>
   <language language-name="Thai" iso6391="th" xmllang="th">
      <iso6392>tha</iso6392>
   </language>
   <language language-name="Tigre" iso6391="" xmllang="tig">
      <iso6392>tig</iso6392>
   </language>
   <language language-name="Tigrinya" iso6391="ti" xmllang="ti">
      <iso6392>tir</iso6392>
   </language>
   <language language-name="Tiv" iso6391="" xmllang="tiv">
      <iso6392>tiv</iso6392>
   </language>
   <language language-name="Tokelau" iso6391="" xmllang="tkl">
      <iso6392>tkl</iso6392>
   </language>
   <language language-name="Klingon; tlhIngan-Hol" iso6391="" xmllang="tlh">
      <iso6392>tlh</iso6392>
   </language>
   <language language-name="Tlingit" iso6391="" xmllang="tli">
      <iso6392>tli</iso6392>
   </language>
   <language language-name="Tamashek" iso6391="" xmllang="tmh">
      <iso6392>tmh</iso6392>
   </language>
   <language language-name="Tonga (Nyasa)" iso6391="" xmllang="tog">
      <iso6392>tog</iso6392>
   </language>
   <language language-name="Tonga (Tonga Islands)" iso6391="to" xmllang="to">
      <iso6392>ton</iso6392>
   </language>
   <language language-name="Tok Pisin" iso6391="" xmllang="tpi">
      <iso6392>tpi</iso6392>
   </language>
   <language language-name="Tsimshian" iso6391="" xmllang="tsi">
      <iso6392>tsi</iso6392>
   </language>
   <language language-name="Tswana" iso6391="tn" xmllang="tn">
      <iso6392>tsn</iso6392>
   </language>
   <language language-name="Tsonga" iso6391="ts" xmllang="ts">
      <iso6392>tso</iso6392>
   </language>
   <language language-name="Turkmen" iso6391="tk" xmllang="tk">
      <iso6392>tuk</iso6392>
   </language>
   <language language-name="Tumbuka" iso6391="" xmllang="tum">
      <iso6392>tum</iso6392>
   </language>
   <language language-name="Tupi languages" iso6391="" xmllang="tup">
      <iso6392>tup</iso6392>
   </language>
   <language language-name="Turkish" iso6391="tr" xmllang="tr">
      <iso6392>tur</iso6392>
   </language>
   <language language-name="Altaic languages" iso6391="" xmllang="tut">
      <iso6392>tut</iso6392>
   </language>
   <language language-name="Tuvalu" iso6391="" xmllang="tvl">
      <iso6392>tvl</iso6392>
   </language>
   <language language-name="Twi" iso6391="tw" xmllang="tw">
      <iso6392>twi</iso6392>
   </language>
   <language language-name="Tuvinian" iso6391="" xmllang="tyv">
      <iso6392>tyv</iso6392>
   </language>
   <language language-name="Udmurt" iso6391="" xmllang="udm">
      <iso6392>udm</iso6392>
   </language>
   <language language-name="Ugaritic" iso6391="" xmllang="uga">
      <iso6392>uga</iso6392>
   </language>
   <language language-name="Uighur; Uyghur" iso6391="ug" xmllang="ug">
      <iso6392>uig</iso6392>
   </language>
   <language language-name="Ukrainian" iso6391="uk" xmllang="uk">
      <iso6392>ukr</iso6392>
   </language>
   <language language-name="Umbundu" iso6391="" xmllang="umb">
      <iso6392>umb</iso6392>
   </language>
   <language language-name="Undetermined" iso6391="" xmllang="und">
      <iso6392>und</iso6392>
   </language>
   <language language-name="Urdu" iso6391="ur" xmllang="ur">
      <iso6392>urd</iso6392>
   </language>
   <language language-name="Uzbek" iso6391="uz" xmllang="uz">
      <iso6392>uzb</iso6392>
   </language>
   <language language-name="Vai" iso6391="" xmllang="vai">
      <iso6392>vai</iso6392>
   </language>
   <language language-name="Venda" iso6391="ve" xmllang="ve">
      <iso6392>ven</iso6392>
   </language>
   <language language-name="Vietnamese" iso6391="vi" xmllang="vi">
      <iso6392>vie</iso6392>
   </language>
   <language language-name="Volapük" iso6391="vo" xmllang="vo">
      <iso6392>vol</iso6392>
   </language>
   <language language-name="Votic" iso6391="" xmllang="vot">
      <iso6392>vot</iso6392>
   </language>
   <language language-name="Wakashan languages" iso6391="" xmllang="wak">
      <iso6392>wak</iso6392>
   </language>
   <language language-name="Wolaitta; Wolaytta" iso6391="" xmllang="wal">
      <iso6392>wal</iso6392>
   </language>
   <language language-name="Waray" iso6391="" xmllang="war">
      <iso6392>war</iso6392>
   </language>
   <language language-name="Washo" iso6391="" xmllang="was">
      <iso6392>was</iso6392>
   </language>
   <language language-name="Sorbian languages" iso6391="" xmllang="wen">
      <iso6392>wen</iso6392>
   </language>
   <language language-name="Walloon" iso6391="wa" xmllang="wa">
      <iso6392>wln</iso6392>
   </language>
   <language language-name="Wolof" iso6391="wo" xmllang="wo">
      <iso6392>wol</iso6392>
   </language>
   <language language-name="Kalmyk; Oirat" iso6391="" xmllang="xal">
      <iso6392>xal</iso6392>
   </language>
   <language language-name="Xhosa" iso6391="xh" xmllang="xh">
      <iso6392>xho</iso6392>
   </language>
   <language language-name="Yao" iso6391="" xmllang="yao">
      <iso6392>yao</iso6392>
   </language>
   <language language-name="Yapese" iso6391="" xmllang="yap">
      <iso6392>yap</iso6392>
   </language>
   <language language-name="Yiddish" iso6391="yi" xmllang="yi">
      <iso6392>yid</iso6392>
   </language>
   <language language-name="Yoruba" iso6391="yo" xmllang="yo">
      <iso6392>yor</iso6392>
   </language>
   <language language-name="Yupik languages" iso6391="" xmllang="ypk">
      <iso6392>ypk</iso6392>
   </language>
   <language language-name="Zapotec" iso6391="" xmllang="zap">
      <iso6392>zap</iso6392>
   </language>
   <language language-name="Blissymbols; Blissymbolics; Bliss" iso6391="" xmllang="zbl">
      <iso6392>zbl</iso6392>
   </language>
   <language language-name="Zenaga" iso6391="" xmllang="zen">
      <iso6392>zen</iso6392>
   </language>
   <language language-name="Standard Moroccan Tamazight" iso6391="" xmllang="zgh">
      <iso6392>zgh</iso6392>
   </language>
   <language language-name="Zhuang; Chuang" iso6391="za" xmllang="za">
      <iso6392>zha</iso6392>
   </language>
   <language language-name="Zande languages" iso6391="" xmllang="znd">
      <iso6392>znd</iso6392>
   </language>
   <language language-name="Zulu" iso6391="zu" xmllang="zu">
      <iso6392>zul</iso6392>
   </language>
   <language language-name="Zuni" iso6391="" xmllang="zun">
      <iso6392>zun</iso6392>
   </language>
   <language language-name="No linguistic content; Not applicable" iso6391="" xmllang="zxx">
      <iso6392>zxx</iso6392>
   </language>
   <language language-name="Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki" iso6391=""
             xmllang="zza">
      <iso6392>zza</iso6392>
   </language>
</xml-langs>
);
(:~
:   This function takes a string and 
:   attempts to clean it up 
:   ISBD punctuation. based on 260 cleaning 
:
:   @param  $s        is fn:string
:   @return fn:string
:)
declare function marc2bfutils:clean-string(
    $s as xs:string?
    ) as xs:string
{ 
	if (fn:exists($s)) then
	    let $s:= fn:replace($s,"from old catalog","","i")
	    let $s := fn:replace($s, "([\[\];]+)", "")
	    let $s := fn:replace($s, " :", "")
	    let $s := fn:normalize-space($s)
	    (:if it contains unbalanced parens, delete:)
	    let $s:= if (fn:contains($s,"(") and fn:not(fn:contains($s, ")")) ) then
	     		fn:replace($s, "\(", "")
	    	else if (fn:contains($s,")") and fn:not(fn:contains($s, "(")) ) then
	    		fn:replace($s, "\)", "")	    	
	    	else $s
	    
	    return 
	        if ( fn:ends-with($s, ",") ) then
	            fn:substring($s, 1, (fn:string-length($s) - 1) )
	        else
	            $s
	
	else ""
};

(:~
:   This function takes a name string and 
:   attempts to clean it up (trailing commas only first).
:
:   @param  $s        is fn:string
:   @return fn:string
:)
declare function marc2bfutils:clean-name-string(
    $s as xs:string?
    ) as xs:string
{ 
	if (fn:exists($s)) then
	    let $s:= fn:replace($s,",$","","i")    	    
	    return 	    
	            $s
	
	else ""

};
(:~
:   This function takes a string and 
:   attempts to clean it up 
:   ISBD punctuation. based on title cleaning: you dont' want to strip out ";" 
:
:   @param  $s        is fn:string
:   @return fn:string
:)
declare function marc2bfutils:clean-title-string(
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
:   not used; copied from marc2mods
:
:  $marcxml    is marcxml:record
:   @return ??
:)
declare function marc2bfutils:generate-controlfields(
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
			element bf:modeOfIssuance{$issuance},
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
