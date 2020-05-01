<#
.SYNOPSYS
    This script get the list of virtual machines and it's 
    hard disks (path, actual size, maximum size).

#>

Param(
    [Parameter(Mandatory=$false)] $server = ""
)

Add-Type -AssemblyName System.Windows.Forms

$form = new-object system.windows.forms.form
$form.AutoSize = $true
$form.width = 400

$grid = new-object system.windows.forms.datagridview
$tabledata = new-object system.data.datatable
$grid.AutoSize = $true
$grid.ReadOnly = $true
$grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells


$tabledata.Columns.Add("VM") | out-null
$tabledata.Columns.Add("Path") | out-null
$tabledata.Columns.Add("MaxSize (GB)") | out-null
$tabledata.Columns.Add("Actual Size (GB)") | out-null


$get_info = { Get-VM | 
	Get-VMHardDiskDrive | 
	Select VMName,Path,@{Name="Size";Expression={Get-VHD $_.Path|Select -expandproperty Size|%{$_ / 1GB}}},@{Name="FileSize";Expression={Get-VHD $_.Path|Select -ExpandProperty FileSize|%{[math]::round($_ / 1GB)}}} }


# Executing local
If([string]::IsNullOrEmpty($server))
{
    Invoke-Command -ScriptBlock $get_info | 
        Select-Object vmname,path,filesize,size  |  
            %{ $tabledata.Rows.Add([object] @($_.vmname, $_.path, $_.size, $_.filesize))  | out-null}
}Else{
    Invoke-Command -Computername $server -ScriptBlock $get_info |
        select vmname,path,filesize,size |  
            %{ $tabledata.Rows.Add([object] @($_.vmname, $_.path, $_.size, $_.filesize))  | out-null}
}




$grid.datasource = $tabledata

$form.Controls.Add($grid)


$form.showdialog()

