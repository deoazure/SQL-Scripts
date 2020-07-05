set statistics io on 
select  count(*) from  [dbo].[Badges]

---Scan count 5, logical reads 208726, physical reads 0, read-ahead reads 75974, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Time 00:18 sec
--Clustered Index Scan,Clustered Index -Primary Key

set statistics io on 
select  count(*) from  [dbo].[Badges]
--Table 'Badges'. Scan count 5, logical reads 58701, physical reads 0, read-ahead reads 8
--Time Taken 00:05 sec
-- Row Count 33743208
--Time Taken to create Non Clustered Index :2:09 sec
--Non Clustered Index Scan,Index key user id(can take any column)
--