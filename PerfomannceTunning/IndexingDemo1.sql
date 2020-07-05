
select productalternatekey from dbo.DimProduct where ProductAlternateKey=N'BE-2349'

---Seek ,Productalternatekey noclustered index 

select productkey from dbo.DimProduct where ProductAlternateKey=N'BE-2349'

---RID Productalternatekey nonclustered ,productkey no index

select productalternatekey from DimProduct where productkey='601'  

----seek when productalternatekey nonclusterkey and productkey clustered and primary 


select productalternatekey from DimProduct where productkey='601'

--seek,Productalternatekey no index cloumn,product key primary



select productalternatekey from DimProduct where productkey='601'
--No index --table scan


select productalternatekey,productkey from DimProduct where productkey='601'
--tablescan

601
602
603