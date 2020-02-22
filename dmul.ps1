
#Get all direcotry items
$direcotry = Get-Childitem -Path .\

#Regular expression to find countries = {"xxx", "yyy", "zzz"}
$regex = "(\bcountries\b[\s][\=][\s][`{][\s]*){1}([\s]*[`"][A-Z]{3}[`"][`,]*[\s]*)+([\s]*[`}])"

#regular expression to insert above groups but as commentary
$regin = "--[[ `$1 `n `t `$2 `n `$3 ]]"

#Regex containing all modules
$modules = ".*A-10A.*|.*A-10C.*|.*AJS37.*|.*AV8BNA.*|.*BF-109K-4.*|.*C-101.*|.*Christian Eagle II.*|.*f_a-18C.*|.*F-15C.*|.*F-16C.*|.*f-16c bl.50.*|.*F-5EF-86.*|.*F14.*|.*FA-18C.*|.*FW-190A8.*|.*FW-190D9.*|.*I-16.*|.*ka-50.*|.*L-39.*|.*M-2000C.*|.*Mi-8mt.*|.*MiG-15bis.*|.*MiG-19P.*|.*MiG-21bis.*|.*mig-29a.*|.*mig-29g.*|.*mig-29s.*|.*mirage 2000-5.*|.*P-51D.*|.*SA342.*|.*su-25.*|.*su-25t.*|.*su-27.*|.*su-33.*|.*uh-1h.*|.*YAK-52.*|.*JF-17.*|.*J-11A.*|.*ChinaAssetPack.*|.*SpitfireLFMkIX.*"


#check if DCS is in the same directory as script
if ($direcotry.Name -match 'DCS World') {
	
	#get full path to DSC World
	$dcspath = Resolve-Path -Path $($direcotry | Where-Object {$_.Name -match 'DCS World'})

	Write-Output "DSC found in: $dcspath"

	#get description.lua file paths and only get those from modules
	$luapaths = $(Get-ChildItem -Path $dcspath\Bazar\Liveries\* -Recurse -Filter "description.lua" | Where-Object {$_.FullName -match $modules} | ForEach-Object {$_.FullName})
	$luapaths += $(Get-ChildItem -Path $dcspath\CoreMods\* -Recurse -Filter "description.lua" | Where-Object {$_.FullName -match $modules} | ForEach-Object {$_.FullName})

	#count entries
	$count = $luapaths.Length

	$save = Read-Host -Prompt "Do you want to change $count files in $dcspath ? (y/n)"

	if ($save -eq 'y' -or $save -eq 'Y'){ 
		#replace matched string
		$luapaths | ForEach-Object  {$(Get-Content -LiteralPath "$_") -replace $regex, $regin | Set-Content -LiteralPath "$_"}
	} else {
		Write-Output "Exiting Script"
		exit
	}
c
} else {
Write-Output "DCS not found :("
}