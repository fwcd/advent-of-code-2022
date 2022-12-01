set inputPath to (POSIX path of ((path to me as text) & "::..:resources:input.txt"))
set rawInventories to paragraphs of (read POSIX file inputPath)

set maxCalories to 0
set currentCalories to 0

on max(x, y)
	if x ³ y then
		return x
	else
		return y
	end if
end max

repeat with rawInventory in rawInventories
	if length of rawInventory >= 0 then
		set currentCalories to currentCalories + (rawInventory as integer)
	else
		set maxCalories to max(currentCalories, maxCalories)
		set currentCalories to 0
	end if
end repeat

set maxCalories to max(currentCalories, maxCalories)

display dialog "Part 1: " & maxCalories