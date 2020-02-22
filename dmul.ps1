#Get all directory items
$directory = Get-Childitem -LiteralPath $PWD

#Regular expression to find countries = {"xxx", "yyy", "zzz"}
$regex = "(\bcountries\b[\s][\=][\s][`{][\s]*){1}([\s]*[`"][A-Z]{3}[`"][`,]*[\s]*)+([\s]*[`}])"

#regular expression to insert above groups but as commentary
$regin = "--[[ `$1 `n `t `$2 `n `$3 ]]"

#Regex containing all modules
$modules = ".*A-10A.*|.*A-10C.*|.*AJS37.*|.*AV8BNA.*|.*BF-109K-4.*|.*C-101.*|.*Christian Eagle II.*|.*f_a-18C.*|.*F-15C.*|.*F-16C.*|.*f-16c bl.50.*|.*F-5EF-86.*|.*F14.*|.*FA-18C.*|.*FW-190A8.*|.*FW-190D9.*|.*I-16.*|.*ka-50.*|.*L-39.*|.*M-2000C.*|.*Mi-8mt.*|.*MiG-15bis.*|.*MiG-19P.*|.*MiG-21bis.*|.*mig-29a.*|.*mig-29g.*|.*mig-29s.*|.*mirage 2000-5.*|.*P-51D.*|.*SA342.*|.*su-25.*|.*su-25t.*|.*su-27.*|.*su-33.*|.*uh-1h.*|.*YAK-52.*|.*JF-17.*|.*J-11A.*|.*ChinaAssetPack.*|.*SpitfireLFMkIX.*"


#check if DCS is in the same directory as script
if ($directory.FullName -match "DCS World") {
	
	#get full path to DSC World
	$dcspath = $directory | Where-Object {$_ -match "DCS World"} | Select-Object  -ExpandProperty FullName 
	#path for copy option
	$copypath = Join-Path -Path $PWD -ChildPath "DCS_Unlocked_Liveries\" 

	Write-Output "DSC found in: $dcspath"

	#get description.lua file paths and only get those from modules
	$luapaths = Get-ChildItem -LiteralPath $dcspath -Recurse -Filter "description.lua" | Where-Object {$_.FullName -match $modules} | ForEach-Object {$_.FullName}

	#count entries
	$count = $luapaths.Length

	$change = Read-Host -Prompt "Change $count files in $dcspath\? (y/n) or Keep original and save modified files in $copypath ? (c/n)"

	Switch ($change){

		#replace inside DCS folder
		{$_ -match 'y' -or $_ -match 'Y'} {

			$luapaths | ForEach-Object  {$(Get-Content -LiteralPath "$_") -replace $regex, $regin | Set-Content -LiteralPath "$_"}

		}

		#replace in new directory
		{$_ -match 'c' -or $_ -match 'C'} {

			for ($i = 0; $i -lt $count; $i++) {

				#little check so the created fodlers can be put inside dcs main directory for overwrite
				if ($luapaths[$i] -match [regex]::escape("\Bazar\")) {

					$subfolderscount = 5

				} else {

					$subfolderscount = 7

				}
	
				#ugly string replacement/construction to .\DCS_Unlocked_Liveries\*
				$tmppath = $copypath + $(($luapaths[$i].Split("\") | Select-Object -Last $subfolderscount) -join "\")
				
				#create new fodler structure
				New-Item -ItemType File -Path $tmppath -Force | Out-Null
				
				#write/fill luas
				(Get-Content -LiteralPath $luapaths[$i]) -replace $regex, $regin | Set-Content -LiteralPath $tmppath

			}

		}

		#user aborted
		default {

			Write-Output "Exiting Script"
			exit

		}
	}

} else {

Write-Output "DCS not found in this directory :("

}