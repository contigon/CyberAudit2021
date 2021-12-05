#-------------------                    Masscan related functions                    --------------------------------#

function AskBanners {
    $ans = Read-Host "would you like to add banners check? [y/n]"
    if($ans -eq 'y'){
        return $true
    }
    return $false
}

function planCustomScan {
    # The next process of asking the user for inputs for the tool
    # Those inpuuts will be concatenated into masscan apply command
    $targets = Read-Host "Type target IPs or subnets to scan"
    $ports = Read-Host "Please type ports or range of ports you wish to scan"
    $rate = Read-Host "Specify the desired packet sending rate (packets/second)"
    $isExcludeFile = Read-Host "Do you want to use an excluding file? [y/n]"
    $optionalArgs = Read-Host "If you wish to insert more arguments for masscan command, do it now.`nTo `
    finish constructing and execute the inserted, hit [Enter] button: "
    $excludeFile = $null
    if($isExcludeFile -eq 'y'){
        $excludeFile = Read-Host "Insert the file path or hit [enter] to use the default file "
        if($excludeFile.Length -gt 2){
            $excludeFile = "‐‐excludefile "+$excludeFile
        }   
        else {
            $excludeFile = "‐‐excludefile exclude.txt"
        }
    }else{
        $excludeFile = ''
    }
    $confFileName = $null
    $isWishSave = Read-Host "would you like to save your constructed scanning plan? [y/n]"
    if($isWishSave -eq "y"){
        $confFileName = Read-Host "Give your config file a name (without the extension type) "
    }
    $massCommand = "masscan.exe "+$targets+" -p"+$ports+" --rate "+$rate +" "+$excludeFile
        if($optionalArgs.Length -gt 2){
            $massCommand = $massCommand +" "+ $optionalArgs
        }
        $isBanners = AskBanners
        $sourceIP = $null
        if($isBanners){
            $sourceIP = Read-Host "Enter local subnet ubused IP address "
            $massCommand = $massCommand + "--banners --source-ip $sourceIP"
        }
    # saving the scan configuration for future run
    if ($confFileName){
        $concatConfName = "$confFileName"+"Conf.txt"
        Write-Host "Saving configuration to $PSScriptRoot/$confFileName"
        $massCommand = $massCommand + " --echo > $concatConfName"
        Invoke-Expression $massCommand
        
    }
    # running scan by gathered arguments
    Write-Host "Running the scan..."
    $massCommand = $massCommand + " > results.txt"
    return $massCommand
}

function scanWebServers {
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them "
    $query =  "masscan.exe $nets -p80,443,8080 ––rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if($isBanners){
        $sourceIP = Read-Host "Enter local subnet ubused IP address "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanTopN {
    $N = Read-Host "Specify the N for top N number of the most common ports to scan"
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them "
    $query =  "masscan.exe $nets ‐‐top-ports $N ––rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if($isBanners){
        $sourceIP = Read-Host "Enter local subnet ubused IP address "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanAllPorts {
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them "
    $query =  "masscan.exe $nets -p0-65535 ––rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if($isBanners){
        $sourceIP = Read-Host "Enter local subnet ubused IP address "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanBroadcast {
    # transmission rate - packets per second
    $rate = "1000000"
    # holds the nets to scan
    $nets = "0.0.0.0/0"
    $exludedFile = Read-Host "Type here a file contains nets to exclude your scan to avoid risky results:`nIf `
    your'e not sure what you're doing, please hit ctrl^C to exit and avoiding scan unwanted IPs over the INTERNET!!"
    $ports = Read-Host "Type the port(s) you would like to scan in the wide internet"
    $query =  "masscan.exe $nets -p$ports ––rate $rate ‐‐excludefile $exludedFile"
    $isBanners = AskBanners
    $sourceIP = $null
    if($isBanners){
        $sourceIP = Read-Host "Enter local subnet ubused IP address "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function preconfigUserPlan {
    Write-Host "The following are the saved configuration files we found:"
    $confFiles = Get-ChildItem -Filter "*Conf.txt"  # Get the text files which contains preset configurations
    for ($i=0;$i -lt $confFiles.Count;$i++){Write-Host ($i+1) - $confFiles[$i].basename}
    $selectedConFile = Read-Host "Choose a file number: "
    $selIndex = $selectedConFile-1
    $conFileName = $confFiles[$selIndex].FullName
    $query = "masscan.exe -c $conFileName"
    return $query
}

function ScanPresetsMenu {
        $help = @"
Choose a preset plan from the following:
----------------------------------------
1. Scan a network for Web Ports.
2. Scan a network for the Top 10 ports.
3. Scan a network for All Ports.
4. Scan everywhere (internet broadcast) for a specific port(s) - `nBe carefull and avoid scanning unwanted hosts by specifying excluded file!
5. Choose a preconfigured plan of yours.
"@
Write-Host $help
$selection = Read-Host "Type a number from the options above: "
switch ($selection) {
    1 { return scanWebServers }
    2 { return scanTopN }
    3 { return scanAllPorts }
    4 { return scanBroadcast }
    5 { return preconfigUserPlan }
    Default {write-host "You typed invalid character. exit..."}
}
}

function createExcludedHostFile {
    # IP addresses to ignore received by the user
    $IPsStr = Read-Host "Please enter the addresses you don't want to scan: "
    $IPArray = $IPsStr.Split(" ")
    # read file name
    $excludeFileName = Read-Host "Name the new file (without type extension): "
    $excFileNameToSave = $excludeFileName+"Exc.txt"
    foreach($ip in $IPArray){
        $ip | Out-File -Append -FilePath $excFileNameToSave
    }
    Write-Host "The new excluding file is saved as $excFileNameToSave"
}