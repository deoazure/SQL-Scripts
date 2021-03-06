--scripts generates backup command. Script shoud be executed on source server - k01s01

SET NOCOUNT ON
DECLARE @BackupPath nvarchar(max)

set @BackupPath = '\\danskenet.net\applications\MITS\SQLBackup\ksvi\' -- path can be changed

DECLARE @DbCnt INT
DECLARE @Cnt INT = 1
DECLARE @BackupCommand nvarchar(max)
DECLARE @DBName nvarchar(max)




CREATE TABLE #CustomResults(
[ID] [INT] IDENTITY (1, 1) NOT NULL,
[DBID] [INT] NOT NULL,
       [DbName] [nvarchar](max) NOT NULL
       
) 

  INSERT INTO #CustomResults
 select database_id, name as DBname from sys.databases where name not in (
'master', --you can add more databases to this exclusion list if needed
'model', 
'msdb', 
'tempdb',
'ibmdba'
) order by DBNAME 






set @DbCnt = (select top 1 ID from #CustomResults order by ID desc)
WHILE @Cnt <= @DbCnt
BEGIN
       set @DBName = (select DbName from  #CustomResults where ID = @Cnt)
       set @BackupCommand = 'BACKUP DATABASE [' + @DBName + '] TO  DISK = N''' + @BackupPath + @DBName + '.bak'' WITH COPY_ONLY, NOFORMAT, INIT,  SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 1' ;

       
       
                           print @BackupCommand

   SET @Cnt = @Cnt + 1;
END;


GO

drop TABLE #CustomResults
