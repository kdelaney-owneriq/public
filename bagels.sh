#!/bin/bash --
#
# FILE:     bagels.sh
# Author:   Keith Delaney
# Created:  2016-10-03

# Function Definitions
fn_help() {
    echo "$(basename $0) is a bash implementation of the number-guessing game BAGELS!
    
    Play goes as follows:
    
     1) The computer will pick a 3-digit number, which you will need to guess.
     2) None of the digits will be repeated, and the solution may begin with 0 - so '100' is no good, but '012' is valid.
     3) On each turn you submit a guess, then press ENTER.
     4) Each valid guess you submit will be checked against the solution, and you will be given clues as follows:
     
         BAGELS - if none of the digits in your guess match to the solution
         PICO   - for each digit in your guess which is correct but in the wrong position
         FERMI  - for each digit in your guess which is correct and in the right position
         
         The order of the clues given in the answer is arbitrary, so, for example, 'FERMI PICO' is the same as 'PICO FERMI'.
         
     5) The object is to find the solution with as few guesses as possible.
     

 Now, can you guess the number I'm thinking of?
    
    "
} ;

function timer() {
    # without arguments, return the current time, in unixtime
    # with an argument, assumed to be a unixtime value, return the elapsed time passed since the given unixtime, and return as time, formatted 'h:mm:ss'
    if [[ $# -eq 0 ]] ; then
        echo $(date '+%s') ;
    else
        local  stime=$1 ;
        etime=$(date '+%s') ;
        if [[ -z "$stime" ]]; then stime=$etime; fi ;
        dt=$((etime - stime)) ;
        ds=$((dt % 60)) ;
        dm=$(((dt / 60) % 60)) ;
        dh=$((dt / 3600)) ;
        printf '%d:%02d:%02d' $dh $dm $ds ;
    fi ;
} ;

fn_time_to_sec() {
    # convert time formatted as 'h:mm:ss' to seconds
    if [[ $# -eq 0 ]] ; then
        echo 0 ;
    else 
        local stime="$1"
        dms=( $(echo ${stime} | sed 's/:/ /g') )
        echo $(( 10#${dms[0]} * 3600 + 10#${dms[1]} * 60 + 10#${dms[2]} ))  # force interpretation of numeric with leading zero as base 10
    fi
} ;

fn_sec_to_time() {
    # convert seconds to time, formatted as 'h:mm:ss'
    if [[ $# -eq 0 ]] ; then
        printf '0:00:00'
    else 
        local dt=$1
        ds=$((dt % 60)) ;
        dm=$(((dt / 60) % 60)) ;
        dh=$((dt / 3600)) ;
        printf '%d:%02d:%02d' $dh $dm $ds ;
    fi
} ;

fn_rand() { 
    # generate a random number from 0 to 9
    echo $(( $RANDOM % 10 )) 
    } ;

fn_solution() {
    # build a random 3-digit string with none of the digits repeated
    local SOLUTION=$(fn_rand)
    for i in $(eval echo {2..${SOLUTION_LENGTH}} ); do
        local NEXT=$(fn_rand)
        while [[ ${SOLUTION} =~ ${NEXT} ]] ;    # bash regexp test condition
        do
            NEXT=$(fn_rand)
        done
        SOLUTION=${SOLUTION}${NEXT}
    done;
    echo ${SOLUTION} 
} ;

fn_qc_guess(){
    # quality check the guess input
    local GUESS="$1"
    if [[ ! "${GUESS}" =~ ^[0-9]{${SOLUTION_LENGTH}}$ ]] ; then # GUESS does not have valid number of numbers
        echo -e "Please guess with a valid ${SOLUTION_LENGTH}-digit number.\n"
        return 1
    elif [[ "$(echo ${GUESS} | grep -o . | sort | tr -d "\n")" != "$(echo ${GUESS} | grep -o . | sort | uniq | tr -d "\n")" ]] ; then               # GUESS has duplicate characters    
        echo -e "Duplicate characters found. Please guess with a valid ${SOLUTION_LENGTH}-digit number without any duplicate characters.\n"
        return 1
    else return 0
    fi ;
    }

fn_match_guess() {
    local GUESS="$1"
    local ANSWER=
    local LOOP_MAX=$(( ${SOLUTION_LENGTH}-1 ))

    # match the guess to the solution and store the result in answer
    for i in $( eval echo {0..${LOOP_MAX}} ); do
        GUESS_SINGLE_CHAR=$( eval echo ${GUESS:${i}:1} )
        SOLUTION_SINGLE_CHAR=$( eval echo ${SOLUTION:${i}:1} )
        # fermi test
        if [[ ${SOLUTION_SINGLE_CHAR} = ${GUESS_SINGLE_CHAR} ]] ; then ANSWER=${ANSWER}F
        # position test
        elif [[ ${SOLUTION} =~ ${GUESS_SINGLE_CHAR} ]] ; then ANSWER=${ANSWER}P
        fi
    done ;
    
    ANSWER=$(echo ${ANSWER} | grep -o . | sed -e 's/F/FERMI /g' -e 's/P/PICO /g' | sort | tr -d "\n")
    
    if [ -z "${ANSWER}" ] ; then ANSWER="BAGELS" ; fi;
    
    if [ "${GUESS}" == "${SOLUTION}" ] ; then ANSWER="\nCongratulations!! ${GUESS} was the number I was thinking of. You Win!!" ;  STATUS=1; fi ;
    
    echo -e "${ANSWER}\n"
}

fn_trim_reply() {
    local REPLY="$1"
    # convert to upper case, trim to one character, and assign default value of 'Y' if the result is null
    REPLY=${REPLY^^}; REPLY=${REPLY:0:1}; REPLY=${REPLY:=Y}
    echo ${REPLY}
} ;

# Variable Definitions
STATUS=0 ; ATTEMPTS=0 ; SOLUTION_LENGTH=3 ;

# begin main

clear; 

fn_help

SOLUTION=$(fn_solution); 

# echo SOLUTION is: ${SOLUTION}             # for testing only
# echo BEST_TIME is: ${BEST_TIME}           # for testing only

MY_TIMER=$(timer)

while [ $STATUS -eq 0 ] 
do
    (( ATTEMPTS++ ))
    echo -n "time spent: $(timer ${MY_TIMER}) ... Guess #"${ATTEMPTS}") "; read GUESS ;
    fn_qc_guess "${GUESS}"
    if [ $? -eq 1 ] ; then (( ATTEMPTS-- )) ; continue ; fi
    fn_match_guess "${GUESS}"
    if [ $? -eq 1 ] ; then (( ATTEMPTS-- )) ; continue ; fi
done ;

THIS_TIME=$(timer ${MY_TIMER})

echo -e "It took you ${THIS_TIME} and ${ATTEMPTS} tries to find the answer.\n"

if [ $(fn_time_to_sec ${THIS_TIME}) -lt ${BEST_TIME:-9999999} ] ; then 
    echo -e "Congratulations, that is the fastest time yet!!\n"
    export BEST_TIME=$(fn_time_to_sec ${THIS_TIME})
else 
    echo -e "Best time so far: $(fn_sec_to_time ${BEST_TIME})\n"
fi ;

echo -ne "Would you like to play again? "
read REPLY
REPLY=$(fn_trim_reply "${REPLY}")

if [ ${REPLY} == 'Y' ]; then
    $0
else
    echo
    echo "Thanks for trying out $(basename ${0})."
    echo "Bye now!" ; echo ;
    exit
fi ;

exit;
