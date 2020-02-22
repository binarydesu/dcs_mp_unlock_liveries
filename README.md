# DCS Unlock Liveries in Multiplayer 

## PowerShell script for modifying description.luas in dcs's livery folders
Please Advise the possible problems further down! 
Use at your own risk. 

1. Open PowerShell by right clicking your Home Button and "Windows Powershell" 
2. Navigate to the folder containing your DCS Install (use "cd" command) 
3. Run the Script (e.g. D:\Downloads\dcs_mp_unlock_liveries\dmul.ps1) 
4. Choose your option 
5. Profit 
  
# Possible Problems: 

- if you can't run scripts: open PowerShell as Administrator and run `set-executionpolicy remotesigned` 
- Only works of you have ONE DCS install where you run the script, also it needs to contain "DCS World" 
- Copying files will override already existing files without prompt, make sure .\DCS_Unlocked_Liveries\ does not exist in your folder 
- script also overrides default skins in MODs folder (nothing concerning but unnecessary) 
- Runnning t two times will break the description.lua and disable the skin

# ToDo 

- [ ] Make it run with parameters for dcs path and save path 
