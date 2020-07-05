set statistics io on
SELECT 
    Count(*) AS CommentCount
FROM 
    Comments --option (maxdop 2)


	--with CTOP setting 50 and maxdop 2
	--1st time 1:22 sec first time,Scan count 3, logical reads 129716, physical reads 1, read-ahead reads 129108, 
	--2nd tim 00:08 sec with maxdop 2 and CTOP 50,Scan count 3, logical reads 129300, physical reads 0, read-ahead reads 0,
	--3rd time 00:06 sec without maxdop settings and CTOP 50, Scan count 5, logical reads 129384, physical reads 0, read-ahead reads 0, 
	--4th time 00:07 sec without maxdop and ctop 5,Scan count 5, logical reads 129392, physical reads 0, read-ahead reads 0,
	--Count in each query 74428966
	--NonClustered Index Scan
	--Parrallelism
	

