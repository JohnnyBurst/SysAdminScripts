#-------------------------------------------------------------------------------
# Script to search for files on Shadow Copies
# Citra IT Corp - IT Consulting Services
#-------------------------------------------------------------------------------

# File with the path's of the missing files, one per line.
$missing_files = Get-Content -path $env:userprofile\documents\missing_files.txt

# base path that should be concatenated with the entries in missing_files
$base_path = "C:\shadowcopy\GED\vault$"


Get-WmiObject Win32_ShadowCopy | Where-Object {$_.VolumeName -eq '\\?\Volume{434beb1c-dbbc-11e8-b81d-001018b383c2}\'} | 
Sort-Object -Property installdate -desc | ForEach-Object {
    write-host "Searching on date $($_.InstallDate.substring(0,12))"
    
    # Mounting shadow copy volume
    cmd /c mklink /d C:\shadowcopy ($_.DeviceObject + "\") | out-null

    $missing_files | %{ 
         $filepath = join-path -path $base_path -ChildPath $_
         if(Test-Path $filepath) { write-host -foreground Green "[+] Found $filepath" } 
    }

    # Unmount the shadow copy
    cmd /c rmdir C:\shadowcopy
    start-sleep 1

}



