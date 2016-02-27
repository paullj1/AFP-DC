
# Logs into remot computers and runs the LocalLoadSimulator script.
# Script assumes 'LocalLoadSimulator.ps1' and 'Connect-Mstsc.ps1' are on the desktop

# If doing SMB share traffic generation, need to enable CredSSP as follows:
# - On Controller: EnableWSManCredSSP -Role Client -DelegateComputer *.domain.com
# - On Clients:    EnableWSManCredSSP -Role Server

$net_use_pass = '!@12QWqwe'
$client = 'client1.afnet.com'
$time = 10
$reqs_per_sec = 2
$rdp_host = 'ts.afnet.com'
$rdp_user = 'user1'
$rdp_pass = '!@12QWqwe'
$net_root = '\\TS\Shared'
$web_urls = 'google.com,espn.com,cnn.com,facebook.com'

$pw = $net_use_pass|ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($net_use_name,$pw)
$s = New-PSSession -ComputerName $client -Credential $cred -Authentication Credssp
Invoke-Command -Session $s -ScriptBlock { Set-Location ..\Desktop }
Invoke-Command -Session $s -ScriptBlock { param($1, $2, $3, $4, $5, $6, $7) .\LocalLoadSimulator.ps1 $1 $2 $3 $4 $5 $6 $7 } -ArgumentList $time, $reqs_per_sec, $rdp_host, $rdp_user, $rdp_pass, $net_root, $web_urls
Remove-PSSession $s