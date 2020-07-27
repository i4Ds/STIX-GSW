function hsi_extrct_flx, obs_time, dummy1, dummy2, name_states=name_states, corrected = corrected; , obj, om

  ;       0 SAA_FLAG
  ;       1 ECLIPSE_FLAG
  ;       2 FLARE_FLAG
  ;       3 IDPU_CONTROL
  ;       4 CRYOCOOLER_POWER
  ;       5 COLD_PLATE_TEMP
  ;       6 FRONT_RATIO_1225
  ;       7 COLD_PLATE_SUPPLY
  ;       8 HV28_SUPPLY
  ;       9 ACTUATOR_SUPPLY
  ;      10 FAST_HOUSEKEEPING
  ;      11 SC_TRANSMITTER
  ;      12 SC_IN_SUNLIGHT
  ;      13 SSR_STATE
  ;      14 ATTENUATOR_STATE
  ;      15 FRONT_RATIO
  ;      16 NON_SOLAR_EVENT
  ;      17 GAP_FLAG
  ;      18 DECIMATION_ENERGY
  ;      19 DECIMATION_WEIGHT
  ;      20 MAX_DET_VS_TOT
  ;      21 NMZ_FLAG
  ;      22 SMZ_FLAG
  ;      23 AAZ_FLAG
  ;      24 PARTICLE_FLAG
  ;      25 REAR_DEC_CHAN/128
  ;      26 PARTSTORM
  ;      27 HLAT
  ;      28 ECLIPSE_EXT
  ;      29 REAR_DEC_WEIGHT
  ;      30 FRONTS_OFF
  ;      31 BAD_PACKETS
  stix_data_dir = curdir()
  bad_times = anytim([['2003/05/21 23:58:42.680','2003/05/22 01:49:33.006'],$
    ['10-Sep-2003 00:00:00.000', '10-Sep-2003 07:20:00.000' ]])
  bad_times = bad_times[sort(bad_times)]
  obs_time= anytim( keyword_set(obs_time) ? obs_time :  anytim('20-aug-2002 08:24:16')+[0.,708])
  if ~evenodd((value_locate(bad_times, obs_time))[0]) then return, -1


  if ~(is_object( obj) && obj_isa(obj,'hsi_obs_summary')) then obj = hsi_obs_summary()
  if ~(is_object( om) && obj_isa(om,'hsi_monitor_rate')) then om = hsi_monitor_rate()
  ;obs_time=anytim('20-feb-2002 10:00:00')+[0.,7200]

  obj->set, obs_time=obs_time
  obs_time = obj->get(/obs_time)
  d = obj->getdata(class='full_rate', corrected = corrected)
  if ~is_struct(d) then return, -1
  ut2 = obj->getaxis(/ut,/edges_2)
  flags = obj->getdata(class='flag')
  flg_info = obj->get(/info,class='flag')
  flag_changes = obj->changes()
  om->set, obs_time=obs_time
  mdata=om->getdata()

  det_id = [0,2,3,4,5]
  dsum = avg(d.countrate[*,det_id],1) ;3-6, 6-12, 12-25,25-50,50-100 keV
  d5 = dsum[[0,1,2,3,4],*]
  ;flag key SAA,0, eclips,1, flare,2 atten, 14, gap,17, dcm_chan,18, dcm_wt,19, bad,31
  keys = [0,1,2,14,17,18,19,31]
  iflag = replicate( {SAA:0, eclipse:1,flare:2,atten:14,gap:17,dcm_chan:18,dcm_wt:19,bad:31},n_elements(flags))
  for i=0,n_elements(keys)-1 do iflag.(i)=flags.flags[keys[i]]
  ;generate base count/sec models
  ;mdl_str =0
  hsi_mk_100kev_resp, mdl_str, out_dir=stix_data_dir;,/reset
  ;restgen,file=concat_dir( stix_data_dir, 'rhessi_bkg97'), edg97, bkg97, units97
  ;bkg = rebin( bkg97, 97, 9, 3)

  ;find contiguous states, same atten_state, dcm_chn, dcm_wt,
  all_state = ulonarr(3, N_elements(flags))
  all_state[0,0] = transpose([ [iflag.atten],[iflag.dcm_chan], [iflag.dcm_wt]]) ;atten dcm_chan
  all_state_vec = ([65536uL, 256ul, 1ul]#all_state)[*]

  find_changes, all_state_vec, index, state
  index =[index, n_elements(all_state_vec)]
  ;for each state, build the obs_summ_rate with decimation and sum over detectors
  ;there will be [3,6,nstate] spectra
  ;obs_summ_rate = hsi_decimate_obssum( edg, all_cnt, dcm_chn, dcm_wt, date)
  ; help, mdl_str.counts
  ;<Expression>    FLOAT     = Array[97, 9, 3, 6]
  nstate = n_elements(state)
  nmodels = n_elements(mdl_str)
  obs_summ_pred = fltarr(5,9, nmodels,nstate)
  bkg_summ_pred = fltarr(5,9,1,nstate)

  for i=0,nstate-1 do for k=0,nmodels-1 do begin
    ifli = iflag[index[i]]
    obs_summ_pred[0,0,k,i] = $
      hsi_decimate_obssum( mdl_str[k].edg,  mdl_str[k].counts[*,*,ifli.atten<2], ifli.dcm_chan, ifli.dcm_wt, avg(obs_time))
    ;	if k eq 0 then bkg_summ_pred[0,0,0,i] = $
    ;hsi_decimate_obssum( mdl_str[k].edg,  bkg[*,*,ifli.atten<2], ifli.dcm_chan, ifli.dcm_wt, avg(obs_time))

  endfor
  bkg_summ5 = avg(bkg_summ_pred[0:4,det_id,0,*],1)
  obs_summ5 = avg(obs_summ_pred[0:4,det_id,*,*],1)

  for ix=0,nstate-1 do begin
    out = hsi_obssum_spec_state_par(ix, index, obs_summ5, d5, mdl_str, bkg_summ5, all_state_vec)
    if ix eq 0 then outarr = replicate( out[0], last_item(index))
    outarr[index[ix]] = out
  endfor

  ;Correct for livetime.  Multiply monitor livetime by 0.75 for datagaps

  if is_struct( mdata) then begin
    live = mdata.live_time
    ut_ref = om->get(/mon_ut_ref)
    ut_mn = mdata.time + ut_ref
    live = avg(live[det_id,*],0)*0.75
    live_obs = (interp2integ( ut2, ut_mn, live)/4) > .1 <1
    ;Integral = INTERP2INTEG( Xlims, Xdata, Ydata)
    ;adjust outarr for live_obs
  endif else live_obs = 0.75
  outarr.f_vth_par[0] /= live_obs
  outarr.f_pow_par[0] /= live_obs
  outarr.ut = avg( ut2, 0)
  if ~arg_present(obj) then obj_destroy, obj
  if ~arg_present(om) then obj_destroy, om

  struct_assign, outarr, out

  if keyword_set(name_states) then begin
    out = replicate( {hsi_obssum_spec_state_par3}, n_elements(outarr))
    struct_assign, outarr, out
    out.d5c = d5c
    out.atten = iflag.atten
    out.dstate = iflag.dcm_wt
    out.dchan  = iflag.dcm_chan
    out.live = live_obs
    out.night = iflag.eclipse
    out.flare = iflag.flare
    outarr = out
  endif


  return, outarr
end



