;+
; :description:
;   Populate a pixel_data data structure with a single live time, a
;   single time frame, the energy axis returned by stx_get_e_axis()
;   and n_energy x n_subc x n_pixel uniform random deviates
;
; :params:
;   None
;
; :keywords:
;   None
;
; :returns:
;   pixel_data: out, "structure"
;   The pixel_data structure with ltime=1.0d, taxis=n_time,
;   eaxis defined from stx_get_e_axis() and the 2d data structure
;   populated with uniform random deviates
;
; :errors:
;   None
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_data_randomu

; hard code n_subc and n_pixel
  n_subc   = 32
  n_pixel  = 12

; get e_axis and number of energy bins from Nicky's routine  
  e_axis   = stx_get_e_axis()
  n_energy = n_elements(e_axis.mean)

; create the pixel_data structure
  pixel_data = stx_pixel_data(ltime = 1.0d,        $
                              taxis = 1.0d,        $
                              eaxis = e_axis.mean)

; populate each energy, subc and pixel with random counts
  pixel_data.data = randomu(12345, n_energy, n_subc, n_pixel) * 1000

  return, pixel_data

end
