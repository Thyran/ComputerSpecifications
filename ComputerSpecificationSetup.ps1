function setupDomain {
    param(
        [parameter (Mandatory = $true, HelpMessage = 'Speicherort')] [string] $destination,
        [parameter (Mandatory = $true, HelpMessage = 'Bezeichnung')] [string] $remoteDir,
        [parameter (Mandatory = $true, HelpMessage = 'Dateiendung')] [string] $collectionDir,
        [parameter (Mandatory = $false)] [string] $filename
    );

    $file = "$PSScriptRoot\$fileName";
    if (!(Test-Path $file)) {
        New-Item $file -type file;
    } else {
        Clear-Content $file -Force;
    }

    Add-Content $file -Value $destination;
    Add-Content $file -Value $remoteDir;
    Add-Content $file -Value $collectionDir;
}

function setupLocal {
    param(
        [parameter (Mandatory = $true, HelpMessage = 'Speicherort')] [string] $saveDir,
        [parameter (Mandatory = $true, HelpMessage = 'Bezeichnung')] [string] $description,
        [parameter (Mandatory = $true, HelpMessage = 'Dateiendung')] [string] $fileType,
        [parameter (Mandatory = $false)] [string] $fileName
    );

    $file = "$PSScriptRoot\$fileName"
    if (!(Test-Path $file)) {
        New-Item $file -type file;
    } else {
        Clear-Content $file -Force;
    }

    Add-Content $file -Value $saveDir;
    Add-Content $file -Value $description;
    Add-Content $file -Value $fileType;
}

function main {
    param([parameter (Mandatory = $true, HelpMessage = 'Mode? [domain|local|exit]')] [string] $mode);

    if ($mode -eq "domain") {
        setupDomain -filename "domainSettings.txt";
    } elseif ($mode -eq "local") {
        setupLocal -fileName "Settings.txt";
    } elseif ($mode -eq "exit") {
        exit;
    } else {
        main;
    }
}

main;