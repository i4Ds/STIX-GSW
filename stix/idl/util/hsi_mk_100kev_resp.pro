pro hsi_mk_100kev_resp, models, use_vird=use_vird, edg=edg, reset=reset, out_dir=out_dir

default, out_dir, curdir()
file = concat_dir( out_dir, 'hsi_100kev_resp')
if file_exist(file+'.genx') && ~keyword_set(reset) then begin
	restgen, file=file, models
	return
	endif

default, edg,findgen(98)+3.
nedg = n_elements(edg)-1
if ~is_struct(models) then begin
	; powerlaw of 4, thermal .8,.9,...,3.7 keV, 3 atten states
	nmodels = 31
	models=replicate({model:'f_vth', apar:fltarr(2), edg:edg, counts:fltarr(nedg,9,3)},nmodels)
	models[nmodels-1].model = 'f_pow'
	models[nmodels-1].apar  = [1.,4.]
	for i=0,nmodels-2 do models[i].apar= [1,0.8+i*0.1]
	endif
;stop
default, use_vird,[bytarr(9)+1b,bytarr(9)]
;use pl of 4 in 25-50 to determine nt flux in 12-25
hessi_build_srm, edg, use_vird, srm0, /sep_vird, /sep_det, geo, all_simp=0,/pha_on_row, time_wanted = '20-feb-2002 11:06:00',atten=0
nbin = n_elements(get_edges(edg,/mean))
dims = size(/dim, srm0)
srm = fltarr( [dims,3])
srm[0,0,0,0] = srm0
atten = [1,3]
for i=0,1 do begin &$
	hessi_build_srm, edg, use_vird, srmi, /sep_vird, /sep_det, geo, all_simp=0,/pha_on_row, time_wanted = '20-feb-2002 11:06:00',atten=atten[i] &$
	srm[0,0,0,i+1] = srmi &$
	endfor

nmodel = n_elements(models)


for iseg=0,8 do for j=0,2 do for k=0,nmodel-1 do models[k].counts[*, iseg, j] = $
	hsi_spec_counts( edg, srm[*,*, iseg,j],models[k].model,models[k].apar)>1e-10

savegen, models, file=file
end