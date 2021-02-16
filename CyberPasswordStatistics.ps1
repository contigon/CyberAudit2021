<#	
	.NOTES
	===========================================================================
	 Created on:   	17/03/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberPasswordsStatistics.ps1
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Cyber Domain and Enterprise admins cracked Passwords Statistics
        https://github.com/dfinke/ImportExcel
        https://github.com/dfinke/ImportExcel/tree/master/Examples
        https://blog.psskills.com/2019/01/13/excel-reports-using-importexcel-module-from-powershell-gallery/
#>

$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Password Statistics"

#Get-Process EXCEL | kill
#kills any excel process with a file name "cyber" if running
KillApp("EXCEL","Cyber")

$filesPath = $ACQ

$xlfile = "$filesPath\CyberStatistics.xlsx"
Remove-Item $xlfile -ErrorAction Ignore

$DomainString = ((Get-Content -Path "$filesPath\found_*.txt" -Tail 1).Split("\")[0])
(((Get-Content -Path "$filesPath\found_*.txt") -replace ":",",") -replace $DomainString,"").TrimStart("\") | Set-Content -Path "$filesPath\foundPasswords.csv"
$domAdmins = Import-Csv -path "$filesPath\Domain_Users_Domain Admins.csv"
$entAdmins = Import-Csv -path "$filesPath\Domain_Users_Enterprise Admins.csv"
$FoundPasswords = Import-Csv -path "$filesPath\foundPasswords.csv" -Header "user","hash","password"

Export-Excel -Path $xlfile -InputObject ($domAdmins + $entAdmins) -WorksheetName 'TotalAdmins' -AutoSize
Export-Excel -Path $xlfile -InputObject ($FoundPasswords) -WorksheetName 'Passwords' -AutoSize

$xl = Export-Excel -Path $xlfile -WorksheetName 'Statistics' -PassThru -AutoSize

$RowsPasswords = $xl.Passwords.Dimension.Rows
$RowsTotalAdmin = $xl.TotalAdmins.Dimension.Rows 

$TotalAdmins = $RowsTotalAdmin -1
$windowSize = $RowsTotalAdmin + 50

Set-ExcelRange -Address $xl.TotalAdmins.Cells["D1"] -Value "Password"

Set-ExcelRange -Worksheet $xl.TotalAdmins -Range A2:A$RowsTotalAdmin -BackgroundColor lightblue
Set-ExcelRange -Worksheet $xl.TotalAdmins -Range A1:D1 -BackgroundColor lightyellow 
Set-ExcelRange -Worksheet $xl.Passwords -Range A1:D1 -BackgroundColor lightyellow
Set-ExcelRange -Worksheet $xl.TotalAdmins -Range A1:P$windowSize -BorderAround Hair -BorderBottom Hair -BorderRight Hair -BorderLeft Hair -BorderTop Hair -BorderColor white
Set-ExcelRange -Worksheet $xl.TotalAdmins -Range D2:D$RowsTotalAdmin -Formula "=VLOOKUP(B2,Passwords!A2:C$RowsPasswords,3,FALSE)" -HorizontalAlignment Center

Set-ExcelRange -Address $xl.TotalAdmins.Cells["F5"] -Value "Total Enterprise & Domain Admins" -AutoSize -BackgroundColor lightyellow
Set-ExcelRange -Address $xl.TotalAdmins.Cells["G5"] -Value $TotalAdmins -HorizontalAlignment Center -AutoSize -BackgroundColor lightyellow
Set-ExcelRange -Address $xl.TotalAdmins.Cells["F6"] -Value "Total Admin Passwords Cracked" -AutoSize  -BackgroundColor lightgray
Set-ExcelRange -Address $xl.TotalAdmins.Cells["G6"] -Formula "=$TotalAdmins - COUNTIF(TotalAdmins!D2:D$RowsTotalAdmin,NA())" -HorizontalAlignment Center -AutoSize -BackgroundColor lightgray
Set-ExcelRange -Address $xl.TotalAdmins.Cells["F7"] -Value "% of cracked Enterprise & Domain Admins passwords" -AutoSize -BackgroundColor lightblue
Set-ExcelRange -Address $xl.TotalAdmins.Cells["G7"] -Formula "=G6/G5" -HorizontalAlignment Center -NumberFormat '0%'  -AutoSize -BackgroundColor lightblue
Set-ExcelRange -Address $xl.TotalAdmins.Cells["F8"] -Value "% of Not yet cracked Enterprise & Domain Admins" -AutoSize -BackgroundColor orange
Set-ExcelRange -Address $xl.TotalAdmins.Cells["G8"] -Formula "=100%-G7" -HorizontalAlignment Center -NumberFormat '0%' -AutoSize -BackgroundColor orange

Close-ExcelPackage $xl

#create the pie chart
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel12
$excel               = New-Object -ComObject Excel.Application
$excel.Visible       = $True
$excel.DisplayAlerts = $False 
$workbook            = $excel.Workbooks.Open( $xlfile, [System.Type]::Missing, $false ) 
$worksheet = $workbook.WorkSheets.item(1)
[void]$worksheet.activate()
$Cracked = $worksheet.Range("G7").value2
$NotCracked = $worksheet.Range("G8").value2

$Cracked = (100 * $Cracked).ToString("#")
$NotCracked = (100 * $NotCracked).ToString("#")
$arr = @()
$object = [pscustomobject]@{ Type = 'Cracked' ; Percent = $Cracked }
$arr += $object
$object = [pscustomobject]@{ Type = 'NotCracked' ; Percent = $NotCracked }
$arr += $object

$objCharts = $worksheet.ChartObjects()
$xlChart=[Microsoft.Office.Interop.Excel.XLChartType]
$firstChart = $worksheet.Shapes.AddChart().Chart
$worksheet.shapes.item("Chart 1").top = 150
$worksheet.shapes.item("Chart 1").left = 350
$firstChart.HasTitle = $true
$firstChart.ChartType = $xlChart::xl3DPie
$firstChart.ChartTitle.Text = "Domain & Enterprise Admins"
$firstChart.SetSourceData($worksheet.range("F7:G8"))
$firstChart.ApplyDataLabels([Microsoft.Office.Interop.Excel.XlDataLabelsType]::xlDataLabelsShowLabelAndPercent,$TRUE,$TRUE,$FALSE,$FALSE)
$firstChart.ApplyLayout(2)
$firstChart.ChartStyle = 2
$firstChart.SeriesCollection(1).ApplyDataLabels() | out-Null
$firstChart.SeriesCollection(1).DataLabels().ShowValue = $True
$firstChart.SeriesCollection(1).DataLabels().Separator = ("{0}" -f [char]10)
$firstChart.SeriesCollection(1).DataLabels().Position = 2

$excel.ActiveWorkbook.SaveAs("$filesPath\Report.xlsb", $xlFixedFormat)

[void]$workbook.Close( $false ) 
[void]$excel.Quit() 
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

Start-Process "$filesPath\Report.xlsb"
