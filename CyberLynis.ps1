function Start-Lynis {
    param (     
        [Alias("ACQ", "OutputPath")]
        [Parameter(Mandatory = $true)]
        [string]
        $ReportDestinationFolder,

        [Alias("Lynis")]
        [Parameter(Mandatory = $true)]
        [string]
        $LynisRemoteTarGz     
    )
    
    Write-Host ""
    $remoteMachine = Read-Host "Enter remote linux server address"
    $username = Read-Host "Enter remote linux server user"
    $password = Read-Host "Enter remote linux server password"
    $ReportRemoteDest = "/home/$username/tmp/lynis-report.dat"
    $LogRemoteDest = "/home/$username/tmp/lynis-log.log"
    $RemoteOutput = "/home/$username/tmp/lynis-output.txt"

    Write-Host ""
    Write-Host "Lynis will run now, please ignore password requests" -ForegroundColor Yellow
    Write-Host ""

    $cmd = "plink -batch -ssh -l $username -pw $password $RemoteMachine `"mkdir -p /home/$username/tmp`""
    Invoke-Expression $cmd

    # Step 2: Copy tarball to target 192.168.56.117
    $cmd = "pscp -l $username -pw $password $LynisRemoteTarGz $remoteMachine`:/home/$username/tmp/lynis-remote.tgz"
    Invoke-Expression $cmd

    # Step 3.1: Deploy the file
    $cmd = "plink -batch -ssh -l $username -pw $password $RemoteMachine `"mkdir -p /home/$username/tmp/tmp-lynis && cd /home/$username/tmp/tmp-lynis && tar xzf ../lynis-remote.tgz && rm ../lynis-remote.tgz`""
    Invoke-Expression $cmd
    # Step 3.2: Execute audit command
    $cmd = "plink -batch -ssh -l $username -pw $password $RemoteMachine `"cd /home/$username/tmp/tmp-lynis/lynis; echo $password | sudo -S ./lynis audit system --nocolors --report-file $ReportRemoteDest --log-file $LogRemoteDest  > $RemoteOutput`""
    Invoke-Expression $cmd

    #Step 4: Clean up directory
    $cmd = "plink -batch -ssh -l $username -pw $password $RemoteMachine `"echo $password | sudo -S rm -rf /home/$username/tmp/tmp-lynis && echo $password | sudo -S chown -R $username /home/$username/tmp/`""
    Invoke-Expression $cmd

    # Step 5: Retrieve log and report
    $cmd = "pscp -l $username -pw $password $remoteMachine`:$LogRemoteDest $ReportDestinationFolder\192.168.56.117-lynis.log"
    Invoke-Expression $cmd
    $cmd = "pscp -l $username -pw $password $remoteMachine`:$ReportRemoteDest $ReportDestinationFolder\192.168.56.117-lynis-report.dat"
    Invoke-Expression $cmd
    $cmd = "pscp -l $username -pw $password $remoteMachine`:$RemoteOutput $ReportDestinationFolder\192.168.56.117-lynis-output.txt"
    Invoke-Expression $cmd

    # Step 6: Clean up tmp files (when using non-privileged account)
    $cmd = "plink -batch -ssh -l $username -pw $password $RemoteMachine `"rm $LogRemoteDest $ReportRemoteDest $RemoteOutput`""
    Invoke-Expression $cmd


    write-host "Done. Press [ENTER] to continue"
}