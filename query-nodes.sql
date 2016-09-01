-- Extract data we'll be using for Processing
.headers on
.mode csv
.output processing/data/nodes.csv

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


with
HotosmChangesets as (
	select changesetId
	from ChangesetTag
	where key='comment' and value like '%#hotosm-project-2044%'
)

, ChangesetsMarked as (
	select
		changesetId,
		changesetId in (
			select changesetId from ChangesetTag
			where key='comment' and value like '%#hotosm-project-2044%'
		) and changesetId in (select changesetId from Changeset) as isHotosm
	from
		ChangesetTag
)
-- select * from ChangesetsMarked;

, InterestingWays as (
	select
		timestamp,
		isHotosm,
		wayId,
		wayId in (
			select wayId from WayTag
			where
				key='building'
				or (key='leisure' and value like '%sport%')
				or (key='amenity' and value in ('grave_yard', 'hospital', 'school'))
		) as isBuilding,
		wayId in (
			select wayId from WayTag
			where
				key='highway'
				or key='aeroway'
				or key='waterway'
				or key like '%fence%'
		) as isPath
	from Way
		left join ChangesetsMarked on Way.changesetId = ChangesetsMarked.changesetId
	where
		wayId not in (
			select wayId from WayTag
			where
				key='landuse' or key='natural' or key='area'
				or key='parking'
				or (key='surface' and value in ('grass', 'ground'))
				or (key='amenity' and value in ('marketplace', 'parking'))
				or (key='leisure' and value in ('pitch'))
		)
		and wayId in (select wayId from WayTag)
)
-- select * from InterestingWays;

, InterestingWaysWithNodeIds as (
	select InterestingWays.*, nodeId
		from InterestingWays
			left join WayNode on InterestingWays.wayId = WayNode.wayId
)
-- select * from InterestingWaysWithNodeIds;

, InterestingWaysWithNodes as (
	select
		InterestingWaysWithNodeIds.*,
		lat,
		lon
	from InterestingWaysWithNodeIds
		left join Node on InterestingWaysWithNodeIds.nodeId = Node.nodeId
)
-- select * from InterestingWaysWithNodes;


select * from InterestingWaysWithNodes
order by timestamp asc, wayId asc, nodeId asc;

