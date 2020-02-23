# DCS Unlock Liveries for Multiplayer script
## PowerShell script for modifying description.luas in dcs's livery folders

Please advise possible problems further down! 
Use at your own risk. 

1. Download .zip and unzip in any directory (e.g. D:\Downloads)
2. Open PowerShell by right clicking your Home Button and select "Windows PowerShell" 
3. If you want to modify the files inside your DCS directory run `D:\Downloads\dcs_mp_unlock_liveries\dmul.ps1 'C:\DCS World OpenBeta'`
4. If you want copy the .luas into a separate folder add the save directory `D:\Downloads\dcs_mp_unlock_liveries\dmul.ps1 'C:\DCS World OpenBeta' 'D:\DCS_Liveries'`
    * this will retain the DCS folder Structure e.g. `D:\DCSLiveries\CoreMods\aircraft\F14\Liveries\f-14b\Santa\description.lua`

  
## Possible Problems: 

- if you can't run scripts: open PowerShell as Administrator and run `set-executionpolicy remotesigned` 
- Copying files will override already existing files (with the same name) without prompt, make sure your folder is correct
- some description.luas are already modified by default, those won't be copied/modified
- ~~ Only works of you have ONE DCS install where you run the script, also it needs to contain "DCS World" ~~
- ~~ script also overrides default skins in MODs folder (nothing concerning but unnecessary) ~~

## ToDo 

- [x] Make it run with parameters for dcs path and save path 
- [ ] Handle Exception when no valid path is given
