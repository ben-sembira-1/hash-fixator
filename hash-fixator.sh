#!/bin/bash

METADATA_DIR=".hash-fixation-metadata"
TREE_FILE=$METADATA_DIR/"tree.txt"
HASHES_FILE=$METADATA_DIR/"hashes.txt"
SCRIPT_NAME="$(basename "$0")"


function error {
    echo ">>>> ERROR <<<<"
    for var in "$@"
    do
        echo "$var"
    done
    exit 1
}

function calculate_tree {
    find . ! -name $SCRIPT_NAME ! -path "*$METADATA_DIR*" -exec file '{}' \;
}

function calculate_hashes {
    find . ! -name $SCRIPT_NAME ! -path "*$METADATA_DIR*" -type f -exec shasum '{}' +
}

function create_fixation {
    echo "Creating..."
    rm -rf $METADATA_DIR
    mkdir $METADATA_DIR
    calculate_tree > $TREE_FILE
    calculate_hashes > $HASHES_FILE
    echo "Directory fixation saved in $METADATA_DIR"
}

function test_fixation {
    echo "Testing..."
    if [ ! -d $METADATA_DIR ]
    then
        error "Looks like this directory was never fixed. Try to run the script on create mode for fixing the directory"
    fi
    [ "`calculate_tree`" == "`cat $TREE_FILE`" ]
    TREE_TEST=$?
    [ "`calculate_hashes`" == "`cat $HASHES_FILE`" ]
    HASH_TEST=$?

    if [ ! 0 -eq $HASH_TEST ]
    then
        diff $HASHES_FILE - <<<"`calculate_hashes`"
        error "The hashes are not the same!"
    fi

    if [ ! 0 -eq $TREE_TEST ]
    then
        diff $TREE_FILE - <<<"`calculate_tree`"
        error "The tree of the directory is not the same!"
    fi

    echo "Directory is fixed :)"
}

function usage {
    echo "USAGE: $SCRIPT_NAME -t(est)|-c(reate)"
    exit 1
}

while getopts tc option; do
    case $option in
        t) test_fixation;;
        c) create_fixation;;
        \?) usage;;
    esac;
done;

if ((OPTIND == 1))
then
    usage
fi