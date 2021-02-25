<#	
	.NOTES
	===========================================================================
	 Created on:   	02/03/2020 1:11 PM
	 Created by:   	Golan Cohen
     Updated by:    Omer Friedman 29/03/2020
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberCoolectNetworkConfig
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Collect Configuration and routing tables from network devices
#>

. $PSScriptRoot\CyberFunctions.ps1
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - CollectNetworkConfig"

$ACQ = ACQ("Network")

$nipperDir = "$ACQ\NIPPER"

$vendors = @("CISCO","HP","H3C","Juniper","Enterasys","Fortigate", "Asa")

$TimeStamp = UniversalTimeStamp

#Global Variables
$global:length = $null;
$global:startRow = $null;
$global:worksheet = $null;
$global:devices = $null;
$global:excel = $null;
$global:usedexcel = $null;
$global:FilePath = $null;
$global:workbook = $null;

function Get-DeviceConfig
{
    [OutputType([String])]
    param
    (
		[Parameter(mandatory=$true)]
        [String]$HostAddress,
		[Parameter(mandatory=$true)]
        [Int]$HostPort,
        [Parameter(mandatory=$true)]
        [String]$Vendor,
		[Parameter(mandatory=$true)]
        [String]$Username,
        [Parameter(mandatory=$true)]
        [String]$Password,
		[Parameter(mandatory=$true)]
        [String]$Command,
        [Parameter(mandatory=$false)]
        [String]$Output,
        [Parameter(mandatory=$false)]
        [Switch]$Append,
        [Parameter(mandatory=$false)]
        [String]$NipperDir,
        [Parameter(mandatory=$true)]
        [String]$EnablePass
    )
    $SecPass = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential $Username, $SecPass
    $SSHSession = New-SSHSession -ComputerName $HostAddress -Port $HostPort -Credential $Credentials -AcceptKey
    $finishLine = ""
    if ($SSHSession.Connected)
    {
        $SessionStream = New-SSHShellStream -SessionId $SSHSession.SessionId
        if ($Vendor -eq $vendors[0]){
            #Cisco
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            $SessionStream.WriteLine("enable")
            Start-Sleep -s 2
            $ReadEnable = ""
            while (($line = $SessionStream.Read()) -ne "" -or $ReadEnable -eq ""){$ReadEnable += $line}
            if ($ReadEnable -like "*Password*") {$SessionStream.WriteLine($EnablePass)}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("terminal length 0")
        } elseif ($Vendor -eq $vendors[2]){
            #H3C
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("screen-length disable")
            $SessionStream.WriteLine("disable paging")
        } elseif ($Vendor -eq $vendors[1]){
            #HP
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("no page")
            $SessionStream.WriteLine("enable")
        } elseif ($Vendor -eq $vendors[3]){
            #Juniper
            while($SessionStream.ReadLine(5) -notlike "*master*"){}
            $SessionStream.WriteLine("")
            $finishLine = $SessionStream.ReadLine()
            $SessionStream.WriteLine("set cli screen-width 1000")
        } elseif ($Vendor -eq $vendors[4]){
            #Enterasys
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("terminal more disable")
        } elseif ($Vendor -eq $vendors[5]) {
            #Fortigate
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("config system console")
            $SessionStream.WriteLine("set output standard")
        } elseif ($Vendor -eq $vendors[6]) {
            #Asa
            $intro = ""
            while(($line=$SessionStream.Read()) -ne "" -or $intro -eq ""){$intro += $line}
            while (($line = $SessionStream.ReadLine(5)) -eq ""){}
            $SessionStream.WriteLine("")
            while($SessionStream.ReadLine(5) -eq $null){}
            while($SessionStream.ReadLine(5) -eq ""){}
            $finishLine = $SessionStream.Read();
            $SessionStream.WriteLine("enable")
            $SessionStream.WriteLine("terminal pager 0")
            $SessionStream.WriteLine("no pager")
        }
        $SessionStream.WriteLine($command)
        $SessionStream.WriteLine("");
        $i = 0;
        while (($line = $SessionStream.ReadLine(5)) -notlike $finishLine){
            if($line -ne $null){
            Write-Host $line
            $SessionResponse += $line | Out-String;
            }
            Write-Progress -Activity "Running $command on $ip" -PercentComplete $i
            $i = ($i + 1) % 100
        }
        if ($Output){
            if ($Append) {
                Add-Content -Encoding UTF8 $Output $SessionResponse;
            } else {
                Set-Content -Encoding UTF8 $Output $SessionResponse;
            }
            Write-Host "Finished running '$command' on $ip" -ForegroundColor Green
        }
        if ($NipperDir){
            Set-Content -Encoding UTF8 "$NipperDir\run$HostAddress.txt" $SessionResponse;
        }
        $SSHSessionRemoveResult = Remove-SSHSession -SSHSession $SSHSession
        if (-Not $SSHSessionRemoveResult)
        {
            Write-Error "Could not remove SSH Session $($SSHSession.SessionId):$($SSHSession.Host)"
        }
    }
    else
    {
        throw [System.InvalidOperationException]"Could not connect to SSH host: $($HostAddress):$HostPort"
        $SSHSessionRemoveResult = Remove-SSHSession -SSHSession $SSHSession
        if (-Not $SSHSessionRemoveResult)
        {
            Write-Error "Could not remove SSH Session $($SSHSession.SessionId):$($SSHSession.Host)."
        }
    }
}

function Check-Table($totalRows) 
{
    $counter = 0
    for ($col = 1; $col -le 5;$col++)
    {     
        for ($row = 2; $row -le $totalRows;$row++)
        {
            $cell = $global:worksheet.Cells.Item($row, $col).Text
            if ([string]::IsNullOrEmpty($cell)){
                    $global:worksheet.Cells.Item($row, $col).Interior.ColorIndex = 3
                    $counter++
                    $global:worksheet.Cells.Item(2,8) = "Checking excel table..."
                    $global:worksheet.Cells.Item(2,8).font.bold = $true
                    $global:worksheet.Cells.Item(2,8).font.size = 12
                    $global:worksheet.Cells.Item(2,8).font.colorindex = 45
                }
        }
    }
    if ($counter -ne 0) 
    {
        Write-Host "Please fill the missing data in the excel table" -ForegroundColor Red
        $global:worksheet.Cells.Item(2,8) = "Please fill the missing data in the excel table"
        $global:worksheet.Cells.Item(2,8).font.bold = $true
        $global:worksheet.Cells.Item(2,8).font.size = 12
        $global:worksheet.Cells.Item(2,8).font.colorindex = 3
        Read-Host "When finished, Press [Enter] to continue"
    }
    else
    {
        Write-Host "Data in table is filled ok" -ForegroundColor Green
        $global:worksheet.Cells.Item(2,8) = "Data in table is filled ok"
        $global:worksheet.Cells.Item(2,8).font.bold = $true
        $global:worksheet.Cells.Item(2,8).font.size = 12
        $global:worksheet.Cells.Item(2,8).font.colorindex = 4
        Read-Host "If all OK, Press [Enter] to continue"
    }
}


function create-excel
{
    #creating the excel file for this audit

    $global:excel.Visible = $false
    try{
        $global:workbook = $global:excel.Workbooks.Add()
        $global:worksheet = $global:workbook.Worksheets.Item(1)
    } catch {
        Write-Host "Excel is installed but not initialized" -ForegroundColor Red
        Read-Host "Press enter to use .json format or re-run the script after initializing excel"
        $global:usedexcel = $false
        Create-JSON
        return;
    }
    $global:worksheet.Name = "DeviceList"
    $global:worksheet._DisplayRightToLeft = $false

    $global:worksheet.Cells.Item(1,1) = "IP"
    $global:worksheet.Cells.Item(1,2) = "SSH Port"
    $global:worksheet.Cells.Item(1,3) = "User Name"
    $global:worksheet.Cells.Item(1,4) = "Password"
    $global:worksheet.Cells.Item(1,5) = "Vendor"
    $global:worksheet.Cells.Item(1,6) = "Enable-Password"
    $global:worksheet.Cells.range("A1:F1").font.bold = $true
    $global:worksheet.Cells.range("A1:F1").font.size = 12
    $global:worksheet.Cells.range("A1:F1").font.colorindex = 4

    $global:worksheet.Cells.Item(1,8) = "Please save [Ctrl+S] after changes !!!"
    $global:worksheet.Cells.Item(1,8).font.bold = $true
    $global:worksheet.Cells.Item(1,8).font.size = 12
    $global:worksheet.Cells.Item(1,8).font.colorindex = 3

    $VendorsHeader = "CISCO,HP,H3C,Juniper,Enterasys,Fortigate,ASA"
    $Range = $global:worksheet.Range("E2:E100")
    $Range.Validation.add(3,1,1,$VendorsHeader)
    $Range.Validation.ShowError = $False

    $global:excel.DisplayAlerts = $false
    $global:FilePath = "$ACQ\NetworkDevices-$TimeStamp.xlsx"
    $global:worksheet.SaveAs($FilePath)

    $global:excel.Visible = $true


}

function Create-JSON
{
    Write-Host "Copy and paste the device object as many times as needed and fill in the values"
    Write-Host 'Make sure to fill vendor = {"CISCO","HP","H3C","Juniper","Enterasys","Fortigate", "Asa"}'
    Read-Host "Please save [Ctrl+S] after changes!!! [Press enter to continue]"
    $global:FilePath = "$ACQ\NetworkDevices-$TimeStamp.txt"
    $Content = 
'[
{"IP": "",
 "SSHPort": "",
 "Username": "",
 "Password": "",
 "Vendor": "",
 "Enable-Password": ""
},
	    
{"IP": "",
 "SSHPort": "",
 "Username": "",
 "Password": "",
 "Vendor": "",
 "Enable-Password": ""
}
]'
    Set-Content $FilePath $Content; Invoke-Item $FilePath
}

function Check-JSON($FilePath)
{
    $loop = $true
    while ($loop){
        Write-Host "Checking JSON format..."
        try {
            $global:devices = Get-Content $FilePath | ConvertFrom-Json
            $loop = $false
        } catch {
            Write-Host "Format of file is incorrect" -ForegroundColor Red
            $input = Read-Host "Please fix the file or press [N] to create a new JSON file (Press Enter if you fixed the file)"
            if ($input -eq "N") {
                create-JSON
            }
        }
    }
    Write-Host "JSON format is good" -ForegroundColor Green    
    Write-Host "Checking file content"
    $length = $devices.length
    $counteri = 0
    $counterj = 0
    for ($row = 0; $row -lt $length;$row++)
    {
        $IPEntry = $devices[$row].IP
        $PortEntry = $devices[$row].SSHPort
        $UserEntry = $devices[$row].Username
        $PassEntry = $devices[$row].Password
        $VendorEntry = $devices[$row].Vendor
        if ([string]::IsNullOrEmpty($IPEntry)){
            $counteri++
        }
        if ([string]::IsNullOrEmpty($UserEntry)){
            $counteri++
        }
        if ([string]::IsNullOrEmpty($PassEntry)){
            $counteri++
        }
        if (!($VendorEntry -in $vendors)){
            Write-Host "Vendor in device $($row+1) must be of $vendors"
            $counterj++
        }
    }
    if ($counteri -ne 0 -or $counterj -ne 0){
        Write-Host "Found [$counteri] empty entries and [$counterj] incompatible vendors" -ForegroundColor Red
        Write-Host "Please fix the file"
        Read-Host "When finished, Press [Enter] to continue"
    } else {
        Write-Host "Data in file is filled ok" -ForegroundColor Green
        Read-Host "If all OK, Press [Enter] to continue"
    }
}

function create-devices-file(){
try{
    $global:excel = New-Object -ComObject Excel.Application
    Write-Host "Excel is installed" -ForegroundColor Green
    Write-Host "We recommend using excel for this script, but you can also use .json format"
    $input = Read-Host "Press Enter to use Excel or [J] for JSON"
    if ($input -eq 'J'){
        $global:usedexcel = $false
        create-json
    } else {
        $global:usedexcel = $true
        create-excel
    }
} catch {
    Write-Host "Excel is not installed on this PC" -ForegroundColor Red
    Write-Host "We recommend running this module using excel" -ForegroundColor Yellow
    Read-Host "Press [Enter] to continue with the run (use .json) or [Ctrl + C] to quit"
    $global:usedExcel = $false
    create-json
}
}

$help = @"

        This tool will try to automatically collect configuration and routing tables from network devices
        using SSH protocol.

        This tool is currently supporting these devices:
        1. CISCO (IOS/Nexus)
        2. HP
        3. H3C
        4. Juniper
        5. Enterasys
        6. Fortigate
        7. ASA

        The tool requires as an input an excel file in this format:
        IP | SSH Port | Username | Password | Enable-Password | Vendor

        Enable-Password - Only fill this box if it is different than the login password (i.e when using RADIUS)

        IP can be in the form of:
        192.168.1.1
        192.168.1.1-192.168.1.20
        192.168.2.0/24

        Please follow these steps:
        1. Excel template file will be automatically created at:
           $ACQ\NetworkDevices-$TimeStamp.xlsx
        2. please fill all the data in the correct columns before running the collection task
        3. Do not Close excel and do not use Save As 
        4. Follow the instructions in the script

"@

Write-Host $help 

$types = @("NetworkDevices*.txt","NetworkDevices*.xlsx")

if(Test-Path -Path "$ACQ\*" -Include $types[1]){
    Write-Host "A .xlsx already exists inside the Network directory" -ForegroundColor Yellow
    Write-Host "Would you like to create a new network file or use the one that exists?"
    $xlsx = Read-Host "Press [N] to create a new file, otherwise press Enter"
    if($xlsx -ne "N"){
        $file = Get-ChildItem $ACQ $types[1]
        $global:FilePath = $file.FullName.ToString()
        $global:usedexcel = $true
        $global:excel = New-Object -ComObject Excel.Application
        $global:workBook = $global:excel.Workbooks.Open($global:FilePath)
        $global:worksheet = $global:workBook.Worksheets.Item(1)
    } else {
    create-devices-file
    }
} elseif(Test-Path -Path "$ACQ\*" -Include $types[0]){
    Write-Host "A .json already exists inside the Network directory" -ForegroundColor Yellow
    Write-Host "Would you like to create a new network file or use the one that exists?"
    $txt = Read-Host "Press [N] to create a new file, otherwise press Enter"
    if($txt -ne "N"){
        $file = Get-ChildItem $ACQ $types[0]
        $global:FilePath = $file.FullName.ToString()
        $global:usedexcel = $false
    } else {
    create-devices-file
    }
} else {
    create-devices-file
}

$action = Read-Host "Press [S] to check device list and to start collecting config data (or Enter to quit)"

if ($action -eq "S") {
    if ($global:usedExcel){
        $length = $worksheet.UsedRange.Rows.Count + 1
        $IPCol = 1
        $PortCol = 2
        $UserCol = 3
        $PassCol = 4
        $VendorCol = 5
        $EnablePass = 6
        $StartRow = 2
        Check-Table($length - 1)
    } else {
        Check-JSON($FilePath)
        $length = $($devices.Length)
        $StartRow = 0
    }
    $null = New-Item -Path "$ACQ\NIPPER" -ItemType Directory -ErrorAction Ignore
    $null = New-Item -Path "$ACQ\log.txt" -ErrorAction Ignore -Force 
    Write-Host "Creating connection and retrieving configuration files,Please wait..."
    for ($i = $StartRow; $i -lt $length; $i++){
        Write-Progress -Activity "Running $command on $ip" -PercentComplete ([Int]$i)/([Int]$length)
        if ($usedExcel){
            $IPRange = $worksheet.Cells.Item($i, $IPCol).Text
            $port = $null 
            $port = $worksheet.Cells.Item($i, $PortCol).Text
            $username = $worksheet.Cells.Item($i, $UserCol).Text
            $password = $worksheet.Cells.Item($i, $PassCol).Text
            $vendor = $worksheet.Cells.Item($i, $VendorCol).Text
            $enable = $worksheet.Cells.Item($i, $EnablePass).Text
        } else {
            $IPrange = $devices[$i].IP
            $port = $null 
            $port = $devices[$i].SSHPort
            $username = $devices[$i].Username
            $password = $devices[$i].Password
            $vendor = $devices[$i].Vendor
            $enable = $devices[$i]."Enable-Password"
        }
        if ([String]::IsNullOrEmpty($enable)) {
            $enable = $password 
        }
        if ([String]::IsNullOrEmpty($port)) {
            $port = 22
        }
        $IPs = $null
        if ($IPRange -like "*[\/]*" -or $IPRange -like "*-*"){
            if ($IPRange -like "*[\/]*"){
                $IPSplit = $IPRange.Split("[\/]")
                $IPs = Get-IPrange -ip $IPSplit[0] -cidr $IPSplit[1] 
            } else {
                $IPSplit = $IPRange.Split("-")
                $IPs = Get-IPrange -start $IPSplit[0] -end $IPSplit[1]
            }
        } else {
            $IPS = $IPRange
        }
        foreach($ip in $IPs){
            $savePath = "$ACQ\$vendor-$ip-$port\"
            Write-Host "Trying to collect data from device: $Vendor ip: $ip port: $port"
            try {
        	    $null = New-Item -Path $savePath -ItemType Directory -ErrorAction Ignore
	            switch($vendor)
	            {
	                #CISCO
	                $vendors[0]{
 				        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "sh run" -Output $savePath'sh run.txt' -Nipper $nipperDir
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "show ip route vrf *" -Output $savePath'route.txt'
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "sh snmp user" -Output $savePath'snmp.txt'
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "sh conf | include hostname" -Output $savePath'run.txt'
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "sh ver" -Output $savePath'run.txt' -a
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[0] -EnablePass $enable -Command "show access-lists" -Output $savePath'run.txt' -a
	                }
	                #H3C
	                $vendors[2]{
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[2] -EnablePass $enable -Command "display" -Output $savePath\'run.txt' -Nipper $nipperDir
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[2] -EnablePass $enable -Command "display ip routing-table" -Output $savePath\'route.txt'
	                }
	                #HP
	                $vendors[1]{
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[1] -EnablePass $enable -Command "sh run" -Output $savePath\'run.txt' -Nipper $nipperDir
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[1] -EnablePass $enable -Command "show ip route" -Output $savePath\'route.txt'
	                }
	                #Juniper
	                $vendors[3]{
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[3] -EnablePass $enable -Command "show configuration | display inheritance | no-more" -Output $savePath\'run.txt' -Nipper $nipperDir
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[3] -EnablePass $enable -Command "show chassis hardware | no-more" -Output $savePath\'run.txt' -a
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[3] -EnablePass $enable -Command "show route logical-system all | no-more" -Output $savePath\'route.txt'
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[3] -EnablePass $enable -Command "show route all | no-more" -Output $savePath\'route-allW.txt'
	                }
	                #Enterasys
	                $vendors[4]{
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[4] -EnablePass $enable -Command "show config all" -Output $savePath\'run.txt' -Nipper $nipperDir
                        Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[4] -EnablePass $enable -Command "show ip route" -Output $savePath\'route.txt'
	                }
	                #Fortigate
	                $vendors[5]{
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[5] -EnablePass $enable -Command "get system status" -Output $savePath\'config.txt'
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[5] -EnablePass $enable -Command "show" -Output $savePath\'config.txt' -Append -Timeout
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[5] -EnablePass $enable -Command "get router info routing-table" -Output $savePath\'route.txt'
	                }
	                #ASA
	                $vendors[6]{
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[6] -EnablePass $enable -Command "show run" -Output $savePath\'run.txt' -Nipper $nipperDir
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[6] -EnablePass $enable -Command "show access-lists" -Output $savePath\'run.txt' -Append
	                    Get-DeviceConfig -HostAddress $ip -HostPort $port -Username $username -Password $password -Vendor $vendors[6] -EnablePass $enable -Command "show route" -Output $savePath\'route.txt'
	                }
                }
            Add-Content -Encoding UTF8 "$ACQ\log.txt" "$ip - Success";
            } catch {
        	    Write-Host "[Failure] Error connecting to device: $Vendor ip: $ip port: $port" -ForegroundColor Red
                Add-Content -Encoding UTF8 "$ACQ\log.txt" "$ip - Failure";
            }
        }
    }
    Invoke-Item "$ACQ\log.txt"
}
if ($UsedExcel){
    [void]$workbook.Close($false)
    $excel.DisplayAlerts = $true
    [void]$excel.quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}


