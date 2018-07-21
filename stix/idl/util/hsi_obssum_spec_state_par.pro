function hsi_obssum_spec_state_par, ix, index, obs_summ5, d5, mdl_str, bkg_summ5, state_vec
;mdl_str contains the function parameters used to determine
;obs_summ5 -= Array[nchannels, nmodels, nstates]
;ix - specifies index
;index - starting index for each separate state, points to the bins in d5
;a state is a contiguous series of time bins with the same decim_channel, decim_weight and atten_state
;obs_summ5 nstates is for each state
;d5 - [nchannels, nbin] - each bin is a separate time integration.
;BKG_SUMM5 FLOAT     = Array[nchannels,  1, nstates] ;measured lowest background summed by decim_channel and decim_weight

;return f_vth and f_pow (really f_pow) parameters
nmodel = n_elements(mdl_str)
nbin = index[ix+1]-index[ix]
x = lindgen(nbin)+index[ix]
o5 =  obs_summ5[*,*,ix]
d5x = d5[*,x]-rebin(bkg_summ5[*,0,ix],5,1,nbin)
;get f_pow par from d5x[3,*] and 05[3,nmodel-1]
out = replicate( {hsi_obssum_spec_state_par}, nbin)
out.f_pow_par[0]= reform(d5x[3,*]/o5[3,nmodel-1]) >0
out.f_pow_par[1]= mdl_str[nmodel-1].apar[1]
r2 =  (d5x[2,*]- o5[2,nmodel-1]*out.f_pow_par[0])>0
r1 =  (d5x[1,*]- o5[1,nmodel-1]*out.f_pow_par[0])>0
ratio = f_div(r2,r1)
;no isolated points should have temps gt min
z = where( ratio gt 0, nz)
if nz gt 0 and nbin ge 2 then begin
	zn = where( ratio[z-1>0] eq 0 and ratio[z+1<(nbin-1)] eq 0, nzn)
	if nzn gt 0 then ratio[z[zn]] = 0
	;check first and last
	if ratio[1] eq 0 then ratio[0] = 0
	if ratio[nbin-2] eq 0 then ratio[nbin-1]=0
	endif
rmodel = o5[2,0:nmodel-2]/o5[1,0:nmodel-2]
ixmodel = value_locate( rmodel, ratio)>0
out.f_vth_par = reform( mdl_str[ixmodel].apar)
out.f_vth_par[0] = reform(r1 / o5[1,ixmodel])
out.d5 = d5x
out.state = state_vec[x]
return, out
end