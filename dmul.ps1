#include Windows Forms and zip
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Assembly 'System.IO.Compression.FileSystem'

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
if ([System.Windows.Forms.Messagebox]::Show($Topmost, "Please select a directory, to which you want the files to be copied.`nThis won't change the files in your DCS directory.`nThe files can then be put inside your '...\saved games\dcs\liveries' folder", "Export descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::OKCancel ) -eq "Cancel") {
	exit
}


if ($FolderBrowserCopyPath.ShowDialog($Topmost) -eq "Cancel") {
		exit
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
$alldescrpaths = @()
$moduledescrpaths = @()
$zipmoduledescrpaths = @()
$zipmoduledescrpathsbasename = @()
$ziptemp = @()

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
	'A-10A',
	'A-10C',
	'A-10CII',
	'AH-64D_BLK_II',
	'AJS37',
	'AV8BNA',
	'BF-109K-4',
	'C-101CC',
	'C-101EB',
	'Christen Eagle II',
	'F-15C',
	'F-16C_50',
	'F-5E-3',
	'F-5E',
	'f-86f sabre',
	'F-14A-135-GR',
	'f14b',
	'FA-18C_hornet',
	'FA-18C',
	'FW-190A8',
	'FW-190D9',
	'Hawk',
	'I-16',
	'J-11A',
	'JF-17',
	'ka-50',
	'L-39C',
	'L-39ZA',
	'M-2000C',
	'Mi-24P',
	'Mi-8mt',
	'MiG-15bis',
	'MiG-19P',
	'MiG-21Bis',
	'mig-29a',
	'mig-29g',
	'mig-29s',
	'P-51D',
	'SA342L',
	'SA342M',
	'SA342Minigun',
	'SA342Mistral',
	'SpitfireLFMkIX',
	'SpitfireLFMkIXCW',
	'su-25',
	'su-25t',
	'su-27',
	'su-33',
	'uh-1h',
	'YAK-52'
)

#get description.lua from Bazar and CoreMods and only those from modules
$alldescrpaths = Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'Bazar') -Recurse -Filter "description.lua"
$alldescrpaths += Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'CoreMods') -Recurse -Filter "description.lua"
$zipfiles = Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'Bazar') -Recurse -Filter "*.zip"
$zipfiles += Get-ChildItem -LiteralPath $(Join-Path -Path $dcspath -ChildPath 'CoreMods') -Recurse -Filter "*.zip"
$zipfiles = $zipfiles | Where-Object { $_.Fullname.Split("\") -like "Liveries" }



for ($i = 0 ; $i -lt $modules.count; $i++) {
	Write-Progress -Activity "Filtering Files for Modules" -status "Checking files for $i" -CurrentOperation $modules[$i] -percentComplete ($i /  $modules.count * 100)

	$moduledescrpaths += $alldescrpaths | Where-Object { (($_.Fullname).Split("\") | Select-Object -Last 3) -like $modules[$i] } | ForEach-Object { $_.FullName }
	$zipmoduledescrpaths += $zipfiles | Where-Object { (($_.Fullname).Split("\") | Select-Object -Last 3) -like $modules[$i] } | ForEach-Object { $_.FullName }
	$zipmoduledescrpathsbasename += $zipfiles | Where-Object { (($_.Fullname).Split("\") | Select-Object -Last 3) -like $modules[$i] } | ForEach-Object { $_.BaseName }
}

#count entries
$count = $moduledescrpaths.Length + $zipmoduledescrpaths.Length

#ask user to continue
if ($([System.Windows.Forms.Messagebox]::Show($Topmost, "Copy and Modify $count files in '$dcspath' to '$copypath\Liveries' ?", "Copy descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )) -notmatch 'Yes') { exit }

for ($i = 0 ; $i -lt $zipmoduledescrpaths.count; $i++) {
	Write-Progress -Activity "Exctracting description.luas from .zip" -status "Extracting from $i" -CurrentOperation $zipmoduledescrpaths[$i] -percentComplete ($i / $zipmoduledescrpaths.count * 100)

	$temppath = $(Join-Path -Path $(Join-Path -Path $Env:TEMP -ChildPath $(($zipmoduledescrpaths[$i].Split("\") | Select-Object -Last 2 -Skip 1) -join "\")) -ChildPath $zipmoduledescrpathsbasename[$i])
	New-Item -ItemType Directory -Path $temppath -Force | Out-Null
	$ziptemp += $(Join-Path -Path $temppath -ChildPath "description.lua")
	$zip = [System.IO.Compression.ZipFile]::Open($zipmoduledescrpaths[$i], 'read')
	$zip.Entries | Where-Object Name -like "description.lua" | ForEach-Object{[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ziptemp[$i], $true)}
	$zip.Dispose()
}

$moduledescrpaths = $moduledescrpaths + $ziptemp

for ($i = 0; $i -lt $count; $i++) {

	#Show Progress Bar
	Write-Progress -Activity "Copying and Modifying files" -status "Modifing file $i" -CurrentOperation $moduledescrpaths[$i] -percentComplete ($i / $count * 100)

	#check if already modified then write/fill luas
	if ((Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -match $regcheck) {
		$unmodifiedcount++
	}
	elseif ((Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -match $regex) {

		#Instead build the folder in a way so it can be put inside "saved games\dcs" folder
		$tmppath = Join-Path -Path $copypath -ChildPath $((($moduledescrpaths[$i]).Split("\") | Select-Object -Last 4) -join "\")
		#create new folder structure
		New-Item -ItemType File -Path $tmppath -Force | Out-Null

		(Get-Content -LiteralPath $moduledescrpaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $tmppath
		$modifiedcount++
	}
	else {
		$nomatchcount++
	}
}

Remove-Item $(Join-Path -Path $Env:TEMP -ChildPath "Liveries") -Recurse

$modi = "Successfully changed $modifiedcount files"
$unmod = "Seems like $unmodifiedcount files were already modified, didn't touch those"
$nomatch = "Seems like $nomatchcount files had no country definition, didn't touch those"

Write-Output "$modi`n$unmod`n$nomatch"