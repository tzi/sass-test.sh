#!/bin/bash

function confirm() {
  read -p "  - Do you want to ${1} (Y/n)? " -n 1 -r;
  echo '';
  if [ $REPLY = 'q' ];
  then
    exit 1
  fi
  if [[ $REPLY =~ ^[Yy]$ ]];
  then
    return 0;
  fi
  return 1;
}

function green() {
  echo "$(tput setab 2; tput setaf 0) $1 $(tput sgr 0)"
}

function red() {
  echo "$(tput setab 1; tput setaf 7) $1 $(tput sgr 0)"
}

function available() {
  return $(hash $1 2>/dev/null);
}

function compile() {
  $1 $2 --sourcemap=none;
}

function test() {
  COMMAND=$1;
  SCSS_FILE=$2;

  # Is expected result exists
  CSS_FILE=$( echo ${SCSS_FILE%.*}.css);
  if [ ! -f ${CSS_FILE} ];
  then
    echo "No existing result test for '${SCSS_FILE}'."
    if confirm "generate a new one?";
    then
      compile "${COMMAND}" "${SCSS_FILE}" > ${CSS_FILE};
    fi;
    return 0;
  fi;

  # Compare compiled & expected
  DIFF=$( compile "${COMMAND}" "${SCSS_FILE}" | diff -w -B ${CSS_FILE} - | wc -l);
  echo -n "${SCSS_FILE}: ${COMMAND} -> ";
  if [ $DIFF -eq 0 ];
  then
    green "PASSED";
    return 0;
  fi;
  red "ERROR"

  if confirm "see the difference?"
  then
    compile "${COMMAND}" "${SCSS_FILE}" | diff -w -B ${CSS_FILE} -;
  fi;

  if confirm "override the current result?";
  then
    compile "${COMMAND}" "${SCSS_FILE}" > ${CSS_FILE}
  fi;
  return 1;
}

# Check sass compiler availability
if ! available sass && ! available node-sass;
then
  echo "Neither sass or node-sass compiler found."
  exit 1;
fi;

# Find sass source files in test folder or in parameters
if [ $# -eq 0 ];
then
  SCSS_FOLDER="test";
else
  SCSS_FOLDER=$@;
fi;
SCSS_FILE_LIST=( $(find ${SCSS_FOLDER} -type f | grep ".scss$") );

# Is a test
if [ ${#SCSS_FILE_LIST[@]} -eq 0 ];
then
  echo "No test found: ${SCSS_FOLDER}"
  exit 1;
fi;
SCSS_FILE_LIST="${SCSS_FILE_LIST[@]}";

# Foreach source file
for SCSS_FILE in ${SCSS_FILE_LIST};
do
  if available sass;
  then
    test sass ${SCSS_FILE}
  fi;

  if available node-sass;
  then
    test node-sass ${SCSS_FILE}
  fi;
done;