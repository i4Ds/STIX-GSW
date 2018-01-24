;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_test_fits_writer_1
;       
; :purpose:
;       Short demo of the spectrogram fits writer routines      
;
;  :category:
;       
;  :description:
;  
;       Generates an ivs result structure from a supplied flare scenario file - converts it to a regular spectrogram, 
;       builds a drm based on pixel area and finally writes spectrum FITS files with both the test dada and the spectrogram
;       which can then be read by OSPEX.
;   
; :params:
;       none
;       
; :keywords:
;       none
;         
; :returns:
;       Writes spectrum and drm fits files 
;       
; :calling sequence:
;       IDL> stx_test_fits_writer_1
; 
;
; :history:
;       24-Sep-2014 – ECMD (Graz) 
;-


;pro stx_test_fits_writer_1

;set short scenario with Gaussian flare 
scenario = 'stx_scenario_ed'

;generate the test data following method of run_ds_fswsim_demo to produce the data simulation 
;and flight software simulator objects
dss = obj_new('stx_data_simulation2')

iti = dss->getdata( scenario = scenario )

fsw = obj_new( 'stx_flight_software_simulator_clocked', start_time = stx_time() )

 for time_bin = 0L, 1000L-1 do begin
    ds_result_data = dss->getdata(output_target = 'stx_ds_result_data', time_bin = time_bin, scenario = scenario, rate_control_regime = 0)
    
    if(ds_result_data eq !NULL) then break
    ds_result_data.filtered_eventlist.start_time = stx_time()
    ds_result_data.triggers.start_time = stx_time()
    fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, plotting=1
 endfor
  
;set the flare flag to be active for all but the first and final time bins
ff = fsw.flare_flag
ffnew = [0b, bytarr(n_elements(ff.data)-2) + 1b, 0b]
fsw.flare_flag = ffnew

;generate the full interval selection structure 
ivs = fsw->getdata(output_target = "stx_fsw_ivs_result")

;make the regular spectrogram form the output ivs data
spec = stx_spcivs2spectrogram( ivs )

;artificial pixel mask of all pixels all detectors, as there isn’t anything turned off in the demos yet
pixel_mask = fltarr(12,32) + 1.


;get the energy edges for building the drm from the spectrogram 
ct_edges = spec.e_axis.edges_1
maxct = max( ct_edges )
ph_edges = [ ct_edges, maxct + maxct*(findgen(10)+1)/10. ]


;build the pixel scaled drm based on the input energy edges and pixel mask
srm = stx_build_pixel_drm(ct_edges, pixel_mask, ph_energy_edges = ph_edges)

;write the spectrogram and the drm into their respective spectrum FITS files
stx_write_ospex_fits, spectrum = spec, srmdata = srm, ph_edges = ph_edges

end
