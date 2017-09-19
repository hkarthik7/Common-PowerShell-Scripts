#/////////////////////////////////////////////////////////////////////////
#POWERSHELL SCRIPT FOR BASIC HEALTH CHECK OF THE SERVERS:
#DEVELOPED IN POWERSHELL VERSION :- 4.0
#DATE & TIME :- 6-MAY-2017, 4:00 PM
#AUTHOR :- HARISH KARTHIC
#/////////////////////////////////////////////////////////////////////////

$servers = Get-Content "C:\Basic_Server_Health_Check\servers.txt" # Input file, place the servers.txt file in C drive and paste all your servers in it.

Get-Date | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Fetch current date and time

foreach($server in $servers) # Forloop starts
{

if(Test-Connection -ComputerName $server -Quiet) # If condition to check whether the server is reachable or not
{
$cpu = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average # Fecth Average CPU Load

$memory = Get-WmiObject -Class win32_operatingsystem -ComputerName $server | 
Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }} # Fetch Average Memory usage

$diskspace = Get-WmiObject win32_logicaldisk -ComputerName $server -Filter "Drivetype=3"  | 
ft DeviceID,@{Label="Total Size in GB";Expression={$_.Size / 1gb -as [int] }},@{Label="Free Size in GB";Expression={$_.freespace / 1gb -as [int] }} -autosize # Fetch Free disk space unit and size

$automatic_service = Get-WmiObject -Class Win32_Service -ComputerName $server -Filter "State = 'Stopped'" | Where-Object {$_.StartMode -eq "Auto"} | Format-Table -AutoSize # Displays all the automatic services status

Write-Output "Generating Output for $server ........................" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Output of the server name for which the script is fetching the information

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "Server Uptime:-" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

$WMIAGENT = gwmi -class Win32_OperatingSystem -computer $Server

$BOOTTime = $WMIAGENT.ConvertToDateTime($WMIAGENT.Lastbootuptime)

[TimeSpan]$uptime = New-TimeSpan $BOOTTime $(get-date)

Write-output "\\$Server is up for $($uptime.days) Days $($uptime.hours) Hours $($uptime.minutes) Minutes $($uptime.seconds) Seconds" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "Average CPU Load :-" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Display's current CPU load of the server

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

$cpu | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "Memory Usage :-" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Display's current memory load of the server

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

$memory | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "DiskSpace :-" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Display's overall diskspace

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

$diskspace | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "Automatic Services status :-" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Display's Automatic services status

Write-Output "/////////////////////////" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

$automatic_service | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

Write-Output "-------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

} # End of if condition

else # Else condition starts

{

Write-Output "$server is not-reachable" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append # Dispalys the server's unreachability status

Write-Output "-------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Append

} # End of else loop

} # End of for loop

Invoke-Item "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt"

Send-MailMessage -SmtpServer smtpgw.seadrill.com -To "Wintel <wintel.sdrl@hpe.com>" -From Server-health_check@DXC.com -Subject "Health Check is Completed" -Attachments "C:\Basic_Server_Health_Check\Health_Check_$((Get-Date).ToString('MM-dd-yyyy')).txt" -Body "Hello All, Please find the attached health check status."