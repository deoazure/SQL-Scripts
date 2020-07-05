set statistics io on
SELECT 
    Count(*) AS CommentCount
FROM 
    Comments 

	Executes	StmtText
1	SELECT       Count(*) AS CommentCount  FROM       Comments
0	  |--Compute Scalar(DEFINE:([Expr1002]=CONVERT_IMPLICIT(int,[globalagg1004],0)))
1	       |--Stream Aggregate(DEFINE:([globalagg1004]=SUM([partialagg1003])))
1	            |--Parallelism(Gather Streams)
4	                 |--Stream Aggregate(DEFINE:([partialagg1003]=Count(*)))
4	                      |--Index Scan(OBJECT:([StackOverflow].[dbo].[Comments].[NonClusteredIndex-20200112-125834]))
    --Plan after changing CTOP
	--Count 74428966
	--Time 1:19 sec
	--CTOP 50
	--Maxdop 0
	--Table 'Comments'. Scan count 5, logical reads 130324, physical reads 1, read-ahead reads 129110, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.