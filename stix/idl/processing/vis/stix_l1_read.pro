PRO stix_l1_read,sci_file,spec_all=spec_all,time_spec=time_spec,dspec_all=dspec_all,$
                 rspec_all=rspec_all,drspec_all=drspec_all,time_dur=time_dur,e0=e0,e1=e1,ee=ee,ddee=ddee,live32=live32, $
                 stop=stop,shift_by_one=shift_by_one

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
if keyword_set(shift_by_one) then begin
  ;stop
  time_dur_shift=time_dur
  time_dur_shift(1:-1)=time_dur(0:-2)
  time_dur=time_dur_shift
  data.timedel=time_dur_shift
endif


;triggers
t2det=stx_ltpair_assignment(dindgen(32)+1,/adgroup_idx)
;CFL and BKG
;print,t2det(8:9)
;    7       5
;assocated pair is
;print,t2det([7,15])
;    7       5
bkg_ratio = 1.1
cfl_ratio = 1.33
triggers32=data.triggers(t2det-1)
;CFL and det8
triggers32(8,*)=data.triggers(t2det(8)-1)/(1.+cfl_ratio)*cfl_ratio
triggers32(7,*)=data.triggers(t2det(7)-1)/(1.+cfl_ratio)
;BKG and det 16
triggers32(9,*)=data.triggers(t2det(9)-1)/(1.+bkg_ratio)*bkg_ratio
triggers32(15,*)=data.triggers(t2det(15)-1)/(1.+bkg_ratio)

;make rates
trates32=triggers32*0.
for i=0,31 do trates32(i,*)=triggers32(i,*)/time_dur

;livetime
;old values
eta = 2.5e-6
tau = 12.5e-6
;latest values
eta = 3.91e-6
tau = 11.0e-6

;incoming counts higher than measured triggers because of deadtime
; trates32*(tau+eta) gives deadtime, Ewan script
in32 = trates32 /(1. - trates32*(tau+eta))
;live time if all triggers would be processed
live32_no_double= 1/(1. + (tau+eta)* in32)
;live double triggers are not processed, i.e. reduction by exp( - eta*in32)=propability that they are no counts within eta
live32 = exp( - eta*in32) /(1. + (tau+eta)*in32)
for i=0,31 do live32(i,*)*=time_dur
;if in double is in same pixel, it will be processed. so live time is different for small and large pixels
;probability that second count is not in same large pixels

; REMOVE LATER
;det_tot=0.88*0.92
;spix=0.1*0.091
;lpix=(det_tot-4*spix)/8.
;p2_large=lpix/(2*det_tot)
;p2_small=spix/(2*det_tot)
;;probability that second count is in the same pixel
;same_large=1-p2_large
;same_small=1-p2_small
;live32_l = exp( - eta*in32*same_large) /(1. + tau* in32)
;live32_s = exp( - eta*in32*same_small) /(1. + tau* in32)


cccc=data.counts
ecounts=stix_cerror(data.counts,skm=control.COMPRESSION_SCHEME_COUNTS_SKM)
rrrr=cccc*0.
erate=ecounts*0.
;live32 = [det,time]
;cccc   = [energy,pixel,det,time]
for i=0,11 do begin
  for j=0,31 do begin
     rrrr(j,i,*,*)=cccc(j,i,*,*)/live32
     erate(j,i,*,*)=ecounts(j,i,*,*)/live32
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

