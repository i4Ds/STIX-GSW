;---------------------------------------------------------------------------
; Document name: stx_module_create_map__define.pro
; Created by:    nicky.hochmuth 22.03.2013
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_create_map Object
;
; PURPOSE:          Wrapping the imaging (creating a map) for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_create_map()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       22.03.2013 nicky.hochmuth initial release
;       23.07.2013 richard.schwartz implementd stx_vis_clean alg, config needs to match 'clean' or 'bpmap'
;       30.07.2013 richard.schwartz added 'bproj' as a possibility for the config, same result as 'bpmap'
;       27.11.2013 richard.schwartz fixed call to stx_vis_fwdfit, does not need the xyoffset_shift since that is encoded
;         in the visibility bag and the map rendering works correctly internally to the routine as opposed to Clean which
;         does its rendering outside. We need to make a proper schema for the image algorithms so they all work in the same way
;         from the callers point of view.
;
;-

function stx_module_create_map::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin
  end
  return, ret
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_create_map::_execute, visibility_bags, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  n_inputs = n_elements(visibility_bags)
  algo = strlowcase(conf.algo)
  
  for i=0L, n_inputs-1  do begin
  
    vis_bag_all = visibility_bags[i].visibility
    vis_shifted = [.0,.0]
    xyoffset = vis_bag_all[0].xyoffset
    if conf.shift_map_center_to_bpmap_peak then begin
      
      stx_vis_bpmap, vis_bag_all, /noplot, map = bpmap, pixel = pbpixel, BP_FOV = 400
      ;15-oct-2013, ras, move the map xyoffset depending on the center of mass of the back-projection
      ;This is an expediency, in reality the user would examine the back projection and
      ;adjust the xyoffset, this must be reconsidered in the real analysis flow
        
      mdim = size( /dimension, bpmap )
      pk = max( bpmap, ipk )
      xyoffset_shift = (get_ij( ipk, mdim[0] ) - mdim[0]/2.0) * pbpixel[0]
      vis_bag_all = hsi_vis_shift_mapcenter(vis_bag_all, xyoffset_shift )
    end
    
    image = { $
          type        : "stx_image", $
          algo        : algo, $
          time_range  : visibility_bags[i].time_range, $
          energy_range: visibility_bags[i].energy_range $
        }
    
    ;hide masked visibilities
    vis_bag = vis_bag_all[where(conf.detector_mask ne 0)]
    
    ;common config params
    
    image_dim = conf.image_dim
    pixel = conf.pixel
     
    switch algo of
      'clean': begin 
        
        cl_res_map = stx_vis_clean(vis_bag, resid_map=resid_map, image_dim = image_dim, pixel = pixel, niter=conf.algo_clean.niter, gain=conf.algo_clean.gain, beam_width=conf.algo_clean.beam_width, clean_map=clean_map, dirty_map=dirty_map,info_struct = info_struct, _extra=extra)

        image = create_struct('map',        make_map( clean_map, id="vis_clean: photons / cm^2 / s / arcsec^2", dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]), image)
        image = create_struct('map_cl_res', make_map( cl_res_map, dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]), image)
        image = create_struct('resid_map',  make_map( resid_map, dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]),  image)
        image = create_struct('dirty_map',  make_map( dirty_map[*,*,0], dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]) , image)
         
        break
      end
      
      'bpmap': void=1
      'bproj': begin ;'bpmap'
        stx_vis_bpmap, vis_bag, MAP=map, _extra=extra, /NOPLOT, pixel = pixel, bp_fov=image_dim
        image = create_struct('map', make_map(map, id='Backprojection', dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]), image)
        break 
      end
      
      'memnjit' : begin ;
       
        grids = minmax(vis_bag.isc)
        mem_map, vis_bag, vis_out, u_out, v_out, image_struct, grids, pixel, svis, imsize=im_dim
        image = create_struct('map', make_map(image_struct.map, id='mem njit: photons / cm^2 / s',  dx = pixel[0], dy = pixel[0], xc = xyoffset[0]+ xyoffset_shift[0], yc = xyoffset[1] + xyoffset_shift[1]), image)
        break
      end
      
      'fwdfit' : begin ;
        
        map = stx_vis_fwdfit(vis_bag, pixel_size = pixel, image_dim=image_dim, xyoffset=xyoffset, circle=conf.algo_fwdfit.circle,NOPLOTFIT=1)
        map.id = 'Forward Fit: photons / cm^2 / s'
        image = create_struct('map',map, image)
        break
      end
      
      'uvsmooth' : begin 
          vis_bag = add_tag(vis_bag,vis_bag.time_range.value,"trange")
          uv_smooth, vis_bag, map, _extra=extra
          image = create_struct('map',map, image)
          break 
       end
    endswitch
    
    if i eq 0 then all_images = replicate(image,n_inputs) else all_images[i]=image
  
    
  endfor;all visibility bags
  return, all_images
  
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_create_map::_verify_input, in
  compile_opt hidden
  
  if ~self->ppl_module::_verify_input(in) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    This internal routine verifies the validity of the configuration
;    parameter
;
; :params:
;    configuration is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'configuration' is valid, false otherwise
;-
function stx_module_create_map::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end


;+
; :description:
;    Cleanup of this class
;-
pro stx_module_create_map::cleanup
  self->ppl_module::cleanup
end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_module_create_map__define
  compile_opt idl2, hidden
  
  void = { stx_module_create_map, $
    inherits ppl_module }
end
