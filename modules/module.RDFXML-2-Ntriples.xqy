xquery version "1.0";

(:
:   Module Name: RDFXML 2 ntriples
:
:   Module Version: 1.0
:
:   Date: 2010 Oct 18
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:    Takes RDF/XML converts to ntriples.
:       xdmp extension used in order to quote/escape otherwise valid
:       XML.
:
:   NB: This file has been modified to remove a ML dependency at
:   around line 126 (xdmp:quote).  Could be a problem for Literal types.  
:)
   
(:~
:   Takes RDF/XML and transforms to ntriples.  xdmp extension 
:   used in order to quote/escape otherwise valid XML.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since October 18, 2010
:   @version 1.0
:)
module namespace    rdfxml2nt   = "info:lc/id-modules/rdfxml2nt#";
declare namespace   rdf         = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:~
:   This is the main function.  Input RDF/XML, output ntiples.
:   All other functions are local.
:
:   @param  $rdfxml        node() is the RDF/XML  
:   @return ntripes as xs:string
:)
declare function rdfxml2nt:rdfxml2ntriples($rdfxml as node()) as xs:string {
    if( $rdfxml[1][fn:local-name() eq "RDF"] ) then
        let $resources := 
            for $i in $rdfxml/child::node()[fn:name()]
            return rdfxml2nt:parse_class($i, "")
        return fn:string-join($resources, "&#x0a;")
    else ("Invalid source: RDF/XML should have a root node of RDF.") 
};

(:~
:   This function parses a RDF Class.
:
:   @param  $node        node()
:   @param  $uri_pass   xs:string, is the URI passed 
:                       from the property evaluation and to be
:                       used in the absence of a rdf:about or rdf:nodeID  
:   @return ntripes as xs:string
:)
declare function rdfxml2nt:parse_class(
    $node as node(), 
    $uri_pass as xs:string
    ) as item()* {
    
    let $uri :=
        if ($node/@rdf:about ne "") then
            fn:concat( "<", fn:data($node/@rdf:about), ">")
        else if ($node/@rdf:about eq "") then
            fn:concat( "<", fn:data($node/ancestor::rdf:RDF[1]/@xml:base), ">")
        else if ($node/@rdf:ID ne "" and $node/ancestor::rdf:RDF[1]/@xml:base) then
            fn:concat( "<", fn:data($node/ancestor::rdf:RDF[1]/@xml:base), $node/@rdf:ID, ">")
        else if ($node/@rdf:nodeID) then
            fn:concat( "_:", fn:data($node/@rdf:nodeID))
        else if ($uri_pass ne "") then
            $uri_pass
        else
            rdfxml2nt:return_bnode($node)
    let $triple := 
        if (fn:local-name($node) eq "Description") then
            (: fn:concat( $uri, " <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <" , $node/child::node()[fn:name(.) eq "rdf:type"]/@rdf:resource , "> . " , fn:codepoints-to-string(10)) :)
            ""
        else if (fn:namespace-uri($node) and fn:local-name($node)) then
            fn:concat( $uri, " <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <" , fn:namespace-uri($node) , fn:local-name($node) , "> . " , fn:codepoints-to-string(10))
        else if (fn:namespace-uri($node/parent::node()) and fn:local-name($node)) then
            (: this is hardly sound, but seems to fix the issue :)
            fn:concat( $uri, " <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <" , fn:namespace-uri($node/parent::node()) , fn:local-name($node) , "> . " , fn:codepoints-to-string(10))
        else ""
    return
        if ($node/child::node()[fn:not(rdf:type)]) then
            let $properties := 
                for $i at $pos in $node/child::node()[fn:not(rdf:type) and fn:name()]
                    return rdfxml2nt:parse_property($i , $uri)
            return fn:concat($triple , fn:string-join($properties , ""))
        else
            $triple
};

(:~
:   This function parses a RDF Property
:
:   @param  $node       node()
:   @param  $uri        xs:string, is the URI passed 
:                       from the Class evaluation
:   @return ntripes as xs:string
:)
declare function rdfxml2nt:parse_property(
    $node as node(), 
    $uri as xs:string
    ) as item()* {
    
    let $resource_string := 
        if ($node/@rdf:resource) then
            fn:concat("<" , fn:data($node/@rdf:resource) , ">")
        else if ($node[@rdf:parseType eq "Collection"] and fn:not($node/@rdf:nodeID)) then
            rdfxml2nt:return_bnode($node/child::node()[1])
        else if ($node/child::node()[1]/@rdf:nodeID) then
            fn:concat("_:" , fn:data($node/child::node()[1]/@rdf:nodeID))
        else if ($node/child::node()[1]/@rdf:about) then
            fn:concat("<" , fn:data($node/child::node()[1]/@rdf:about) , ">")
        else if ($node[@rdf:parseType eq "Literal"]) then
            fn:concat('"' , 
                fn:replace(
                    fn:replace(
                        fn:replace(
                             $node/child::node()/text(), 
                            '&quot;',
                            '\\"'
                        ),
                        '\n',
                        '\\r\\n'
                    ),
                    "\t",
                    '\\t'
                ),
            '"^^<http://www.w3.org/2000/01/rdf-schema#Literal>')
            (: '"Comment"' :)
        else if (fn:local-name($node/child::node()[fn:name()][1]) ne "") then
            rdfxml2nt:return_bnode($node/child::node()[fn:name()][1])
        else
            fn:concat('"' , rdfxml2nt:clean_string(xs:string($node)) , '"',
                if ($node/@xml:lang) then
                    fn:concat('@' , xs:string($node/@xml:lang) )
                else if ($node/@rdf:datatype) then
                    fn:concat('^^<' , xs:string($node/@rdf:datatype) , '>' )
                else ()
            )
            
    let $triple := fn:concat( $uri , " <" , fn:namespace-uri($node) , fn:local-name($node) , "> " , $resource_string , " . ", fn:codepoints-to-string(10) )
    return
        if ($node/child::node()[fn:name()] and $node[@rdf:parseType eq "Collection"]) then
            let $classes := rdfxml2nt:parse_collection($node/child::node()[fn:name()][1] , $resource_string)
            return fn:concat($triple , fn:string-join($classes,''))
            
        else if ($node/child::node()[fn:name()] and fn:not($node/@rdf:parseType)) then
            (:  is this the correct "if statement"?  Could there be a parseType 
                *and* a desire to traverse the tree at this point? :)
            let $classes := 
                for $i in $node/child::node()[fn:name()]
                return rdfxml2nt:parse_class($i , $resource_string)
            return fn:concat($triple , fn:string-join($classes,""))
        else
            $triple
            
};

(:~
:   Parse a rdf:parseType="Collection" element
:
:   @param  $node       node()
:   @param  $uri        xs:string, is the URI passed 
:                       from the Property evaluation
:   @return ntripes as xs:string
:)
declare function rdfxml2nt:parse_collection(
    $node as node(), 
    $uri as xs:string
    ) as item()* {
    
    let $resource_string := 
        if ($node/@rdf:resource) then
            fn:concat("<" , fn:data($node/@rdf:resource) , ">")
        else if ($node/@rdf:about) then
            fn:concat( "<", fn:data($node/@rdf:about), ">")
        else if ($node/@rdf:nodeID) then
            fn:concat( "_:", fn:data($node/@rdf:nodeID))
        else
            rdfxml2nt:return_bnode($node/child::node()[fn:name()][1])
            
    let $triple := fn:concat( $uri , " <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> " , $resource_string , " . " , fn:codepoints-to-string(10))
    let $following_bnode :=
        if ($node/following-sibling::node()[fn:name()][1]) then 
            rdfxml2nt:return_bnode_collection($node/following-sibling::node()[fn:name()][1])
        else 
            fn:false()
    let $rest := 
        if ($following_bnode) then
            fn:concat( $uri , " <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> " , $following_bnode , " . " , fn:codepoints-to-string(10))
        else
            fn:concat( $uri , " <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> . " , fn:codepoints-to-string(10))

    let $uri := $resource_string
    let $class := rdfxml2nt:parse_class($node, $uri)
        
    return
        if ($following_bnode) then
            let $sibling :=  rdfxml2nt:parse_collection($node/following-sibling::node()[fn:name()][1] , $following_bnode)
            return fn:concat($triple, $rest, $class, fn:string-join( $sibling, "" ) )
        else
            fn:concat($triple, $rest, $class)

};

(:~
:   Helper funtion, to return a _bnode
:
:   @param  $node       node()
:   @return _bnode as xs:string
:)
declare function rdfxml2nt:return_bnode($node as node()) as xs:string
 {
    let $uri4bnode := rdfxml2nt:return_uri4bnode($node/ancestor-or-self::node()[fn:name()='rdf:RDF']/child::node()[1]/@rdf:about)
    let $unique_num := xs:integer( fn:count($node/ancestor-or-self::node()) + fn:count($node/preceding::node()) )
    return fn:concat("_:bnode" , xs:string($unique_num) , $uri4bnode)
};

(:~
:   Helper funtion, to return a _bnode for a collection
:
:   @param  $node       node()
:   @return _bnode as xs:string
:)
declare function rdfxml2nt:return_bnode_collection($node as node()) as xs:string {
    let $uri4bnode := rdfxml2nt:return_uri4bnode($node/ancestor-or-self::node()[fn:name()='rdf:RDF']/child::node()[1]/@rdf:about)
    let $unique_num := xs:integer( fn:count($node/ancestor-or-self::node()) + fn:count($node/preceding::node()) )
    return fn:concat("_:bnode" , "0" , xs:string($unique_num))
};

(:~
:   bnode distinction - munges the URI in an attempt to 
:   create a better probability for bnode uniqueness
:
:   @param  $uri        xs:string
:   @return _bnode      as xs:string
:)
declare function rdfxml2nt:return_uri4bnode($uri as xs:string) as xs:string {
    let $uriparts := fn:tokenize($uri, '/')
    let $uriparts4bnode := 
            for $u in $uriparts
            let $str := 
                if ( fn:matches($u , '\.|:|#') eq fn:false() ) then
                    $u
                else ()
            return $str
    return fn:string-join( $uriparts4bnode , '')
};


(:~
:   Clean string of odd characters.
:
:   @param  $string       string to clean
:   @return xs:string
:)
declare function rdfxml2nt:clean_string($str as xs:string) as xs:string
 {
    let $str := fn:replace( $str, '\\', '\\\\')
    let $str := fn:replace( $str , '&quot;' , '\\"')
    let $str := fn:replace( $str, "\n", "\\r\\n")
    let $str := fn:replace( $str, "’", "'")
    let $str := fn:replace( $str, '“|”', '\\"')
    let $str := fn:replace( $str, 'ā', '\\u0101')
    return $str
};



