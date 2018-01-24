;---------------------------------------------------------------------------
; Document name: stx_image_cube__define.pro
; Created by:    rschwartz70@gmail.com
; 
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       STIX IMAGE CLASS DEFINITION
;
; PURPOSE:
;       Reads and holds image cubes. 
;
;
; CATEGORY:
;       HESSI Imaging
;
; CONSTRUCTION:
;       obj = Obj_Name( 'stx_image_cube' )

;
; CONTROL PARAMETERS:

;       im_input_fits - specify the input filename to use. If set to
;                       an empty string (the default), it will
;                       generate new images.

; EXAMPLES:
;     Check stx_image_cube_test for a lot of examples.
;
;     This example will make 8 images, four 5-second time bins starting at 20-feb-02 10:00, and
;     two energy bands (3-12 and 12-25), and write the image cube in the file test_cube.fits
;     obj = hsi_multi_image()
;     obj -> set, obs_time_interval='20-feb-02 10:' + ['00','00:20']
;     obj -> set, im_time_interval=5, im_energy_bin=[3,12,25]
;     ptim, obj -> getaxis(/ut, /edges_2)   ; shows time bins
;     print,obj -> getaxis(/energy, /edges_2) ; shows energy bins
;     data = obj -> getdata(image_dim=16, multi_fits_filename='test_cube.fits')
;
; SEE ALSO:
;
; Modifications:
;
; Written:  23-sep-2016
;--------------------------------------------------------------------
function stx_image_cube_control

  control = {stx_image_cube_control, im_input_fits: '', $
    use_single:1}
  return, control
end

function stx_image_cube_info

  info = {stx_image_cube_info, cube_dim: intarr(2), nebin:0, ntbin:0, image_dim:intarr(2), nmaps:0, $
    energy_edges: ptr_new(), $
    time_bins: ptr_new(), $
    image_units: '',$
    t_idx: 0, $
    e_idx: 0}

  return, info
end

FUNCTION stx_image_cube::INIT, _ref_EXTRA=extra

  
  ret=self->Framework::INIT( CONTROL = stx_image_cube_control(), $
    INFO=stx_image_cube_info()) ;, $  ras, 10-apr-2007

  IF Keyword_Set( extra ) THEN self->Set, _EXTRA = extra

  RETURN, ret

END


;----------------------------------------------------------

;function hsi_image::get, fitsfile = fitsfile, _ref_extra = extra
; this should be here for compatibility reasons.
; lets wait to see if we really need it

;----------------------------------------------------------

PRO stx_image_cube::Set, im_input_fits = im_input_fits, $
  _extra=_extra, done=done, not_found=not_found

if is_string(im_input_fits) && is_fits( im_input_fits ) then $
  Self->framework::set, im_input_fits = im_input_fits

Self->framework::set, _extra=_extra

END
function stx_image_cube::get, xc = xc, yc = yc, pixel_size = pixel_size, $
  _extra=_extra

  if keyword_set( xc ) || keyword_set( yc ) || keyword_set( pixel_size ) then begin
    map = ( self->framework::getdata() )[0]
    case 1 of 
      keyword_set( xc ) : out = map.xc
      keyword_set( yc ) : out = map.yc
      keyword_set( pixel_size ) : out = [ map.dx ,map.dy ]
    endcase
  endif

  if keyword_set( _extra ) then out =Self->framework::get( _extra=_extra )
return, out

END
function stx_image_cube::getdata, all_images = all_images, _extra = _extra, map = map


Self->set, _extra = _extra
use_single = Self->get(/use_single)
if keyword_set( all_images ) then use_single = 0
maps = self->framework::getdata()
flat_data = ~keyword_set( map )
t_idx = self->get(/t_idx)
e_idx = self->get(/e_idx)
out   = is_struct( maps ) ? (flat_data ? maps.data : maps ) :maps
out   = ~use_single ? out : (flat_data ? out[*, *, e_idx, t_idx ] : out[e_idx, t_idx ] )
return, out
end

pro stx_image_cube::process, _extra = _extra

error = 1
self->set, _extra = _extra
filename = Self->Get(/im_input_fits)
if ~is_string( filename ) || ~is_fits( filename ) then begin
  message,'No FITS file in IM_INPUT_FITS',/continue
  self->setdata, 0
  return
endif
stx_fits2mapcube, filename, map, time_axis=time_bins, energy_axis = energy_edges, index = index

image_units = have_tag( index )? index.dataunit : 'photons cm!u-2!n s!u-1!n asec!u-2!n'

if ~keyword_set( energy_edges ) || ~keyword_set( time_bins ) then begin
  print, 'Energy_edges and Time_bins (2xN form) required for map structure array input'
  return
endif

nebin = n_elements(  energy_edges[0,*] )
ntbin = n_elements( time_bins[0,*] )
nmaps = n_elements( map )
if nebin * ntbin ne nmaps then message, 'Not a valid map cube file. Number of energies x Number of times must be Number of Maps'

;Add energy edges and time bins explicitly
kmap = 0
map  = add_tag( map[*], dblarr(2), 'time_bins' )
map  = add_tag( map[*], fltarr(2), 'energy_edges' )
for iebin=0,nebin-1 do begin
  for itbin=0, ntbin-1 do begin
    
    map[kmap].energy_edges = energy_edges[*,iebin]
    map[kmap].time_bins    = time_bins[*,itbin]
    kmap++
  endfor
endfor
Self->setdata, reform( /over, map, nebin, ntbin )

self->set, cube_dim = [ nebin, ntbin ]
self->set, nebin = nebin
self->set, ntbin = ntbin
self->set, image_dim = size(/dim, map[0].data )
self->set, nmaps = nmaps
self->set, time_bins = time_bins
self->set, energy_edges =  energy_edges
self->set, image_units = image_units

error = 0 ;successfully loaded map "cube" (pseudo cube, as maps are referenced by 1d index
end

;--------------------------------------------------------------------

;pro stx_image_cube::plot, p_e_idx, p_t_idx,_extra = extra;, choose=choose
;
;  ; just forward the command
;  ; ... but need to set parameters before so that we can switch to the correct
;  ; strategy in case it's needed
;
;  if keyword_set( extra ) then self -> set,  _extra=extra
;
;  ;strat = self -> getstrategy()
;  ; terrible, extra needs to be done here again. so it will go into set two times.
;  ; need to solve that later.
;
;  if keyword_set(choose) then begin
;    self -> chooser, p_e_idx, p_t_idx, count=count
;    if count eq 0 then return
;  endif else count = 1
;
;  if count eq 1 then strat -> plot, p_e_idx, p_t_idx, _extra = extra else begin
;    not_first = 0
;    for ie=0,n_elements(p_e_idx)-1 do begin
;      for it=0,n_elements(p_t_idx)-1 do begin
;        if not_first then window,/free
;        not_first = 1
;        strat -> plot, p_e_idx[ie], p_t_idx[it], _extra=extra
;      endfor
;    endfor
;  endelse
;
;end
;
;;--------------------------------------------------------------------
;
;pro stx_image_cube::movie, _ref_extra = extra
;
;  ; just forward the command
;
;  strat = self->getstrategy()
;  strat -> movie, _extra = extra
;
;end

;--------------------------------------------------------------------

; Method to show all panels at once.
; Input keywords:
;   zoom - if selected, then the panel clicked will be replotted bigger.
;   plotman - if set, then that replotted panel will be shown in
;      a plotman widget (if running from the GUI, it will use the GUI plotman widget).
; Output keywords:
;   t_idx, e_idx - time, energy indices of panel clicked
;   selected_images - accumulated time,energy indices of each panel clicked
;   done - finished, return

;pro stx_image_cube::panel_display,  _ref_extra =  extra, $
;  zoom = zoom, plotman=plotman, group=group, $
;  t_idx = t_idx, e_idx = e_idx, selected_images = selected_images, $
;  done = done
;
;
;  if keyword_set( extra ) then begin
;    self -> set,  _extra=extra
;  endif
;
;  hsi_panel_display,  self, t_idx = t_idx, e_idx = e_idx,  $
;    _extra= extra, done = done, group=group, $
;    selected_images = selected_images
;
;  if done then return
;
;  if keyword_set( zoom ) then begin
;    repeat begin
;      self->set, t_idx = t_idx, e_idx = e_idx
;      ; 2007-08-24 - in plotman, unless specify e and t index, wants to bring whole cube in,
;      ; whereas plot method just does current e and t (set in previous line). Also if pass
;      ; in selected_images, draws a box around images we've zoomed in
;      if keyword_set(plotman) then self->plotman,e_idx,t_idx else self->plot
;      hsi_panel_display,  self, t_idx = t_idx, e_idx = e_idx, selected_images = selected_images, _extra= extra, done = done
;    end until done
;  endif
;
;end
;


;--------------------------------------------------------------------

function stx_image_cube::getaxis, xaxis = xaxis, yaxis = yaxis, energy=energy, ut=ut, $
   _ref_extra = extra
  
  default, extra, {edges_2:1}
  if keyword_set( ut ) then return, get_edges( self->get(/time_bins), _extra = extra ) 
  if keyword_set( energy ) then return, get_edges( self->get( /energy_edges), _extra = extra )
  
  
  if keyword_set( xaxis) || keyword_set( yaxis ) then begin
    maps = self->framework::getdata()
    map  = maps[0]
    om   = obj_new( 'map' )
    om->setmap, 0, map
    case 1 of
      keyword_set( xaxis) : out = (om->xp())[*,0]
      else: out = reform( (om->yp())[0,*])
    endcase
    obj_destroy, om
  endif

  return, out

end

;--------------------------------------------------------------------
;
;pro stx_image_cube::fitswrite,  err_msg=err_msg, _ref_extra =  extra
;
;  if keyword_set( extra ) then begin
;    self -> set,  _extra =  extra
;  endif
;
;  strategy =  self -> getstrategy()
;  strategy->fitswrite, err_msg=err_msg, _extra=extra
;
;end


;-------------------------------------------------------------------------

PRO stx_image_cube__define

  self = {stx_image_cube, $
    INHERITS framework }

END

