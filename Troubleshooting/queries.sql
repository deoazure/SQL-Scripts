-- Ordered sp_who2 info

CREATE TABLE #sp_who2 (SPID INT,Status VARCHAR(255),
      Login  VARCHAR(255),HostName  VARCHAR(255), 
      BlkBy  VARCHAR(255),DBName  VARCHAR(255), 
      Command VARCHAR(255),CPUTime INT, 
      DiskIO INT,LastBatch VARCHAR(255), 
      ProgramName VARCHAR(255),SPID2 INT, 
      REQUESTID INT) 
INSERT INTO #sp_who2 EXEC sp_who2
SELECT      * 
FROM        #sp_who2
-- Add any filtering of the results here :
WHERE DBName in ('database1','database2') 
-- and login='NT0001\fPBQSVViewOnly'
-- or blkby <>'  .'
ORDER BY DBName ASC
DROP TABLE #sp_who2

-- number of connections from hosts

CREATE TABLE #sp_who2 (SPID INT,Status VARCHAR(255),
      Login  VARCHAR(255),HostName  VARCHAR(255), 
      BlkBy  VARCHAR(255),DBName  VARCHAR(255), 
      Command VARCHAR(255),CPUTime INT, 
      DiskIO INT,LastBatch VARCHAR(255), 
      ProgramName VARCHAR(255),SPID2 INT, 
      REQUESTID INT) 
INSERT INTO #sp_who2 EXEC sp_who2
SELECT      hostname, count( hostname) as Connection_count
FROM        #sp_who2
group by HostName
DROP TABLE #sp_who2

-- currently running sql queries with plan cache

SELECT QP.query_plan as [Query Plan], 
       ST.text AS [Query Text]
FROM sys.dm_exec_requests AS R
   CROSS APPLY sys.dm_exec_query_plan(R.plan_handle) AS QP
   CROSS APPLY sys.dm_exec_sql_text(R.plan_handle) ST;


-- progress of backup, dbcc, index create etc

SELECT SESSION_ID, '[' + CAST(DATABASE_ID AS VARCHAR(10)) + '] ' + DB_NAME(DATABASE_ID) AS [DATABASE],
PERCENT_COMPLETE, START_TIME, STATUS, COMMAND,
DATEADD(MS, ESTIMATED_COMPLETION_TIME, GETDATE()) AS ESTIMATED_COMPLETION_TIME, CPU_TIME
FROM sys.dm_exec_requests
--Apply this Where Clause Filter if you need to check specific events such as Backups, Restores, Index et al.
WHERE COMMAND LIKE '%BACKUP%' OR COMMAND LIKE '%RESTORE%' OR COMMAND LIKE '%INDEX%' OR COMMAND LIKE '%DBCC%'


-- recent slow queries

SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1),
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time,
qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_logical_reads DESC -- logical reads
-- ORDER BY qs.total_logical_writes DESC -- logical writes
-- ORDER BY qs.total_worker_time DESC -- CPU time

-- worker threads

select (select max_workers_count from sys.dm_os_sys_info) as 'TotalThreads',sum(active_Workers_count) as 'Currentthreads',(select max_workers_count from sys.dm_os_sys_info)-sum(active_Workers_count) as 'Availablethreads',sum(runnable_tasks_count) as 'WorkersWaitingfor_cpu',sum(work_queue_count) as 'Request_Waiting_for_threads' 
from  sys.dm_os_Schedulers where status='VISIBLE ONLINE'

-- which queries run in parallel
-- https://dba.stackexchange.com/questions/114455/sql-server-thread-status

-- all running requests

-- SELECT all active requests across all databases. 
-- NOTE: Percentage complete is only reported for certain command types (e.g. backups, restores, DBCCs etc)
SELECT 
    sys.dm_exec_sql_text.text AS  CommandText,
    sys.dm_exec_requests.Status AS Status,
    sys.dm_exec_requests.Command AS CommandType, 
    db_name(sys.dm_exec_requests.database_id) AS DatabaseName,
    sys.dm_exec_requests.cpu_time AS CPUTime, 
    sys.dm_exec_requests.total_elapsed_time AS ElapsedTime, 
    sys.dm_exec_requests.percent_complete AS PercentageComplete
     
FROM   
    sys.dm_exec_requests 
 
CROSS APPLY 
    sys.dm_exec_sql_text(sys.dm_exec_requests.sql_handle)

-- all checked plans
    
SELECT cplan.usecounts, cplan.objtype, qtext.text, qplan.query_plan
FROM sys.dm_exec_cached_plans AS cplan
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS qtext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qplan
ORDER BY cplan.usecounts DESC
    
-- Memory usage per database
-- http://dbadiaries.com/sql-server-how-to-find-buffer-pool-usage-per-database/

SELECT 
  CASE WHEN database_id = 32767 THEN 'ResourceDB' ELSE DB_NAME(database_id) END AS DatabaseName,
  COUNT(*) AS cached_pages,
  (COUNT(*) * 8.0) / 1024 AS MBsInBufferPool
FROM
  sys.dm_os_buffer_descriptors
GROUP BY
  database_id
ORDER BY
  MBsInBufferPool DESC

-- memory clerk usage

-- https://www.sqlshack.com/monitoring-memory-clerk-and-buffer-pool-allocations-in-sql-server/

SELECT TOP(5) [type] AS [ClerkType],
SUM(pages_kb) / 1024 AS [SizeMb]
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]
ORDER BY SUM(pages_kb) DESC

-- similar - memory per database

SELECT count(*)*8/1024 AS 'Data Cache Size(MB)'
,CASE database_id
WHEN 32767 THEN 'RESOURCEDB'
ELSE db_name(database_id)
END AS 'DatabaseName'
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 'Data Cache Size(MB)' DESC


-- Available memory, available page file
SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       total_page_file_kb/1024 AS [Total Page File (MB)], 
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

--

select
 er.session_id,
 er.status,
 er.command,
 er.blocking_session_id,
 er.wait_type,
 ot.exec_context_id,
 ot.task_state,
 st.text
from
 sys.dm_exec_requests er
 join sys.dm_os_tasks ot on (er.session_id = ot.session_id)
 cross apply sys.dm_exec_sql_text(er.sql_handle) st
where er.session_id in
 (select session_id
 from sys.dm_os_tasks
group by session_id
having count(exec_context_id)>1)


-- Script to review query hash:

select query_hash, sum(cast(ecp.size_in_bytes as bigint)) 'Cache consuming in Bytes'
from sys.dm_exec_query_stats eqs
join sys.dm_exec_cached_plans ecp
on eqs.plan_handle=ecp.plan_handle
group by query_hash
order by 2 desc



-- Execute query to find out problem query
select sql.text, sql_handle, query_hash, query_plan_hash,creation_time,last_execution_time,plan_generation_num,plan_handle
from sys.dm_exec_query_stats eqs
cross apply sys.dm_exec_sql_text (eqs.sql_handle) sql
where query_hash = 0xA0872BEF3DEE485C --sample hash



-- To know if you are suffering from worker thread starvation,use below queries.

select sum(work_queue_count) from sys.dm_os_schedulers
select * from sys.dm_os_tasks

select * from sys.dm_os_waiting_tasks where wait_type='threadpool'




-- Remove new line symbols when pasting to excel from SSMS 2012

SELECT col1, '"' + replace(columnWithLineBreaks,'"', '""') + '"', col3 FROM table

select '"' + replace(@@version,'"', '""') + '"' as [Server version]


-- http://answers.flyppdevportal.com/categories/sqlserver/sqltools.aspx?ID=d4c71898-2a71-4dcc-977f-8881a990dc12





-- Running processes

select
    P.spid
,   right(convert(varchar, 
            dateadd(ms, datediff(ms, P.last_batch, getdate()), '1900-01-01'), 
            121), 12) as 'batch_duration'
,   P.program_name
,   P.hostname
,   P.loginame
from master.dbo.sysprocesses P
where P.spid > 50
and      P.status not in ('background', 'sleeping')
and      P.cmd not in ('AWAITING COMMAND'
                    ,'MIRROR HANDLER'
                    ,'LAZY WRITER'
                    ,'CHECKPOINT SLEEP'
                    ,'RA MANAGER')
order by batch_duration desc

--2

SELECT
    p.spid, p.status, p.hostname, p.loginame, p.cpu, r.start_time, r.command,
    p.program_name, text 
FROM
    sys.dm_exec_requests AS r,
    master.dbo.sysprocesses AS p 
    CROSS APPLY sys.dm_exec_sql_text(p.sql_handle)
WHERE
    p.status NOT IN ('sleeping', 'background') 
AND r.session_id = p.spid






-- Replace CR and LF symbols in query result

SELECT REPLACE(REPLACE(REPLACE(MyCol, CHAR(10), ''), CHAR(13), ''), CHAR(9), '')
FROM MyTable



-- Query log from BICC database


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [nt_user_name]
      ,[session_id]
      ,[blocking_session_id]
      ,[start_time]
      ,[wait_type]
      ,[query_cost]
      ,[dop]
      ,[requested_memory_kb]
      ,[granted_memory_kb]
      ,[ideal_memory_kb]
      --,[text]
	  , REPLACE(REPLACE(REPLACE(text, CHAR(10), ''), CHAR(13), ''), CHAR(9), '') as text_fixed
      ,[Timestamp]
  FROM [BICC].[dbo].[QueryData]
  where start_time<'2015-12-22'
  and start_time>'2015-12-20'
 and blocking_session_id<>0
 --and nt_user_name='B82393'



-- Backup history (date/time)

SELECT sdb.Name AS DatabaseName,
COALESCE(CONVERT(VARCHAR(24), MAX(bus.backup_finish_date), 113),'-') AS LastBackUpTime
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
GROUP BY sdb.Name






-- Locking information

SELECT  L.request_session_id AS SPID, 
        DB_NAME(L.resource_database_id) AS DatabaseName,
        O.Name AS LockedObjectName, 
        P.object_id AS LockedObjectId, 
        L.resource_type AS LockedResource, 
        L.request_mode AS LockType,
        ST.text AS SqlStatementText,        
        ES.login_name AS LoginName,
        ES.host_name AS HostName,
        TST.is_user_transaction as IsUserTransaction,
        AT.name as TransactionName,
        CN.auth_scheme as AuthenticationMethod
FROM    sys.dm_tran_locks L
        JOIN sys.partitions P ON P.hobt_id = L.resource_associated_entity_id
        JOIN sys.objects O ON O.object_id = P.object_id
        JOIN sys.dm_exec_sessions ES ON ES.session_id = L.request_session_id
        JOIN sys.dm_tran_session_transactions TST ON ES.session_id = TST.session_id
        JOIN sys.dm_tran_active_transactions AT ON TST.transaction_id = AT.transaction_id
        JOIN sys.dm_exec_connections CN ON CN.session_id = ES.session_id
        CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
WHERE   resource_database_id = db_id()
ORDER BY L.request_session_id

-- http://weblogs.sqlteam.com/mladenp/archive/2008/04/29/SQL-Server-2005-Get-full-information-about-transaction-locks.aspx





-- List All Jobs and Their Schedules


/*******************************************************************************

Name:			GetJobSchedule	(For SQL Server7.0&2000)

Author:			M.Pearson
Creation Date:		5 Jun 2002
Version:		1.0


Program Overview:	This queries the sysjobs, sysjobschedules and sysjobhistory table to
			produce a resultset showing the jobs on a server plus their schedules
			(if applicable) and the maximun duration of the job.
			
			The UNION join is to cater for jobs that have been scheduled but not yet
			run, as this information is stored in the 'active_start...' fields of the 
			sysjobschedules table, whereas if the job has already run the schedule 
			information is stored in the 'next_run...' fields of the sysjobschedules table.


Modification History:
-------------------------------------------------------------------------------
Version Date		Name		Modification
-------------------------------------------------------------------------------
1.0 	5 Jun 2002	M.Pearson	Inital Creation
1.1		6 May 2009	A. Gonzalez	Adapted to SQL Server 2005 and to show
								subday frequencies.

*******************************************************************************/



USE msdb
Go


SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE active_start_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),active_start_date),1,4) + '/' + 
		substring(convert(varchar(15),active_start_date),5,2) + '/' + 
		substring(convert(varchar(15),active_start_date),7,2)
	END,
	'Start Time' = CASE len(active_start_time)
		WHEN 1 THEN cast('00:00:0' + right(active_start_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(active_start_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(active_start_time,3),1)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(active_start_time,5),1) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(active_start_time,6),2) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
	END,
--	active_start_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules 
ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time = 0

UNION

SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE next_run_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),next_run_date),1,4) + '/' + 
		substring(convert(varchar(15),next_run_date),5,2) + '/' + 
		substring(convert(varchar(15),next_run_date),7,2)
	END,
	'Start Time' = CASE len(next_run_time)
		WHEN 1 THEN cast('00:00:0' + right(next_run_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(next_run_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(next_run_time,3),1)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 5 THEN cast('0' + Left(right(next_run_time,5),1) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(next_run_time,6),2) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
	END,
--	next_run_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time <> 0

ORDER BY [Start Date],[Start Time]

-- Databases by sizes

SELECT 
      database_name = DB_NAME(database_id)
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , total_size_mb = CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
--WHERE database_id = DB_ID() -- for current db 
GROUP BY database_id

-- Tables by sizes

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB, 
    SUM(a.used_pages) * 8 / 1024 AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    SUM(a.total_pages) * 8 desc





-- Keyword search in job steps


USE [msdb]
GO
SELECT	j.job_id,
	s.srvname,
	j.name,
	js.step_id,
	js.command,
	j.enabled 
FROM	dbo.sysjobs j
JOIN	dbo.sysjobsteps js
	ON	js.job_id = j.job_id 
JOIN	master.dbo.sysservers s
	ON	s.srvid = j.originating_server_id
WHERE	js.command LIKE N'%KEYWORD_SEARCH%'
GO





select @@VERSION as 'SQL server version'

SELECT SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')




-- last backup
 ISNULL((SELECT TOP 1
 CASE TYPE WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
ltrim(ISNULL(STR(ABS(DATEDIFF(day, GetDate(),Backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
' (' + CAST(DATEDIFF(second, BK.backup_start_date,
 BK.backup_finish_date) AS VARCHAR(4)) + ' '
+ 'seconds)'
FROM msdb..backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [Last backup],

CASE WHEN is_fulltext_enabled = 1 THEN 'Fulltext enabled' ELSE '' END AS [fulltext],
 CASE WHEN is_auto_close_on = 1 THEN 'autoclose' ELSE '' END AS [autoclose],
 page_verify_option_desc AS [page verify option],
 CASE WHEN is_read_only = 1 THEN 'read only' ELSE '' END AS [read only],
 CASE WHEN is_auto_shrink_on = 1 THEN 'autoshrink' ELSE '' END AS [autoshrink],
 CASE WHEN is_auto_create_stats_on = 1 THEN 'auto create statistics' ELSE '' END AS [auto create statistics],
 CASE WHEN is_auto_update_stats_on = 1 THEN 'auto update statistics' ELSE '' END AS [auto update statistics],
 CASE WHEN is_in_standby = 1 THEN 'standby' ELSE '' END AS [standby],
 CASE WHEN is_cleanly_shutdown = 1 THEN 'cleanly shutdown' ELSE '' END AS [cleanly shutdown]
 FROM sys.databases DB
 ORDER BY dbName, [Last backup] DESC, NAME






-- Locations of databases

SELECT db_name(database_id) as DatabaseName,name,type_desc,physical_name FROM sys.master_files




-- File group information

EXEC master.dbo.sp_MSforeachdb @command1 = 'USE [?] SELECT * FROM sys.filegroups'


http://www.databasejournal.com/features/mssql/article.php/3923371/Top-10-Transact-SQL-Statements-a-SQL-Server-DBA-Should-Know.htm



-- Database users

SELECT *
FROM sys.database_principals



-- Map logins and users by SID

SELECT d.[name] AS 'DB User', d.sid AS 'DB SID', s.[name] AS 'Login', s.sid AS 'Server SID'FROM sys.database_principals d JOIN sys.server_principals s ON d.sid = s.sid


sysusers has been superseded by sys.database_principals (http://msdn.microsoft.com/en-us/library/ms187328.aspx)

syslogins has been superseded by sys.server_principals (http://msdn.microsoft.com/en-us/library/ms188786.aspx) and sys.sql_logins (http://msdn.microsoft.com/en-us/library/ms174355.aspx)






-- SSAS sessions, connections

SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS

Select * from $System.discover_object_activity -- This query reports on object activity since the service last started. For example queries based on this DMV, see New System.Discover_Object_Activity.
Select * from $System.discover_object_memory_usage -- This query reports on memory consumption by object.
Select * from $System.discover_sessions -- This query reports on active sessions, including session user and duration.
Select * from $System.discover_locks -- This query returns a snapshot of the locks used at a specific point in time.


All objects owned by specific user


;with objects_cte as
(
    select
        o.name,
        o.type_desc,
        case
            when o.principal_id is null then s.principal_id
            else o.principal_id
        end as principal_id
    from sys.objects o
    inner join sys.schemas s
    on o.schema_id = s.schema_id
    where o.is_ms_shipped = 0
    and o.type in ('U', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TA', 'TF', 'TR', 'V')
)
select
    cte.name,
    cte.type_desc,
    dp.name
from objects_cte cte
inner join sys.database_principals dp
on cte.principal_id = dp.principal_id
where dp.name like '%DB_Team_Sofia%';


-- free space current DB files

SELECT
 SUBSTRING(a.FILENAME, 1, 1) Drive,
 [FILE_SIZE_MB] = convert(decimal(12,2),
round(a.size/128.000,2)),
 [SPACE_USED_MB] = convert(decimal(12,2),
round(fileproperty(a.name,'SpaceUsed')/128.000,2)),
 [FREE_SPACE_MB] = convert(decimal(12,2),
round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) ,
 [FREE_SPACE_%] = convert(decimal(12,2),
(convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) 
/ convert(decimal(12,2),round(a.size/128.000,2)) * 100)),
 a.NAME, a.FILENAME
FROM dbo.sysfiles a
ORDER BY Drive, [Name]

-- schema size




   	SELECT  SCHEMA_NAME(so.schema_id) AS SchemaName
               ,SUM(ps.reserved_page_count) * 8.0 / 1024 AS SizeInMB
        FROM    sys.dm_db_partition_stats ps
        JOIN    sys.indexes i
          ON    i.object_id                                     =           ps.object_id
         AND    i.index_id                                      =           ps.index_id
		JOIN	sys.objects	so
		  ON	i.object_id										=			so.object_id
       WHERE    so.type											=			'U'
	   and SCHEMA_NAME(so.schema_id) = 'NT0001\BC4285' -- shema name, remove if you need all schema sizes
    GROUP BY	so.schema_id
    ORDER BY	OBJECT_SCHEMA_NAME(so.schema_id), SizeInMB DESC 
    
    

