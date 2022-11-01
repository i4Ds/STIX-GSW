FUNCTION stx_bproj,vis,imsize,pixel,aux_data,_extra=extra;uni=uni

  ; wrapper around backprojection
  ; output map structure has north up
  ; 
  ; 10-Sep-2021: Sam: first version
  ; 05-Oct-2022: Paolo: updated for using 'stx_make_map'

  ;natural weighting is default
  vis_bpmap, vis,  MAP = map, BP_FOV = imsize[0]*pixel[0], PIXEL = pixel[0],_extra=extra;,uni=uni
  ;make map
  bp_map = stx_make_map(map, aux_data, pixel, "BPROJ", vis)
  
  return,bp_map

END
