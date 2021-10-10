
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



Write-Host "Browse and Create a new path for the last version installation..."
$BasePath = Get-Folder
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
write-host "[Success] The folder $BasePath is empty" -ForegroundColor Green
Set-Location $BasePath

# download CyberAuditTool from main (cloning)
try {
    $cloneCmd = "git clone https://github.com/contigon/CyberAudit2021.git"
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
 