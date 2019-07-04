d = obj->getdata()
retall
help, obj
d = obj->getdata()
help, d
chkarg,'deriv
dd = deriv( findgen(389), d.data)
pmm, dd
print, histogram( alog10(abs(dd)>1), bin=.1)
print, histogram( alog10(abs(dd)>1), bin=.2)
print, histogram( alog10(abs(dd)>1), bin=.2, rev=rdd)
print, reverseindices( rdd, 12)
print, reverseindices( rdd, 13)
print, reverseindices( rdd, 11)
print, reverseindices( rdd, 9)
print, histogram( alog10((dd)>1), bin=.2, rev=rdd)
print, reverseindices( rdd, 13)
print, reverseindices( rdd, 12)
print, reverseindices( rdd, 10)
print, reverseindices( rdd, 9)
chkarg,'cluster_fit
help, dd
add = abs(dd)
x = findgen(389)
ord = sort( add)
plot, x[ord], psy=1
plot, x,x[ord], psy=1
plot, add, psy=1
plot, smooth(add,5), psy=1
chkarg,'resistant_mean
resistant_mean, add, 3, wused=q
resistant_mean, add, 3, mean, sigma, nreg, wused=q
help, nreg
help, q
resistant_mean, smooth(add,5), 3, mean, sigma, nreg, wused=q
help, q
plot, (smooth(add,5))[q], psy=1
plot, x[q],(smooth(add,5))[q], psy=1
linecolors
plot, (smooth(add,5))[q], psy=1
oplot, x[q],(smooth(add,5))[q], psy=1, col=3
plot, x,(smooth(add,5)), psy=1
oplot, x[q],(smooth(add,5))[q], psy=1, col=3
chkarg,'find_changes
z = where( q[1:*]-q eq 1)
help, z
help, where(z eq 1)
z = where( q[1:*]-q gt 5)
help, z
print, z
print, q[z]
z = where( q[1:*]-q gt 10)
print, q[z]
print, q[z+1]
;IDL> d = obj->getdata()
;IDL> help, d
;** Structure <160e25d0>, 3 tags, length=9336, data length=9336, refs=2:
;DATA            DOUBLE    Array[389]
;EDATA           DOUBLE    Array[389]
;LTIME           DOUBLE    Array[389]
;IDL> chkarg,'deriv
;% Compiled module: CHKARG.
;% Compiled module: GET_LIB.
;% Compiled module: XKILL.
;% Compiled module: GET_PROC.
;---- Module: deriv.pro
;---- From:   C:\Program Files\exelis\IDL85\lib
;% Compiled module: STRIP_ARG.
;---> Call: Function Deriv, X, Y
;IDL> dd = deriv( findgen(389), d.data)
;IDL> pmm, dd
;% Compiled module: PMM.
;-600.500      623.000
;IDL> print, histogram( alog10(abs(dd)>1), bin=.1)
;32          13           0          26          14          14          34          17          32          43          29          29          25          27
;10           2          12           5           2           5           5           5           0           1           1           1           1           4
;IDL> print, histogram( alog10(abs(dd)>1), bin=.2)
;45          26          28          51          75          58          52          12          17           7          10           1           2           5
;IDL> print, histogram( alog10(abs(dd)>1), bin=.2, rev=rdd)
;45          26          28          51          75          58          52          12          17           7          10           1           2           5
;IDL> print, reverseindices( rdd, 12)
;% Compiled module: REVERSEINDICES.
;62          65
;IDL> print, reverseindices( rdd, 13)
;63          64          67          68          69
;IDL> print, reverseindices( rdd, 11)
;70
;IDL> print, reverseindices( rdd, 9)
;56          60          61          75         187         189         196
;IDL> print, histogram( alog10((dd)>1), bin=.2, rev=rdd)
;218          16          14          27          39          26          21           6           9           6           3           0           2           2
;IDL> print, reverseindices( rdd, 13)
;63          64
;IDL> print, reverseindices( rdd, 12)
;62          65
;IDL> print, reverseindices( rdd, 10)
;73          74         188
;IDL> print, reverseindices( rdd, 9)
;56          60          61          75         187         189
;IDL> chkarg,'cluster_fit
;---- Module: cluster_fit.pro
;---- From:   C:\ssw\hessi\idl\util
;---> Call: FUNCTION CLUSTER_FIT, x, xtol, AVG=avg
;IDL> help, dd
;DD              DOUBLE    = Array[389]
;IDL> add = abs(dd)
;IDL> x = findgen(389)
;IDL> ord = sort( add)
;IDL> plot, x[ord], psy=1
;IDL> plot, x,x[ord], psy=1
;IDL> plot, x,x[ord], psy=1
;IDL> plot, add, psy=1
;IDL> plot, smooth(add,5), psy=1
;IDL> chkarg,'resistant_mean
;---- Module: resistant_mean.pro
;---- From:   C:\ssw\gen\idl\fund_lib\sdac
;---> Call: PRO RESISTANT_Mean,Y,CUT,Mean,Sigma,Num_Rej,goodvec = goodvec, $
;  dimension=dimension, double=double,sumdim=sumdim, $
;  wused=wused, Silent = silent
;IDL> resistant_mean, add, 3, wused=q
;% Compiled module: RESISTANT_MEAN.
;Syntax - Resistant_Mean, Vector, Sigma_cut, Mean, [ Sigma_mean,
;Num_Rejected,  GOODVEC=,
;DIMEN=, /DOUBLE]
;IDL> resistant_mean, add, 3, mean, sigma, nreg, wused=q
;% Compiled module: POLY.
;IDL> help, nreg
;NREG            LONG      =           46
;IDL> help, q
;Q               LONG      = Array[343]
;IDL> resistant_mean, smooth(add,5), 3, mean, sigma, nreg, wused=q
;IDL> help, q
;Q               LONG      = Array[344]
;IDL> plot, (smooth(add,5))[q], psy=1
;IDL> plot, x[q],(smooth(add,5))[q], psy=1
;IDL> linecolors
;IDL> plot, (smooth(add,5))[q], psy=1
;IDL> oplot, x[q],(smooth(add,5))[q], psy=1, col=3
;IDL> plot, x,(smooth(add,5)), psy=1
;IDL> oplot, x[q],(smooth(add,5))[q], psy=1, col=3
;IDL> chkarg,'find_changes
;---- Module: find_changes.pro
;---- From:   C:\ssw\gen\idl\util
;---> Call: pro find_changes, inarray, index, state, count=count, index2d=index2d
;IDL> z = where( q[1:*]-q eq 1)
;IDL> help, z
;Z               LONG      = Array[339]
;IDL> help, where(z eq 1)
;<Expression>    LONG      = Array[1]
;IDL> z = where( q[1:*]-q gt 5)
;IDL> help, z
;Z               LONG      = Array[2]
;IDL> print, z
;50         153
;IDL> print, q[z]
;53         184
;IDL> z = where( q[1:*]-q gt 10)
;IDL> print, q[z]
;53         184
;IDL> print, q[z+1]
;82         199
;IDL