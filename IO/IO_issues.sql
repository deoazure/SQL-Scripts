-- Look for I/O requests taking longer than 15 seconds in the five most recent SQL Server Error Logs (Query 25) (IO Warnings)
CREATE TABLE #IOWarningResults(LogDate datetime, ProcessInfo sysname, LogText nvarchar(1000));

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 0, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 1, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 2, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 3, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 4, 1, N'taking longer than 15 seconds';

SELECT LogDate, ProcessInfo, LogText
FROM #IOWarningResults
ORDER BY LogDate DESC;

DROP TABLE #IOWarningResults;  

-- IO latency per database and IO% per database (extracted from performance dashboard)

select database_name,   

cast([Reads] * 100 /(select SUM(cast([num_of_reads] AS decimal (38,2))) from sys.dm_io_virtual_file_stats(NULL, NULL) ) AS decimal (6,2)) as [% Reads], 
[Reads],
[Read Wait Time (ms)],
      [Avg Read Wait (ms)] =
case 
      when [Reads] > 0 then cast(cast([Read Wait Time (ms)] AS decimal (38,2)) / cast([Reads]  AS decimal (38,2)) AS decimal (9,1))
      else 0
      end,
cast([Writes] * 100 /(select SUM(cast([num_of_writes] AS decimal (38,2))) from sys.dm_io_virtual_file_stats(NULL, NULL) ) AS decimal (6,2)) as [% Writes],   
      [Writes], [Write Wait Time (ms)],
            [Avg Write Wait (ms)] =
case 
      when [Writes]  > 0 then cast(cast([Write Wait Time (ms)] AS decimal (38,2)) / cast([Writes]   AS decimal (38,2)) AS decimal (38,1))
      else 0
      end,
      cast(( ([Reads] + [Writes]) * 100 /(select SUM(cast([num_of_reads] AS decimal (38,2)) + cast([num_of_writes] AS decimal (38,2))) from sys.dm_io_virtual_file_stats(NULL, NULL) )  )AS decimal (6,2)) as [% Total]
--,* 
from
            (select
      --    m.database_id,
            db_name(m.database_id) as database_name,
      --    m.file_id,
      --    m.name as file_name, 
      --    m.physical_name, 
      --    m.type_desc,
            sum(fs.num_of_reads) as [Reads], 
            sum(fs.num_of_bytes_read) as [num_of_bytes_read], 
            sum(fs.io_stall_read_ms) as [Read Wait Time (ms)], 
            sum(fs.num_of_writes) as [Writes], 
            sum(fs.num_of_bytes_written) as [num_of_bytes_written], 
            sum(fs.io_stall_write_ms) as [Write Wait Time (ms)]
      from sys.dm_io_virtual_file_stats(NULL, NULL) fs
            join sys.master_files m on fs.database_id = m.database_id and fs.file_id = m.file_id
            group by    
            db_name(m.database_id))as A
            order by database_name

------------------------------------- 
-- https://sqlperformance.com/2013/01/io-subsystem/trimming-more-transaction-log-fat

--On a slow-performing I/O subsystem, the volume of tiny transaction log writes could overwhelm the I/O subsystem leading to high-latency writes and subsequent transaction log throughput degradation. This situation can be identified by high-write latencies for the transaction log file in the output of sys.dm_io_virtual_file_stats (see the demo links at the top of the previous post)


--Data and log file/disk latency

SELECT physical_name AS drive,
  CAST(SUM(io_stall_read_ms) / (1.0 + SUM(num_of_reads))
AS NUMERIC(10, 1)) AS 'Avg Read Latency/ms',
  CAST(SUM(io_stall_write_ms) / (1.0 +
SUM(num_of_writes)) AS NUMERIC(10, 1)) AS 'Avg Write Latency/ms',
  CAST((SUM(io_stall)) / (1.0 + SUM(num_of_reads +
num_of_writes)) AS NUMERIC(10, 1)) AS 'Avg Disk Latency/ms'
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS d
  JOIN sys.master_files AS m
       ON m.database_id = d.database_id
       AND m.file_id = d.file_id
GROUP BY physical_name
ORDER BY physical_name DESC;

-----------------------------
-- On a high-performing I/O subsystem, the writes may complete extremely quickly, but the limit of 32 concurrent log-flush I/Os creates a bottleneck when trying to make the log records durable on disk. This situation can be identified by low write latencies and a near-constant number of outstanding transaction log writes near to 32 in the aggregated output of sys.dm_io_pending_io_requests (see the same demo links).

-- check if there are 112 waits constantly ( 32 concurrent log-flush I/Os at any one time (raised to 112 on SQL Server 2012).)
-- total waits
select * from sys.dm_io_pending_io_requests

-- log file waits
select * from sys.dm_io_pending_io_requests
where io_handle_path like '%SQL_Log%'

