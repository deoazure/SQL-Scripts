
---restore script generation. script should be executed on source server k01s01

SET NOCOUNT ON
DECLARE @BackupPath nvarchar(max)
DECLARE @DBFilePath nvarchar(max)
DECLARE @DBLogPath nvarchar(max)
DECLARE @OverrideFlag nvarchar(15)
DECLARE @NorecoveryFlag nvarchar(15)

set @BackupPath = '\\danskenet.net\applications\MITS\SQLBackup\ksvi\'  -- parameters can be adjusted 
set @DBFilePath = 'E:\SQL_Data\MSSqlserver\'
set @DBLogPath = 'F:\SQL_Log\MSSqlserver\'
set @OverrideFlag = '' --set @OverrideFlag = 'REPLACE,'
set @NorecoveryFlag = 'RECOVERY,' --set @OverrideFlag = ''
  



DECLARE @DbCnt INT
DECLARE @Cnt INT = 1
DECLARE @RestoreCommand nvarchar(max)
DECLARE @RestoreFileCommand nvarchar(max)
DECLARE @DBName nvarchar(max)
DECLARE @FileCnt INT
DECLARE @FileName nvarchar(max)
DECLARE @FilePhysicalName nvarchar(max)
DECLARE @FileCommand nvarchar(max)
DECLARE @LoopCnt INT



CREATE TABLE #CustomResults(
      [DbName] [nvarchar](max) NOT NULL,
      [FileLogicalName] [nvarchar](max) NOT NULL,
      [physical_name] [nvarchar](max) NOT NULL,
      [type_desc] [nvarchar](10) NOT NULL
) 

CREATE TABLE #databases(
[ID] [INT] IDENTITY (1, 1) NOT NULL,
      [DbName] [nvarchar](128) NOT NULL,
) 

CREATE TABLE #DatabaseFiles(
[ID] [INT] IDENTITY (1, 1) NOT NULL,
--    [DbName] [nvarchar](128) NOT NULL,
[FileLogicalName] [nvarchar](max) NOT NULL,
      [physical_name] [nvarchar](max) NOT NULL,
      [type_desc] [nvarchar](10) NOT NULL
) 






  INSERT INTO #CustomResults exec sp_MSforeachdb @Command1 = 'USE [?] SELECT DB_NAME() AS DbName, 
name AS FileLogicalName, right (physical_name,  CHARINDEX(''\'',REVERSE(physical_name))-1) as physical_name, [type_desc] 
FROM sys.database_files where DB_NAME() not in (''master'', ''model'', ''msdb'', ''tempdb'');'  --exclusions can be added to this list





insert into #databases ([DbName])
select distinct [DBname] FROM #CustomResults order by [DBname]


set @DbCnt = (select top 1 ID from #databases order by ID desc)
WHILE @Cnt <= @DbCnt
BEGIN
      set @DBName = (select DbName from  #databases where ID = @Cnt)
      set @RestoreCommand = 'USE [master] RESTORE DATABASE [' + @DBName + '] FROM  DISK = N''' + @BackupPath + @DBName + '.bak'' WITH  FILE = 1,';

      
      set @LoopCnt = 1
      set @RestoreFileCommand  = ''

      truncate TABLE #DatabaseFiles
      insert into #DatabaseFiles([FileLogicalName], [physical_name],[type_desc] )
      select [FileLogicalName], [physical_name],[type_desc] FROM #CustomResults where [DbName] = @DBName order by  [type_desc] desc, [physical_name]

                  set @FileCnt = (select top 1 ID from #DatabaseFiles order by ID desc)
                  WHILE @LoopCnt <= @FileCnt
                  begin
                        set @FileName  = (select [FileLogicalName]  from  #DatabaseFiles where ID = @LoopCnt)
                        set @FilePhysicalName = (select [physical_name]  from  #DatabaseFiles where ID = @LoopCnt)

                        set @RestoreFileCommand  = @RestoreFileCommand  +  ' MOVE N''' + @FileName + ''' TO N''' + (
                              Select FilePath =
                                    case when (select [type_desc] FROM #DatabaseFiles where [ID] = @LoopCnt) = 'LOG' then @DBLogPath
                                    else @DBFilePath
                                    end) + @FilePhysicalName + ''','
                                                
                        
                        SET @LoopCnt = @LoopCnt + 1;
                        
                  end
                        print @RestoreCommand + @RestoreFileCommand + ' ' + @NorecoveryFlag + ' NOUNLOAD, ' + @OverrideFlag + ' STATS = 1'


   SET @Cnt = @Cnt + 1;
END;


GO








drop TABLE #CustomResults
drop TABLE #databases
drop TABLE #DatabaseFiles
