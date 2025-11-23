-- get all indexes with > 10% fragmentation
select
  DB_NAME(database_id) as DatabaseName,
  OBJECT_NAME (sys.indexes.object_id) as TableName,
  sys.indexes.index_id as IndexID,
  name as IndexName,
  avg_fragmentation_in_percent as AVG_INDEX_FRAGMENTATION_PERCENTAGE,
  page_count
from
  sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')
join
  sys.indexes on sys.dm_db_index_physical_stats.object_id = sys.indexes.object id
  and sys.dm_db_index_physical_stats.index_id = sys.indexes.index_id
where
  avg_fragmentation_in_percent > 10  -- Filter for indexes with > 10% fragmentation
order by
  avg_fragmentation_in_percent desc;

-- CAUTION - REBUILDS INDEX
-- ALTER INDEX [IndexName] on [TableName] REBUILD WITH (ONLINE = on);
-- Get queries running for more than 10 seconds
select
  r.session_id,
  st.text as batch_text,
  qp.query_plan as 'XML Plan',
  r.start_time,
  r.status,
  r.total_elapsed_time,
  DB_NAME(r.database_id) as database_name
from
  sys.dm_exec_requests as r
cross apply
  sys.dm_exec_sql_text(r.sql_handle) as st
cross apply
  sys.dm_exec_query_plan(r.plan_handle) as qp
where
  r.status = 'running' -- Filter for currently running queries
  and r.total_elapsed_time > 10000 -- in milliseconds
order by
  r.total_elapsed_time desc;

-- NTILE - used to seperate results into multiple buckets by some column or group of columns
-- only computing ntile once is better - guarentees disjointness and full coverage within
-- this execution
-- if ntile is computed twice, rows could move between buckets between executions (first
-- select vs second seperate select)
select
  j.columnA,
  r.columnB,
  NTILE(2) OVER (order by j.columnA, r.columnB) as tile_nr -- NTILE(N) - N = number of chunks
into #temp
from DbName..TableA j
inner join DbName..TableB jrs on j.columnA = jrs.columnA
inner join DbName..TableC r on r.columnB = jrs.columnC

select * from #temp where tile_nr = 1 order by columnA, columnB -- select from chunk 1
select * from #temp where tile_nr = 2 order by columnA, columnB -- select from chunk 2

-- string split fn
alter Function dbo.Split(@String varchar(max), @Delimiter CHAR(1))
  Returns
  @Returnlist Table ([Name] nvarchar(max), [Position] int)
  
  as
  Begin
    declare @FullName nvarchar(50)
    declare @Pos int = 0;
    declare @Count int = 0;

    while charindex(@Delimiter, @String) > @
    begin
      Select @Pos = charindex(@Delimiter, @String)
      select @FullName = substring(@String, 1, @Pos - 1)

    insert into @ReturnList
      select @FullName, @Count
      select @String = substring(@String, @Pos + 1, len(@String) - @Pos)
      select @Count += 1;
    end

    insert into @ReturnList
      select @String, @Count
  Return
End
  
-- Find tables with no PK
select
  schema_name(tab.schema_id) as [schema_name],
  tab.[name] as table_name
from sys.tables tab
left outer join sys.indexes pk
  on tab.object_id = pk.object_id
  and pk.is_primary_key = 1
where pk.object_id is null
order by schema_name(tab.schema_id), tab.[name]

-- Find proc by name
select schema_name(schema_id) as [schema], [name]
from sys.procedures
where name like '%sometext%'
  
-- Find proc by text in definition
select schema_name(schema_id) as [schema], [name]
from sys.procedures
from Object_definition(object_id) like '%sometext%'

-- Find db trigger by name
use Dbname
go

select
  sysobjects.name name as trigger_name,
  USER_NAME(sysobjects.uid) as trigger_owner,
  s.name as table_schema,
  OBJECT_NAME (parent_obj) as table_name,
  OBJECTPROPERTY(id, 'ExecIsUpdatetrigger' ) as isOnUpdate,
  OBJECTPROPERTY(id, 'ExecIsDeleteTrigger') as isOnDelete,
  OBJECTPROPERTY(id, 'ExecIsInsertTrigger') as isOnInsert,
  OBJECTPROPERTY(id, 'ExecIsAfterTrigger') as isAfter,
  OBJECTPROPERTY(id, 'ExecIsinsteadOfTrigger') as isInsteadOf,
  OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') as [disabled]

from sysobjects
inner join sysusers
  on sysobjects.uid = sysusers.uid
inner join sys.tables t
  on sysobjects.parent_obj = t.object_id
inner join sys.schemas ¢
  on t.schema_id = s.schema_id
inner join sys.sql_modules m
  on id = m.object_id
where sysobjects.type = 'TR' -- TR = trigger
and m.definition like '%sometext%'
  
-- get all column names from a table
select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'Formulas'

-- Cast column to NVARCHAR(MAX) and replace text in XML
update r
set r.[Settings] = REPLACE(CAST(r.[Settings] as NVARCHAR(MAX)), '<XMLTAG>FOO</XMLTAG>', '<XMLTAG>BAR</XMLTAG>')}
from DbName..TableName r
where SomeColumn = 'foo'

-- get XML from NVARCHAR column and display as XML
select
cast (tableColumnWithXmlAsText) as xml
from DbName..TableName

-- Julian Date conversion to datetime
select tn.*, CONVERT(DATETIME, ([tn].julianDate - 109573)) as DT
from DbName..TableName tn

-- alternatively..
select CONVERT(DATETIME, 155150 - 109573) as DT
