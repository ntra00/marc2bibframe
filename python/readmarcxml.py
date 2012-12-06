#!/usr/bin/env python
'''
readmarcml - the main MARCXML parser, produces the base layer of JSON
'''
#take a MARCXML file, interprets its records, and does some augmentation, creating multiple Exhibit JSON files

#Authority files: http://en.wikipedia.org/wiki/Authority_control

import io
import sys
sys.path.append("lib/")

import re
import os
import logging
import itertools
import json

import amara
from amara.lib.util import coroutine
from amara.lib import U

from marc import *
from marcspecialfields import canonicalize_isbns, process_leader, process_008

FALINKFIELD = u'856u'
#CATLINKFIELD = u'010a'
CATLINKFIELD = u'LCCN'
CACHEDIR = os.path.expanduser('~/tmp')

NON_ISBN_CHARS = re.compile(u'\D')

def invert_dict(d):
    #http://code.activestate.com/recipes/252143-invert-a-dictionary-one-liner/#c3
    #See also: http://pypi.python.org/pypi/bidict
        #Though note: http://code.activestate.com/recipes/576968/#c2
    inv = {}
    for k, v in d.iteritems():
        keys = inv.setdefault(v, [])
        keys.append(k)
    return inv

PREFIXES = {u'ma': 'http://www.loc.gov/MARC21/slim', u'me': 'http://www.loc.gov/METS/'}

#ISBNNU_PAT = 'http://isbn.nu/{0}.xml'
ISBNNU_PAT = 'http://isbn.nu/{0}'
OPENLIBRARY_COVER_PAT = 'http://covers.openlibrary.org/b/isbn/{0}-M.jpg'
#http://catalog.hathitrust.org/api/volumes/brief/json/isbn:0030110408 -> http://catalog.hathitrust.org/Record/000578050

class subobjects(object):
    def __init__(self, exhibit_sink):
        self.ix = 0
        self.exhibit_sink = exhibit_sink
        return

    def add(self, props, sink=None, last=False):
        sink = sink or self.exhibit_sink
        objid = 'obj_' + str(self.ix + 1)
        code = props[u'marccode']
        item = {
            u'id': objid,
            u'label': objid,
            u'type': 'Object',
        }
        for k, v in props.items():
            #Try to substitute Marc field code names with friendlier property names
            lookup = code + k
            if lookup in FIELD_RENAMINGS:
                subst = FIELD_RENAMINGS[lookup]
                k = subst
                item[k] = v
                
        emitter(item, sink)
        if last == True:
            sink.write(",\n")
        self.ix += 1
        print >> sys.stderr, 'Processing authority: ', item[u'id']
        return objid

        #Work out the item's catalogue link
        lcid = item.get(CATLINKFIELD)
        if code == '010' and lcid:
            item['catLink'] = 'http://lccn.loc.gov/' + ''.join(lcid.split())
            
            
def emitter(dictry, stream, indent=4):
    '''
    A framework for streamed output of exhibit records
    stream - the output stream for the data
    '''
    #FIXME: use the with statement to handle situations where the caller doesn't wrap up
    print >> stream, '\n{'
    first_item = True
    for a, b in dictry.items():
        if first_item:
            first_item = False
        else:
            stream.write(unicode(',\n'))
            # json.dump(item, stream, indent=indent)
        if (type(b) is not tuple):
            print >> stream, '\t',
            json.dump(a, stream, indent=indent)
            print >> stream, ': ',
            json.dump(b, stream, indent=indent)
        else:
            fItem = True
            for k, v in b.items():
                if fItem:
                    fItem = False
                else:
                    stream.write(unicode(',\n'))
                print >> stream, '\t\t',
                json.dump(k, stream, indent=indent)
                print >> stream, ': ',
                json.dump(v, stream, indent=8)
            
    print >> stream, '}',
    # stream.write(unicode(']'))
    return
            

#def records2json(recs, work_sink, instance_sink, stub_sink, objects_sink, annotations_sink, logger=logging):
def records2json(recs, work_sink, instance_sink, objects_sink, annotations_sink, logger=logging):
    '''
    
    '''


    subobjs = subobjects(objects_sink)
    @coroutine
    def receive_items():
        '''
        Receives each record and processes it by creating an item
        dict which is then forwarded to the sink
        '''
        ix = 1
        while True:
            rec = yield
            recid = u'_' + str(ix)

            leader = U(rec.xml_select(u'ma:leader', prefixes=PREFIXES))
            work_item = {
                u'id': u'work' + recid,
                u'label': recid,
                #u'label': u'{0}, {1}'.format(row['TPNAML'], row['TPNAMF']),
                u'type': u'WorkRecord',
            }
            print >> sys.stderr, 'Begin processing Work: ', work_item[u'id']

            #Instance starts with same as work, with leader added
            instance_item = {
                u'leader': leader,
            }
            instance_item.update(work_item)
            instance_item[u'id'] = u'instance' + recid
            instance_item[u'type'] = u'InstanceRecord'
            work_item[u'instance'] = u'instance' + recid

            for cf in rec.xml_select(u'ma:controlfield', prefixes=PREFIXES):
                key = u'cftag_' + U(cf.xml_select(u'@tag'))
                val = U(cf)
                if list(cf.xml_select(u'ma:subfield', prefixes=PREFIXES)):
                    for sf in cf.xml_select(u'ma:subfield', prefixes=PREFIXES):
                        code = U(sf.xml_select(u'@code'))
                        sfval = U(sf)
                        #For now assume all leader fields are instance level
                        instance_item[key + code] = sfval
                else:
                    #For now assume all leader fields are instance level
                    instance_item[key] = val

            for df in rec.xml_select(u'ma:datafield', prefixes=PREFIXES):
                code = U(df.xml_select(u'@tag'))
                key = u'dftag_' + code
                val = U(df)
                if list(df.xml_select(u'ma:subfield', prefixes=PREFIXES)):
                    subfields = dict(( (U(sf.xml_select(u'@code')), U(sf)) for sf in df.xml_select(u'ma:subfield', prefixes=PREFIXES) ))
                    lookup = code
                    #See if any of the field codes represents a reference to an object which can be materialized
                    handled = False
                    if code in MATERIALIZE:
                        (subst, extra_props) = MATERIALIZE[code]
                        props = {u'marccode': code}
                        props.update(extra_props)
                        #props.update(other_properties)
                        props.update(subfields)
                        #work_item[FIELD_RENAMINGS.get(code, code)] = subid
                        # subid = subobjs.add(props)
                        if ix < len(recs):
                            subid = subobjs.add(props)
                            objects_sink.write(",\n")
                        else:
                            subid = subobjs.add(props, last=True)
                            
                        if code in INSTANCE_FIELDS:
                            instance_item.setdefault(subst, []).append(subid)
                        elif code in WORK_FIELDS:
                            work_item.setdefault(subst, []).append(subid)

                        handled = True

                    if code in MATERIALIZE_VIA_ANNOTATION:
                        (subst, extra_object_props, extra_annotation_props) = MATERIALIZE_VIA_ANNOTATION[code]
                        object_props = {u'marccode': code}
                        object_props.update(extra_object_props)
                        #props.update(other_properties)

                        #Separate annotation subfields from object subfields
                        object_subfields = subfields.copy()
                        annotation_subfields = {}
                        for k, v in object_subfields.items():
                            if code+k in ANNOTATIONS_FIELDS:
                                annotation_subfields[k] = v
                                del object_subfields[k]

                        object_props.update(object_subfields)
                        # objectid = subobjs.add(object_props)
                        # if ix < len(recs):
                        #    objects_sink.write(",\n")
                        if ix < len(recs):
                            objectid = subobjs.add(object_props)
                            objects_sink.write(",\n")
                        else:
                            objectid = subobjs.add(object_props, last=True)

                        annid = u'annotation' + recid
                        annotation_item = {
                            u'id': annid,
                            u'label': recid,
                            subst: objectid,
                            u'type': u'Annotation',
                            u'on_work': work_item[u'id'],
                            u'on_instance': instance_item[u'id'],
                        }
                        annotation_item.update(extra_annotation_props)
                        annotation_item.update(annotation_subfields)

                        emitter(annotation_item, annotations_sink)
                        if ix < len(recs):
                            annotations_sink.write(",\n")
                        # annotations_sink.write(annotation_item)
                        print >> sys.stderr, 'Processing annotation: ', annotation_item[u'id'] , "\n"

                        if code in INSTANCE_FIELDS:
                            instance_item.setdefault('annotation', []).append(annid)
                        elif code in WORK_FIELDS:
                            work_item.setdefault('annotation', []).append(annid)
                        
                        #The actual subfields go to the annotations sink
                        #annotations_props = {u'annotates': instance_item[u'id']}
                        #annotations_props.update(props)
                        #subid = subobjs.add(annotations_props, annotations_sink)
                        #The reference is from the instance ID
                        #instance_item.setdefault(subst, []).append(subid)

                        handled = True



                        #work_item.setdefault(FIELD_RENAMINGS.get(code, code), []).append(subid)

                    #See if any of the field+subfield codes represents a reference to an object which can be materialized
                    if not handled:
                        for k, v in subfields.items():
                            lookup = code + k
                            if lookup in MATERIALIZE:
                                (subst, extra_props) = MATERIALIZE[lookup]
                                props = {u'marccode': code, k: v}
                                props.update(extra_props)
                                #print >> sys.stderr, lookup, k, props, 
                                if ix < len(recs):
                                    subid = subobjs.add(props)
                                    objects_sink.write(",\n")
                                else:
                                    subid = subobjs.add(props, last=True)
                                    
                                if lookup in INSTANCE_FIELDS or code in INSTANCE_FIELDS:
                                    instance_item.setdefault(subst, []).append(subid)
                                elif lookup in WORK_FIELDS or code in WORK_FIELDS:
                                    work_item.setdefault(subst, []).append(subid)
                                handled = True

                            else:
                                field_name = u'dftag_' + lookup
                                if lookup in FIELD_RENAMINGS:
                                    field_name = FIELD_RENAMINGS[lookup]
                                #Handle the simple field_nameitution of a label name for a MARC code
                                if lookup in INSTANCE_FIELDS or code in INSTANCE_FIELDS:
                                    instance_item.setdefault(field_name, []).append(v)
                                elif lookup in WORK_FIELDS or code in WORK_FIELDS:
                                    work_item.setdefault(field_name, []).append(v)


                #print >> sys.stderr, lookup, key
                elif not handled:
                    if code in INSTANCE_FIELDS:
                        instance_item[key] = val
                    elif code in WORK_FIELDS:
                        work_item[key] = val
                else:
                    if code in INSTANCE_FIELDS:
                        instance_item[key] = val
                    elif code in WORK_FIELDS:
                        work_item[key] = val

            #link = work_item.get(u'cftag_008')


            #Handle ISBNs re: https://foundry.zepheira.com/issues/1976
            new_instances = []

            isbns = instance_item.get('isbn', [])
            def isbn_list(isbns):
                isbn_tags = {}
                for isbn in isbns:
                    parts = isbn.split(None, 1)
                    #Remove any cruft from ISBNs. Leave just the digits
                    cleaned_isbn = NON_ISBN_CHARS.subn(u'', parts[0])[0]
                    if len(parts) == 1:
                        #FIXME: More generally strip non-digit chars from ISBNs
                        isbn_tags[cleaned_isbn] = None
                    else:
                        isbn_tags[cleaned_isbn] = parts[1]
                c14ned = canonicalize_isbns(isbn_tags.keys())
                for c14nisbn, variants in invert_dict(c14ned).items():
                    #We'll use the heuristic that the longest ISBN number is the best
                    variants.sort(key=len, reverse=True) # sort by descending length
                    yield variants[0], isbn_tags[variants[0]]
                return# list(isbnset)

            base_instance_id = instance_item[u'id']
            instance_ids = []
            subscript = ord(u'a')
            for subix, (inum, itype) in enumerate(isbn_list(isbns)):
                #print >> sys.stderr, subix, inum, itype
                subitem = instance_item.copy()
                subitem[u'isbn'] = inum
                subitem[u'id'] = base_instance_id + (unichr(subscript + subix) if subix else u'')
                if itype: subitem[u'isbnType'] = itype
                instance_ids.append(subitem[u'id'])
                new_instances.append(subitem)
                isbnnu_url = ISBNNU_PAT.format(inum)
                subitem[u'isbnnu'] = isbnnu_url
                #U(doc.xml_select(u'/rss/channel/item/link'))
                subitem[u'openlibcover'] = OPENLIBRARY_COVER_PAT.format(inum)
                #time.sleep(2) #Be polite!

                #instance_item[u'isbn'] = isbns[0]

            if not new_instances:
                #Make sure it's created as an instance even if it has no ISBN
                new_instances.append(instance_item)
                instance_ids.append(base_instance_id)

            work_item[u'instance'] = instance_ids

            special_properties = {}
            for k, v in process_leader(leader):
                special_properties.setdefault(k, set()).add(v)

            for k, v in process_008(instance_item[u'cftag_008']):
                special_properties.setdefault(k, set()).add(v)

            #We get some repeated values out of leader & 008 processing, and we want to
            #Remove dupes so we did so by working with sets then converting to lists
            for k, v in special_properties.items():
                special_properties[k] = list(v)

            instance_item.update(special_properties)

            #reduce lists of just one item
            for k, v in work_item.items():
                if type(v) is list and len(v) == 1:
                    work_item[k] = v[0]
            
            # work_sink.write(work_item)
            emitter(work_item, work_sink)
            if ix < len(recs):
                work_sink.write(",\n")

            def send_instance(instance):
                print >> sys.stderr, 'Processing instance: ', instance[u'id']
                emitter(instance, instance_sink)
            
            i = 0
            for ninst in new_instances:
                i += 1
                send_instance(ninst)
                if i < len(new_instances):
                    instance_sink.write(",\n")
                
            
            if ix < len(recs):
                instance_sink.write(",\n")

            print >> sys.stderr, 'Finished processing Work: ', work_item[u'id'] , "\n"
            ix += 1

        return

    target = receive_items()

    for rec in recs:
        #target.send(map(string.strip, row))
        target.send(rec)

    target.close()
    return


if __name__ == "__main__":
    #python readmarcxml.py sample-files.xml lcsample
    #python -m btframework.marccuncher sample-files.xml /tmp/lcsample
    
    try:
        marcxmlfile = sys.argv[1]
    except IndexError:
        print >> sys.stderr, 'Error: Did not specify MARC/XML file. \n\nUsage: python readmarcxml.py /path/to/marc/xml/file [/path/to/output/file] \n'
        sys.exit(0)
        
    indoc = amara.parse(sys.argv[1]) 
    
    try:
        name_base = sys.argv[2]
    except IndexError:
        name_base = "default"
    
    work_outf = io.open('html/data/' + name_base + '.work.json', 'w+b')
    instance_outf = io.open('html/data/' + name_base + '.instance.json', 'w+b')
    #stub_outf = open(name_base + '.stub.json', 'w')
    objects_outf = io.open('html/data/' + name_base + '.object.json', 'w+b')
    annotations_outf = io.open('html/data/' + name_base + '.annotations.json', 'w+b')

    work_emitter = work_outf
    instance_emitter = instance_outf
    #stub_emitter = emitter.emitter(stub_outf)
    objects_emitter = objects_outf
    annotations_emitter = annotations_outf

    recs = indoc.xml_select(u'/ma:collection/ma:record', prefixes=PREFIXES)

    #outf = open(name_base + '.json', 'w')
    if len(sys.argv) > 3:
        count = int(sys.argv[3])
        recs = itertools.islice(recs, count)

    #records2json(recs, work_emitter, instance_emitter, stub_emitter, objects_emitter, annotations_emitter)
    work_emitter.write('{"items": [')
    instance_emitter.write('{"items": [')
    objects_emitter.write('{"items": [')
    annotations_emitter.write('{"items": [')
            
    records2json(recs, work_emitter, instance_emitter, objects_emitter, annotations_emitter)

    work_emitter.write(']}')
    instance_emitter.write(']}')
    objects_emitter.write('{}') # this seems like the quickest fix for that problem.  Yes, that one.
    objects_emitter.write(']}')
    annotations_emitter.write('{}') # Sometimes, it's just easier.
    annotations_emitter.write(']}')
    
    
    work_emitter.close()
    instance_emitter.close()
    #stub_emitter.close()
    objects_emitter.close()
    annotations_emitter.close()
    #print >> sys.stderr, requests_cache.get_cache()
