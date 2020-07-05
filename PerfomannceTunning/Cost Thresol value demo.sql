set statistics io on
SELECT 
    Count(*) AS CommentCount
FROM 
    Comments

	--Plan before changing cost thresold value
	--Count 74428966
	--Time 1:40 sec
	--Cost Thresold value:5
	--maxdop 0
	--Table 'Comments'. Scan count 5, logical reads 130344, physical reads 0, read-ahead reads 128664,
Rows	Executes	StmtText
1	1	SELECT       Count(*) AS CommentCount  FROM       Comments
0	0	  |--Compute Scalar(DEFINE:([Expr1002]=CONVERT_IMPLICIT(int,[globalagg1004],0)))
1	1	       |--Stream Aggregate(DEFINE:([globalagg1004]=SUM([partialagg1003])))
4	1	            |--Parallelism(Gather Streams)
4	4	                 |--Stream Aggregate(DEFINE:([partialagg1003]=Count(*)))
74428966	4	                      |--Index Scan(OBJECT:([StackOverflow].[dbo].[Comments].[NonClusteredIndex-20200112-125834]))