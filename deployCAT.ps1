# The following script creates go.pdf to update CATInstall repo from the CyberAuditBuild Repo
Function Get-Folder {
    param (
        $initialDirectory,        
        # You can add a description to the folder choose window
        $Description,
        # An option to disable the "Add new folder button"
        [switch] $DisableNewFolder,
        # If paramter is present, return "Cancel" if user pressed the Cancel or "X" buttons
        [switch] $ReturnCancelIfCanceled
    ) 
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
    $FolderBrowserDialog.ShowNewFolderButton = !$DisableNewFolder
    if (![string]::IsNullOrEmpty($Description)) { $FolderBrowserDialog.Description = $Description }
    if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
    $Topmost = New-Object System.Windows.Forms.Form
    $Topmost.TopMost = $True
    $Topmost.MinimizeBox = $True
    $ButtonPressed =  $FolderBrowserDialog.ShowDialog($Topmost) 
    if ($ReturnCancelIfCanceled -and ($ButtonPressed -eq "Cancel")) {return "Cancel"}
    return $FolderBrowserDialog.SelectedPath
}

function ReplaceGoPDFFile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $BasePath
    )
    try{
        $src = "$BasePath\go.pdf"
        $dest = "$BasePath\CATInstall\go.pdf"
        # copy and replace new pdf file into th catinstall repo
        [System.IO.File]::Copy($src, $dest, $true);
        Write-Host "The updated go.pdf file is in local repository."
    } catch {
        "[failed] error occured while trying to copy and overwite the go.pdf file."
    }
}

function UploadCATInstallToGit {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $BasePath
    )
    try{
        $commands = @("cd $BasePath\CATInstall","git add go.pdf","git commit -m `"new version of CAT deployed`"","git push -u")
        Foreach ($cmd in $commands) {
            Invoke-Expression $cmd
        }
    } catch {
        Write-Host "[failed] error while uploading to github..."
    }
    
}

$dirName = 'C:\CATDeploy'
If (Test-Path $dirName){
    rmdir $dirName -Force -Recurse
}
Write-Host "Creating temporary folders in $dirName"
New-Item -Path "c:\" -Name "CATDeploy" -ItemType "directory"
$BasePath = $dirName
While([bool](Get-ChildItem $BasePath)){
    if ([string]::IsNullOrEmpty($BasePath)) {
        exit
    }
    write-host "[Fail] The folder $BasePath is not empty" -ForegroundColor Red
    Write-Host "Would you like to empty the chosen folder?([Y]\[N]) If the answer is No, you must choose an empty folder" -ForegroundColor Yellow
    $input = Read-Host 
    if ($input -eq "y"){
        Get-ChildItem -Path $BasePath | foreach { rm -Recurse $BasePath\$_ -Force}
        if ([bool](Get-ChildItem $BasePath)) {
             write-host "[Fail] Failed to delete all files. Please delete manualy" -ForegroundColor Red
             read-host “Press ENTER to continue (or Ctrl+C to quit)”
        }
    } else {
        Write-Host "Please choose a different folder"
        $BasePath = ""
        $BasePath = Get-Folder
    }
}
Set-Location $BasePath

# download CyberAuditTool from main (cloning)
try {
    $authcmd1 = "git config --global user.email `"barper@post.bgu.ac.il`""
    $authcmd2 = "git config --global user.name `"barPerlman`""
    $authcmd3 = "git remote add origin https://contigon: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@github.com/contigon/CyberAudit2021.git"
    Invoke-Expression $authcmd1
    Invoke-Expression $authcmd2
    Invoke-Expression $authcmd3
    $cloneCmd = "git clone https://contigon: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@github.com/contigon/CyberAudit2021.git"
    Invoke-Expression $cloneCmd
    Write-Host "Last version of CAT repository is cloned"
    }
catch {
    Write-Host "[Failed] Error connecting to download site."
    }
# compressing into pdf
 try{
    Write-Host "creating the deployment file..."
    [System.IO.Compression.ZipFile]::CreateFromDirectory("$BasePath\CyberAudit2021", "$BasePath\go.pdf")
    Write-Host "PDF deployment file created successfully"
 }catch {
     Write-Host "[Failed] error in compression to PDF process"
 }
 # download CATInstall from main (cloning)
try {
    
    $cloneCmd = "git clone https://contigon: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@github.com/contigon/CATInstall.git"
    Invoke-Expression $cloneCmd
    Write-Host "Last version of CATInstall repository is cloned"
    ReplaceGoPDFFile $BasePath
    UploadCATInstallToGit $BasePath
    }
catch {
    Write-Host "[Failed] Error connecting to download site."
    }
# deployment finished so deletes temporary folder.
Set-Location "c:\"
If (Test-Path $dirName){
    rmdir $dirName -Force -Recurse
}
