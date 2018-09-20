;+
; Name: HSI_DECIMATE_OBSSUM
;
; Call:
;	obs_summ_rate = hsi_decimate_obssum( edg, all_cnt, dcm_chn, dcm_wt, date)
;
; Purpose:
;	This function takes an input spectrum of energy bins, 9 front segs, number of models, number of atten states
;	and bins them into 5 obs_summ_rates with the same remaining dimensions.  It also decimates them
;	by the decimation digital bin (dcm_chn) and the decimation weighting factor (1,2,3,4, ...)
;
; History
;	May 2011, ras
;
;-
function hsi_decimate_obssum, edg, all_cnt, dcm_chn, dcm_wt, date
;input a count spectrum on channels defined by edg
;all_cnt should be  fltarr(nedg, 9, nbin) ;energy bins, 9 front segs, number of models, number of attenuator states
hsi_rd_ct_edges, 10, ee ;
ee = ee[0:5] ;3.00000      6.00000      12.0000      25.0000      50.0000      100.000
;edg must have ee values or generate error
test = where_arr( edg, ee, c)
if c ne n_elements(ee) then message,'edg arrary must lie on obs_summary bin boundaries
all_lt = all_cnt * 0. + 1
if dcm_chn gt 0 and dcm_wt gt 1 then begin
	cf = (hsi_get_e_edges(/coeff,gain_time=date))[0:8,*] ;energy at chan 0, low edg, gain in keV per chan
	xenrg = dcm_chn*cf[*,1]+cf[*,0]
	ixchn = value_locate( edg, xenrg)
	frac = (xenrg - edg[ixchn])/(edg[ixchn+1]-edg[ixchn])
	frac_lt = frac/dcm_wt+ (1.-frac) ;multiply true cnt by this to get predict cnts
	for i=0,8 do all_lt[0:ixchn[i],i,*,*] = [all_lt[0:ixchn[i]-1,i,*,*]/dcm_wt,all_lt[ixchn[i],i,*,*]*frac_lt[i]]
	endif
dims = size(/dimension, all_cnt)
dims[0] = 5
decim_cnt = fltarr(dims)
for i=0,4 do decim_cnt[i,*,*,*] = total( all_cnt[test[i]:test[i+1]-1,*,*,*]*all_lt[test[i]:test[i+1]-1,*,*,*], 1)
return, decim_cnt
end

