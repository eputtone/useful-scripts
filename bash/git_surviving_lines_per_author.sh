#!/bin/bash

# Visualize surviving code lines from different time periods of git repository lifetime
  
FILTER=${1:-"^.*"}
shift 1
OUTPUTFILE=git_surviving_lines.png
ALL_BLAME_FILE=tmp_all_blame.txt
GIT_PLOT_DATA=tmp_git_plot_data.plot

git ls-tree --name-only -r HEAD | while read filename; do [[ $filename =~ $FILTER ]] && git blame -w "$filename"; done > $ALL_BLAME_FILE
cat $ALL_BLAME_FILE| awk '
  BEGIN { 
    author=""; 
    readingauthor=0 
  } 
  { 
    for (i=1; i<=NF; ++i) { 
      if ($i ~ /\(.*/) { 
        readingname=1; 
        author=substr($i,2); 
      } else if ($i ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) { 
        print $i " " author; 
        break; 
      } else if (readingname) { 
        author=author "-" $i 
      }
    }
  }
' | sort | uniq -c | awk '{ print $3 " " $2 " " $1}' > $GIT_PLOT_DATA

DAY_ONE=$(head -1 $GIT_PLOT_DATA  | cut -d ' ' -f2)
DAY_END=$(tail -1 $GIT_PLOT_DATA  | cut -d ' ' -f2)
MAX_ROWS=$(cut -d ' ' -f3 $GIT_PLOT_DATA | sort -n | tail -1)

gnuplot << EOF
set term png size 800,400
set key outside
set key right top
set output "$OUTPUTFILE"
set timefmt "%Y-%m-%d"
set xdata time
set xrange [ "$DAY_ONE":"$DAY_END" ]
set yrange [ "0":"$MAX_ROWS" ]
unset xtics
set ylabel "Lines of code"
set xlabel "Time"
set autoscale
filename = "$GIT_PLOT_DATA"
from=system('tail -n +2 '.filename. '| cut -f 1 -d " " | sort | uniq')
select_source(w) = sprintf('< (cat '.filename. ' | grep  "%s")', w)
set style data fsteps
set multiplot layout 1,2
set title 'Surviving $DAY_ONE - $DAY_END'
plot for [f in from] select_source(f) using 2:3 smooth cumulative title f
unset multiplot
EOF

rm $ALL_BLAME_FILE
rm $GIT_PLOT_DATA
echo "Written graph in "$OUTPUTFILE