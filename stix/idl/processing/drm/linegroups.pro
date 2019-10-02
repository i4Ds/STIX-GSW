
file_search( concat_dir( getenv('ssw_stix'),'idl'),'*elut*.pro')
file_search(getenv('stx_dbase'),'elut_table*.csv')
f = file_search(getenv('stx_dbase'),'elut_table*.csv')

out = stx_read_elut(f[0])
chkarg,'stx_read_elut
stx_read_elut, gain, ofst, adc_str, elut_file=f[0]
.e stx_read_elut
help, adc_str
help, adc_str,/st
help, gain, ofst
adc_str = add_tag( adc_str, gain,'gain')
adc_str = add_tag( adc_str, ofst,'ofst')
help, adc_str
pmm, offset
pmm, ofst
plot, histogram( ofst, min = 200, max=360)
plot, histogram( ofst, min = 200, max=360), psym=10
adc1024grp = stx_energy2calchan( [30, 34, 79, 83.] )

e3033 = reform( [30.+fltarr(384),33+fltarr(384)]/reproduce( gain[*], 384*2), 384, 2) + reform( reproduce( ofst[*], 2), 384,2)
pmm, e3033[*,1]-e3033[*,0]
plot, histogram( e3033[*], min=300, max=450),psy=10
e7983 = reform( [79.+fltarr(384),83+fltarr(384)]/reproduce( gain[*], 384*2), 384, 2) + reform( reproduce( ofst[*], 2), 384,2)

pmm, e7983[*,1]-e7983[*,0]
e3033 = reform( e3033, 12, 32, 2)
mm=lonarr(2,32)
for i=0,31 do mm[0,i]= minmax( e3033[*,i,*])
print,mm
print,mm[1,*]-mm[0,*]

print,fix(avg( mm,0))

plot, histogram( fix( avg(mm, 0)),min=300,max=400),psym=10
plot, histogram( fix( avg(mm, 0)),min=300,max=400, bin=20),psym=10
