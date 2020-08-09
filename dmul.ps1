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
if($FolderBrowserDCSPath.ShowDialog($Topmost) -eq "Cancel") {
	exit
}

#Ask user for export
$ifexport = [System.Windows.Forms.Messagebox]::Show($Topmost,"Do you want to export the files and then modify? This won't change the files in your DCS directory.", "Export descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )

if ($ifexport -eq "Yes")
{
	if($FolderBrowserCopyPath.ShowDialog($Topmost) -eq "Cancel") {
		exit
	}
}

#Save Paths
$dcspath = $FolderBrowserDCSPath.SelectedPath
$copypath = $FolderBrowserCopyPath.SelectedPath

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

#Validate CopyPath argument
if ($copypath -ne "") {
	if (!(Test-Path -Path $copypath)) {
		Write-Output "'$copypath' Directory is not valid. Exiting Script"
		exit
	}
}

#Regular expression to find countries = {"xx", "yyy", "zzzzz"}
$regex = '(?ms)^(\bcountries\b.*?[\=].*?[\{].*?){1}(.*?[\"][A-Z]*?[\"][\,]*.*?)+?(.*?[\}])+?'

#Regex to check if file is already modified
$regcheck = '(?ms)^([\-]{2})([\[]{2}|[\[]{0})+([\s]*?)(\bcountries\b.*?[\=].*?)+'

#regular expression to insert groups but as commentary
$regin = "--[[ `$1 `n `t `$2 `n `$3 ]]"

#Regex containing all modules
$modules = '.*A-10A.*|.*A-10C.*|.*AJS37.*|.*AV8BNA.*|.*BF-109K-4.*|.*C-101.*|.*Christen Eagle II.*|.*f_a-18C.*|.*F-15C.*|.*F-16C.*|.*F-5E.*|.F-86.*|.*F14.*|.*FA-18C.*|.*FW-190A8.*|.*FW-190D9.*|.*I-16.*|.*ka-50.*|.*L-39.*|.*M-2000C.*|.*Mi-8mt.*|.*MiG-15bis.*|.*MiG-19P.*|.*MiG-21bis.*|.*mig-29a.*|.*mig-29g.*|.*mig-29s.*|.*P-51D.*|.*SA342.*|.*su-25.*|.*su-25t.*|.*su-27.*|.*su-33.*|.*uh-1h.*|.*YAK-52.*|.*JF-17.*|.*J-11A.*|.*ChinaAssetPack.*|.*SpitfireLFMkIX.*'

#get description.lua file paths and only get those from modules and only those in Bazar and CoreMods
$luapaths = Get-ChildItem -LiteralPath $dcspath -Recurse -Filter "description.lua" | 
Where-Object { $_.FullName -match $modules } | 
ForEach-Object { $_.FullName } | 
Select-String -Pattern "$bazaresc", "$coremodesc"

#count entries
$count = $luapaths.Length

#check if there is a copy path
if ($copypath -ne "") {
	#ask user to continue
	if ($([System.Windows.Forms.Messagebox]::Show($Topmost, "Copy and Modify $count files in '$dcspath' to '$copypath' ?", "Copy descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )) -notmatch 'Yes') { exit }
	
	#counter for already modified/not modified files
	$modifiedcount = 0
	$unmodifiedcount = 0
	$nomatchcount = 0
	for ($i = 0; $i -lt $count; $i++) {	
		#Show Progress Bar
		Write-Progress -Activity "Copying and Modifying files" -status "Modifing file $i" -CurrentOperation $luapaths[$i] -percentComplete ($i / $count*100) 
		
		#little check so the created folders can be put inside dcs main directory for overwrite
		if ($luapaths[$i] -match $bazaresc) {
			$subfolderscount = 5
		}
		elseif ($luapaths[$i] -match $coremodesc) {
			$subfolderscount = 7
		}
		else {
			Write-Output "Something went wrong! Exiting"
			exit
		}

		#ugly string replacement/construction to $CopyPath
		$tmppath = Join-Path -Path $copypath -ChildPath $((($luapaths[$i]).Line.Split("\") | Select-Object -Last $subfolderscount) -join "\")
		
		#check if already modified then write/fill luas
		if ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regcheck) {
			$unmodifiedcount++
		}
		elseif ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regex) {
			#create new folder structure
			New-Item -ItemType File -Path $tmppath -Force | Out-Null

			(Get-Content -LiteralPath $luapaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $tmppath
			$modifiedcount++
		}
		else {
			$nomatchcount++
		}
	}	
	$modi = "Successfully changed $modifiedcount files"
}
else {
	#No copy path given, Ask user to continue
	if ($([System.Windows.Forms.Messagebox]::Show($Topmost, "Modify $count files in $dcspath ?", "Modify descritpion.luas?", [System.Windows.Forms.MessageBoxButtons]::YesNo )) -notmatch 'Yes') { exit }

	#counter for already modified/not modified files
	$modifiedcount = 0
	$unmodifiedcount = 0
	$nomatchcount = 0
	for ($i = 0; $i -lt $count; $i++) {
		#Show Progress Bar
		Write-Progress -Activity "Modifing files in $dcspath" -status $i -CurrentOperation $luapaths[$i] -percentComplete ($i / $count*100)
		
		if ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regcheck) {
			$unmodifiedcount++
		}	
		elseif ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regex) {
			#Modify .lua files in DCS directory
			(Get-Content -LiteralPath $luapaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $luapaths[$i]
			$modifiedcount++
		}
		else {
			$nomatchcount++
		}
	}
}

$modi = "Successfully changed $modifiedcount files"
$unmod = "Seems like $unmodifiedcount files were already modified, didn't touch those"
$nomatch = "Seems like $nomatchcount files had no country definition, didn't touch those"

Write-Output "$modi`n$unmod`n$nomatch"