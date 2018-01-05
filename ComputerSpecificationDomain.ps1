function log ($Log) {
    write-output $Log;
}

function main {
    param($settingsFilePath, $peripheralPath, $scriptPath);

    Enable-PSRemoting -Force;

    if (!(Test-Path -Path $PSScriptRoot\$settingsFilePath)) {
        log -Log "Pfad nicht gefunden: $PSScriptRoot\$settingsFilePath";
    } else {
        $file = Get-Content -Path $PSScriptRoot\$settingsFilePath;
        $destinationFolder = $file | Select-Object -Index 0;
        $remoteScriptPath = $file | Select-Object -Index 1;
        $collectionFolder = $file | Select-Object -Index 2;

        if (!(Test-Path -Path $PSScriptRoot\$peripheralPath)) {
            log -Log "Pfad nicht gefunden: $PSScriptRoot\$peripheralPath";
        } else {
            $computerName = Get-Content -Path $PSScriptRoot\$peripheralPath;
            $currentPC = [Environment]::MachineName;
            log -Log "Current PC: $currentPC";
            foreach ($pc in $computerName) {
                if (!(Test-Connection -computername $pc -Quiet)) {
                    log -Log "Computer nicht gefunden: $pc";
                } else {
                    log -Log "Computer gefunden: $pc";
                    if (!(Test-path \\$pc\$destinationFolder$scriptPath)) {
                        Copy-Item -Path $PSScriptRoot\$scriptPath -Destination \\$pc\$destinationFolder -Force;
                    }
                    Invoke-Command -computerName $pc -FilePath $remoteScriptPath$scriptPath;
                    sleep 5;
                    Copy-Item -Path \\$pc\$($destinationFolder)*.csv -Destination $collectionFolder;
                }
            }
        }
    }
}

main -settingsFilePath "domainSettings.txt" -peripheralPath "Peripherals.txt" -scriptPath "ComputerSpecification.ps1";