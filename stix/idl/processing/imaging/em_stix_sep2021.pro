;+
;
; NAME:
;   em_stix_sep2021
;
; PURPOSE:
;   Wrapper around stx_em
;
;-
FUNCTION em_stix_sep2021,countrates,energy_range,time_range,IMSIZE=imsize,PIXEL=pixel,MAPCENTER=mapcenter, WHICH_PIX=which_pix, $
                 subc_index=subc_index, MAXITER=maxiter, TOLERANCE=tolerance, SILENT=silent, MAKEMAP=makemap, XY_FLARE=xy_flare

default, which_pix, 'TOP+BOT'
default, subc_index, stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c','6a','6b','6c',$
                                     '5a','5b','5c','4a','4b','4c','3a','3b','3c'])

 
subc_str = stx_construct_subcollimator()

; Grid correction
phase_cal = read_csv(loc_file( 'GridCorrection.csv', path = getenv('STX_VIS_DEMO') ), header=header, table_header=tableheader)
phase_corr = phase_cal.field1

; Pixel correction
phase_corr += 46.1

phase_corr *= !dtor


; Sum over top and bottom pixels
case which_pix of

  'TOP': begin
         pixel_ind = [0]
         end

  'BOT': begin
         pixel_ind = [1]
         end

  'TOP+BOT': begin
             pixel_ind = [0,1]
             end

endcase
 
pix = reform(countrates, 32, 4, 3)
countrates = n_elements( pixel_ind ) eq 1 ? reform(pix[*, *, pixel_ind , *]) : total( pix[*, *, pixel_ind, *], 3 )

;;;;;;;; Paolo: 6 settembre 2021
this_gtrans = stix_gtrans32_test_sep_2021(xy_flare)
for i=0,31 do begin
  countrates(i,*)=countrates(i,*) * this_gtrans(i)
endfor
;;;;;;;;

uv = stx_uv_points_giordano()
u = -uv.u * subc_str.phase
v = -uv.v * subc_str.phase

em_im = stx_em(countrates[subc_index, *], u[subc_index], v[subc_index], phase_corr[subc_index], SUMCASE = 0, $
                IMSIZE=imsize, PIXEL=pixel, XYOFFSET=[mapcenter[1], -mapcenter[0]], TOLERANCE=tolerance)
   
em_map = make_map(em_im)
this_estring=strtrim(fix(energy_range[0]),2)+'-'+strtrim(fix(energy_range[1]),2)+' keV'
em_map.ID = 'STIX EM '+this_estring+': '
em_map.dx = pixel[0]
em_map.dy = pixel[1]
em_map.xc = mapcenter[0]
em_map.yc = mapcenter[1]
em_map.time = anytim((anytim(time_range[1])+anytim(time_range[0]))/2.,/vms)
em_map.DUR = anytim(time_range[1])-anytim(time_range[0])
;eventually fill in radial distance etc
add_prop,em_map,rsun=0.
add_prop,em_map,B0=0.
add_prop,em_map,L0=0.

;rotate map to heliocentric view
em__map=em_map
em__map.data=rotate(em_map.data,1)

return,em__map   

end