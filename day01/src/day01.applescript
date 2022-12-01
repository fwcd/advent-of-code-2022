set inputPath to (POSIX path of ((path to me as text) & "::..:resources:input.txt"))
set rawInventories to paragraphs of (read POSIX file inputPath)

set maxCalories to 0
set currentCalories to 0

repeat with rawInventory in rawInventories
	if length of rawInventory is greater than 0 then
		set currentCalories to currentCalories + (rawInventory as integer)
	else
		if currentCalories is greater than maxCalories then
			set maxCalories to currentCalories
		end if
		set currentCalories to 0
	end if
end repeat

if currentCalories is greater than maxCalories then
	set maxCalories to currentCalories
end if

log "Part 1: " & maxCalories