use StackOverflow
set statistics io on 
select count(*) from [dbo].[Comments]

---Cluster Index Scan,clustered index as primary key
---Scan Count 5,Logical read 3217495,Logical ahead read 31950321
--Time 11:50 sec with clustered Index
--+++++++++++++++++++++++++
set statistics io on 
select count(*) from [dbo].[Comments]
---Index Scan with Non Clustered index Key as Userid
--Scan Count 5,logical reads 129376, physical reads 0, read-ahead reads 0,
--Time 00:07 sec after index creation
--Index Creation time taken 17:02 Sec
--Row Count 74428966