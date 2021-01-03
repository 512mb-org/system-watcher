[void][system.reflection.Assembly]::LoadFrom("C:\Users\Administrator\Desktop\sql\MySql.Data.dll")

$pcdomain = (Get-WmiObject Win32_ComputerSystem).Domain

###Make SQL function
Function Run-MySQLQuery {
Param(
[Parameter(
Mandatory = $true,
ParameterSetName = '',
ValueFromPipeline = $true)]
[string]$query,
[Parameter(
Mandatory = $true,
ParameterSetName = '',
ValueFromPipeline = $true)]
[string]$connectionString
)
Begin {
Write-Verbose "Starting Begin Section"
}
Process {
Write-Verbose "Starting Process Section"
try {
# load MySQL driver and create connection
Write-Verbose "Create Database Connection"
# You could also could use a direct Link to the DLL File
# $mySQLDataDLL = "C:\scripts\mysql\MySQL.Data.dll"
# [void][system.reflection.Assembly]::LoadFrom($mySQLDataDLL)
[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
$connection = New-Object MySql.Data.MySqlClient.MySqlConnection
$connection.ConnectionString = $ConnectionString
Write-Verbose "Open Database Connection"
$connection.Open()
 
# Run MySQL Querys
Write-Verbose "Run MySQL Querys"
$command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)
$dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($command)
$dataSet = New-Object System.Data.DataSet
$recordCount = $dataAdapter.Fill($dataSet, "data")
$dataSet.Tables["data"] | Format-Table
}
catch {
Write-Host "Could not run MySQL Query" $Error[0]
}
Finally {
Write-Verbose "Close Connection"
$connection.Close()
}
}
End {
Write-Verbose "Starting End Section"
}
}

$pcname = [system.environment]::MachineName
$pcsqldomain = ("$pcdomain" -replace "\.", "")

#This is a basic MySQL Command for doing stuff
run-MySQLQuery -ConnectionString "Server=192.168.1.11;Uid=root;Pwd=;" -Query "CREATE DATABASE IF NOT EXISTS systems2;"
run-MySQLQuery -ConnectionString "Server=192.168.1.11;Uid=root;Pwd=;database=systems2;" -Query "CREATE TABLE $pcsqldomain (
id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
pcname VARCHAR(30) NOT NULL,
domain VARCHAR(50),
serial VARCHAR(30) NOT NULL,
avast VARCHAR(50),
user VARCHAR(50),
diskspace VARCHAR(50),
programms MEDIUMTEXT NOT NULL,
pcstart VARCHAR(50),
session VARCHAR(50),
reg_date TIMESTAMP)"