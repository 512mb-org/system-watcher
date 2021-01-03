$pathuser = [Environment]::UserName
$endtime = Get-Date -Format "HH:mm:ss"
$startdate = (Get-Content C:\ProgramData\systemwatcher\"$pathuser"time.txt)
$uploadid = (Get-Content C:\ProgramData\systemwatcher\"$pathuser"id.txt)
$timestuff= (New-TimeSpan -Start $startdate -End $endtime)
$divider = (":")
$totalworktime= ( -join ($timestuff.Hours,$divider,$timestuff.Minutes,$divider,$timestuff.Seconds))
$pcdomain = (Get-WmiObject Win32_ComputerSystem).Domain
$pcsqldomainnodots = ("$pcdomain" -replace "\.","")
$pcsqldomain = ("$pcsqldomainnodots" -replace "\-","")
$pathuser = [Environment]::UserName

#Imports SQL Module
[void][System.Reflection.Assembly]::LoadFrom("C:\ProgramData\systemwatcher\MySql.Data.dll")
#Make SQL function
function Run-MySQLQuery {
	param(
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
	begin {
		Write-Verbose "Starting Begin Section"
	}
	process {
		Write-Verbose "Starting Process Section"
		try {
			#load MySQL
			Write-Verbose "Create Database Connection"
			[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
			$connection = New-Object MySql.Data.MySqlClient.MySqlConnection
			$connection.ConnectionString = $ConnectionString
			Write-Verbose "Open Database Connection"
			$connection.Open()

			#Run Querys
			Write-Verbose "Running MySQL Querys"
			$command = New-Object MySql.Data.MySqlClient.MySqlCommand ($query,$connection)
			$dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter ($command)
			$dataSet = New-Object System.Data.DataSet
			$recordCount = $dataAdapter.Fill($dataSet,"data")
			$dataSet.Tables["data"]
		}
		catch {
			Write-Host "Trying to connect again"
            
		}
		finally {
			Write-Verbose "Connection was Stopped"
			$connection.Close()
            

		}
	}
	end {
		Write-Verbose "Starting End Section"
        
	}
}

if(-not ($uploadid -eq $null -or $uploadid -eq "")) {
 run-MySQLQuery -ConnectionString "Server=192.168.1.11;Uid=sysi;Pwd=zuitO20055002;database=systems2;" -Query "
 UPDATE $pcsqldomain 
SET 
    session = '$totalworktime'
WHERE
    id = $uploadid;"}
    else{exit}