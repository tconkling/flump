#!/bin/bash

print_help() {
    echo "$0 <path to .flump>";
    echo "    Exports the given .flump project as if the \"Export Modified\" or \"Export Combined\"";
    echo "    button were pressed in the UI";
}

if [[ $# -ne 1 ]]; then
    print_help
    exit 0
fi

if [[ ! -f $1 ]]; then
    echo "Flump project file not found!"
    echo
    print_help
    exit 1
fi


get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}
project=`get_abs_filename $1`

if [[ "$FLUMP_HOME" == "" ]]; then
    FLUMP_HOME=/Applications/Flump.app
fi
pushd $FLUMP_HOME/Contents/Resources > /dev/null

# empty the current file out, if it exists, otherwise create it for tailing
echo -n "" > exporter.log
tail -F exporter.log &
TAIL_PID=$!

$FLUMP_HOME/Contents/MacOS/Flump --export $project

# give it a second to make sure we caught all the output
sleep 1

# Now that Flump is done, kill tail and exit
disown $TAIL_PID
kill -9 $TAIL_PID

popd > /dev/null
