;+
;
; Modifications:
;   19-Jul-2004, Kim.  Moved preview method out of spex__define to here
;   11-Aug-2004, Kim.  In plot_setup, check if # energy bins is 1, and if so,
;     don't try to plot spectrum or spectrogram.
;   16-Sep-2004, Kim.  Added show_err option in plot_setup method.
;   18-Nov-2004, Sandhia.  Added code to manage XSM-specific data.
;   17_Aug-2005, Kim.  Added spex_deconvolved, spex_pseudo_livetime to preview args.
;   13-Feb-2006, Kim.  In set method, handle invalid FITS files - use status keyword in
;     getpar call and print error message for bad or not found files
;     In plot_setup, call get_plot_title to get title
; 26-May-2006, Kim.  Added spex_data_pos to args.
; 23-Jun-2006, Kim.  Added get_source_pos method
; 30-Jun-2006, Kim.  Added tband (in set and intervals pre and post hook methods)
; Jun 2006,    Kim.  Added SPEX__SPECFILE strategy, Changed preview to do a getdata
;   and get the info from the obj (previously tried to keep preview separate, not putting
;   the data in the obj, but it's not worth it).  Made dim1_sum=0 the default for time plots.
; 13-Sep-2006, Kim.  In plot_setup, call spex_apply_drm for errors too if photons
; 31-Oct-2006 A.B. Shah - New SOXS .les identified by 'soxs' or 'corr' in file name
; 13-Jun-2007, Kim. Added SPEX_MESSENGER_SPECFILE strategy
; 25-Mar-2008, Kim. In plot_setup, name xlog, ylog in args, and use checkvar to set them
; 28-Mar-2008, Kim. In set, check just file part of name for 'fits', not entire path
; 29-Apr-2008, Kim. use uppercase when checking for xrs in file name for MESSENGER data
; 16-Jun-2008,  Kim. spex_specfile is now allowed to be an array.  Use file[0] in most cases
;   where it is treated as a scalar.
; 31-Mar-2009, Kim.  soxs files now identified by .les extension
; 04-Aug-2009, Kim.  In intervals_pre_hook, ensure that spex_eband is float
; 17-Sep-2009, Kim. Added setunits method
; 28-Oct-2009, Kim. Added fermi gbm  strategy
; 27-Nov-2009, Kim. Added yohkoh wbs strategy.  Also, in set, added dialog keyword for popup widget
;   for data type selection for yohkoh and soxs (have multiple data types in one file)
; 18-Feb-2010, Kim. Get data type classes from function spex_datatypes, instead of hardcoded. Next - 
;   should make setting the data strategy table-driven. 
;   Also added spex_accum_time to set, so can change to sec.
; 07-Jul-2010, Kim.  Added select_type method.  For files that contain more than one type of data,
;   this selects which type, either through a widget selection tool, or by looking at spex_data_sel param.
;   Call new method for SOXS and YOHKOH_WBS data.  Also, call locate_file instead of just assuming
;   spex_specfile is in cur dir (will implement spex_data_dir later)
; 25-Jan-2011, Kim. Added Fermi LAT.  Restructured set method to use is_fits function and
;   get_fits_instr, and use them for determining data type.
; 23-Feb-2011, Kim. In set, call getpar and getheader with /silent
; 31-Oct-2011, Kim. In set, sort spex_specfile before setting so they will be in time order
; 7-Nov-2011, Kim. When only have one file, the sort in previous change turned spex_specfile into a vector, which 
;   caused other problems for data types (like RHESSI) that are expected to have a single file. Only do sort for 
;   multiple files.
;   04-Oct-2012, Kim.  Added is_image_input method
; 19-Feb-2013, Kim.  Added SMM HXRBS.
; 27-Jul-2013, richard.schwartz@nasa.gov Make stx_obj_spectrogram (name may change) from spex_data object.  
; So this is really a spex object that is used in OSPEX with a few new methods
;-
;---------------------------------------------------------------------------

pro stx_obj_spectrogram_test

o =  stx_obj_spectrogram()
;o->set,  spex_spec =  '../ospex/hsi_spectrum_20031028_110633.fits'
o->set, spex_specfile = 'hsi_spectrum_20020220_105002.fits'
sp =  o->getdata()
help,  sp,  /struct
info =  o -> get( /info )
help,  info,  /struct
obj_destroy, o

o = ospex(/no_gui)

o->set, spex_specfile = 'hsi_spectrum_20020220_105002.fits'
o->set, spex_drmfile = 'hsi_srm_20020220_105002.fits'
;o->set, spex_specfile = 'hsi_spectrum_20020421_004040.fits'
;o->set, spex_drmfile = 'hsi_srm_20020421_004040.fits'

o-> set, spex_bk_time_int = [['20-Feb-2002 10:56:23.040', '20-Feb-2002 10:57:02.009'], $
  ['20-Feb-2002 11:22:13.179', '20-Feb-2002 11:22:47.820'] ]

o->set, spex_eband=get_edge_products([3,22,43,100,240],/edges_2)

o->set, spex_fit_time_inte = [ ['20-Feb-2002 11:06:03.259', '20-Feb-2002 11:06:11.919'], $
  ['20-Feb-2002 11:06:11.919', '20-Feb-2002 11:06:24.909'], $
  ['20-Feb-2002 11:06:24.909', '20-Feb-2002 11:06:33.570'] ]


o->set, spex_erange=[19,190]

o->set, fit_function='vth+bpow'

o->set, fit_comp_param=[1.0e-005,1., .5, 3., 45., 4.5]
o->set, fit_comp_free = [0,0,1,1,1,1]
o->set, fit_comp_min = [1.e-20, .5, 1.e-10, 1.7, 10., 1.7]

o->set, spex_fit_auto=1
o->set, spex_autoplot_enable=1

o->gui
o->dofit, /all

o->fitsummary

obj_destroy, o

print,  'test with the spex gui'
o = ospex( /no )
o->set,  spex_specfile = 'hsi_spectrum_20020220_105002.fits'
o->set,  spex_drmfile =  'hsi_srm_20020220_105002.fits'
o->gui
obj_destroy,  o

o =  stx_obj_spectrogram()
;o->set,  multi_fits = 'test_cube_small.fits'
o->set,  spex_specfile = 'test_cube_small.fits'
data =  o->getdata()
help,  data
o->set,  spex_specfile = 'hsi_spectrum_20020220_105002.fits'
o->set,  spex_drmfile =  'hsi_srm_20020220_105002.fits'
data2=  o->getdata()
help,  data2
obj_destroy,  o

o =  ospex()
;o->set,  spex_specfile = 'test_cube_small.fits'
;o->set,  multi_fits = 'test_cube_small.fits'
o->set, spex_specfile = 'hsi_imagecube_20040421_1500_14x2.fits'

o->gui
obj_destroy,  o

o =  ospex()
o->set,  spex_specfile = 'cc_60s_ispec_1311.fits'
o->xfit

o->gui
o =  stx_obj_spectrogram()
o->set,  spex_specfile = 'cc_60s_ispec_1311.fits'
data =  o->getdata()
help,  data


end
;------------------------------------------------------------------------
;stx data creation demo
;
;
pro stx_obj_spectrogram::input_demo, _extra=_extra
stx_obj_spectrogram_demo, _extra=_extra, Self=Self

end
;------------------------------------------------------------------------
;;To set data directly into OSPEX, you must use the command line to select the 'SPEX_USER_DATA' input strategy and input your data with commands like the following: 
;
;This routine performs the handoff between a stx_rate format input and the spex_user_data format
;  Done internally o -> set, spex_data_source = 'SPEX_USER_DATA'
;   rate_array = rate_array,  $  internally spectrum_array is counts externally RATE= RATE_ARRAY
;   ct_edges = energy_edges, $   for this routine it is 
;   ut_edges = ut_edges, $
;   erate = erate, $
;   livetime = livetime
;   
;where
;rate_array - the spectrum or spectra you want to fit as a rate, dimensioned n_energy, or n_energy x n_time.
;energy_edges - energy edges of spectrum_array, dimensioned 2 x n_energy.
;ut_edges - time edges of spectrum_array
;   Only necessary if spectrum_array has a time dimension.  Dimensioned 2 x n_time., time in anytim format
;erate    - array must match spectrum_array dimensions. If not set, defaults to all zeros.
;livetime - array must match spectrum_array dimensions.  If not set, defaults to all ones.
;
;You must supply at least the spectrum array and the energy edges.  The other inputs are optional.   By default, the DRM is set to a 1-D array dimensioned n_energy of 1s, the area is set to 1., and the detector is set to 'unknown'.  To change them, use commands like the following:


;
;
pro stx_obj_spectrogram::data_input, $
                        rate=rate, $
                        ut_edges=ut_edges, $
                        livetime=livetime, $
                        erate=erate, $
                        ct_edges=ct_edges,$
                         _extra=_extra

Self->Set, _extra=_extra
;
; 
default, livetime, 1
dim_rate = size(/dimensions, rate)
dim_livetime = size( /dimensions, livetime )
dim_erate = size(/dimensions, erate)
dim_ut  =  size(/dimensions, ut_edges)
if dim_ut[1] ne last_item( dim_rate) then begin
  help, rate
  help, ut_edges
  message, 'Rate array and UT_edges array have inconsistent dimensions. No data set'
  return
  endif
livetime = same_data2( dim_rate, dim_livetime) ? livetime : fltarr( dim_rate ) + 1.0
erate = same_data2( dim_rate, dim_erate) ? erate : fltarr( dim_rate ) 
dt = get_edges(/width, ut_edges)
dt = ( fltarr( dim_rate[0] ) + 1.0 ) # dt
stx_count = rate * livetime  * dt
stx_count_error = erate * livetime * dt

Self->set, spex_data_source = 'spex_user_data'

stx_count_error = sqrt( stx_count)
self->set, spectrum=stx_count, $
  spex_ct_edges = ct_edges , $
  spex_ut_edges = ut_edges, $
  errors = stx_count_error,$
  livetime = livetime

end



;--------------------------------------------------------------------------

pro stx_obj_spectrogram__define

dummy = {stx_obj_spectrogram, $
         inherits spex_data }

end