PRO stix_l1_read,sci_file,spec_all=spec_all,time_spec=time_spec,dspec_all=dspec_all,rspec_all=rspec_all,drspec_all=drspec_all,time_dur=time_dur,e0=e0,e1=e1,ee=ee,ddee=ddee,stop=stop

;reads L1 fits file and extracts counts in array = [tdim,ddim,pdim,edim]
; stix_l1_read,'solo_L1_stix-sci-xray-l1-1178428688_20200607T213708-20200607T215208_V01.fits',spec_all=spec_all,dspec_all=dspec_all,rspec_all=rspec_all,drspec_all=drspec_all,time_spec=time_spec,e0=e0,e1=e1,ee=ee,ddee=ddee


;new fits files
tmp = mrdfits(sci_file, 0, header)
data = mrdfits(sci_file, 2, data_header,/unsigned)
energy = mrdfits(sci_file, 3, energy_header)
control = mrdfits(sci_file, 1, control_header)

base_time = anytim(sxpar(header,'DATE_OBS'))
tttt = anytim(base_time) + data.time
tdim=n_elements(data.time)
time_spec=tttt
time_dur=data.timedel

;triggers
t2det=stx_ltpair_assignment(dindgen(32)+1,/adgroup_idx)
triggers32=data.triggers(t2det-1)
dead32=12.5d-6*triggers32
live32=dead32*0.
for i=0,31 do live32(i,*)=data.timedel-dead32(i,*)

cccc=data.counts
ecounts=stix_cerror(data.counts,skm=control.COMPRESSION_SCHEME_COUNTS_SKM)
rrrr=cccc*0.
erate=ecounts*0.
;live32 = [energy,time]
;cccc   = [energy,pixel,det,time]
for i=0,11 do begin
  for j=0,31 do begin 
     rrrr(*,i,j,*)=cccc(*,i,j,*)/live32
     erate(*,i,j,*)=ecounts(*,i,j,*)/live32
  endfor
endfor


;energy bins
e0=energy.e_low
e1=energy.e_high
ee=(e1+e0)/2
ddee=e1-e0
edim=n_elements(e0)

;IDL> help,data.counts
;<Expression>    DOUBLE    = Array[32, 12, 32, 45]
; [energy,pixel,det,time]

;rearrange how I like it
ddim=32  ;now always all detectors
edim=32  ;now all energy bins
pdim=12  ;now all pixels
spec_all=fltarr(tdim,ddim,pdim,edim)
dspec_all=spec_all
rspec_all=spec_all
drspec_all=spec_all
for i=0,tdim-1 do begin
  for j=0,ddim-1 do begin
    for n=0,pdim-1 do begin 
      spec_all(i,j,n,*)=cccc(*,n,j,i)
      dspec_all(i,j,n,*)=ecounts(*,n,j,i)
      rspec_all(i,j,n,*)=rrrr(*,n,j,i)
      drspec_all(i,j,n,*)=erate(*,n,j,i)
    endfor
  endfor
endfor

if keyword_set(stop) then stop

END

