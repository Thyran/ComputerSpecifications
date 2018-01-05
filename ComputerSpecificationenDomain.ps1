function log ($Log) {
    write-output $Log
}

function main {
    Enable-PSRemoting -Force

    $computerName = Get-Content -Path C:\Benedikt\PowershellScripts\Peripherals.txt
    $currentPC = [Environment]::MachineName
    log -Log "Current PC: $currentPC"
    foreach ($pc in $computerName) {
        if (!(Test-Connection -computername $pc -Quiet)) {
            log -Log "Computer nicht gefunden: $pc"
        } else {
            log -Log "Computer gefunden: $pc"
            if (!(Test-path \\$pc\c$\\temp\ComputerSpecificationen.ps1)) {
                Copy-Item -Path C:\Benedikt\PowershellScripts\ComputerSpecificationen.ps1 -Destination \\$pc\c$\\temp\ -Force
            }
            Invoke-Command -computerName $pc -FilePath C:\temp\ComputerSpecificationen.ps1
            sleep 1
        }
    }
}

main