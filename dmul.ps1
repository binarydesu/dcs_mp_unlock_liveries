#include Windows Forms
Add-Type -AssemblyName System.Windows.Forms

#Some Settings for the windows
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Windows.Forms.Application]::EnableVisualStyles()

#Browser Window configuration
$FolderBrowserDCSPath = New-Object System.Windows.Forms.FolderBrowserDialog 
$FolderBrowserDCSPath.RootFolder = [System.Environment+SpecialFolder]'MyComputer'
$FolderBrowserDCSPath.ShowNewFolderButton = $false
$FolderBrowserDCSPath.Description = "Select DCS Main Directory"

$FolderBrowserCopyPath = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowserCopyPath.RootFolder = [System.Environment+SpecialFolder]'MyComputer'
$FolderBrowserCopyPath.ShowNewFolderButton = $true
$FolderBrowserCopyPath.Description = "Select Directory for Exported files"

#new form so everything comes into foreground
$Topmost = New-Object System.Windows.Forms.Form
$Topmost.TopMost = $True
$Topmost.MinimizeBox = $True

#calling first window
if ($FolderBrowserDCSPath.ShowDialog($Topmost) -eq "Cancel") {
	exit
}

#save path in separate variable
$dcspath = $FolderBrowserDCSPath.SelectedPath

#Check if directory has Bazar and CoreMods
if (Test-Path -Path  $dcspath) {

	#Get complete path in case of a relative path
	$dcspath = Resolve-Path -LiteralPath $dcspath
	#Get directory content
	$directory = Get-Childitem -LiteralPath $dcspath
	#Escaped path to Bazar
	$bazaresc = [regex]::escape(($(Join-Path -Path $dcspath -ChildPath 'Bazar')))
	#Escaped path to CoreMods
	$coremodesc = [regex]::escape(($(Join-Path -Path $dcspath -ChildPath 'CoreMods')))

	if (!(($directory.FullName -match $bazaresc) -and ($directory.FullName -match $coremodesc))) {
		Write-Output "'$dcspath' DCS not found in this directory, exiting"
		exit
	}
}
else {
	Write-Output "'$dcspath' Invalid directory, exiting"
	exit
}

#Ask user for export
$ifexport = [System.Windows.Forms.Messagebox]::Show($Topmost, "Do you want to export the files and then modify?`nThis won't change the files in your DCS directory.`nThe files can than be put inside your '...\saved games\dcs\liveries' folder", "Export descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )

if ($ifexport -eq "Yes") {
	if ($FolderBrowserCopyPath.ShowDialog($Topmost) -eq "Cancel") {
		exit
	}
}

#Save Path
$copypath = $FolderBrowserCopyPath.SelectedPath

#Validate CopyPath
if ($ifexport -eq "Yes") {
	if (!(Test-Path -Path $copypath)) {
		Write-Output "'$copypath' Directory is not valid. Exiting Script"
		exit
	}
}

#make sure variable is empty
#Remove-Variable -name moduledescrpaths 
$moduledescrpaths = @()

#counter for already modified/not modified files
$modifiedcount = 0
$unmodifiedcount = 0
$nomatchcount = 0

#Regular expression to find countries = {"xx", "yyy", "zzzzz"}
$regex = '(?ms)^(\bcountries\b.*?[\=].*?[\{].*?){1}(.*?[\"][A-Z]*?[\"][\,]*.*?)+?(.*?[\}])+?'

#Regex to check if file is already modified
$regcheck = '(?ms)^([\-]{2})([\[]{2}|[\[]{0})+([\s]*?)(\bcountries\b.*?[\=].*?)+'

#regular expression to insert groups but as commentary
$regin = "--[[ `$1 `n `t `$2 `n `$3 ]]"

#Regex containing all modules
$modules = @(
	'.*A-10A.*',
	'.*A-10C.*',
	'.*AJS37.*',
	'.*AV8BNA.*',
	'.*BF-109K-4.*',
	'.*C-101CC.*',
	'.*C-101EB.*',
	'.*Christen Eagle II.*',
	'.*F-15C.*',
	'.*F-16C_50.*',
	'.*F-5E-3.*',
	'.*F-5E.*',
	'.*f-86f sabre.*',
	'.*f14b.*',
	'.*FA-18C_hornet.*',
	'.*FA-18C.*',
	'.*FW-190A8.*',
	'.*FW-190D9.*',
	'.*Hawk.*',
	'.*I-16.*',
	'.*J-11A.*',
	'.*JF-17.*',
	'.*ka-50.*',
	'.*L-39C.*',
	'.*L-39ZA.*',
	'.*M-2000C.*',
	'.*Mi-8mt.*',
	'.*MiG-15bis.*',
	'.*MiG-19P.*',
	'.*MiG-21Bis.*',
	'.*mig-29a.*',
	'.*mig-29g.*',
	'.*mig-29s.*',
	'.*P-51D.*',
	'.*SA342.*',
	'.*SpitfireLFMkIX.*',
	'.*su-25.*',
	'.*su-25t.*',
	'.*su-27.*',
	'.*su-33.*',
	'.*uh-1h.*',
	'.*YAK-52.*'
)


#get description.lua from Bazar and CoreMods and only those from modules
$alldescrpaths = Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'Bazar') -Recurse -Filter "description.lua" 
$alldescrpaths += Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'CoreMods') -Recurse -Filter "description.lua" 
for ($i = 0 ; $i -lt $modules.count; $i++) {
	$moduledescrpaths += $alldescrpaths | Where-Object { (($_.Fullname).Split("\") | Select-Object -Last 3) -match $modules[$i] } | ForEach-Object { $_.FullName } 
}

#count entries
$count = $moduledescrpaths.Length

#check if there is a copy path
if ($ifexport -eq "Yes") {
	#ask user to continue
	if ($([System.Windows.Forms.Messagebox]::Show($Topmost, "Copy and Modify $count files in '$dcspath' to '$copypath' ?", "Copy descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )) -notmatch 'Yes') { exit }
}
else {
	#No copy path given, Ask user to continue
	if ($([System.Windows.Forms.Messagebox]::Show($Topmost, "Modify $count files in $dcspath ?", "Modify descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )) -notmatch 'Yes') { exit }
}

for ($i = 0; $i -lt $count; $i++) {	
	#Show Progress Bar
	if ($ifexport -eq "Yes") {
		Write-Progress -Activity "Copying and Modifying files" -status "Modifing file $i" -CurrentOperation $moduledescrpaths[$i] -percentComplete ($i / $count * 100) 
	}
	else {
		Write-Progress -Activity "Modifing files in $dcspath" -status $i -CurrentOperation $moduledescrpaths[$i] -percentComplete ($i / $count * 100)
	}

	<# 
	#little check so the created folders can be put inside dcs main directory for overwrite
	if ($moduledescrpaths[$i] -match $bazaresc) {
		$subfolderscount = 5
	}
	elseif ($moduledescrpaths[$i] -match $coremodesc) {
		$subfolderscount = 7
	}
	else {
		Write-Output "Something went wrong! Exiting"
		exit
	}

	#ugly string replacement/construction to $CopyPath
	$tmppath = Join-Path -Path $copypath -ChildPath $((($moduledescrpaths[$i]).Line.Split("\") | Select-Object -Last $subfolderscount) -join "\")
	#>
		
	#check if already modified then write/fill luas
	if ((Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -match $regcheck) {
		$unmodifiedcount++
	}
	elseif ((Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -match $regex) {

		if ($ifexport -eq "Yes") {
			#Instead build the folder in a way so it can be put inside "saved games\dcs" folder
			$tmppath = Join-Path -Path $copypath -ChildPath $((($moduledescrpaths[$i]).Split("\") | Select-Object -Last 4) -join "\")
			#create new folder structure
			New-Item -ItemType File -Path $tmppath -Force | Out-Null

			(Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $tmppath
			$modifiedcount++
		}
		else {
			#Modify .lua files in DCS directory
			(Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $moduledescrpaths[$i]
			$modifiedcount++
		}
	}
	else {
		$nomatchcount++
	}
}	

$modi = "Successfully changed $modifiedcount files"
$unmod = "Seems like $unmodifiedcount files were already modified, didn't touch those"
$nomatch = "Seems like $nomatchcount files had no country definition, didn't touch those"

Write-Output "$modi`n$unmod`n$nomatch"