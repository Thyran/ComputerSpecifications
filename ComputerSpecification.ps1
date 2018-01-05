function log ($Log) {
    write-output $Log;
}

function formatStr {
    param ([String]$string);

    if ($string.contains('=')) {
        $string = $string.Substring($string.IndexOf('=') + 1, ($string.Length - $string.IndexOf('=') - 2));
    }

    return $string;
}

function formatAsSize {
    param ([string] $string);

    $string = ([string] ([math]::round((formatStr($string) -as [double]) / [math]::pow(1024, 3)))).Substring(0, 1) + " GB";

    return $string;
}

function formatDriveSize {
    param ([string] $string);

    $string = ([string] ([math]::Round((formatStr ($string) -as [double]) / [math]::Pow(1024, 3), 2)));

    return $string;
}

function computer {
    param($obj);

    $computer = Get-WmiObject Win32_Computersystem | select Name, Manufacturer, Model, SystemType, Domain;

    $systemType = formatStr ($computer | select SystemType);
    if ($systemType.contains("64")) {
        $systemType = "64-Bit";
    } elseif ($systemType.contains("86") -or $systemType.contains("32")) {
        $systemType = "32-Bit";
    } else {
        $systemType = "Nicht erkannt";
        log -Log "Systemtyp wurde nicht erkannt";
    }

    $obj | Add-Member "Computer Name" (formatStr ($computer | select Name));
    $obj | Add-Member "Hersteller" (formatStr ($computer | select Manufacturer));
    $obj | Add-Member "Model" (formatStr ($computer | select Model));
    $obj | Add-Member "System Typ" $systemType;
    $obj | Add-Member "Domäne" (formatStr ($computer | select Domain));

    return $obj;
}

function bios {
    param($obj);

    $bios = Get-WmiObject Win32_Bios | select Version, SMBIOSBIOSVersion, SerialNumber;

    $obj | Add-Member "Bios Verison" (formatStr($bios | select Version));
    $obj | Add-Member "Bios SMBiosVersion" (formatStr($bios | select SMBIOSBIOSVersion));
    $obj | Add-Member "Seriennummer" (formatStr($bios | select SerialNumber));

    return $obj;
}

function arbeitsspeicher {
    param($obj);

    for ($i = 0; $i -le (Get-WmiObject Win32_PhysicalMemory | select Capacity).length - 1; $i++) {
        $ram = (Get-WmiObject Win32_PhysicalMemory | select Tag, Capacity, Speed) | Select-Object -Index $i;

        $obj | Add-Member "Ram Tag $i" (formatStr ($ram | select Tag));
        $obj | Add-Member "RAM Kapazität $i" (formatAsSize ($ram | select Capacity));
        $obj | Add-Member "RAM Frequenz $i" ((formatStr($ram | select Speed)) + " Mhz");
    }

    return $obj;
}

function laufwerk {
    param($obj);

    $drive = Get-WmiObject Win32_DiskDrive | select DeviceID, Index, Caption, Size | where Index -EQ 0;

    $size = (formatDriveSize($drive | select Size)).Substring(0, 4);
    if ($size.EndsWith('.')) {
        $size = $size.substring(0, $size.length -1);
    }
    $size += " GB";

    $obj | Add-Member "Laufwerk ID"  (formatStr ($drive | select DeviceID)).substring(4);
    $obj | Add-Member "Laufwerk Index" (formatStr ($drive | select Index));
    $obj | Add-Member "Laufwerk Name" (formatStr ($drive | select Caption));
    $obj | Add-Member "Laufwerk Kapazität" $size;

    return $obj;
}

function processor {
    param($obj);

    $processor = Get-WmiObject Win32_Processor | select Name, MaxClockSpeed;

    $obj | Add-Member "Prozessor Name" (formatStr ($processor | select Name));
    $obj | Add-Member "Prozessor Frequenz" ((formatStr ($processor | select MaxClockSpeed)) + " Mhz");

    return $obj;
}

function videoController {
    param($obj);

    $videoController = Get-WmiObject Win32_VideoController | select Name, AdapterRAM;

    $obj | Add-Member "Grafikkarte Name" (formatStr (Get-WmiObject Win32_VideoController | select Name));
    $obj | Add-Member "Grafikkarte RAM Kapazität" (formatAsSize ($videoController | select AdapterRAM));

    return $obj;
}

function CollectInfos {
    param($pc, $path, $fileName, $fileType);

    log -Log "Beginne mit der Datenerfassung ...";
    $object = New-Object PSObject;
    
    log -Log "Erfasse Daten des Computers ...";
    $object = computer $object;
    log -Log "Erfassen der Daten des Computers abgeschlossen";

    log -Log "Erfasse Daten des Bios ...";
    $object = bios $object;
    log -Log "Erfassen der Daten des Bios abegschlossen";

    log -Log "Erfasse Daten der Laufwerke ...";
    $object = laufwerk $object;
    log -Log "Erfassen der Daten der Laufwerke abgeschlossen";

    log -Log "Erfasse Daten des RAM ...";
    $object = arbeitsspeicher $object;
    log -Log "Erfassen der Daten des RAM abgeschlossen";

    log -Log "Erfasse Daten des Prozessors ...";
    $object = processor -obj $object;
    log -Log "Erfassen der Daten des Prozessors abgeschlossen";

    log -Log "Erfasse Daten der Grafikkarte ...";
    $object = videoController $object;
    log -Log "Erfassen der Daten der Grafikkarte abgeschlossen";

    log -Log "Bereite Export der Daten vor ...";
    $date = Get-Date -Format yyyyMMddhhmm;
    $object | Export-Csv -path $path$fileName$($pc)_$date$fileType -Encoding UTF8 -NoTypeInformation;
    log -Log "Daten exportiert nach $path$fileName$($pc)_$date$fileType";
    log -Log "Datenerfassung abgeschlossen";
}

function main {
    param([string] $settingsFileName);

    if (!(Test-Path -Path $PSScriptRoot\$settingsFileName)) {
        log -Log "Pfad nicht gefunden zu Datei: $PSScriptRoot\$settingsFileName";
    } else {
        $file = Get-Content -Path $PSScriptRoot\$settingsFileName;
        $currentPC = [Environment]::MachineName;
        $path = $file | Select-Object -Index 0;
        $fileName = $file | Select-Object -Index 1;
        $fileType = $file | Select-Object -Index 2;

        log -Log "Current PC: $currentPC";
        CollectInfos -pc $currentPC -path $path -fileName $fileName -fileType $fileType;
    }
}

main -settingsFileName "Settings.txt";