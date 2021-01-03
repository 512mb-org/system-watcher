$pathuser = [Environment]::UserName
$time = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$time2 = Get-Date -Format "HH:mm:ss"
$missingupload = "no"
$disks = Get-WmiObject -Class "Win32_LogicalDisk" -Filter "DeviceID='C:'"
$filename = Get-Date -UFormat "%m %d %Y"
$txt = ".txt"
$doesfileexist = Test-Path .\$filename$txt
$disks = Get-WmiObject -Class "Win32_LogicalDisk" -Filter "DeviceID='C:'"
$domainuser = (Get-WmiObject –Class Win32_ComputerSystem).Username
$user =  ("$domainuser" -replace ("\\", "_"))
$pcdomain = (Get-WmiObject Win32_ComputerSystem).Domain
#Checks installed software
$installed64 = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*  | Select-Object DisplayName,Publisher,Version,InstallDate | Sort-Object -Property InstallDate -Descending | Out-String)
$installed32 = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | Select-Object DisplayName,Publisher,Version,InstallDate | Sort-Object -Property InstallDate -Descending  | Out-String)
#Setting disk
if (-not (Test-Path C:\ProgramData\systemwatcher)) {
New-Item -ItemType directory -Path C:\ProgramData\systemwatcher}

if (-not (Test-Path C:\ProgramData\systemwatcher\"$pathuser"time.txt)) {
New-Item -ItemType file -Path C:\ProgramData\systemwatcher\"$pathuser"time.txt -Value "$time"}
else{
Remove-Item C:\ProgramData\systemwatcher\"$pathuser"time.txt
New-Item -ItemType file -Path C:\ProgramData\systemwatcher\"$pathuser"time.txt -Value "$time"
}


if (-not (Test-Path C:\ProgramData\systemwatcher\MySql.Data.dll -PathType leaf)){


#change the path to the one that is correct for your domain !


Copy-Item -Path '\\512.mb\netlogon\sql\*' -Destination 'C:\ProgramData\systemwatcher'
}

#this is not functional yet but will be kept so its easier to fix it.
#$startupexe = "\\$pcdomain\netlogon\startup.exe"
#$autostart = "C:\Users\$pathuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
#if(-not (Test-Path "C:\Users\$pathuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup.exe" -PathType Leaf)){
#if(-not (Test-Path "C:\Users\$pathuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")){
#New-Item -ItemType directory -Path "C:\Users\$pathuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"}
#Copy-Item -Path \\512.mb\NETLOGON\startup.exe -Destination $autostart
#}


$results = foreach ($disk in $disks)
#calculates disk in GB's raw data is $free and $size 
{
	if ($disk.Size -gt 0)
	{
		$size = [math]::Round($disk.Size / 1GB,0)
		$free = [math]::Round($disk.FreeSpace / 1GB,0)
		[pscustomobject]@{
			Drive = $disk.Name
			Name = $disk.VolumeName
			"Total Disk Size" = $size
			"Free Disk Size" = "{0:N0} ({1:P0})" -f $free,($free / $size)
		}
	}
}
#Makes disk chart(unused)
$freedisk = ($results | Format-Table -AutoSize | Out-String)

#This is here to check the version of Avast
function Version_Check {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0,Mandatory = $true,ValueFromPipeline = $true)]
		$Name
	)
	$app = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
	Where-Object { $_.DisplayName -match $Name } |
	Select-Object DisplayName,DisplayVersion,InstallDate,Version
	if ($app) {
		return $app.DisplayVersion
	}
}
$avast = Version_Check "Avast Business CloudCare"
#sets pc name
$pcname = [System.Environment]::MachineName
#gets serialnumber
$serialnumber = (Get-WmiObject -Class WIN32_SystemEnclosure -ComputerName $env:ComputerName).SerialNumber
#detects domain, gets converter later down.
$pcdomain = (Get-WmiObject Win32_ComputerSystem).Domain
#set time

$uptime =  (gcim Win32_OperatingSystem).LastBootUpTime | get-date -Format "yyyy/MM/dd HH:mm:ss" 
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
			Write-Verbose "Create Database Connection"
			[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
			$connection = New-Object MySql.Data.MySqlClient.MySqlConnection
			$connection.ConnectionString = $ConnectionString
			Write-Verbose "Open Database Connection"
			$connection.Open()

			#This makes Querys
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
$pcsqldomainnodots = ("$pcdomain" -replace "\.","")
$pcsqldomain = ("$pcsqldomainnodots" -replace "\-","")

#This is part of the offline session script and will be kept so its easier to reimplement
#if(-not(Test-Path C:\ProgramData\systemwatcher\"$pathuser"uploadmissing.txt -PathType leaf)){
#   New-Item -ItemType file -Path C:\ProgramData\systemwatcher\"$pathuser"uploadmissing.txt -Value "$time $uptime  $pathuser"}
#   else{$offlinesession = (Get-Content C:\ProgramData\systemwatcher\"$pathuser"uploadmissing.txt)}

Do{
 run-MySQLQuery -ConnectionString "Server=192.168.1.11;Uid=sysi;Pwd=zuitO20055002;database=systems2;" -Query "INSERT INTO $pcsqldomain (pcname, domain, serial, avast, user, diskspace, programms, pcstart, session)
    VALUES ('$pcname', '$pcdomain', '$serialnumber', '$avast', '$pathuser', '$free GB free from $size GB', ' 64bit $installed64 32bit $installed32', '$uptime', '1');"
   Write-Output "Loading"
   #Start-Sleep -ms 200
   $formatedinsertid=(run-MySQLQuery -ConnectionString "Server=192.168.1.11;Uid=sysi;Pwd=zuitO20055002;database=systems2;" -Query "SELECT LAST_INSERT_ID();" | Out-String)
   $insertid=($formatedinsertid -replace '\D+(\d+)','$1' -replace "`n","" -replace "`r","")
   Start-Sleep -Seconds 1
}
until(-not ($insertid -eq "" -or $insertid -eq $null))
if (-not (Test-Path C:\ProgramData\systemwatcher\"$pathuser"id.txt)) {
New-Item -ItemType file -Path C:\ProgramData\systemwatcher\"$pathuser"id.txt -Value "$insertid"}
else{
Remove-Item C:\ProgramData\systemwatcher\"$pathuser"id.txt
New-Item -ItemType file -Path C:\ProgramData\systemwatcher\"$pathuser"id.txt -Value "$insertid"
}

Write-Output "Start was succsefull"

#This is also part of the offline session script and will be keptop so its easier to reimplement when ready
#if(-not ($insertid -eq "" -or $insertid -eq $null)){Remove-Item C:\ProgramData\systemwatcher\"$pathuser"uploadmissing.txt}
exit
