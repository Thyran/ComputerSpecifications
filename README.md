# ComputerSpecifications

A simple script to retrieve some  hardware information
-
"Settings.txt" saves Settings for the local device
-  @line 0: Path to save the output file
-  @line 1: Prefix of the file (Ex. "inv_[deviceName](_)[date].csv")
-  @line 2: Ending of the file (here: ".csv")
 
"domainSetting.txt" saves Settings that influence the DomainScript
-  @line 0: remote Path on the remote device to save the local script
-  @line 1: actual Path to run the script via the command (Invoke-Command)
-  @line 2: collection Folder to copy the local files from the remote command to the executing device
 
"Peripherals.txt" saves a list of the remote devices to run the domain script on
