function Connect-Mstsc {
<#
.NOTES   
Name: Connect-Mstsc
Author: Jaap Brasser
DateUpdated: 2016-01-12
Version: 1.2.2
Blog: http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com
#>
    [cmdletbinding(SupportsShouldProcess,DefaultParametersetName='UserPassword')]
    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [Alias('CN')]
            [string[]]$ComputerName,
        [Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=1)]
        [Alias('U')] 
            [string]$User,
        [Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=2)]
        [Alias('P')] 
            [string]$Password,
        [Parameter(ParameterSetName='Credential',Mandatory=$true,Position=1)]
        [Alias('C')]
            [PSCredential]$Credential,
        [Alias('A')]
            [switch]$Admin,
        [Alias('MM')]
            [switch]$MultiMon,
        [Alias('F')]
            [switch]$FullScreen,
        [Alias('Pu')]
            [switch]$Public,
        [Alias('W')]
            [int]$Width,
        [Alias('H')]
            [int]$Height,
        [Alias('WT')]
            [switch]$Wait
    )

    begin {
        [string]$MstscArguments = ''
        switch ($true) {
            {$Admin} {$MstscArguments += '/admin '}
            {$MultiMon} {$MstscArguments += '/multimon '}
            {$FullScreen} {$MstscArguments += '/f '}
            {$Public} {$MstscArguments += '/public '}
            {$Width} {$MstscArguments += "/w:$Width "}
            {$Height} {$MstscArguments += "/h:$Height "}
        }

        if ($Credential) {
            $User = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $Process = New-Object System.Diagnostics.Process
            
            # Remove the port number for CmdKey otherwise credentials are not entered correctly
            if ($Computer.Contains(':')) {
                $ComputerCmdkey = ($Computer -split ':')[0]
            } else {
                $ComputerCmdkey = $Computer
            }

            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\cmdkey.exe"
            $ProcessInfo.Arguments = "/generic:TERMSRV/$ComputerCmdkey /user:$User /pass:$Password"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($ComputerCmdkey,'Adding credentials to store')) {
                [void]$Process.Start()
            }

            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\mstsc.exe"
            $ProcessInfo.Arguments = "$MstscArguments /v $Computer"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($Computer,'Connecting mstsc')) {
                [void]$Process.Start()
                Start-Sleep -Seconds 5
                $Process.Kill()
            }
        }
    }
}

# Need to enable CredSSP as follows:
# - On Controller: EnableWSManCredSSP -Role Client -DelegateComputer *.domain.com
# - On Clients:    EnableWSManCredSSP -Role Server

Write-Host '###################################################################'
Write-Host '#                                                                 #'
Write-Host '#        -- Welcome to the dynamic Load Generator! --             #'
Write-Host '#                                                                 #'
Write-Host '# This script generates Web, Mail, RDP, and DNS traffic at random #'
Write-Host '#                                                                 #'
Write-Host '###################################################################'
Write-Host ''

$num_services = 0

[int]$reqs_sec = Read-Host 'How many requests per second would you like to run (1-10)? [2]'
if (-not $reqs_sec) { $reqs_sec = 2 }
if ($reqs_sec -gt 10 -or $reqs_sec -lt 1) {
    Write-Host 'Must enter number between 1 and 10'
    Exit
}

[int]$runtime = Read-Host 'How long (seconds) would you like to run? [60]'
if (-not $runtime) { $runtime = 60 }
if ($runtime -lt 1) {
    Write-Host 'Must enter number greater than 1'
    Exit
}

$clients = Read-Host 'Which hosts can I use (comma seperated)? [localhost]'
if (-not $clients) { $clients = 'localhost' }
$clients = $clients.Split(',')
    
# Remote Desktop Connection
$rdp = Read-Host 'Would you like to run RDP connections? [Y/n]'
if ($rdp -match "[y+Y+yes]" -or -not $rdp ) {
    $name = Read-Host 'Enter your RDP username'
    $pass = Read-Host 'Enter your RDP password'
    $rdp_host = Read-Host 'Enter your RDP host'
    if ( -not ($name -or $pass -or $rdp_host)) {
        Write-Host 'You must enter host and credentials to be able to use RDP.  Continuing without it.'
        $rdp = 0
    } else {
        $rdp = 1
        $num_services++
    }
} else {
    $rdp = 0
}

# Net Use
$net_use = Read-Host 'Would you like to make file-share transfers? [Y/n]'
if ($net_use -match "[y+Y+yes]" -or -not $net_use ) {
    $net_use_host = Read-Host 'Enter your network share (\\server\share)'
    $net_use_name = Read-Host 'Enter the username for the network share'
    $net_use_pass = Read-Host 'Enter the password for the network share'
    if ( -not ($net_uset_name -or $net_use_pass -or $net_use_host)) {
        Write-Host 'You must enter the network share to be able to use this feature.  Continuing without it.'
        $net_use = 0
    } else {
        $net_use = 1
        $num_services++
    }
} else {
    $net_use = 0
}

# Web Requests
$web_req = Read-Host 'Would you like to make web requests? [Y/n]'
if ($web_req -match "[y+Y+yes]" -or -not $web_req ) {
    $url = Read-Host 'Enter desitnation URL(s, comma seperated)'
    if ( -not $url ) {
        Write-Host 'You must enter a destination URL to use this feature.  Continuing without it.'
        $web_req = 0
    } else {
        $web_req = 1
        $urls = $url.Split(',')
        $num_services++
    }
} else {
    $web_req = 0
}

# Mail
$mail = Read-Host 'Would you like to send randomly generated e-mails? [Y/n]'
if ($mail -match "[y+Y+yes]" -or -not $mail ) {
    $smtp = Read-Host 'Enter smtp server'
    if ( -not $smtp ) {
        Write-Host 'You must enter an SMTP server to use this feature.  Continuing without it.'
        $mail = 0
    } else {
        $mail = 1
        $num_services++
    }
} else {
    $mail = 0
}


$end_time = [convert]::ToDecimal((Get-Date -UFormat "%s")) + $runtime
do {
    $start_time = [convert]::ToDecimal((Get-Date -UFormat "%s"))
    for ( $i = 0; $i -lt $reqs_sec; $i+=$num_services ) {
        $client = $clients[(Get-Random -Minimum 0 -Maximum 100) % $clients.Count]
    
        # Remote Desktop
        if ($rdp) {
            Write-Host "Initiating RDP Connection to: $rdp_host, from: $client"
            Invoke-Command -ComputerName $client -ScriptBlock ${ function:Connect-Mstsc } -ArgumentList $rdp_host,$name,$pass
        }

        # Network Share (Connect, write 100 random bytes, delete file, disconnect)
        if ($net_use) {
            Write-Host "Initiating Net Share Access on: $net_use_host, from: $client"
            
            $pw = $net_use_pass|ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($net_use_name,$pw)
            $s = New-PSSession -ComputerName $client -Credential $cred -Authentication Credssp
            Invoke-Command -Session $s -ScriptBlock { New-PSDrive -Name Shared -PSProvider FileSystem -Root $args[0] } -ArgumentList $net_use_host
            
            for ($i=0;$i -lt 100;$i++) {
                $text += Get-Random -InputObject (48..90) | %{[char]$_}
            }

            Invoke-Command -Session $s -ScriptBlock { $args[0] > 'Shared:\file.txt' } -ArgumentList $text 
            Invoke-Command -Session $s -ScriptBlock { Remove-Item 'Shared:\file.txt' }
            Invoke-Command -Session $s -ScriptBlock { Remove-PSDrive Shared }
            Remove-PSSession -Session $s            
        }

        # Web Requests
        if ($web_req) {
            $rand = (Get-Random -Minimum 0 -Maximum 100) % $urls.Count
            $url = $urls[$rand]
            Write-Host "Initiating WebRequest to: $url, from: $client"
          
            $r = Invoke-Command -ComputerName $client -ScriptBlock { param($url) Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 7.0; InfoPath.3; .NET CLR 3.1.40767; Trident/6.0; en-IN)" } -ArgumentList $url
            if ($r.StatusCode -notcontains "200") {
                Write-Warning "Warning:  Recieved status code '$r.StatusCode' on request to $url"
            }
        }

        # Send E-mail
        if ($mail) {

        }
    }

    $current_time = [convert]::ToDecimal((Get-Date -UFormat "%s"))
    $diff_time = $current_time - $start_time 
    if ( $diff_time -lt 1.0 ) {
        $diff_time /= 1000
        [math]::floor($diff_time)
        Start-Sleep -Milliseconds $diff_time
    }
} while ( $current_time -lt $end_time ) 







