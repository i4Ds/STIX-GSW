;---------------------------------------------------------------------------
; Document name: stx_img_spectra__define.pro
; Created by:    Andre Csillaghy, March 4, 1999
;
; Last Modified: Mon Apr 23 14:19:32 2001 (csillag@soleil)
;---------------------------------------------------------------------------
;
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_img_spectra CLASS
;
; PURPOSE:
;
;       Given an input of a set of image intervals, return the intervals for summing for spectra or lightcurves
;
; CATEGORY:
;       Objects
;
; CONTRUCTION:
;       o = Obj_New( '' )
;       or
;       o = ( )
;
; INPUT (CONTROL) PARAMETERS:
;       Defined in {_control}
;
; SEE ALSO:
;       _control__define
;       _control
;       _info__define
;
; HISTORY:
; Created by:  rschwartz70@gmail.com
;
; Last Modified: 14-jun-2014
;                8-jul-2014, changed index_erange to this_index_erange in time_bins_4_energy()
;                index_erange = n_elements( index_erange ) eq 2 ? this_index_erange : Self->Get( /index_erange )
;                 to
;                index_erange = n_elements( this_index_erange ) eq 2 ? this_index_erange : Self->Get( /index_erange )
;                changed
;                if keyword_set( img )  && is_struct( ptr_valid(img) ? *img : img )   then begin
;                to
;                if keyword_set( img )  && is_struct( ptr_valid(img[0]) ? *img : img )   then begin
;                removed spectroscopy boxes on ingest of img boxes
;                added mod_img info paramater same as img control parameter image set but with added tags for convenience
;                 meant for internal use
;                removed sort by time as this was unnecessary, not setup_time is used to extract intervals from the input
;                img set and add tags to mod_img
;                fixed the sum_time_groups where the 2D histogram for the sum had been set up incorrectly
;                6-oct-2014, RAS, fixed bug in energy axis definition inside of Sum_Time_Groups()
;                28-feb-2018, RAS, using standard formatting
;-
pro stx_img_spectra_demo, simg
  ;See below for the output log of the demo
  ;It also produces a figure showing the spectrogram boundary for the default erange of 16.0 - 52.915 keV
  simg = obj_new( 'stx_img_spectra' )
  help, simg->get( /control ),/st

  help, simg->Get( /mod_img )
  help, simg->Get( /mod_img ), /st
  help, simg->get(/erange ) ;initial energy selection
  print, simg->get(/erange ) ;initial energy selection
  print, simg->get(/_info )
  help, simg->get(/_info )
  ;Now process the parameters to make a plot and a spectrogram
  spect_struct = simg ->sum_time_groups( /mk_struct )
  help, spect_struct
  simg -> plot
  help, simg->Get( /info )
end
;IDL> simg = obj_new( 'stx_img_spectra' )
;% RESTORE: Portable (XDR) SAVE/RESTORE file.
;% RESTORE: Save file written by raschwar@GS671-DECKARD, Fri Jun 20 12:23:59 2014.
;% RESTORE: IDL version 8.1 (Win32, x86_64).
;% RESTORE: Restored variable: IOUT.
;IDL> help, simg->get( /control ),/st
;** Structure <a627c90>, 2 tags, length=78088, data length=76136, refs=1:
;   IMG             STRUCT    -> <Anonymous> Array[976]
;   ERANGE          FLOAT     Array[2]
;IDL> help, simg->get( /mod_img )
;<Expression>    STRUCT    = -> <Anonymous> Array[976]
;IDL> help, simg->get( /mod_img ), /st
;** Structure <d81f6c0>, 8 tags, length=80, data length=78, refs=2:
;   TYPE            STRING    'stx_ivs_interval'
;   START_TIME      STRUCT    -> <Anonymous> Array[1]
;   END_TIME        STRUCT    -> <Anonymous> Array[1]
;   START_ENERGY    FLOAT           4.00000
;   END_ENERGY      FLOAT           6.00000
;   COUNTS          LONG              3209
;   TRIM            BYTE        10
;   SPECTROSCOPY    BYTE         0
; help, simg-> Get(/erange)
;<Expression>    FLOAT     = Array[2]
;IDL>print, simg->Get(/erange)
;      16.0000      52.9150
;IDL> print, simg->get(/_info )
;      -1
;IDL> help, simg->get( /info )
;<Expression>    INT       =       -1
;;Now process the parameters to make a plot and a spectrogram
;IDL> spect_struct = simg ->sum_time_groups( /mk_struct )
;IDL> help, spect_struct, /st
;** Structure <883b150>, 6 tags, length=2608, data length=2600, refs=1:
;   TYPE            STRING    'stx_spectrogram'
;   DATA            ULONG64   Array[14, 7]
;   T_AXIS          STRUCT    -> <Anonymous> Array[1]
;   E_AXIS          STRUCT    -> <Anonymous> Array[1]
;   LTIME           FLOAT     Array[14, 7]
;   ATTENUATOR_STATE
;                   INT       Array[14]
;IDL> simg->plot
;IDL> help, simg->get( /info )
;** Structure <d817b80>, 4 tags, length=1344, data length=1340, refs=1:
;   BOUNDARY_GRID   POINTER   <NullPointer>
;   UT_EDGE         DOUBLE    Array[158]
;   ENERGY_EDGE     FLOAT     Array[16]
;   INDEX_ERANGE    LONG      Array[2]
;IDL>


;--------------------------------------------------------------------

FUNCTION stx_img_spectra::INIT, SOURCE = source, _EXTRA=_extra

  ;IF NOT Obj_Valid( source ) THEN BEGIN
  ;    source =  obj_new( '_source' )
  ;ENDIF

  ;(*
  ; Here we pass the control and info parameters to the framework, and,
  ; optionally, the source object.
  ;*)
  CONTROL = stx_img_spectra_control()
  RET=self->Framework::INIT( CONTROL = control, $
    INFO={stx_img_spectra_info}, $
    ;SOURCE=source, $
    _EXTRA=_extra )
  ;
  Self->Set, img = control.img, erange= control.erange
  RETURN, RET

END
;--------------------------------------------------------------------

pro stx_img_spectra::setup_time
  ;This is to be used only by self->set when a new set of images in ingested
  img = Self->Get( /img )

  utst = stx_time2any( img.start_time )

  ut0  = min( utst )
  utst -= ut0

  utet = stx_time2any( img.end_time ) - ut0
  utmean = 0.5 * ( utst + utet ) + ut0
  img = add_tag( img, utmean, 'ut_mean' )
  img = add_tag( img, utst + ut0, 'uts' )
  img = add_tag( img, utet + ut0, 'ute' )
  ut_edge = get_uniq( [utst, utet], eps=1e-5 ) + ut0
  img = add_tag( img, value_locate( ut_edge - ut0, img.uts - ut0 + 0.05 ), 'iuts' )
  img = add_tag( img, value_locate( ut_edge - ut0, img.ute - ut0 + 0.05 ), 'iute' )

  Self->Set, ut_edge = ut_edge, mod_img = img

  Self->Framework::Set, img = img ;has to be by framework because self->set will send it back thru sort_by_time
end
;--------------------------------------------------------------------
function stx_img_spectra::time_bins_4_energy, boundary_grid, $
  this_index_erange = this_index_erange, time = time, _extra=_extra

  Self->Set, _extra = _extra

  ;time given by the row (first) index
  index_erange = n_elements( this_index_erange ) eq 2 ? this_index_erange : Self->Get( /index_erange )


  test = where(  total( boundary_grid[ *, index_erange[0]:index_erange[1] ], 2 ) eq ( index_erange[1] - index_erange[0] +1), nsuccess)

  return, test
end

;--------------------------------------------------------------------
function stx_img_spectra::build_valid_time_energy_grid, boundary_grid
  ;From the boundary grid, take all energy pairs and find the time boundaries that span all the energies
  ;between the two energy bin boundaries.
  ;First, dimension a 3 dimensional array of time boundaries, low energy, high energy
  ;We only will fill the upper right major elements of the grid, i.e. only fill the rows for time where the low energy is lt the high energy
  dim = size(/dimension, boundary_grid)
  valid_time_energy_grid = bytarr( dim[0], dim[1], dim[1] ) ;time bins x low energy x high energy
  ;Less than half of this grid is used only the upper major where for indices i, j, k where  j is lt k
  for ii = 0l, dim[1]-1 do for jj = 0l, dim[1] - 1 do begin
    ;apply the test to find all the spanning time boundaries
    if ii lt jj then test = Self->time_bins_4_energy( boundary_grid, this_index_erange = [ii, jj] ) $
    else test = -1
    if test[0] ne -1 then valid_time_energy_grid[ test, ii, jj ] = 1 ;mark the spanning time boundaries
  endfor
  return, valid_time_energy_grid
end
;---------------------------------------------------------------------------
;

PRO stx_img_spectra::Process, $
  _EXTRA=_extra

  Self->Set, _EXTRA=_extra

  ;set up the interval box boundary grid
  boundary_grid = Self->build_boundary_grid() ;also sets ut_edge and energy_edge sets for img control param
  ;from this grid set up the lookup table for a spectrogram between two energy boundaries
  img_spectra_valid = self->build_valid_time_energy_grid( boundary_grid )

  Self->setdata, img_spectra_valid

END
;--------------------------------------------------------------------

;--------------------------------------------------------------------
function stx_img_spectra::build_boundary_grid

  img = Self->Get( /mod_img )
  ut_edge = Self->Get( /ut_edge)
  ntb = n_elements( ut_edge )
  iut_edge_start = img.iuts

  iut_edge_end   = img.iute
  energy_edge = Self->Get(/energy_edge )
  ienergy_edge   = value_locate( energy_edge, img.start_energy )
  nev = n_elements( energy_edge )
  boundary_grid_start = bytarr( ntb, nev )
  boundary_grid_end   = boundary_grid_start
  boundary_grid_start[ iut_edge_start, ienergy_edge ] = 1b
  boundary_grid_end  [ iut_edge_end, ienergy_edge ] = 1b

  boundary_grid = boundary_grid_start + boundary_grid_end < 1 ;
  return, boundary_grid
end

function stx_img_spectra::getdata, $
  this_subset1=this_subset1, $
  this_subset2=this_subset2, $
  _extra=_extra

  ; first we call the predefined getdata in framework:
  Self->Set, _EXTRA=_extra
  data=self->framework::getdata(  )


  return, data

end

;--------------------------------------------------------------------


pro stx_img_spectra::set, $
  img = img, $
  erange = erange, $ ;does not cause reprocessing
  _extra=_extra

  if keyword_set( img )  && is_struct( ptr_valid(img[0]) ? *img : img )   then begin
    ;finds all ut_edge, orders img by time, and sets ut_edge into the control


    Self->framework::set, img = img
    img = Self->Get(/img)
    q = where( img.spectroscopy eq 0, nq)
    Self->framework::set, img = img[q] ;remove spectroscopy bins
    Self->setup_time
    img = Self->Get( /mod_img )
    img = add_tag( img, 0.5 * ( img.start_energy + img.end_energy ), 'mean_energy' )
    energy_edge = get_uniq( [img.start_energy, img.end_energy], eps = 1e-5 )
    Self->framework::Set, energy_edge = energy_edge, mod_img = img
  endif


  if keyword_set( erange ) then begin

    ; first set the parameter using the original set

    self->framework::set, erange = erange, /no_update
    energy_edge = Self->Get(/energy_edge)
    if keyword_set( energy_edge ) then begin

      index_erange = value_locate( energy_edge, erange ) > 0 < ( n_elements(energy_edge) - 1 )
      Self->framework::set, index_erange = index_erange ;info param
    endif


  endif

  ; for all other parameters (included in _extra), just pass them to the
  ; original set procedure in framework

  if keyword_set( _extra ) then begin
    self->framework::set, _extra = _extra
  endif

end

;---------------------------------------------------------------------------
;
;
function stx_img_spectra::get, $
  not_found=not_found, $
  found=found, $
  ;parameter=parameter, $
  _extra=_extra


  ;if keyword_set( parameter ) then begin
  ;    parameter_local=self->framework::get( /parameter )
  ;endif

  return, self->framework::get( parameter = parameter, $
    not_found=not_found, $
    found=found, _extra=_extra )
end
;---------------------------------------------------------------------------
function stx_img_spectra::ut4spectra, index_erange = index_erange, iut_return = iut_return, utcount = utcount, _extra=_extra
  ;for an input of INDEX_ERANGE, return the time boundaries for this uniform spectrogram
  ;if iut_return is set, return the indices (on all ut_edge) instead of the time values of the edge
  ;time values are returned as anytim seconds from 1-jan-1979
  Self->Set, _extra = _extra
  index_erange = Self->Get( /index_erange )
  default, iut_return, 0
  img_spectra_valid = Self->Getdata()
  utcount = 0
  default, index_erange, [6,12]
  index_erange1_0 = index_erange[1]

  while utcount le 1 and index_erange[1] gt index_erange[0] do begin
    iut = where( img_spectra_valid[ *, index_erange[0], index_erange[1] ], utcount )

    if index_erange[1] ne index_erange1_0 then print, 'Max boundary changed to ', index_erange[1]
    index_erange[1] --
  endwhile
  index_erange[1] ++
  ut_edge     = Self->Get( /ut_edge )
  ut_edge_spectrogram = ( get_edges( ut_edge, /edges_1 ) ) [ iut ]

  return, iut_return eq 1 ?  iut : ut_edge_spectrogram
end
;---------------------------------------------------------------------------


pro stx_img_spectra::plot,  subrange, tmargin = tmargin,  _extra = _extra

  default, subrange, 0
  Self->Set, _extra = _extra

  energy_edge = Self->Get( /energy_edge )
  nenergy  = n_elements( energy_edge )
  ut_edge     = Self->Get( /ut_edge )
  default, eplotrange, minmax( energy_edge ) * [0.5, 1.20]
  default, tmargin, 60.0

  ;img_spectra_valid = Self->Getdata()
  ;utcount = 0
  index_erange = Self->Get( /index_erange )
  if n_elements( index_erange ) ne 2 then default, index_erange, [6,12]
  ut_edge_spectrogram = Self->ut4spectra( index_erange = index_erange, utcount = utcount )


  img = Self->Get( /mod_img )
  uts = img.uts
  ute = img.ute
  nimg = n_elements( img )
  linecolors

  utplot, anytim( minmax( ut_edge ) + tmargin *[-1., 1.0],/ints), [0, 0]+1, yrang=eplotrange, /ystyle,  /ylog, ytitl='Energy (keV)'
  for ii = 0L, nimg - 1 do rectangle, uts[ii] - getutbase(), img[ii].start_energy, $
    ute[ii] - uts[ii], img[ii].end_energy - img[ii].start_energy, col=4; ( i mod 9 ) + 1, thick=2
  ut_edge_spectrogram -= getutbase()

  if utcount ge 2 then begin
    dut_edge = ut_edge_spectrogram[1:*] - ut_edge_spectrogram
    for ii = 0L, utcount-2 do $
      rectangle, ut_edge_spectrogram[ii], energy_edge[index_erange[0]], dut_edge[ii] , $
      energy_edge[index_erange[1]+1] - energy_edge[index_erange[0]], col=7, thick=1, linestyle = 1
  endif
end
;---------------------------
function stx_img_spectra::Sum_Time_Groups, mk_struct = mk_struct, _extra=_extra
  Self->Set, _extra = _extra

  default, eps_time, 1e-4 ;sec
  default, eps_energy, 1e-4 ;keV
  index_erange = Self->Get(/index_erange)
  nebins = index_erange[1] - index_erange[0] + 1

  ut_edge_spectrogram = Self->ut4spectra( index_erange = index_erange, utcount = utcount )
  if utcount eq 0 then return, -1
  img = Self->Get(/mod_img)
  ;clip the last time edge
  q   = where_within( img.ut_mean, minmax( ut_edge_spectrogram[0:utcount-1] ), tcount )
  img = img[q] ;select the ivs to use
  energy_edge = Self->Get( /energy_edge )
  ke  = value_locate( energy_edge, img.mean_energy )
  q   = where( ke ge index_erange[0] and ke le index_erange[1], ecount )
  img = img[q]
  ke  = ke[q] - index_erange[0]

  ut0 = ut_edge_spectrogram[0]
  z   = value_locate( ut_edge_spectrogram, img.ut_mean )
  h   = histogram( z * nebins + ke  , min=0, max = (utcount-1)*nebins - 1,  reverse_indices = revindex )
  if img[0].type eq 'stx_ivs_interval' and have_tag( img[0], 'COUNTS' ) then begin
    summed_counts = fltarr( nebins, utcount-1 )
    for ii = 0L, n_elements( summed_counts )-1 do summed_counts[ii] = ( h[ii] ge 1 ? $
      ftotal( img[ reverseindices( revindex, ii )].counts ) : 0.0 )
  endif
  default, mk_struct, 0
  mk_struct = mk_struct<1>0
  if mk_struct then begin

    ;e_axis = stx_construct_energy_axis( select = lindgen(index_erange[1]-index_erange[0]+1)+index_erange[0] )
    e_axis = stx_construct_energy_axis( energy_edge = energy_edge, select = indgen( nebins + 1) + index_erange[0] ) ;6-oct-2014, ras
    t_axis = stx_construct_time_axis( ut_edge_spectrogram )
    <<<<<<< .mine
    ;Why is the order of the dimensions still wrong for the spectrogram structure, ask Nicky!!!!
    ;summed_counts = transpose( summed_counts )
    =======
    >>>>>>> .r1206

    ltime  = summed_counts * 0.0 + 1 ;defer until later
    ;Set Ltime to 0 where there is no image
    qzero = where( h eq 0, nzero )
    if nzero ge 1 then ltime[ qzero ] = 0.0
    attenuator_state = 1 + intarr(utcount-1) ;defer until later

    spectrogram = stx_spectrogram(  summed_counts, t_axis, e_axis, ltime, attenuator_state=attenuator_state )
    return, spectrogram
  endif else return, summed_counts
end
;---------------------------------------------------------------------------

pro stx_img_spectra__define

  self = {stx_img_spectra, $
    inherits framework }

end


;---------------------------------------------------------------------------
; End of '__define.pro'.
;---------------------------------------------------------------------------
