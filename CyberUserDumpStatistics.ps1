<#	
	.NOTES
	===========================================================================
	 Created on:   	17/03/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberUserDumpStatistics.ps1
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Cyber Domain and Enterprise admins users Statistics
        https://github.com/dfinke/ImportExcel
        https://github.com/dfinke/ImportExcel/tree/master/Examples
        https://blog.psskills.com/2019/01/13/excel-reports-using-importexcel-module-from-powershell-gallery/
#>

$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Domain and Enterprise admins users Statistics"

. $PSScriptRoot\CyberFunctions.ps1

#Get-Process EXCEL | kill
#kills any excel process with a file name "cyber" if running
KillApp("EXCEL","Cyber")

$filesPath = $ACQ

$xlfile = "$filesPath\Admin-users-dump-statistics.xlsx"
Remove-Item $xlfile -ErrorAction Ignore

$userDump = Import-Csv -path "$filesPath\user-dump.csv"

$AdminConTxt = New-ConditionalText -Range C:G -Text "TRUE" -ConditionalTextColor Black -BackgroundColor Green
$PassExpireConTxt = New-ConditionalText -Range H:H -Text "TRUE" -ConditionalTextColor Black -BackgroundColor Red
$userDump | Export-Excel $xlfile -AutoSize -StartRow 1 -StartColumn 1 -WorksheetName "Statistics" -ConditionalFormat $AdminConTxt,$PassExpireConTxt


$xl = Export-Excel -Path $xlfile -WorksheetName "Statistics"  -PassThru -AutoSize
$ws = $xl.Workbook.Worksheets["Statistics"]

$TotalRows = $ws.Dimension.Rows
$range = $ws.Dimension.Address

for ($i = 2;$i -le $TotalRows; $i++)
{
    #check if not an admin so hide row
   if ($ws.SelectedRange["C$i:C$i"].Value.Equals("False"))
   {
        $ws.Row($i).Hidden = $true
   }
}

$TotAdmins = 0
for ($i = 2;$i -le $TotalRows; $i++)
{
    #check if not an admin so hide row
   if ($ws.SelectedRange["C$i:C$i"].Value.Equals("True") -and $ws.SelectedRange["H$i:H$i"].Value.Equals("True"))
   {
        $TotAdmins++
   }
}

$lastRow = $TotalRows + 2
Set-ExcelRange -Worksheet $ws -Range "A1:L1" -BackgroundColor lightGray -Bold
$ws.Cells["A$lastRow"].Value = "Total Admins with Password never expires = $TotAdmins"
Set-ExcelRow -Worksheet $ws -Row $lastRow -Bold -FontSize 28 -BackgroundColor yellow

Close-ExcelPackage $xl -Show
success "Taking snapshot of results and saving"
Convert-ExcelRangeToImage -workSheetname "Statistics" -Path $xlfile  -range $range  -destination "$ACQ\Admin-Users-Passwordno-Statistics.png" -show
