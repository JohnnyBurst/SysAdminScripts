<#
.SINOPSYS
	List services configured with custom user accounts (other than)
	system, localservice, networkservice...
#>


Add-Type -AssemblyName System.Windows.Forms

$form = new-object system.windows.forms.form
$form.AutoSize = $true
$form.width = 400
$form.Text = "List Services with Custom Accounts"

$grid = new-object system.windows.forms.datagridview
$tabledata = new-object system.data.datatable
$grid.AutoSize = $true
$grid.ReadOnly = $true
$grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells


$tabledata.Columns.Add("Name") | out-null
$tabledata.Columns.Add("State") | out-null
$tabledata.Columns.Add("Account") | out-null
$tabledata.Columns.Add("StartMode") | out-null


$startname_blacklist = @("localSystem","NT AUTHORITY\LocalService","NT AUTHORITY\NetworkService")

$services = Get-WMIObject Win32_Service | 
	Where-Object {$_.StartName -notin $startname_blacklist}
	
If($services.count -eq 0)
{
	[System.Windows.Forms.MessageBox]::SHow("No services with custom accounts found!")
	exit
}
$services | 
	ForEach-Object { $tabledata.Rows.Add([object] @($_.DisplayName, $_.State, $_.StartName, $_.StartMode))  | out-null}


$grid.datasource = $tabledata
$form.Controls.Add($grid)
$form.showdialog()


	
