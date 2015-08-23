#!/bin/bash

function confirm() {
  read -p "  - Do you want to ${1} (Y/n)? " -n 1 -r;
  echo '';
  ANSWER=false;
  if [ $REPLY = 'q' ];
  then
    exit 1
  fi
  if [[ $REPLY =~ ^[Yy]$ ]];
  then
    ANSWER=true;
  fi
}

function green() {
  echo "$(tput setab 2; tput setaf 0) $1 $(tput sgr 0)"
}

function red() {
  echo "$(tput setab 1; tput setaf 7) $1 $(tput sgr 0)"
}

function compile() {
  sass $1 --style expanded --sourcemap=none
}

# Find sass source files in test folder or in parameters
if [ $# -eq 0 ];
then
  SCSS_FILE_LIST=( $(find ./test -type f | grep ".scss$") );
  SCSS_FILE_LIST="${SCSS_FILE_LIST[@]}";
else
  SCSS_FILE_LIST=$@;
fi;

for SCSS_FILE in $(echo ${SCSS_FILE_LIST});
do

  # Is source file correct
  if [ ! -f ${SCSS_FILE} -o ${SCSS_FILE##*.} != "scss" ];
  then
    echo "${SCSS_FILE}: NOT FOUND";
    continue;
  fi;
  
  # Is expected result exists
  CSS_FILE=$( echo ${SCSS_FILE%.*}.css);
  if [ ! -f ${CSS_FILE} ];
  then
    echo "No existing result test for '${SCSS_FILE}'."
    confirm "generate a new one?"
    if [ $ANSWER == true ];
    then
      compile ${SCSS_FILE} > ${CSS_FILE}
    fi;
    continue;
  fi;
  
  # Compare compiled & expected
  DIFF=$( compile ${SCSS_FILE} | diff ${CSS_FILE} - | wc -l);
  echo -n "${SCSS_FILE}: ";
  if [ $DIFF -eq 0 ];
  then
    green "PASSED";
    continue;
  fi;
  red "ERROR"
  
  confirm "see the difference?"
  if [ $ANSWER == true ];
  then
    compile ${SCSS_FILE} | diff --side-by-side ${CSS_FILE} -;
  fi;
  
  confirm "override the current result?"
  if [ $ANSWER == true ];
  then
    compile ${SCSS_FILE} > ${CSS_FILE}
  fi;
  
done;