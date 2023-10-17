SELECT
SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as ComputerName,
@@SERVERNAME as InstanceName,
  CASE 
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '8%' THEN 'SQL Server 2000'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '9%' THEN 'SQL Server 2005'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.0%' THEN 'SQL Server 2008'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.5%' THEN 'SQL Server 2008 R2'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '11%' THEN 'SQL Server 2012'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '12%' THEN 'SQL Server 2014'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '13%' THEN 'SQL Server 2016'     
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '14%' THEN 'SQL Server 2017' 
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '15%' THEN 'SQL Server 2019' 
     ELSE 'unknown'
  END AS MajorVersion,
  SERVERPROPERTY('Edition') AS Edition,
  SERVERPROPERTY('ProductVersion') AS ProductVersion,
  SERVERPROPERTY('ProductLevel') AS SPInstalled, 
  SERVERPROPERTY('ProductUpdateLevel') as CUInstalled,
  SERVERPROPERTY('Collation') as Collation