# --------------------------------------------------------------------------
# Script para Windows Update
# --------------------------------------------------------------------------

<# Notification Level
'1 = Disables AU (Same as disabling it through the standard controls)
'2 = Notify Download and Install (Requires Administrator Privileges)
'3 = Notify Install (Requires Administrator Privileges)
'4 = Automatically, no notification (Uses ScheduledInstallTime and ScheduledInstallDay)
#>

$updt = New-Object -ComObject Windows.Update.AutoUpdate
$update_settings = $updt.Settings



