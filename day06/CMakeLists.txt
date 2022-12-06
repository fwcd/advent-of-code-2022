project(day06)
cmake_minimum_required(VERSION 3.17)

file(READ resources/input.txt raw_input)
string(STRIP "${raw_input}" input)
string(LENGTH "${input}" length)

function(find_position_past_window)
  set(options "")
  set(one_value_args OUTPUT WINDOW_LENGTH)
  set(multi_value_args "")

  cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  set(window_length "${ARG_WINDOW_LENGTH}")
  math(EXPR window_preend "${window_length} - 2")
  math(EXPR window_end "${window_length} - 1")
  math(EXPR end "${length} - 1")

  foreach(i RANGE "${end}")
    string(SUBSTRING "${input}" "${i}" "1" char)

    # Update window of last ${WINDOW_LENGTH} chars
    foreach(j RANGE "${window_preend}")
      math(EXPR next "${j} + 1")
      set("last_${j}" "${last_${next}}")
    endforeach()
    set("last_${window_end}" "${char}")

    # Check if window is distinct
    if("${i}" GREATER_EQUAL "${window_end}")
      set(found_window ON)
      foreach(j1 RANGE "${window_preend}")
        math(EXPR next "${j1} + 1")
        foreach(j2 RANGE "${next}" "${window_end}")
          if("${last_${j1}}" STREQUAL "${last_${j2}}")
            set(found_window OFF)
            break()
          endif()
        endforeach()
        if(NOT "${found_window}")
          break()
        endif()
      endforeach()

      # Print position past end of window if a distinct window was found
      if("${found_window}")
        math(EXPR result "${i} + 1")
        set("${ARG_OUTPUT}" "${result}" PARENT_SCOPE)
        break()
      endif()
    endif()
  endforeach()
endfunction()

find_position_past_window(OUTPUT part1 WINDOW_LENGTH 4)
find_position_past_window(OUTPUT part2 WINDOW_LENGTH 14)

message("Part 1: ${part1}")
message("Part 2: ${part2}")
