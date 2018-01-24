;+
;Name: stx_obj_creation_demo
;
;;read in data set through gui or cmd line using script
;energy_binning=round( [(findgen(16)+4),20d*(150/20)^(dindgen(16)/16),150])
;hessi_data, sp=sp
;sp->set, sp_energy_binning= energy_binning
;;write hsi_spectrum hsi_srm FITS files, use diag srm for simplicity
;
;;IDL> print, file_search('*.fits')
;hsi_spectrum_20020220_105020.fits hsi_srm_20020220_105020.fits
;Use ospex to get background. All of that is done in the script
;History: 
; 27-jul-2013, richard.schwartz@nasa.gov, 
;-
pro stx_obj_spectrogram_demo, _extra=_extra, self=self, stx_obj=stx_obj, spex_obj= spex_obj
ospex_script_26_jul_2013, obj=spex_obj, demo_input_dir = demo_input_dir  
;Diagonal response
d = spex_obj->getdata()
eff= spex_obj->getdata(class='spex_drm')
;Get the background rate after using the OSPEX background tool
bk =spex_obj->getdata(class='spex_bk',spex_units='rate')


rate = spex_obj->getdata(spex_units='rate')
ut = spex_obj->getaxis(/ut, /edges_2)

ct_edges = spex_obj->get(/spex_ct_edges)
stx_drm = stx_build_drm( ct_edges )

;convert rhessi photon rate using diagonal approximation
AU = 0.5
grid_tran = 0.25
ndet = 30.0
dim = size(/dimensions, rate.data)
stx_rate = ndet * grid_tran * (1.0/AU)^2 * $
  stx_drm.smatrix # ( (rate.data - bk.data)/ rebin( eff, dim ) * rebin( stx_drm.ewidth, dim) ) 

dt = get_edges(/widt, ut)

dt = (fltarr(dim[0],1)+1.)#get_edges(/widt, ut)
livetime = dt
stx_erate = f_div ( sqrt( stx_rate * livetime) , livetime )
livetime = f_div( livetime, livetime)
;s = stx_obj_spectrogram()
stx_obj = is_class( Self, 'stx_obj_spectrogram') ? Self : stx_obj_spectrogram()
stx_obj->data_input, $
  rate = stx_rate, $
  erate = stx_erate, $
  livetime = livetime, $
  ut_edges =ut,  $
  ct_edges = ct_edges

stx_obj->plotman
stx_obj->plotman, /pl_spec
end
