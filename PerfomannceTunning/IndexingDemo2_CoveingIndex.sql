set statistics io on
select productkey from dbo.DimProduct where ProductAlternateKey=N'BE-2349'
--Scan,when covering index order([ProductKey],ProductAlternateKey)
--Table 'DimProduct'. Scan count 1, logical reads 5, physical reads 0


select productkey from dbo.DimProduct where ProductAlternateKey=N'BE-2349'
--seek,when covering index order(ProductAlternateKey,[ProductKey])
--Table 'DimProduct'. Scan count 1, logical reads 2, physical reads 0,

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set statistics io on
select productalternatekey from DimProduct where productkey='601'  

----scan when covering index order([ProductAlternateKey],[ProductKey])

set statistics io on
select productalternatekey from DimProduct where productkey='601'  

----scan when covering index order([ProductKey],ProductAlternateKey)

+++++++++++++++++++++++++++++++++++
set statistics io on
select productalternatekey from DimProduct where productkey='601'  

----seek when covering index order([ProductKey],ProductAlternateKey)

set statistics io on
select productalternatekey from DimProduct where productkey='601'  

----seek when covering index order([ProductKey],ProductAlternateKey)