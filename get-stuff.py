#!/usr/bin/python3

import json
import os
import requests
import sqlite3
import xml.etree.ElementTree

# our bbox
# w 0.681152
# s 7.07908802481
# e 0.922851562335
# n 7.297088
# w,s,e,n 0.681152,7.07908802481,0.922851562335,7.297088
# s,w,n,e 7.07908802481,0.681152,7.297088,0.922851562335

if not os.path.exists('data'):
    os.makedirs('data')
if not os.path.exists('data/changesets'):
    os.makedirs('data/changesets')

db_conn = None
db_cursor = None

# Overpass QL
nodes_query_test = '''
[out:json];
node(7.07908802481,0.681152,7.297088,0.922851562335);
out meta qt 10;
'''
nodes_and_ways_query = '''
[out:json];
node(7.07908802481,0.681152,7.297088,0.922851562335);
<;
/*added by auto repair*/
(._;>;);
/*end of auto repair*/
out meta qt;
'''

overpass_ql_url = 'http://overpass-api.de/api/interpreter'
overpass_ql_headers = {'Content-Type': 'text/plain'}

osm_api_url = 'http://api.openstreetmap.org/api/0.6/'
#osm_api_url = 'http://api06.dev.openstreetmap.org/api/0.6/'


def prepare_db():
    print('Preparing sqlite database...')
    global db_conn, db_cursor
    #db_conn = sqlite3.connect(':memory:')
    db_conn = sqlite3.connect('data/sqlite.db')
    db_cursor = db_conn.cursor()
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS Changeset (
            changesetId integer not null primary key,
            user text not null,
            userId integer not null,
            createdAt text not null,
            min_lat number not null,
            min_lon number not null,
            max_lat number not null,
            max_lon number not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS ChangesetTag (
            changesetId integer not null
                REFERENCES Changeset(changesetId),
            key         text not null,
            value       text not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS Node (
            nodeId    integer not null primary key,
            lat       number  not null,
            lon       number  not null,
            timestamp text not null,
            version   integer not null,
            changesetId integer not null
                REFERENCES Changeset(changesetId),
            user      text not null,
            userId    integer not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS Way (
            wayId       integer not null primary key,
            timestamp   text    not null,
            version     integer not null,
            changesetId integer not null
                REFERENCES Changeset(changesetId),
            user        text    not null,
            userId      integer not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS WayNode (
            wayId  integer not null
                REFERENCES Way(wayId),
            nodeId integer not null
                REFERENCES Node(nodeId)
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE IF NOT EXISTS WayTag (
            wayId integer not null
                REFERENCES Way(wayId),
            key   text not null,
            value text not null
        )
    ''')


def get_stuff_in_area():
    if os.path.isfile('data/osm.json'):
        return

    print('Requesting OSM stuff from the given bounding box using Overpass Query Language...')
    r = requests.get(overpass_ql_url, headers=overpass_ql_headers, data=nodes_and_ways_query)
    r.raise_for_status()

    print('  Writing result to disk...')
    with open('data/osm.json', 'wt') as f:
        f.write(r.text)


def store_stuff_in_db(osm_json_path):
    print('Storing local cache of Overpass API results into sqlite db...')
    jsn = None
    with open(osm_json_path) as f:
        jsn = json.load(f)
    i = 0
    percent_done = 0
    for element_jsn in jsn['elements']:
        i += 1
        new_percent_done = int((float(i) / len(jsn['elements'])) * 100)
        if new_percent_done != percent_done:
            db_conn.commit()  # save to disk every 1% (is that what this does?)
            if new_percent_done % 10 == 0:
                print('  {}% through source data...'.format(new_percent_done))
        percent_done = new_percent_done
        if element_jsn['type'] == 'node':
            db_create_node(element_jsn)
        elif element_jsn['type'] == 'way':
            db_create_way(element_jsn)
        else:
            print('  Ignored element type:', element_jsn['type'])


def db_create_node(node_jsn):
    try:
        db_cursor.execute(
            'INSERT OR ABORT INTO Node (nodeId, lat, lon, timestamp, version, changesetId, user, userId) VALUES (?,?,?,?,?,?,?,?);',
            [
                node_jsn['id'],
                node_jsn['lat'],
                node_jsn['lon'],
                node_jsn['timestamp'],
                node_jsn['version'],
                node_jsn['changeset'],
                node_jsn['user'],
                node_jsn['uid'],
            ]
        )
    except sqlite3.IntegrityError as e:
        return


def db_create_way(way_jsn):
    if 'nodes' not in way_jsn.keys():
        print("Way {} doesn't have nodes; skipped.".format(way_jsn['id']))
        return

    try:
        db_cursor.execute(
            'INSERT OR ABORT INTO Way (wayId, timestamp, version, changesetId, user, userId) VALUES (?,?,?,?,?,?);',
            [
                way_jsn['id'],
                way_jsn['timestamp'],
                way_jsn['version'],
                way_jsn['changeset'],
                way_jsn['user'],
                way_jsn['uid'],
            ]
        )
    except sqlite3.IntegrityError as e:
        return
    for node_id in way_jsn['nodes']:
        db_cursor.execute('INSERT INTO WayNode (wayId, nodeId) VALUES (?,?);', [way_jsn['id'], node_id])
    if 'tags' in way_jsn.keys():
        for k,v in way_jsn['tags'].items():
            db_cursor.execute('INSERT INTO WayTag (wayId, key, value) VALUES (?,?,?);', [way_jsn['id'], k, v])


def store_changeset_from_api(id):
    xml_filepath = 'data/changesets/{}.xml'.format(id)
    if os.path.isfile(xml_filepath):
        return

    r = requests.get(osm_api_url + 'changeset/' + str(id))
    r.raise_for_status()

    with open(xml_filepath, 'wt') as f:
        f.write(r.text)
    return


def store_changeset_file_in_db(id):
    osm_element = xml.etree.ElementTree.parse('data/changesets/{}.xml'.format(id)).getroot()
    for changeset_element in osm_element:
        sql_params = [
            changeset_element.attrib['id'],
            changeset_element.attrib['user'],
            changeset_element.attrib['uid'],
            changeset_element.attrib['created_at'],
            changeset_element.attrib['min_lat'],
            changeset_element.attrib['min_lon'],
            changeset_element.attrib['max_lat'],
            changeset_element.attrib['max_lon'],
        ]
        try:
            db_cursor.execute(
                '''
                    INSERT OR ABORT INTO Changeset (changesetId, user, userId, createdAt, min_lat, min_lon, max_lat, max_lon)
                    VALUES (?,?,?,?,?,?,?,?)
                ''',
                sql_params
            )
        except sqlite3.IntegrityError as e:
            continue  # if changeset exists, skip inserting its tags
        for tag_element in changeset_element:
            sql_params = [
                changeset_element.attrib['id'],
                tag_element.attrib['k'],
                tag_element.attrib['v'],
            ]
            db_cursor.execute(
                'INSERT INTO ChangesetTag (changesetId, key, value) VALUES (?,?,?)',
                sql_params
            )
    return


def get_changeset_from_disk(id):
    xml_filepath = 'data/changesets/{}.xml'.format(id)
    if not os.path.isfile(xml_filepath):
        return None
    return xml.etree.ElementTree.parse(xml_filepath).getroot()
    with open(xml_filepath) as f:
        return f.read()


# Get changeset data
changeset_url_format = 'http://api.openstreetmap.org/api/0.6/changeset/{}'  # (id)
# example_output
'''
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="OpenStreetMap server" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">
    <changeset id="41177103" user="searker" uid="4230804" created_at="2016-08-01T20:31:11Z" closed_at="2016-08-01T21:37:33Z" open="false" min_lat="7.004053" min_lon="0.6677343" max_lat="7.3201202" max_lon="0.8197606" comments_count="0">
        <tag k="source" v="Bing"/>
        <tag k="created_by" v="JOSM/1.5 (10526 en)"/>
        <tag k="comment" v="#hotosm-project-2044 #PeaceCorps #PCTogo source=Bing"/>
    </changeset>
</osm>
'''

prepare_db()
get_stuff_in_area()  # super expensive!  Wait minutes for multi-GB download of JSON.

store_stuff_in_db('data/osm.json')

#store_changeset_from_api(41177103)
#store_changeset_file_in_db(41177103)
#print(db_conn.execute('select * from Changeset').fetchall())

db_conn.commit()
db_conn.close()

