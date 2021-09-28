;+
; Name: clean_stix_sep2021
;
; Purpose: This function returns the clean map including residuals using visibilities
;          adapted from vis_clean.pro for STIX use before we have a proper version.
;
; Inputs:
;   - vis - visibility bag  
;   Typical visibility structure for vis, only the fields used in vis_clean marked with ***
;   the operation of vis_clean only depends on the fiels, U, V, OBSVIS, and XYOFFSET
;   This is the RHESSI visibility structure, see this reference for details
;   http://sprg.ssl.berkeley.edu/~tohban/wiki/index.php/User's_Guide_to_RHESSI_Visibilities
;   The values of obsvis, totflux, sigamp, and chi2 are derived within hsi_vis_gen
;   from fitting a sine/cosine profile to the count rates in the calibrated_eventlist as a function of phase for
;   a single position angle bin bin
;    ** Structure HSI_VIS, 15 tags, length=112, data length=102:
;    ISC             INT              0                     Subcollimator index (=0,,,,8)  
;    HARM            INT              1
;    ERANGE          FLOAT     Array[2]                     Energy range (keV) 
;    TRANGE          DOUBLE    Array[2]
;    U               FLOAT          0.220757                 ****  u=East-west spatial frequency component (arcsec^-1)
;    V               FLOAT         0.0105846                 ****  v=North-south spatial frequency component (arcsec^-1)
;    OBSVIS          COMPLEX   (     -570.841,     -1448.74) ****  Observed (semicalibrated) visibility (ph/cm2/s)
;    TOTFLUX         FLOAT           49844.5
;    SIGAMP          FLOAT           2008.48
;    CHI2            FLOAT           1.62104
;    XYOFFSET        FLOAT     Array[2]                      **** West, north heliocentric offset of phase center (arcsec)
;    TYPE            STRING    'photon'
;    UNITS           STRING    'Photons cm!u-2!n s!u-1!n'
;    ATTEN_STATE     INT              3
;    COUNT           FLOAT           75801.4

;   
;
; Keyword inputs:
;   - niter        max iterations  (default 100)
;   - image_dim    number of pixels in x and y, 1 or 2 element long vector or scalar
;       images are square so the second number isn't used
;   - pixel        pixel size in asec (pixels are square)
;   - gain         clean loop gain factor (default 0.05)
;   - clean_box    clean only these pixels (1D index) in the fov
;   - negative_max if set stop when the absolute maximum is a negative value (default 1)
;   - nmap         1/frequency for intermediate plotting
;   - make_map     If set, final map is a map structure
;   - wait_time    Time in seconds for dwelling on intermediate plots
;   - beam_width   psf beam width (fwhm) in asec
;   - noresid      If set, final clean_image output does not have the residuals added in
;   - uniform_weighting      assign weights by uniform weighting which preferentially weights higher spatial
;     frquencies. Takes precedence over the next argument, SPATIAL_FREQUENCY_WEIGHT
;     For natural weighting (no spatial preference) set uniform_weighting to 0 or set
;     spatial_frequency_weight to 1 as a scalar or an array with the same number of elements as the
;     input visibility bag
;   - spatial_frequency_weight - an array with the same number of elements as the input vis bag computed
;     by the user's preference. 
;   
;
; Keyword outputs:
;   - iter
;   - dirty_map    two maps in an [image_dim, 2] array (3 dim), original dirty map first, last unscaled dirty map second
;   - clean_beam   the idealized Gaussian PSF
;   - clean_map    the clean components convolved with normalized clean_beam
;   - clean_components structure containing the fluxes of the identified clean components
;         ** Structure <1ee894d8>, 3 tags, length=8, data length=8, refs=1:
;             IXCTR           INT              0
;             IYCTR           INT              0
;             FLUX            FLOAT            0.00000
;	- clean_sources_map the clean components realized as point sources on an fov map (lik)
;	  - weight_used - weighting factors applied to each visibility based on input
;	Finally make all of the outputs available as a single structure for convenience
;	  - info_struct = { $
;          image: clean_image, $  ;image returned by vis_clean, clean image + residual map convolved with clean beam
;          iter: iter, $
;          dirty_map: dirty_map[*,*,0], $
;          last_dirty_map: dirty_map[*,*,1], $
;          clean_map: clean_map, $
;          clean_components: clean_components, $
;          clean_sources_map: clean_sources_map, $
;          resid_map: resid_map }

; History:
;	12-feb-2013, Anna Massone and Richard Schwartz, based on hsi_map_clean
;	11-jun-2013, Richard Schwartz, identified error in subtracting gain modified psf from
;	 dirty map. Before only psf had been subtracted!!!
;	17-jul-2013, Richard Schwartz, converted beam_width to pixel units for st_dev on call to
;	 psf_gaussian for self-consistency
;	23-jul-2013, Richard Schwartz, added info_struct for output consolidation
;	10-mar-2016, Richard Schwartz, added to the documentation, fixed the propagation of the
;	  spatial weighting to the psf and dirty map, and clarified how the weighting could
;	  be specified. Described the elements of the visibility structure that are used in the construction.
;	04-sep-2021, Säm changed intermediate display, and fixed clean boxes and make it possible to select boxes 
;	05-sep-2021  Säm changed how residuals are added (simply added, not convolved with PSF)
;	05-sep-2021  Säm changed output to map structures (clean image, bproj map, residual map, component map, and clean image without residuals)
;	06-sep-2021  Säm renamed updated procedure to clean_stix_sep2021.pro
;-


function clean_stix_sep2021, vis, niter = niter, image_dim = image_dim_in, pixel = pixel, $
  _extra = _extra,  $
  spatial_frequency_weight = spatial_frequency_weight, $
  uniform_weighting = uniform_weighting, $
  
	gain = gain, clean_box = clean_box, negative_max = negative_max, $
	beam_width = beam_width, $
	clean_beam = clean_beam, $
	make_map   = make_map, $
	plot = plot, $
	wait_time = wait_time, $
	nmap = nmap, $
	noresid = noresid, $
	;Outputs
	weight_used = weight_used, $
	iter = iter, dirty_map = dirty_map,$
	clean_map = clean_map, clean_components = clean_components, $
	clean_sources_map = clean_sources_map, $
	resid_map = resid_map, $
	info_struct = info_struct, $
	set_clean_boxes=set_clean_boxes

;clean using vis
;obj->set, _extra=_extra

;image_dim = obj->get(/image_dim)
default, noresid, 0
default, wait_time, 0.2
default, plot, 0
default, make_map, 0
default, image_dim_in, 65
default, pixel, 1.0
negative_max = fix(fcheck(negative_max,1)) > 0 < 1
default, niter, 100
default, gain, 0.05
first_time=1
image_dim = image_dim_in[0]
image_dim = image_dim / 2 *2 + 1 ;forces odd image_dim
default, beam_width, 10. ;convolving beam sigma in asec, set it to 10" (for STIX 3 to 10 this is better, nominal 14")
;beam_width_factor=fcheck(beam_width_factor,1.0) > 1.0
default, clean_beam, psf_gaussian( npixel = image_dim[0], st_dev = beam_width / pixel, ndim = 2)
default, nmap, 20  ;1/frequency that intermediate maps are plotted 

this_disp=256. ; used for setting plot dimensions

;realize the dirty map and build a psf at the center, use odd numbers of pixels to center the map
weight_used = vis_spatial_frequency_weighting( vis, spatial_frequency_weight, UNIFORM_WEIGHTING = uniform_weighting )

vis_bpmap, vis, map = dmap0, bp_fov = image_dim[0] * pixel, pixel = pixel, /data_only, $
  spatial_freqency_weight = weight_used

default, clean_box, where( abs( dmap0)+1) ;every pixel is the default

;new Sep 4, 2021: select clean boxes interactively if set_clean_boxes is set
if keyword_set(set_clean_boxes) then begin
  ;select box in rotated image
  this_image=rotate(dmap0,1)
  clean_box_r=hsi_select_box(this_image,separation=separation,list=plist,nop=nop)
  ;rotate back and selected pixel list
  this_image=this_image*0
  this_image(clean_box_r)=1
  this_image0=rotate(this_image,3)
  clean_box=where(this_image0 eq 1)
  ;tst=dmap0
  ;tvscl,tst,0
  ;tvscl,rotate(dmap0,3),1
  ;tvscl,this_image,2
  ;tvscl,this_image0,3
  ;tst(clean_box)=0
  ;tvscl,tst,4
endif

component = {clean_comp,  ixctr: 0, iyctr: 0, flux:0.0}
clean_components = replicate( component, niter) ;positions in pixel units from center

;Now we can begin a clean loop
;Find the max of the dirty map, save the component, subtract the psf at the peak from dirty
iter = 0
clean_map = dmap0 * 0.0
dmap = dmap0
test = 1

while  test do begin
	
	zflux = max(  ( negative_max ? abs( dmap[clean_box] ) : dmap[ clean_box ] ), iz  )
  ;stop
	if dmap[ clean_box[ iz ] ] lt 0 then begin   ;;;;;; only enters if negative_max is set
		test = 0
		break ;leave while loop
  endif
	
	psf = vis_psf( vis, clean_box[iz], pixel = pixel, psf00 = psf00, image_dim = image_dim, $
	  spatial_freqency_weight = weight )
	default, pkpsf, max( psf )
	flux = zflux * gain / pkpsf
	;I think this is wrong, the residual map needs to be updated for all pixels
  ;dmap[clean_box] -= psf *flux
  dmap -= psf *flux
  ;here it should be the other way around: iz is the index relative to the clean_box
  ;izdm = get_ij( iz, image_dim ) ;convert 1d index to 2d form
  izdm = get_ij( clean_box[iz], image_dim ) ;convert 1d index to 2d form

	clean_components[ iter ] = { clean_comp, izdm[0], izdm[1], flux }
	;same here
  ;clean_map[ iz ] += flux
  clean_map[ clean_box[iz] ] += flux
	
	
	;change of display September 4, 2021
	if keyword_set( plot ) and (iter mod nmap eq 0) then begin
	  pmulti = !p.multi
	  loadct,5
	  ;!p.multi = [0, 2, 1]
	  ;plot_image, dmap
	  ;cleaned_map_iter = convol( clean_map, clean_beam, /norm, /center, /edge_zero)
	  ;contour, /over, cleaned_map_iter, col=2, thick=2, levels = interpol( minmax( cleaned_map_iter ), 5)
	  cleaned_map_iter = convol( clean_map, clean_beam, /norm, /center, /edge_zero)
	  if first_time eq 1 then begin
	   window,2,xsize=5*this_disp,ysize=this_disp
	   first_time=0
	  endif 
	  erase
	  this_dmap0=dmap0
	  this_dmap0[clean_box[iz]]=0.
	  tvscl,congrid(rotate(this_dmap0,1),this_disp,this_disp),0
	  ;draw clean box on bproj map
	  if keyword_set(set_clean_boxes) then begin
	   ;for j=0,nop-1 do this_dmap0[plist[0,j],plist[1,j]]=0.
	   ;tvscl,congrid(rotate(this_dmap0,1),this_disp,this_disp),0
	   ;overplot boxes
	   ;how many boxes
	   bdim=n_elements(nop)
	   set_viewport,0,0.2,0,1
	   plot,[0,1],[0,1],xrange=[0,1],yrange=[0,1],xst=1+4,yst=1+4,/nodata,/noe
	   for n=0,bdim-1 do begin
	     ;corners of the current box
	     if n eq 0 then this_box=plist(*,0:nop(n)-1) else this_box=plist(*,nop(n-1):total(nop(0:n))-1)
	     ;connect corners
       for j=0,nop[n]-2 do oplot,[this_box[0,j],this_box[0,j+1]]/image_dim[0],[this_box[1,j],this_box[1,j+1]]/image_dim[1]
	     ;last one goes back to first
       oplot,[this_box[0,nop[n]-1],this_box[0,0]]/image_dim[0],[this_box[1,nop[n]-1],this_box[1,0]]/image_dim[1]
	     ;;old version when boxes are selected in rotated image
	     ;;needs to rotated by 90 degree
	     ;for j=0,nop[n]-2 do oplot,[this_box[1,j],this_box[1,j+1]]/image_dim[1],1-[this_box[0,j],this_box[0,j+1]]/image_dim[0]
	     ;;last one goes back to first
	     ;oplot,[this_box[1,nop[n]-1],this_box[1,0]]/image_dim[1],1-[this_box[0,nop[n]-1],this_box[0,0]]/image_dim[0]
	   endfor
	  endif
	  ;stop
	  this_dmap=dmap
	  ;this_dmap[iz]=0.
	  ;mark current component with max value
	  this_dmap[clean_box[iz]]=max(dmap0)
	  tvscl,congrid(rotate(this_dmap,1),this_disp,this_disp),1
	  this_display=clean_map
	  this_display(where(this_display ne 0))=1
	  tvscl,congrid(rotate(this_display,1),this_disp,this_disp),2
	  tvscl,congrid(rotate(cleaned_map_iter,1),this_disp,this_disp),3
	  ;clean map (not per arcsec)
    tvscl,congrid(rotate(cleaned_map_iter+dmap/total(clean_beam),1)  ,this_disp,this_disp),4
	  this_start=0.015
    xyouts,this_start,0.9,'backprojection',charsize=1.5,/normal
    xyouts,this_start+0.2,0.9,/normal,'residual map',charsize=1.5
    xyouts,this_start+0.4,0.9,/normal,'CLEAN components',charsize=1.5
    xyouts,this_start+0.6,0.9,/normal,'convolved components',charsize=1.5
    xyouts,this_start+0.8,0.9,/normal,'CLEAN map',charsize=1.5
    xyouts,this_start+0.2,0.83,/normal,'iteration: '+strtrim(iter+1,2),charsize=1.5
    xyouts,this_start+0.4,0.83,/normal,'iteration: '+strtrim(iter+1,2),charsize=1.5
    xyouts,this_start+0.6,0.83,/normal,'iteration: '+strtrim(iter+1,2),charsize=1.5
    xyouts,this_start+0.6,0.76,/normal,'beam size: '+strmid(strtrim(beam_width,2),0,4)+'"',charsize=1.5
    xyouts,this_start+0.8,0.83,/normal,'iteration: '+strtrim(iter+1,2),charsize=1.5
	  wait, wait_time
	  !p.multi = pmulti

	endif

	iter++
	test = iter lt niter
	endwhile



;Convolve with a clean beam
clean_sources_map = clean_map
clean_map = convol( clean_map, clean_beam, /norm, /center, /edge_zero) / pixel^2 ;add pixel^2 to make it per arcsecond^2
resid_map = dmap / total(clean_beam) / pixel^2   
bproj_map = dmap0 / total(clean_beam) / pixel^2
               ;;;; just as in hsi_map_clean normalize the residuals just like the clean image
               ;;;; 11 feb 2013, N.B. in hsi_map_clean the normalization factor, nn, is used on
               ;;;; both residual map and clean map because they do not use convol() as here with /norm
               ;;;; but instead multiply the clean sources by the unnormalized cbm
dirty_map = [[[dmap0]], [[dmap]]] ;original dirty map first, last unscaled dirty map second
;clean_image=clean_map + resid_map
;Säm: TBD, but it seems to me that there is no need to convolve the residual map with the clean beam. for now I use clean_map+resid_map
;clean_image = noresid ? clean_map : clean_map + convol( resid_map, clean_beam, /norm, /center, /edge_zero)
clean_image=clean_map+resid_map

info_struct = { $
          image: clean_image, $
          iter: iter, $
          dirty_map: dirty_map[*,*,0], $
          last_dirty_map: dirty_map[*,*,1], $
          clean_map: clean_map, $
          clean_components: clean_components, $
          clean_sources_map: clean_sources_map, $
          resid_map: resid_map }
;out = make_map ? make_map( clean_image, dx = pixel[0], dy = pixel[0], $
;  xcen = vis[0].xyoffset[0], ycen = vis[1].xyoffset[1],  units = 'Photons cm!u-2!n asec!u-2!n s!u-1!n',$
;  image_alg = 'vis_clean',$
;  time = anytim(/vms, avg(vis[0].trange )), erange=arr2str( string( form='(2f7.2)' ,vis[0].erange ),' - ')+' keV' ): clean_image
  
;Sep 4: make map structure default output; and rotate images
;output has 
; 0: clean map
; 1: backprojection map (dirty map)
; 2: residual map
; 3: component map
; 4: convolved component map (ie. residual not added)
; 5: clean beam map
; we need to add later solar orbiter specific information: Rsun, B0, radial distance etc.

this_time= stx_time2any(vis[0].time_range,/vms)
this_time_avg=anytim(average(anytim(this_time)),/vms)
this_duration = anytim(this_time[1])-anytim(this_time[0])
this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
;rsun to be added
this_rsun=0.0

out0 = make_map( rotate(clean_image,1), dx = pixel[0], dy = pixel[0], $
  xcen = vis[0].xyoffset[0],ycen = vis[0].xyoffset[1],  units = 'photons cm!u-2!n asec!u-2!n s!u-1!n',$
  image_alg = 'vis_clean', id = 'STIX CLEAN '+this_estring+': ', beam_size = beam_width, $
  time = this_time_avg, dur = this_duration, erange=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV', energy_range=vis[0].energy_range, rsun=this_rsun, L0=0., B0=0.  )

out1 = make_map( rotate(bproj_map,1), dx = pixel[0], dy = pixel[0], $
    xcen = vis[0].xyoffset[0], ycen = vis[0].xyoffset[1],  units = 'photons cm!u-2!n asec!u-2!n s!u-1!n',$
    image_alg = 'vis_pb', id = 'STIX BPROJ '+this_estring+': ', beam_size = beam_width, $
    time = this_time_avg, dur = this_duration, erange=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV', energy_range=vis[0].energy_range, rsun=this_rsun, L0=0., B0=0.  )

out2 = make_map( rotate(resid_map,1), dx = pixel[0], dy = pixel[0], $
    xcen = vis[0].xyoffset[0], ycen = vis[0].xyoffset[1],  units = 'photons cm!u-2!n asec!u-2!n s!u-1!n',$
    image_alg = 'vis_clean', id = 'CLEAN RESIDUAL '+this_estring+': ', beam_size = beam_width, $
    time = this_time_avg, dur = this_duration, erange=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV', energy_range=vis[0].energy_range, rsun=this_rsun, L0=0., B0=0.  )

out3 =make_map( rotate(clean_sources_map,1), dx = pixel[0], dy = pixel[0], $
    xcen = vis[0].xyoffset[0], ycen = vis[0].xyoffset[1],  units = 'photons cm!u-2!n asec!u-2!n s!u-1!n',$
    image_alg = 'vis_clean', id = 'CLEAN components '+this_estring+': ', beam_size = beam_width, $
    time = this_time_avg, dur = this_duration, erange=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV', energy_range=vis[0].energy_range, rsun=this_rsun, L0=0., B0=0.  )

out4 =make_map( rotate(clean_map,1), dx = pixel[0], dy = pixel[0], $
    xcen = vis[0].xyoffset[0], ycen = vis[0].xyoffset[1],  units = 'photons cm!u-2!n asec!u-2!n s!u-1!n',$
    image_alg = 'vis_clean', id = 'CLEAN convolved '+this_estring+': ', beam_size = beam_width, $
    time = this_time_avg, dur = this_duration, erange=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV', energy_range=vis[0].energy_range, rsun=this_rsun, L0=0., B0=0. )

if keyword_set(plot) then begin
  window,6,xsize=5*this_disp,ysize=2*this_disp
  cleanplot
  !p.multi=[0,3,1]
  chs2=2.
  plot_map,out0,charsize=chs2
  this_dmax=max(out1.data)
  this_dmin=min(out1.data)
  plot_map,out1,charsize=chs2,dmin=this_dmin,dmax=this_dmax
  plot_map,out2,/per,/over,level=[50]
  plot_map,out2,charsize=chs2,dmin=this_dmin,dmax=this_dmax
  plot_map,out2,/per,/over,level=[50]
endif


out=[out0,out1,out2,out3,out4]
return, out
end