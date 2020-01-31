

#[system.reflection.assembly]::loadwithpartialname("system.windows.forms") | Out-Null
Add-Type -AssemblyName "System.Windows.Forms"

$form1 = New-Object Windows.Forms.Form

$datagrid = New-Object Windows.Forms.DataGridView

$col1 = [System.Windows.Forms.DataGridViewTextBoxColumn]
#$col1.Text = "Luciano"

$columns = new-object System.Windows.Forms.DataGridViewColumn $col1
$datagrid.Columns.Add( $columns )

$form1.Controls.Add($datagrid)


$form1.ShowDialog()