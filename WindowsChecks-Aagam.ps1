Function Get-Mondalezpostpovisioncheck 
{
<#

    .SYNOPSIS
        

    .DESCRIPTION
        

    .PARAMETER file
        String. Mandatory.
        

    .PARAMETER ExportPath
        String.
        

    .EXAMPLE
        Get-Mondalezpostpovisioncheck -File "C:\servers.txt" -ExportPath "C:\Output.xlsx"

    .NOTES
        -------------------------------------------------------------------------------------------------
        Author              Date            Version         Comments
        -------------------------------------------------------------------------------------------------
        Aagam Jain     21/06/2019    1.0.0        Initial script
        Harish Karthic 21/06/2019    1.1.0        Minor tweaks
        Aagam Jain     7/08/2019     1.2.0        Keepalivetime and keepaliveintervel added
#>

[Cmdletbinding()]
param (
[Parameter(Mandatory=$false)]
[string]$File,
[Parameter(Mandatory=$false)]
[string]$ExportPath
)



  
    # initializing variables
$input = Get-Content -LiteralPath $file
#$ExportPath = $ExportPath +"\$($erv).xlsx"


foreach ($erv in $input)
{
$ExportPath1 = $null
$ExportPath1 = $ExportPath +"\$erv.xlsx"
$varacc = $false
$localacc=Get-WmiObject -Class Win32_UserAccount -Filter  "name='admin_accenture'"
$OS=Get-CimInstance Win32_OperatingSystem -ComputerName $erv
$service=Get-Service -Name wuauserv -ComputerName $erv
$timezone=Invoke-Command -ComputerName $erv -ScriptBlock {Get-TimeZone}
$software=Get-WmiObject -Class Win32_Product -ComputerName $erv #| where { $_.name -like "*Snare*" -or $_.name -like "*CrowdStrike*" -or $_.name -like "*Red Cloak*"}
$domainjoinstatus=(Get-WmiObject -Class Win32_ComputerSystem -ComputerName $erv).PartOfDomain
#$drive=Get-WmiObject -Class Win32_logicaldisk -ComputerName $erv -Filter DriveType="3" #| select @{n="Drive letter";e={$_.DeviceID}},@{n="Size";e={$_.Size/1GB}},@{n="Free Space";e={$_.FreeSpace/1GB}},VolumeName
$drive = gwmi -Class win32_volume -ComputerName $erv -erroraction Ignore
$DSubnetsAuthoritive=Invoke-Command -ComputerName $erv -ScriptBlock {Get-ItemPropertyValue HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation -Name "DSubnetsAuthoritive"}
$DomainSubnets=Invoke-Command -ComputerName $erv -ScriptBlock {Get-ItemPropertyValue HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation -Name "DomainSubnets"}
$firewall=Invoke-Command -ComputerName $erv -ScriptBlock {Get-NetFirewallProfile -Name "Domain"}
$activation=Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $erv | where {$_.PartialProductKey}
$dns=Invoke-Command -ComputerName $erv -ScriptBlock {Get-NetAdapter | Get-DnsClient -ErrorAction SilentlyContinue}
$dgate=Get-WMIObject Win32_NetworkAdapterConfiguration -computername "$erv" | where{$_.IPEnabled -eq $true} | select Description,DefaultIPGateway
$localadmin=Invoke-Command -ComputerName $erv -ScriptBlock {Get-LocalGroupMember -Group "Administrators"}
#$Remotedesktopusers=Invoke-Command -ComputerName $erv -ScriptBlock {Get-LocalGroupMember -Group "Remote Desktop Users"}
$Pagefilesize=get-wmiobject Win32_pagefileusage -ComputerName $erv #| select caption,AllocatedBaseSize
$IP=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $erv | where {$_.DefaultIPGateway -ne $null} | select-object Description,ipaddress
$Amatric=Invoke-Command -ComputerName $erv -ScriptBlock {Get-NetIPInterface | where {$_.AddressFamily -like "IPV4"}}
invoke-command -computername $ERV -scriptblock {Send-MailMessage -To "aagam.jain@accenture.com" -from "PCUTreadiness@mdlz.com" -SmtpServer smtp.mdlz.com -Subject "$env:COMPUTERNAME-Pcut"}
$windowspatch=Get-HotFix -ComputerName $erv
$Drivers = Get-WmiObject Win32_PnPSignedDriver -ComputerName $erv |where {$_.DeviceName -like "*Mellanox*"}
#Enter-PSSession -ComputerName $erv
$NICX=Invoke-Command -ComputerName $erv -ScriptBlock { Get-NetAdapterStatistics}
$IPaddress=(Resolve-DnsName -Name $erv |where {$_.type -eq 'A'}).IPAddress
$reverselookup = (Resolve-DnsName $IPaddress).NameHost
$ervdb = ($erv).ToLower().replace("wap","wdb")
$ervdb = $ervdb -replace ".{2}$"
$ervdb = $ervdb+"01"+".krft.net"
$telnet=(Test-NetConnection -ComputerName $ervdb -Port 1433)
$sqlConn = New-Object System.Data.SqlClient.SqlConnection
$sqlConn.ConnectionString = “Server=$evrdb;Integrated Security=true;Initial Catalog=master”
$sqlConn.Open()
$sqlcmd = $sqlConn.CreateCommand()
$sqlcmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $sqlConn
$query = “SELECT SERVERPROPERTY('productversion'), 
       SERVERPROPERTY ('productlevel'), 
       SERVERPROPERTY ('edition')”
$sqlcmd.CommandText = $query
$adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
$data = New-Object System.Data.DataSet
$adp.Fill($data) | Out-Null
$clusterfeature=Get-WindowsFeature -Name "Failover-Clustering" -ComputerName $erv

$ser = [system.directoryservices.directorysearcher]"LDAP://dc=krft,dc=net"
$ser.Filter = "(&(objectclass=computer)(name=$erv))"
$res = $ser.FindAll()

if( $res[0] -eq $null){ 
$ou = "Not Found in AD"
}


$res[0].path.replace("LDAP://","").split(",") | where {$_ -like "DC=*"} | %{ 

$ou=$null

for ($i=  ($res[0].path.replace("LDAP://","").split(",") ).count; $i -gt 0;--$i){
if($i -eq  ($res[0].path.replace("LDAP://","").split(",") ).count -or $i -eq (($res[0].path.replace("LDAP://","").split(",") ).count-1) ){

#"in if"
}
else{
$ou +=  $( [string]($res[0].path.replace("LDAP://","").split(",") )[$i-1].split("=")[-1] + [string]"/")
}
}
}

$ou = "/KRFT.Net/" + $ou
$ou = $ou.substring(0, ($ou.Length - ($ou.split("/")[-2]).length-2) )


$windowsdefender=(Get-WindowsFeature |where {$_.name -eq "Windows-Defender-GUI"}).Installstate 

if($windowsdefender -eq "Available")
{
$windefender =  "NOT-INSTALLED"
}
else
{
$windefender =  "INSTALLED"
}

if (($localacc).Name -eq "admin_accenture")

{
$varacc= $true
}
if ($DSubnetsAuthoritive -eq 1)
{
$DSubnets= "Enabled"
}
else {$DSubnets= "Disabled" }
if (($firewall).Enabled -eq 0 )

{
$fire= $false
}
else {$fire= $true }
if (($activation).LicenseStatus -eq 1 )

{
$activate= "Activated"
}
else {$activate= "Not Activated"}

If ($reverselookup -ne $null)
{
$reverselookup = "True"
}

if($data.Tables -ne $null)
{
$DSNconnection = "Open"
}
if($clusterfeature -ne $null)
{
$clusternames = Invoke-Command -ComputerName $erv {(Get-Cluster).name}
$clustergroups = Invoke-Command -ComputerName $erv {Get-ClusterGroup}
$clusterNodes = Invoke-Command -ComputerName $erv {Get-ClusterNode}
}

$keepalivetime = $null
$keepaliveinterval = $null
$keepalivetime=invoke-command -ComputerName $erv -ScriptBlock {(Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name KeepAliveTime -ErrorAction SilentlyContinue).keepalivetime}
$keepaliveinterval=invoke-command -ComputerName $erv -ScriptBlock {(Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name KeepAliveInterval -ErrorAction SilentlyContinue).KeepAliveInterval}
if ($keepalivetime -ne $null)
{
$keepalivetime= "$keepalivetime"
}
Else
{
$keepalivetime = "NA"
}

if ($keepaliveinterval -ne $null)
{
$keepaliveinterval = "$keepaliveinterval"
}
Else
{
$keepaliveinterval = "NA"
}

$servicesToCheck = @("GxClMgrS(Instance001)", "GxCVD(Instance001)", "GXMMM(Instance001)", "GxFWD(Instance001)", "GxVssProv(Instance001)" )
$commvaultservice = $null
$commvaultservice=Get-Service -ComputerName $erv -Name $servicesToCheck -ErrorAction SilentlyContinue
if($commvaultservice -eq $null)
{
$Commvaultservicestatus = "NotFound"
}
Else 
{
$Commvaultservicestatus = "Present"
}

$hfile = $null
$hostfile = $null
$hostfile=Invoke-Command -ComputerName $erv -ScriptBlock{Get-Content -path C:\Windows\System32\Drivers\etc\hosts} |
 where {(!$_.StartsWith("#")) -and $_ -ne ""}

 if($hostfile -ne $null)
 {
 $hfile = "exist"
 }
 else
 {
 $hfile ="Not-exist"
 }

$dnssuffixlist = $null
$dnssuffixlist = Invoke-Command -ComputerName $erv -ScriptBlock {(Get-DnsClientGlobalSetting).SuffixSearchList.count}

$event = $null
$systemevent = $null
$event = Get-EventLog System -After (Get-Date).Adddays(-1)|Where {$_.EntryType -eq 'Critical' -or $_.EntryType -eq 'Error'}
if ($event-eq $null)
{
 $Systemevent = "Null"
}
Else
{
$Systemevent  = "Errors"
}

$xboxstartuptype = (Get-Service XblAuthManager -ComputerName $erv).StartType
$xboxservicestatus = (Get-Service XblAuthManager -ComputerName $erv).Status

$arr11 = @()
foreach($clustername in $clusternames)
{
$clusterIP=(Resolve-DnsName  $clusternames).IPAddress
$obj11=new-object -TypeName PSobject
$obj11 | Add-Member -MemberType NoteProperty -Name "Clustername" -Value $clustername
$obj11 | Add-Member -MemberType NoteProperty -Name "ClusterIP" -Value $clusterIP
$arr11 += $obj11
}
$arr11 | Export-Excel -Path $ExportPath1 -WorksheetName "ClusterConfiguration"
$clusterpath = Test-Path "\\$erv\C$\Windows\Cluster\Reports"
if ($clusterpath -eq $true)
{
$clusterreport=[xml]$(Get-Content -Path "\\$erv\C$\Windows\Cluster\Reports\*.xml")
if ($clusterreport.Report.Channel.Channel.message.level -like 'Warn' -and $clusterreport.Report.Channel.Channel.message.level -like 'Erro*')
{
$clusterstatus = "Error"
}
elseif ($clusterreport.Report.Channel.Channel.message.level -like 'Warn')
{
$clusterstatus = "OK with Warning"
}
Else
{
$clusterstatus = "OK"
}
}
else
{
$clusterstatus = "NA"
}

$array=@()
$obj=new-object -TypeName PSobject
$obj | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj | Add-Member -MemberType NoteProperty -Name "Operating System" -Value $OS.caption
$obj | Add-Member -MemberType NoteProperty -Name "Operating System Version" -Value $OS.version
$obj | Add-Member -MemberType NoteProperty -Name "Time Zone" -Value $timezone.DisplayName
$obj | Add-Member -MemberType NoteProperty -Name "admin_accenture" -Value $varacc
$obj | Add-Member -MemberType NoteProperty -Name "DSubnetsAuthoritive" -Value $DSubnets
$obj | Add-Member -MemberType NoteProperty -Name "DomainSubnets" -Value $DomainSubnets
$obj | Add-Member -MemberType NoteProperty -Name "Domain joinstatus" -Value $domainjoinstatus
$obj | Add-Member -MemberType NoteProperty -Name "Domain Firewall" -Value $fire
$obj | Add-Member -MemberType NoteProperty -Name "Server Activation" -Value $activate
$obj | Add-Member -MemberType NoteProperty -Name "KMS Server" -Value $activation.KeyManagementServiceMachine
$obj | Add-Member -MemberType NoteProperty -Name "Windows update service startuptype" -Value $service.StartType
$obj | Add-Member -MemberType NoteProperty -Name "Windows update service status" -Value $service.Status
$obj | Add-Member -MemberType NoteProperty -name "ReverseLookup" -value $reverselookup
$obj | Add-Member -MemberType NoteProperty -Name "TelnetConnection" -value $telnet.TcpTestSucceeded
$obj | Add-Member -MemberType NoteProperty -name "RemoteAddress" -value $telnet.RemoteAddress
$obj | Add-Member -MemberType NoteProperty -name "DSNConnection" -value $DSNconnection
$obj | add-member -MemberType NoteProperty -name "OU" -Value "$OU"
$obj | add-member -MemberType NoteProperty -name "WindowsDefenderStatus" -Value "$windefender"
$obj | add-member -membertype Noteproperty -name "keepalivetime" -value "$keepalivetime"
$obj | add-member -membertype Noteproperty -name "keepaliveinterval" -value "$keepaliveinterval"
$obj | add-member -membertype Noteproperty -name "Commvaultservicestatus" -value "$Commvaultservicestatus"
$obj | add-member -membertype Noteproperty -name "Hostfile" -value "$hfile"
$obj | Add-Member -MemberType NoteProperty -name "DNSsuffixcount" -Value "$dnssuffixlist"
$obj | Add-Member -MemberType NoteProperty -name "SystemEvents" -Value "$Systemevent"
$obj | Add-Member -MemberType NoteProperty -name "xboxstartuptype" -Value "$xboxstartuptype"
$obj | Add-Member -MemberType NoteProperty -name "xboxservicestatus" -Value "$xboxservicestatus"

$array += $obj
$array | Export-Excel -Path $ExportPath1 -WorksheetName "OS1"

$array1=@()
foreach ($disk in $drive)
{
$obj1=new-object -TypeName PSobject
$obj1 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj1 | Add-Member -MemberType NoteProperty -Name "Drive letter" -Value $disk.Name
$obj1 | Add-Member -MemberType NoteProperty -Name "Total Size" -Value ($disk.Capacity/1GB)
$obj1 | Add-Member -MemberType NoteProperty -Name "Free Space" -Value ($disk.FreeSpace/1GB)
$obj1 | Add-Member -MemberType NoteProperty -Name "Volume Name" -Value $disk.Label
$obj1 | Add-Member -MemberType NoteProperty -Name "Blocksize" -Value $disk.blocksize

$array1 += $obj1
} 
$array1 | Export-Excel -Path $ExportPath1 -WorksheetName "Disk Detail"

$array2=@()
foreach ($IPs in $IP)
{
$obj2 =new-object -TypeName PSobject
$obj2 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj2 | Add-Member -MemberType NoteProperty -Name "IP Description" -Value $IPs.Description
$obj2 | Add-Member -MemberType NoteProperty -Name "IP Address" -Value $IPs.ipaddress
$array2 +=$obj2
} 
 $array2 |  Export-Excel -Path $ExportPath1 -WorksheetName "IP"

$array3=@()
foreach ($nicdns in $dns)
{
$obj3=new-object -TypeName PSobject
$obj3 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj3 | Add-Member -MemberType NoteProperty -Name "NIC Name" -Value $nicdns.InterfaceAlias
$obj3 | Add-Member -MemberType NoteProperty -Name "RegisterThisConnectionsAddress" -Value $nicdns.RegisterThisConnectionsAddress
$obj3 | Add-Member -MemberType NoteProperty -name "UseSuffixWhenRegistering" -Value $nicdns.UseSuffixWhenRegistering

$array3+=$obj3 
}
$array3 | Export-Excel -Path $ExportPath1 -WorksheetName "NIC Detail"

$arraydgate=@()
foreach ($gate in $dgate)
{
$objdgate=new-object -TypeName PSobject
$objdgate | Add-Member -MemberType NoteProperty -Name "Nic Description" -Value $gate.Description
$objdgate | Add-Member -MemberType NoteProperty -Name "DefaultIPGateway" -Value $gate.DefaultIPGateway
$arraydgate += $objdgate }
$arraydgate | Export-Excel -Path $ExportPath1 -WorksheetName "Nic Gateway"

$arrayamate=@()
foreach ($Amate in $Amatric)
{
$objamate=new-object -TypeName PSobject
$objamate | Add-Member -MemberType NoteProperty -Name "Interface Alias" -Value $Amate.InterfaceAlias
$objamate | Add-Member -MemberType NoteProperty -Name "Automatic Metric" -Value $Amate.AutomaticMetric
$objamate | Add-Member -MemberType NoteProperty -Name "Automatic Metric Value" -Value $Amate.InterfaceMetric
$arrayamate += $objamate }
$arrayamate | Export-Excel -Path $ExportPath1 -WorksheetName "AutomaticMetric"

$array4=@()
foreach ($admins in $localadmin)
{
$obj4=new-object -TypeName PSobject
$obj4 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj4 | Add-Member -MemberType NoteProperty -Name "Local Admin Group list" -Value $admins.name 
$array4 += $obj4 }
$array4| Export-Excel -Path $ExportPath1 -WorksheetName "LocalAdmin"


$array5=@()
foreach ($page in $Pagefilesize)
{
$obj5=new-object -TypeName PSobject
$obj5 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj5 | Add-Member -MemberType NoteProperty -Name "Page File Drive" -Value $page.caption
$obj5 | Add-Member -MemberType NoteProperty -Name "Page File Size" -Value $page.AllocatedBaseSize 
$array5 += $obj5 
}
$array5| Export-Excel -Path $ExportPath1 -WorksheetName "PagefileSetting"

$array6=@()
foreach ($name1 in $software)
{

$obj6=new-object -TypeName PSobject
$obj6 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj6 | Add-Member -MemberType NoteProperty -Name "Software Name" -Value $name1.name
$obj6 | Add-Member -MemberType NoteProperty -Name "Version" -Value $name1.version

$array6+=$obj6
}
$array6 |  Export-Excel -Path $ExportPath1 -WorksheetName "Installed Software"


$array7=@()
foreach ($patch in $windowspatch)
{
$obj7=new-object -TypeName PSobject
$obj7 | Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj7 | Add-Member -MemberType NoteProperty -Name "Patch Description" -Value $patch.Description
$obj7 | Add-Member -MemberType NoteProperty -Name "HotFixID" -Value $patch.HotFixID
$obj7 | Add-Member -MemberType NoteProperty -Name "InstalledBy" -Value $patch.InstalledBy
$obj7 | Add-Member -MemberType NoteProperty -Name "InstalledOn" -Value $patch.InstalledOn

$array7+=$obj7
}
$array7 |  Export-Excel -Path $ExportPath1 -WorksheetName "All Patches"

$array8=@()
if($Drivers -ne $null)
{

    $obj8=new-object -TypeName PSobject
    $obj8 |Add-Member -MemberType NoteProperty -name "MellanoxDriveName" -Value $drivers[0].DeviceName
    $obj8 |Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
    $obj8 |Add-Member -MemberType NoteProperty -Name "Driver Version" -Value $drivers[0].DriverVersion
    $array8+=$obj8
    
}
Else
{
    $obj8=new-object -TypeName PSobject
    $obj8 |Add-Member -MemberType NoteProperty -name "MellanoxDriveName" -Value "Mellanox driver is not present"
    $obj8 |Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
    $obj8 |Add-Member -MemberType NoteProperty -Name "Driver Version" -Value "Mellanox driver is not present"
    $array8+=$obj8
}
$array8 |  Export-Excel -Path $ExportPath1 -WorksheetName "Mellanoxdriver"

$array9=@()
$recievebuffers =@()
Foreach($NIC in $NICX)
{
$recievebuffers=Invoke-Command -ComputerName $erv -ScriptBlock{Get-NetAdapterAdvancedProperty -DisplayName "Receive Buffer Size"}
}
Foreach($recievebuffer in $recievebuffers)
{
$obj9=new-object -TypeName PSobject
#$obj9 |Add-Member -MemberType NoteProperty -name "NICName" -Value "$rbuffer.name"
$obj9 |Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj9 |Add-Member -MemberType NoteProperty -Name "Nicname" -Value $recievebuffer.Name
$obj9 |Add-Member -MemberType NoteProperty -Name "Receivebuffersize" -Value $recievebuffer.RegistryValue
$array9+=$obj9
}
$array9 |  Export-Excel -Path $ExportPath1 -WorksheetName "Receivebuffer"

$array10=@()
$Sendbuffers =@()
Foreach($NIC in $NICX)
{
$Sendbuffers=Invoke-Command -ComputerName $erv -ScriptBlock{Get-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size"}
}
Foreach($Sendbuffer in $Sendbuffers)
{
$obj10=new-object -TypeName PSobject
#$obj9 |Add-Member -MemberType NoteProperty -name "NICName" -Value "$rbuffer.name"
$obj10 |Add-Member -MemberType NoteProperty -Name "Server Name" -Value $erv
$obj10 |Add-Member -MemberType NoteProperty -Name "Nicname" -Value $Sendbuffer.Name
$obj10 |Add-Member -MemberType NoteProperty -Name "SendBuffersize" -Value $Sendbuffer.RegistryValue
$array10+=$obj10
}
$array10 |  Export-Excel -Path $ExportPath1 -WorksheetName "SendBuffer"

$routeprint= $null
 $rfilename = "$erv"+"Routeprint"
 $routeprint=Invoke-Command -ComputerName $erv -ScriptBlock {cmd /c Route print}
$routeprint |out-file  "c:\temp\$rfilename.txt"

$rfiles=gc -path "c:\temp\$rfilename.txt"
$Rfs = $rfiles.Split("`n")
foreach($rf in $Rfs)
{
$rf |  Export-Excel -Path $ExportPath1 -WorksheetName "Route Print" -append
}

Write-Host "Data fetching completed for the server:" $erv -ForegroundColor Yellow

}
#start comparison block
If($?) {Get-WinDowsComparisonResults}
}