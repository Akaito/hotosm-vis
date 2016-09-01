-- Extract data we'll be using for Processing
.headers on
.mode csv
.output processing/data/nodes-not-hotosm.csv

-- db schema:
-- CREATE TABLE Changeset (
--             changesetId integer not null primary key,
--             user text not null,
--             userId integer not null,
--             createdAt text not null,
--             min_lat number not null,
--             min_lon number not null,
--             max_lat number not null,
--             max_lon number not null
--         );
-- CREATE TABLE ChangesetTag (
--             changesetId integer not null
--                 REFERENCES Changeset(changesetId),
--             key         text not null,
--             value       text not null
--         );
-- CREATE TABLE Node (
--             nodeId    integer not null primary key,
--             lat       number  not null,
--             lon       number  not null,
--             timestamp text not null,
--             version   integer not null,
--             changesetId integer not null
--                 REFERENCES Changeset(changesetId),
--             user      text not null,
--             userId    integer not null
--         );
-- CREATE TABLE Way (
--             wayId       integer not null primary key,
--             timestamp   text    not null,
--             version     integer not null,
--             changesetId integer not null
--                 REFERENCES Changeset(changesetId),
--             user        text    not null,
--             userId      integer not null
--         );
-- CREATE TABLE WayNode (
--             wayId  integer not null
--                 REFERENCES Way(wayId),
--             nodeId integer not null
--                 REFERENCES Node(nodeId)
--         );
-- CREATE TABLE WayTag (
--             wayId integer not null
--                 REFERENCES Way(wayId),
--             key   text not null,
--             value text not null
--         );


with InterestingChangesets as (
	select changesetId
		from  ChangesetTag
		where key='comment' and value not like '%#hotosm-project-2044%'
)
-- select * from InterestingChangesets;

, InterestingWays as (
	select wayId, timestamp
		from Way
		where Way.changesetId in InterestingChangesets
)
-- select * from InterestingWays;

, InterestingWaysWithNodeIds as (
	select InterestingWays.wayId, timestamp, nodeId
		from InterestingWays
			left join WayNode on InterestingWays.wayId = WayNode.wayId
)
-- select * from InterestingWaysWithNodeIds;

, InterestingWaysWithNodes as (
	select
		InterestingWaysWithNodeIds.wayId,
	    InterestingWaysWithNodeIds.timestamp,
		InterestingWaysWithNodeIds.nodeId,
		lat,
		lon
	from InterestingWaysWithNodeIds
		left join Node on InterestingWaysWithNodeIds.nodeId = Node.nodeId
)
-- select * from InterestingWaysWithNodes;


select timestamp, wayId, nodeId, lat, lon from InterestingWaysWithNodes order by timestamp asc, wayId;
