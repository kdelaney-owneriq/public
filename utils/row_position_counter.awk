#! /usr/bin/awk
# file:     row_position_counter.awk
# purpose:  numbers the characters for each line of input file
# author:   kd
# usage:
#    from std in:
#      echo "any string or rows of strings" | awk -f row_position_counter.awk
# 
#    from file "my_text_file":
#      awk -f row_position_counter.awk "my_text_file"

{
  l = length($0)
  n = length(l)
  for (d=n-1; d >= 0; d--) {
    for (a=1; a <= l; a++) {
      t = int(a/(10**d))
      b = substr(t, length(t),1)
      printf "%s", b
    }
    printf "\n"
  }
  print $0
  print ""
}
