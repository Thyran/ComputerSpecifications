function log ($Log) {
    write-output $Log
}

function formatStr {
    param ([String]$string)

    if ($string.contains('=')) {
        $string = $string.Substring($string.IndexOf('=') + 1, ($string.Length - $string.IndexOf('=') - 2))
    }

    return $string
}

function computer {
    param($obj)

    $obj | Add-Member "Computer Name" (formatStr (Get-WmiObject Win32_Computersystem | select Name))
    $obj | Add-Member "Hersteller" (formatStr (Get-WmiObject Win32_Computersystem | select Manufacturer))
    $obj | Add-Member "Model" (formatStr (Get-WmiObject Win32_Computersystem | select Model))
    $tmp = formatStr (Get-WmiObject Win32_Computersystem | select SystemType)
    if ($tmp.contains("64")) {
        $tmp = "64-Bit"
    } else {
        if ($tmp.contains("86")) {
            $tmp = "32-Bit"
        } else {
            if ($tmp.contains("32")) {
                $tmp = "32-Bit"
            }
        }
    }
    $obj | Add-Member "System Typ" $tmp
    $obj | Add-Member "Domaene" (formatStr (Get-WmiObject Win32_Computersystem | select Domain))

    return $obj
}

function bios {
    param($obj)

    $obj | Add-Member "Bios Verison" (formatStr(Get-WmiObject Win32_Bios | select Version))
    $obj | Add-Member "Bios SMBiosVersion" (formatStr(Get-WmiObject Win32_Bios | select SMBIOSBIOSVersion))
    $obj | Add-Member "Seriennummer" (formatStr(Get-WmiObject Win32_Bios | select SerialNumber))

    return $obj
}

function arbeitsspeicher {
    param($obj)

    for ($i = 0; $i -le (Get-WmiObject Win32_PhysicalMemory | select Capacity).length - 1; $i++) {
        $tmp = ([string] ([math]::round((formatStr(Get-WmiObject Win32_PhysicalMemory | select Capacity)) -as [double]) / [math]::pow(1024, 3))).Substring(0, 1) + " GB"
        $obj | Add-Member "RAM Kapazität $i" $tmp
        $obj | Add-Member "RAM Speed $i" (formatStr(Get-WmiObject Win32_PhysicalMemory | select Speed))
    }

    return $obj
}

function laufwerke {
    param($obj)

    for ($i=0; $i -le (Get-WmiObject Win32_DiskDrive | select DeviceID).length - 1; $i++) {
        $obj | Add-Member "Laufwerk ID $i"  (formatStr ((Get-WmiObject Win32_DiskDrive | select DeviceID) | select-object -Index $i)).substring(4)
        $tmp = ([string] ([math]::Round(((formatStr ((Get-WmiObject Win32_DiskDrive | select Size) | select-object -Index $i)) -as [double]) / [math]::Pow(1024, 3), 2))).Substring(0, 4)
        if ($tmp.EndsWith('.')) {
            $tmp = $tmp.substring(0, $tmp.length -1)
        }
        $tmp += " GB"
        $obj | Add-Member "Laufwerk Kapazität $i" $tmp
    }

    return $obj
}

function processor {
    param($obj, $numProcessors)

    for ($i = 0; $i -le ($numProcessors - 1); $i++) {
        $obj | Add-Member "Prozessor Name $i" (formatStr (Get-WmiObject Win32_Processor | select Name))
        $tmp = (formatStr (Get-WmiObject Win32_Processor | select MaxClockSpeed)) + " Mhz"
        $obj | Add-Member "Prozessor Speed $i" $tmp
    }

    return $obj
}

function videoController {
    param($obj)

    $obj | Add-Member "Grafikkarte Name" (formatStr (Get-WmiObject Win32_VideoController | select Name))
    $tmp = ([string] ([math]::Round((formatStr (Get-WmiObject Win32_VideoController | select AdapterRAM) -as [double]) / ([Math]::pow(1024, 3))))).substring(0, 1) + " GB"
    $obj | Add-Member "Grafikkarte RAM Kapazität" $tmp

    return $obj
}

function CollectInfos {
    param($pc)

    $object = New-Object PSObject
    
    $object = computer $object
    $object = bios $object
    $object = laufwerke $object
    $object = arbeitsspeicher $object
    $object = processor -obj $object -numProcessors ([int] (formatStr(Get-WmiObject Win32_Computersystem | select NumberOfProcessors)))
    $object = videoController $object

    $date = Get-Date -Format yyyyMMddhhmm
    $object | Export-Csv -path C:\temp\inv_$($pc)_$date.csv -Encoding UTF8 -NoTypeInformation
}

function main {
    $currentPC = [Environment]::MachineName
    log -Log "Current PC: $currentPC"
    log -Log "Computer gefunden: $currentPC"
    CollectInfos -pc $currentPC
}

main