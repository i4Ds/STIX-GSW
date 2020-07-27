;---------------------------------------------------------------------------
;+
; project:
;       STIX
;
; :name:
;       stx_ospex_fits_demo
;       
; :purpose:
;       A demo script which will create a spectrogram from a specified scenario file. This data is then 
;       written into spectrum and srm fits files. Then creates an ospex object and loads the generated files.
;       
; :category:
;       simulation, spectra
;       
; :description:
;       Starting with a scenario file this script runs the data simulation and the flight software simulator.
;       A spectrogram of the count data is created from the level 1 output of the interval selection 
;       algorithm. A detector response matrix using the standard 32 STIX energy channels in count space 
;       with a high energy extension in photon space scaled to the total area of the pixels used is also generated.       
;       
; :params:
;       none
;       
; :keywords:
;       scenario_name :             in, optional, type="string", 
;                                   The name of the scenario .csv file on which to run the demo. 
;                                   The file should be located in \stix\dbase\sim\scenarios                  
;       
; :calling sequence:
;       IDL> stx_ospex_fits_demo, scenario_name = 'stx_scenario_2'
;       
; :history:
;       12-Dec-2014 – ECMD (Graz), initial release (primarily based on stx_test_fits_writer_1)
;       
;-
pro stx_ospex_fits_demo, scenario_name = scenario_name

; If no scenario is specified default to Scenario 2
default, scenario_name, 'stx_scenario_2'

; Run the simulation of the specified scenario 
stx_software_framework, scenario_name = scenario_name, /run_simulation, dss = dss, fsw = fsw
;restore, 'stixidldemosavstx_scenario_2_dss.sav'
;restore, 'stixidldemosavstx_scenario_2_fsw.sav

;set the flare flag so the intervals will be processed by the interval selection algorithm 
;ff = fsw.flare_flag
;ffnew = [0b, bytarr(n_elements(ff.data)-2) + 1b, 0b]
;fsw.flare_flag = ffnew

; as scenario 2 does not trigger the flare flag a flare time has to be set artificially
flare_time = {$
  type            : "stx_fsw_flare_selection_result", $
  is_valid        : 1b, $
  flare_times     : reform([stx_construct_time(time=104.0),stx_construct_time(time=240.0)],1,2), $
  continue_time   : stx_time() $
}

help, flare_time

;to ensure the time boundaries remain aligned the trimming is set to 0
fsw->set, module="stx_fsw_module_intervalselection_img", trimming_max_loss = 0.0d


;run the interval selection for the given flare time
ivs = fsw->getdata(output_target="stx_fsw_ivs_result", input_data=flare_time)

;run the interval selection algorithm on the fsw object
;ivs = fsw->getdata(output_target = "stx_fsw_ivs_result")

;create a spectrogram structure from the level 1 interval selection data
spec = stx_l1_spc_ivs2spectrogram( ivs )

;artificial pixel mask of all pixels all detectors
pixel_mask = fltarr(12,32) + 1.

;get the energy edges for building the drm from the spectrogram 
ct_edges = spec.e_axis.edges_1
maxct = max( ct_edges )
ph_edges = [ ct_edges, maxct + maxct*(findgen(10)+1)/10. ]

;build the pixel scaled drm based on the input energy edges and pixel mask
srm = stx_build_pixel_drm(ct_edges, pixel_mask, ph_energy_edges = ph_edges)

;set the names of the fits files to make them easier to load later
specfilename = scenario_name + '_spectrum.fits'
srmfilename = scenario_name + '_srm.fits'

;write the spectrogram and the drm into their respective spectrum FITS files
stx_write_ospex_fits, spectrum = spec, srmdata = srm, ph_edges = ph_edges, $
  specfilename = specfilename, srmfilename = srmfilename

;create an ospex object
obj = ospex()

;set the file reader to stix and load the fits files 
obj->set, spex_file_reader = 'stx_read'
obj->set, spex_specfile = specfilename
obj->set, spex_drmfile = srmfilename

;stop
end
