set statistics io on
SELECT 
    Count(*) AS CommentCount
FROM 
    Comments option (maxdop 2)

	Executes	StmtText
1	SELECT       Count(*) AS CommentCount  FROM       Comments option (maxdop 2)
0	  |--Compute Scalar(DEFINE:([Expr1002]=CONVERT_IMPLICIT(int,[globalagg1004],0)))
1	       |--Stream Aggregate(DEFINE:([globalagg1004]=SUM([partialagg1003])))
1	            |--Parallelism(Gather Streams)
2	                 |--Stream Aggregate(DEFINE:([partialagg1003]=Count(*)))
2	                      |--Index Scan(OBJECT:([StackOverflow].[dbo].[Comments].[NonClusteredIndex-20200112-125834]))

--With maxdop 2
--CTOP 50
--count 74428966
--Time 00:08 Sec
--Table 'Comments'. Scan count 3, logical reads 129316, physical reads 0