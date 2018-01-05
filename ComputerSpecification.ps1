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

function computer {
    param($obj);

    $systemType = formatStr (Get-WmiObject Win32_Computersystem | select SystemType);
    if ($systemType.contains("64")) {
        $systemType = "64-Bit";
    } elseif ($systemType.contains("86") -or $systemType.contains("32")) {
        $systemType = "32-Bit";
    } else {
        $systemType = "Nicht erkannt";
        log -Log "Systemtyp wurde nicht erkannt";
    }

    $obj | Add-Member "Computer Name" (formatStr (Get-WmiObject Win32_Computersystem | select Name));
    $obj | Add-Member "Hersteller" (formatStr (Get-WmiObject Win32_Computersystem | select Manufacturer));
    $obj | Add-Member "Model" (formatStr (Get-WmiObject Win32_Computersystem | select Model));
    $obj | Add-Member "System Typ" $systemType;
    $obj | Add-Member "Domaene" (formatStr (Get-WmiObject Win32_Computersystem | select Domain));

    return $obj;
}

function bios {
    param($obj);

    $obj | Add-Member "Bios Verison" (formatStr(Get-WmiObject Win32_Bios | select Version));
    $obj | Add-Member "Bios SMBiosVersion" (formatStr(Get-WmiObject Win32_Bios | select SMBIOSBIOSVersion));
    $obj | Add-Member "Seriennummer" (formatStr(Get-WmiObject Win32_Bios | select SerialNumber));

    return $obj;
}

function arbeitsspeicher {
    param($obj);

    for ($i = 0; $i -le (Get-WmiObject Win32_PhysicalMemory | select Capacity).length - 1; $i++) {
        $obj | Add-Member "RAM Kapazität $i" (([string] ([math]::round((formatStr((Get-WmiObject Win32_PhysicalMemory | select Capacity) | select-object -Index $i)) -as [double]) / [math]::pow(1024, 3))).Substring(0, 1) + " GB");
        $obj | Add-Member "RAM Speed $i" ((formatStr((Get-WmiObject Win32_PhysicalMemory | select Speed) | Select-Object -index $i)) + " Mhz");
    }

    return $obj;
}

function laufwerke {
    param($obj);

    for ($i=0; $i -le (Get-WmiObject Win32_DiskDrive | select DeviceID).length - 1; $i++) {
        if (([int] (formatStr((Get-WmiObject Win32_DiskDrive | select Index) | Select-Object -Index $i))) -eq ([int] 0)) {
            $size = ([string] ([math]::Round((formatStr ((Get-WmiObject Win32_DiskDrive | select Size) | select-object -Index $i) -as [double]) / [math]::Pow(1024, 3), 2))).Substring(0, 4);
            if ($size.EndsWith('.')) {
                $size = $size.substring(0, $size.length -1);
            }
            $size += " GB";

            $obj | Add-Member "Laufwerk ID"  (formatStr ((Get-WmiObject Win32_DiskDrive | select DeviceID) | select-object -Index $i)).substring(4);
            $obj | Add-Member "Laufwerk Index" (formatStr ((Get-WmiObject Win32_DiskDrive | select Index) | Select-Object -Index $i));
            $obj | Add-Member "Laufwerk Name" (formatStr ((Get-WmiObject Win32_DiskDrive | select Caption) | Select-Object -Index $i));
            $obj | Add-Member "Laufwerk Kapazität" $size;
        }
    }

    return $obj;
}

function processor {
    param($obj);

    $obj | Add-Member "Prozessor Name" (formatStr (Get-WmiObject Win32_Processor | select Name));
    $obj | Add-Member "Prozessor Speed" (formatStr (Get-WmiObject Win32_Processor | select MaxClockSpeed) + " Mhz");

    return $obj
}

function videoController {
    param($obj);

    $obj | Add-Member "Grafikkarte Name" (formatStr (Get-WmiObject Win32_VideoController | select Name));
    $obj | Add-Member "Grafikkarte RAM Kapazität" (([string] ([math]::Round((formatStr (Get-WmiObject Win32_VideoController | select AdapterRAM) -as [double]) / ([Math]::pow(1024, 3))))).substring(0, 1) + " GB");

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
    $object = laufwerke $object;
    log -Log "Erfassen der Daten der Laufwerke abgeschlossen";

    log -Log "Erfasse Daten des RAM ...";
    $object = arbeitsspeicher $object;
    log -Log "Erfassen der Daten des RAM abgeschlossen";

    log -Log "Erfasse Daten des Prozessors ...";
    $object = processor -obj $object -numProcessors ([int] (formatStr(Get-WmiObject Win32_Computersystem | select NumberOfProcessors)));
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