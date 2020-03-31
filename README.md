# DCS Unlock Liveries for Multiplayer script
## PowerShell script for modifying description.luas in dcs's livery folders

Please advise possible problems further down! 
Use at your own risk! 

### Compiled Executable:

**Either** Download Win-PS2EXE (https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5)
and Compile the Script yourself. (You might have to add a Version number, otherwise windows defender/anti virus thinks it's malware)

**Or** download the executable `UnlockLiveries.exe`

Execute the File and follow the workflow


### Powershell Script:

1. Download .zip and unzip in any directory (e.g. D:\Downloads)
2. Open PowerShell by right clicking your Home Button and select "Windows PowerShell" 
3. Execute Script and follow the workflow


## Possible Problems: 

- if you can't run scripts: open PowerShell as Administrator and run `set-executionpolicy remotesigned` 
- Copying files will override already existing files (with the same name) without prompt, make sure your save folder is correct
- some description.luas are already modified by default, those won't be copied/modified
    * also those which don't have countries defined
- >Windows or *\***insert Anti-Virus Software here***\* detects your Program as a Virus!
   * Add an exception or compile it yourself if you don't trust me. You can also just use the script version.
