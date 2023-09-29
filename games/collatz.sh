# Collatz Conjecture Demonstration
# evaluates the Collatz Conjecture for all N from 2 to 'last'
# outputs a text file with columns: start, steps, orbit
# last=20
MAXLIMIT="100"
ERR="Please enter a number less than ${MAXLIMIT}."
echo -n "How many numbers do you want to calculate?  " ; read last
(( last <= MAXLIMIT )) || { echo "${ERR}" ; exit ; } 
list="$(eval echo {2..$last})"
for i in $list; do
    cnt=1; v=$i; vs=$i; h=0;
    while (( $v > 1 )); do
      (( v > h )) && h=${v}
      if (( $v % 2 == 0 )); 
        then v=$(( ${v}/2 ))
        else v=$(( ${v}*3 + 1 ))
      fi
      ((cnt++))
      vs="${vs},${v}"
    done;
    
    steps[i]=${cnt}
    orbit[i]=${vs}
    high[i]=${h}
done ;
FILE=~/collatz_out.txt
rm -f ${FILE}
echo ; echo "start steps high orbit" | sed 's/ /\t/g' >> ${FILE}
for a in $list; do
    echo $a ${steps[a]} ${high[a]} ${orbit[a]} | sed 's/ /\t/g' >> ${FILE}
done ;
cat ${FILE}
