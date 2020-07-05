---Get SQL Server process memory

select physical_memory_in_use_kb/1024 as Phsycial_memory_in_use_mb,
large_page_allocations_kb/1024 as large_page_allocations_mb,
locked_page_allocations_kb/1024 as locked_page_allocation_mb,
total_virtual_address_space_kb/1024 as total_virtual_address_space_mb,
virtual_address_space_reserved_kb/1024 as virtual_adress_space_reserved_mb,
virtual_address_space_committed_kb/1024 as virtual_address_space_commited_mb,
virtual_address_space_available_kb/1024 as virtual_address_space_available_mb,
available_commit_limit_kb/1024 as available_commit_mb
from sys.dm_os_process_memory

--Get Total Buffer pool size

select sum(pages_kb + virtual_memory_committed_kb + 
     shared_memory_committed_kb)/1024 As [used by Bpool,MB]
from sys.dm_os_memory_clerks
--Get Buffer pool utilization by each database
select Dbname =case when database_id=32767 
then 'RESOURCEDB'
else DB_NAME(database_id) end,
size_mb=count(1)/128
from sys.dm_os_buffer_descriptors
group by database_id
order by 2 desc

--Get Buffer Pool Utilization by each object in a database
use AdventureWorks2014

select DBName=Case when database_id=32767 then 'ResouceDB'
else DB_NAME(database_id) end,
objName = o.name,
size_mb=count(1)/128
from sys.dm_os_buffer_descriptors obd
inner join sys.allocation_units au
on obd.allocation_unit_id=au.allocation_unit_id
inner join sys.partitions p9
on au.container_id=p.hobt_id
inner join sys.objects o
on p.object_id=o.object_id
where obd.database_id=db_id()	
and o.type ! ='S'
group by obd.database_id,o.name
order by 3 desc