; -----------------------------------------------------------------------------
;+
; :description:
;     This procedure defines stx_sim_source structure
;     Structure contains the basic information of simulated sources:
;                  name:       the name of the source (integer number)
;                  type:       type of source (e.g. 'point', 'gaussian', 'loop-like')
;                  xpos:       position of the source in respect to center of the Sun [arcseconds] - horizontal component
;                  ypos:       position of the source in respect to center of the Sun [arcseconds] - vertical component
;                  dx:         width of the source (a full-width at half-maximum) [arcseconds]
;                  dy:         height of the source (a full-width at half-maximum) [arcseconds]
;                  phi:        rotation of the source in degrees (counterclockwise)
;                  loopdy:     height of the loop (for loop-like source) [arcseconds]
;                  intensity:  total number of source source photons
;
; :todo:
;     Add the field containig information of energy distribution energies and time evolution of the source
;   
; :history:
;     28 Oct 2012 - Marek Steslicki (Wro), written
;     10-Feb-2013 - Marek Steslicki (Wro), size and position units
;                   changed to arcseconds
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified tag names during
;                   merging with STX_SIM_FLARE.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), now anonymous structure,
;                   'type' tag changed to 'shape' and 'name' tag
;                   changed to 'source'
;     06-Nov-2013 - Shaun Bloomfield (TCD), removed previous quickfix
;                   'name' tag
;     29-Jul-2014 - Laszlo I. Etesi (FHNW), - added * 'source_id',
;                                                   * 'sub_source_id'
;                                                   * 'start_time',
;                                                   * 'time_distribution',
;                                                   * 'energy_distribution'
;                                           - named structure again
;     06-Aug-2014 - Laszlo I. Etesi (FHNW), changed duration to double
;     04-Dec-2014 - Shaun Bloomfield (TCD), changed energy_spectrum_params1/2
;                   to floating-point values (were integer before)
;     05-Dec-2014 - Shaun Bloomfield (TCD), added time and energy
;                   distribution types into comment lines and the
;                   32-element background effective area multiplier
;                   array tag
;     05-Dec-2014 - Laszlo I. Etesi (FHNW), small typo fixed (missing comma)
;     10-Jan-2015 - Aidan O'Flannagain (TCD), changed flux type from LONG to
;                   FLOAT in order to accommodate very small fluxes (<1)
;     05-Mar-2015 - Shaun Bloomfield (TCD), added time_distribution_param1/2
;     11-Oct-2016 - Laszlo I. Etesi (FHNW), added detector and pixel override parameter (testing)
;     17-MAr-2017 - Shane Maloney (TCD), change type of source_id and source_sub_id to prevent overflows
;     
;-
function stx_sim_source_structure
  
  sourcestr={ stx_sim_source,                  $
              source_id:1s,                    $ ; source number, identifies the main 'physical' source
              source_sub_id:1s,                $ ; sub source number, identifies a partial source
              start_time:0d,                   $ ; relative start time since the beginning of a scenario
              shape:'point',                   $ ; source shape ['point', 'gaussian', 'loop-like']
              xcen:0.d,                        $ ; position of the source in respect to center of the Sun - horizontal [arcseconds]
              ycen:0.d,                        $ ; position of the source in respect to center of the Sun - vertical [arcseconds]
              duration:1d,                     $ ; source duration [s]
              flux:10000.,                     $ ; source photon flux [photons cm^-2 s^-1]
              distance:1.,                     $ ; distance from source to spacecraft [AU]
              fwhm_wd:20.d,                    $ ; width of the source [arcseconds]
              fwhm_ht:15.d,                    $ ; height of the source [arcseconds]
              phi:0.d,                         $ ; rotation of the source [degrees]
              loop_ht:10.d,                    $ ; height of the loop (for loop-like source) [arcseconds]
              time_distribution:'uniform',     $ ; defines the time spectrum ['uniform', 'linear', 'gaussian', 'exp']
              time_distribution_param1:0.,     $ ; first time distribution parameter
              time_distribution_param2:0.,     $ ; second time distribution parameter
              energy_spectrum_type:'powerlaw', $ ; defines the energy spectrum ['powerlaw', 'uniform']
              energy_spectrum_param1:1.,       $ ; first energy spectrum parameter
              energy_spectrum_param2:5.,       $ ; second energy spectrum parameter
              background_multiplier:fltarr(32),$ ; array of 32 subcollimator background effective-area multiplier values
              detector_override:0b,            $ ; used for testing purposes, will direct all background counts towards that detector and pixel \
              pixel_override:0b                $ ; not compatible with background_multiplier, value 0 -> inactive, pixel: 1-12, detector: 1-32
            }
  
  return, sourcestr
  
end
