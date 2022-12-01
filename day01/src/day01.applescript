#!/usr/bin/osascript

on swap(xs, i, j)
	set tmp to item i of xs
	set item i of xs to item j of xs
	set item j of xs to tmp
end swap

on partition(xs, l, r)
	set i to l
	set j to (r - 1)
	set p to r -- Use last element as pivot
	
	repeat while i < j
		repeat until i ³ j or item i of xs > item p of xs
			set i to i + 1
		end repeat
		repeat until i ³ j or item j of xs ² item p of xs
			set j to j - 1
		end repeat
		if item i of xs > item j of xs then
			swap(xs, i, j)
		end if
	end repeat
	
	if item i of xs > item p of xs then
		swap(xs, i, p)
	else
		set i to p
	end if
	
	return i
end partition

on quickSort(xs, l, r)
	if l < r then
		set i to partition(xs, l, r)
		quickSort(xs, l, i - 1)
		quickSort(xs, i + 1, r)
	end if
end quickSort

set inputPath to (POSIX path of ((path to me as text) & "::..:resources:input.txt"))
set rawInventories to paragraphs of (read POSIX file inputPath)
set inventories to {}
set currentCalories to 0

repeat with rawInventory in rawInventories
	if length of rawInventory > 0 then
		set currentCalories to currentCalories + (rawInventory as integer)
	else
		set inventories's end to currentCalories
		set currentCalories to 0
	end if
end repeat

set inventories's end to currentCalories

quickSort(inventories, 1, inventories's length)

set part1 to item (inventories's length) of inventories
set part2 to part1 + (item ((inventories's length) - 1) of inventories) + (item ((inventories's length) - 2) of inventories)

"Part 1: " & part1 & "\nPart 2: " & part2
