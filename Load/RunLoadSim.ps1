
# Logs into remot computers and runs the LocalLoadSimulator script.
# Script assumes 'LocalLoadSimulator.ps1' and 'Connect-Mstsc.ps1' are on the desktop

# If doing SMB share traffic generation, need to enable CredSSP as follows:
# - On Controller: Enable-WSManCredSSP -Role Client -DelegateComputer *.domain.com
# - On Clients:    Enable-WSManCredSSP -Role Server
#                  Enable-PSRemoting

$net_use_name = 'Administrator'
$net_use_pass = '!@12QWqwe'
$clients = "client1.afnet.com,client2.afnet.com,client3.afnet.com,client4.afnet.com,client5.afnet.com".Split(',')
$time = 300
$reqs_per_sec = 2
$rdp_host = 'ts.afnet.com'
$rdp_user = 'user1'
$rdp_pass = '!@12QWqwe'
$net_root = '\\TS\Shared'
$web_urls = 'espn.com,cnn.com,facebook.com,yahoo.com,news.google.com'

foreach ( $client in $clients ) {
    $pw = $net_use_pass|ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($net_use_name,$pw)
    $s = New-PSSession -ComputerName $client -Credential $cred -Authentication Credssp
    Invoke-Command -Session $s -ScriptBlock { Set-Location ..\Desktop }
    Invoke-Command -Session $s -AsJob -ScriptBlock { param($1, $2, $3, $4, $5, $6, $7) .\LocalLoadSimulator.ps1 $1 $2 $3 $4 $5 $6 $7 } -ArgumentList $time, $reqs_per_sec, $rdp_host, $rdp_user, $rdp_pass, $net_root, $web_urls
    
}
