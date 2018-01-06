function main {
    param ([string] $settingsFile);

    $mergeDir = Get-Content -Path $PSScriptRoot\$settingsFile | Select-Object -index 0;
    $fileType = Get-Content -Path $PSScriptRoot\$settingsFile | Select-Object -index 2;

    $out = @();
    $files = Get-ChildItem $mergeDir;
    foreach ($table in $files) {
        if (!($table.Name.contains('all.csv'))) {
            Write-Output $table.FullName
            if ($table.Name.substring($table.Name.length - 4, 4) -eq $fileType) {
                $temp = Import-Csv -Path $table.FullName
                $out += $temp;
            }
        }
    }

    $out | Export-Csv -Path $mergeDir\all.csv -Encoding UTF8 -NoTypeInformation;
}

main -settingsFile "Settings.txt";