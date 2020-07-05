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

select 
type,SUM(pages_in_bytes)/1024/1024 as total_mb
from sys.dm_os_memory_objects
group by type
order by total_mb desc
go

select * from sys.dm_os_memory_clerks
order by pages_kb desc

select * from sys.dm_os_memory_objects
where type like '%cursor%'

---
How to troubleshoot OOM
Extended Event
schedule a job for top 10 memory clerk
top 10 memory object 
and dump into a table
---