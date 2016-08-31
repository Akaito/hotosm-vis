#!/usr/bin/python3

import os
import requests
import sqlite3

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
    db_conn = sqlite3.connect(':memory:')
    db_cursor = db_conn.cursor()
    db_cursor.execute('''
        CREATE TABLE Changeset (
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
        CREATE TABLE ChangesetTag (
            changesetId integer not null
                REFERENCES Changeset(changesetId),
            key         text not null,
            value       text not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE Node (
            nodeId    integer not null primary key,
            lat       number  not null,
            lon       number  not null,
            version   integer not null,
            timestamp text not null,
            user      text not null,
            userId    integer not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE Way (
            wayId       integer not null primary key,
            timestamp   text    not null,
            changesetId integer not null
                REFERENCES Changeset(changesetId),
            user        text    not null,
            userId      integer not null
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE WayNode (
            wayId  integer not null
                REFERENCES Way(wayId),
            nodeId integer not null
                REFERENCES Node(nodeId)
        )
    ''')
    db_cursor.execute('''
        CREATE TABLE WayTag (
            wayId integer not null
                REFERENCES Way(wayId),
            key   text not null,
            value text not null
        )
    ''')


def get_stuff_in_area():
    if os.path.isfile('data/01_nodes.json'):
        return

    r = requests.get(overpass_ql_url, headers=overpass_ql_headers, data=nodes_and_ways_query)
    r.raise_for_status()

    with open('data/01_nodes.json', 'wt') as f:
        f.write(r.text)


def store_changeset_from_api(id):
    xml_filepath = 'data/changesets/{}.xml'.format(id)
    if os.path.isfile(xml_filepath):
        return

    r = requests.get(osm_api_url + 'changeset/' + str(id))
    r.raise_for_status()

    with open(xml_filepath, 'wt') as f:
        f.write(r.text)
    return


def get_changeset_from_disk(id):
    xml_filepath = 'data/changesets/{}.xml'.format(id)
    if not os.path.isfile(xml_filepath):
        return None
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
get_stuff_in_area()
store_changeset_from_api(41177103)

