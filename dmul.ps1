#Argument handle
param (
	[parameter(
		Mandatory = $true,
		Position = 0,
		HelpMessage = "Enter DCS Path for modifiying liveries")]
	[ValidateCount(1, 1)]
	[Alias("path", "dcs", "dp")]
	[String[]]
	$dcspath,
	
	[parameter(
		Mandatory = $false,
		Position = 1,
		HelpMessage = "Enter Save Path for modified liveries")]
	[ValidateCount(1, 1)]
	[Alias("copy", "cp")]
	[String[]]
	$copypath = $false
)

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

	if (!($directory.FullName -match $bazaresc) -and ($directory.FullName -match $coremodesc)) {
		Write-Output "'$dcspath' DCS not found in this directory"
		exit
	}
}
else {
	Write-Output "'$dcspath' Invalid directory"
	exit
}

#Validate CopyPath argument
if ($copypath -ne $false) {

	if (Test-Path -Path $copypath) {

		$copypath = Resolve-Path -LiteralPath $copypath
		Write-Output "'$copypath' Directory is valid and will be used to save modified .luas"
	}
	else {
		Write-Output "'$copypath' Directory is not valid. Exiting Script"
		exit
	}
}

#Regular expression to find countries = {"xxx", "yyy", "zzz"}
$regex = '(?m)^(\bcountries\b[\s\S]*[\=][\s\S]*[\{][\s\S]*){1}([\s\S]*[\"][A-Z]*[\"][\,]*[\s\S]*)+([\s\S]*[\}])'

#Regex to check if file is already modified
$regcheck = '(?m)^([\-]{2}([\[]{2}|[\[]{0}))+[\s]*(\bcountries\b)+[\s\S]*([\]]{2})*'

#regular expression to insert groups but as commentary
$regin = "--[[ `$1 `n `t `$2 `n `$3 ]]"

#Regex containing all modules
$modules = '.*A-10A.*|.*A-10C.*|.*AJS37.*|.*AV8BNA.*|.*BF-109K-4.*|.*C-101.*|.*Christen Eagle II.*|.*f_a-18C.*|.*F-15C.*|.*F-16C.*|.*f-16c bl.50.*|.*F-5EF-86.*|.*F14.*|.*FA-18C.*|.*FW-190A8.*|.*FW-190D9.*|.*I-16.*|.*ka-50.*|.*L-39.*|.*M-2000C.*|.*Mi-8mt.*|.*MiG-15bis.*|.*MiG-19P.*|.*MiG-21bis.*|.*mig-29a.*|.*mig-29g.*|.*mig-29s.*|.*mirage 2000-5.*|.*P-51D.*|.*SA342.*|.*su-25.*|.*su-25t.*|.*su-27.*|.*su-33.*|.*uh-1h.*|.*YAK-52.*|.*JF-17.*|.*J-11A.*|.*ChinaAssetPack.*|.*SpitfireLFMkIX.*'

Write-Output "DSC found in: $dcspath"

#get description.lua file paths and only get those from modules and only those in Bazar and CoreMods
$luapaths = Get-ChildItem -LiteralPath $dcspath -Recurse -Filter "description.lua" | 
Where-Object { $_.FullName -match $modules } | 
ForEach-Object { $_.FullName } | 
Select-String -Pattern "$bazaresc", "$coremodesc"

#count entries
$count = $luapaths.Length

#check if there is a copy path
if ($copypath -ne $false) {
	#ask user to continue
	if ($(Read-Host -Prompt "Copy and Modify $count files in '$dcspath' to '$copypath' ? (y/n)") -notmatch 'y') { exit }
	
	#counter for already modified/not modified files
	$modifiedcount = 0
	$unmodifiedcount = 0
	$nomatchcount = 0
	for ($i = 0; $i -lt $count; $i++) {
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
				
		#create new folder structure
		New-Item -ItemType File -Path $tmppath -Force | Out-Null
				
		#check if already modified then write/fill luas
		if ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regcheck) {
			$unmodifiedcount++
		}
		elseif ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regex) {
			(Get-Content -LiteralPath $luapaths[$i] -Raw) -replace $regex, $regin | Set-Content -LiteralPath $tmppath
			$modifiedcount++
		}
		else {
			$nomatchcount++
		}
	}	
	Write-Output "Successfully copied and changed $modifiedcount files"
}
else {
	#No copy path given, Ask user to continue
	if ($(Read-Host -Prompt "Modify $count files in $dcspath ? (y/n)") -notmatch 'y') { exit }

	#counter for already modified/not modified files
	$modifiedcount = 0
	$unmodifiedcount = 0
	$nomatchcount = 0
	for ($i = 0; $i -lt $count; $i++) {
		
		if ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regcheck) {
			$unmodifiedcount++
			
		}
		elseif ((Get-Content -LiteralPath $luapaths[$i] -Raw) -match $regex) {
			#Modify .lua files in DCS directory
			$luapaths | ForEach-Object { $(Get-Content -LiteralPath "$_" -Raw) -replace $regex, $regin | Set-Content -LiteralPath "$_" }
			$modifiedcount++			
		}
		else {
			$nomatchcount++
		}
	}
	Write-Output "Successfully changed $modifiedcount files"
}


if ($unmodifiedcount -gt 0) {
	Write-Output "Seems like $unmodifiedcount files were already modified, didn't touch those"
}
if ($nomatchcount -gt 0) {
	Write-Output "Seems like $nomatchcount had no country definition, didn't touch those"
}