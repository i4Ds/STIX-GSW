set encoding iso_8859_1
#set title "" 0.0,-0.5
#set key title 50,0.5
file = "Bkg.dat"

######################################

set xlabel "E [keV]"
#################
#set xrange [0:250]
#################
# set autoscale x
# set xzeroaxis lt -1 lw 2
#set xtics nomirror 10
#set mxtics 2 
# set format x "10^{%L}"
# set logscale x
#################
# set x2label "" 0.0,-4.0
# set x2range [0:(100*60)]
# set x2tics nomirror 500
# set mx2tics 5
# set format x2 "10^{%L}"
# set logscale x2
######################################
set ylabel "intensity []"
##################
#set yrange [0:330]
##################
# set autoscale y
# set yzeroaxis lt -1 lw 2
# set ytics 1
# set mytics 10
#set format y "1E%L"
#set logscale y
#################
# set y2label ""
# set y2range [0:4000]
# set y2tics 500
# set my2tics 10
# set format y2 "10^{%L}"
# set logscale y2
#################
#set size ratio -1

set grid
#set sample 500
set key right bottom

#set terminal wxt persist font 'Arial'
set terminal svg
set output "./Bkg_lin.svg"
plot file u 1:2 w lines  lt 1 notitle,\
     file u 1:2 w points lt 1 ps 0.5 notitle
######################################

#set yrange [1E-8:1E0]
set format y "1E%L"
 set mytics 10
set logscale y
set output "./Bkg_log.svg"
plot file u 1:2 w lines lt 1 notitle,\
     file u 1:2 w points lt 1 ps 0.5 notitle
