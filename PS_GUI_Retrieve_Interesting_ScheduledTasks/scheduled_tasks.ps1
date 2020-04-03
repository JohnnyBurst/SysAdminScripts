<#
.SINOPSYS
	This script list the 'not built in' windows scheduled tasks.
	
#>


$TASK_TRIGGER_EVENT = 				0
$TASK_TRIGGER_TIME = 				1
$TASK_TRIGGER_DAILY = 				2
$TASK_TRIGGER_WEEKLY =				3
$TASK_TRIGGER_MONTHLY = 			4
$TASK_TRIGGER_MONTHLYDOW = 			5
$TASK_TRIGGER_IDLE =				6
$TASK_TRIGGER_REGISTRATION = 		7
$TASK_TRIGGER_BOOT = 				8
$TASK_TRIGGER_LOGON = 				9
$TASK_TRIGGER_SESSION_STATE_CHANGE = 11

$selected_tasks_type = @($TASK_TRIGGER_DAILY,$TASK_TRIGGER_WEEKLY,$TASK_TRIGGER_MONTHLY)

# Weekdays used to retrieve task scheduling
$SUNDAY = 1
$MONDAY = 2
$TUESDAY = 4
$WEDNESDAY = 8
$THURSDAY = 16
$FRIDAY = 32
$SATURDAY = 64

# taskschd folders to exclude from results because they contain default tasks
$folders_blacklist = @("\Microsoft","\WPD","\OfficeSoftwareProtectionPlatform")





# Function:  Get-ScheduledTaskTrigger
# @Argument: Task (comobject)
# @Out: 	 [string] describing the schedule
#
#
Function Get-ScheduledTaskTrigger
{
    Param( $task )
	
	Switch ($task.Definition.Triggers[1].Type)
	{
		0 {
			# At specific event
			break;
		}
		1 {
			# At specific time
			#$taskdays = $task.Definition.Triggers[1].DaysOfWeek;
			#$run_hour = (Get-Date $task.Definition.triggers[1].StartBoundary).Hour;
			break;
		}
		2 {
			# Daily
			$run_hour = (Get-Date $task.Definition.triggers[1].StartBoundary).Hour;
			Return "daily at $run_hour";
			break;
		}
		3 {
			# Weekly
			$days = @()
			$taskdays = $task.Definition.Triggers[1].DaysOfWeek
			$run_hour = (Get-Date $task.Definition.triggers[1].StartBoundary).Hour
			
			# evaluating the days that the task runs
			if(($taskdays -band $SUNDAY)    -eq $SUNDAY)   { $days += "SUN" }
			if(($taskdays -band $MONDAY)    -eq $MONDAY)   { $days += "MON" }
			if(($taskdays -band $TUESDAY)   -eq $TUESDAY)  { $days += "TUE" }
			if(($taskdays -band $WEDNESDAY) -eq $WEDNESDAY){ $days += "WED" }
			if(($taskdays -band $THURSDAY)  -eq $THURSDAY) { $days += "THU" }
			if(($taskdays -band $FRIDAY)    -eq $FRIDAY)   { $days += "FRI" }
			if(($taskdays -band $SATURDAY)  -eq $SATURDAY) { $days += "SAT" }
			Return [string]::join("," , $days) + " at " + [string]$run_hour
			
		}
		4 {
			# Montly
			break;
		}
		5 {
			# At every month at specifid DOW 
			break;
		}
		6 {
			# When idle
			break;
		}
		7 {
			# run when task is registered
			break;
		}
		8 {
			# At boot
			break;
		}
		9 {
			# At logon
			break;
		}
		11 {
			# At session change
			break;
		}
		
	} # end switch
} # end of function



#
# MAIN ROUTINE STARTS HERE
#


Add-Type -AssemblyName System.Windows.Forms

$form = new-object system.windows.forms.form
$form.AutoSize = $true
$form.width = 400
$form.Text = "List interesting scheduled tasks"

$grid = new-object system.windows.forms.datagridview
$tabledata = new-object system.data.datatable
$grid.AutoSize = $true
$grid.ReadOnly = $true
$grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells


$tabledata.Columns.Add("Name") | out-null
$tabledata.Columns.Add("Enabled") | out-null
$tabledata.Columns.Add("Run") | out-null
$tabledata.Columns.Add("Args") | out-null
$tabledata.Columns.Add("Runas") | out-null
$tabledata.Columns.Add("Schedule") | out-null


$mytasks = @()
$ts = New-Object -ComObject Schedule.Service

# @args: server, user, domain, password
$ts.connect()

$root = $ts.GetFolder("\")

$root.GetTasks(0) | Where-Object{$_.Definition.Triggers[1].Type -in ($TASK_TRIGGER_DAILY,$TASK_TRIGGER_WEEKLY,$TASK_TRIGGER_MONTHLY)} | 
	ForEach-Object{
		$mytasks += $_
}

$folders = $root.GetFolders(0) | Where-Object{ $_.Path -notin $folders_blacklist }
$folders | ForEach-Object{
	$_.GetTasks(0) | Where-Object{ $_.Definition.Triggers[1].Type -in $selected_tasks_type } | ForEach-Object{
		$mytasks += $_
	}
	
}

if($mytasks.Count -eq 0)
{
	[System.Windows.Forms.MessageBox]::Show("No interesting scheduled tasks found !")
}


$mytasks | Select Name, `
		   Enabled, `
		   @{Name="Run";Expression={Split-Path -Leaf $_.Definition.Actions[1].Path}}, `
		   @{Name="Args";Expression={$_.Definition.Actions[1].Arguments}}, `
		   @{Name="Runas";Expression={$_.Definition.Principal.UserID}}, `
			@{Name="Schedule";Expression={Get-ScheduledTaskTrigger $_}} |
	ForEach-Object { $tabledata.Rows.Add([object] @($_.Name, $_.Enabled, $_.Run, $_.Args, $_.Runas, $_.Schedule))  | out-null}


$grid.datasource = $tabledata

$form.Controls.Add($grid)


$form.showdialog()

