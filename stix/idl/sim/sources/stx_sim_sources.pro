;+
; :description:
;    This procedure simulates the detector counts recorded in all STIX
;    pixels from a given sources distributions, shapes (point, Gaussian, loop) and
;    intensities
;    
;    
; :modification history:
;     4-Jan-2013 - Tomek Mrozek (Wro), initial release
;
;-

pro stx_sim_sources, filename=filename, x_off=x_off, y_off=y_off

;If offset of the STIX z axis with regards to the Sun center is not defined
;it is assumed that there is no offset
if keyword_set(x_off) eq 0 then x_off=0d
if keyword_set(y_off) eq 0 then y_off=0d

;load the text file containing parameters of simulated 
;sources and converts it to "stx_sim_source" structure
sources=stx_sim_load_tabstructure(filename)

ph_struct=stx_sim_multisource_sourcestruct2photon(sources,x_off,y_off)

stx_sim_plot_photons, ph_struct, s_dist=sources[0].distance

end
