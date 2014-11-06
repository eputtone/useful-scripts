#!/bin/bash

# Visualize surviving code lines from different time periods of git repository lifetime

FILTER=${1:-"^.*"}
shift 1
OUTPUTFILE=git_surviving_lines.png
ALL_BLAME_FILE=tmp_all_blame.txt
GIT_PLOT_DATA=tmp_git_plot_data.plot

git ls-tree --name-only -r HEAD | while read filename; do [[ $filename =~ $FILTER ]] && git blame -w "$filename"; done > $ALL_BLAME_FILE
cat $ALL_BLAME_FILE| awk '{ for (i=1; i<=NF; ++i) if ($i ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) { print $i; break; }}' | sort | uniq -c | awk '{print $2 " " $1}' > $GIT_PLOT_DATA

DAY_ONE=$(head -1 $GIT_PLOT_DATA  | cut -d ' ' -f1)
DAY_END=$(tail -1 $GIT_PLOT_DATA  | cut -d ' ' -f1)
MAX_ROWS=$(cut -d ' ' -f2 $GIT_PLOT_DATA | sort -n | tail -1)

gnuplot << EOF
set term png
set output "$OUTPUTFILE"
set timefmt "%Y-%m-%d"
set xdata time
set xrange [ "$DAY_ONE":"$DAY_END" ]
set yrange [ "0":"$MAX_ROWS" ]
set style data impulses
set title "Surviving lines of code (from git blame)"
set ylabel "Lines of code"
set xlabel "Date"
plot '$GIT_PLOT_DATA' using 1:2
EOF

rm $ALL_BLAME_FILE
rm $GIT_PLOT_DATA
echo "Written graph in "$OUTPUTFILE
