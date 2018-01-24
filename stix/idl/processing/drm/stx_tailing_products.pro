;+
; :description:
;
;    This procedure calculates the pulse height matrix and detector response matrix from
;    an energy loss matrix with hole tailing included
;
; :params:
;
;    eloss_mat : in, required, type = "float"
;                the detector energy loss matrix including charge collection tailing
;
;    ein       : in, required, type = "float"
;                2 x ninput energy array with low and high energy edges in keV
;
;    eout      : in, required, type = "float"
;                2 x noutput energy array with low and high energy edges in keV
;
;    win       : in, required, type = "float"
;                difference between upper and lower edges in input energy binning (in keV)
;
;    wout      : in, required, type = "float"
;                difference between upper and lower edges in output energy binning (in keV)
;
;    func      : in, required, type = "string"
;                the name of the function used to describe full width at half maximum vs energy
;
;    func_par  : in, required, type = "float"
;                vector of parameters used to control func
;
;    area      : in, required, type = "float"
;                the area of the detector in cm^2
;
; :keywords:
;
;    costheta   : in, type = "float", default = 1.0 (zero degrees from normal)
;                 cosine of angle of incidence
;
;    pls_ht_mat : out, type = "float"
;                 pulse-height response matrix, eloss_mat convolved with energy resolution broadening
;
;    smatrix    : out, type = "float"
;                 pulse-height response matrix normalized to units of 1/keV
;
; :returns:
;
;    eloss_mat : the detector energy loss matrix including charge collection tailing
;                scaled by detector area and cos(theta)
;
;
; :examples:
;
;   tail_eloss_mat =  stx_tailing_products( eloss_mat, ein, eout, win, wout, func, func_par, area,  pls_ht_mat = pls_ht_mat, smatrix = smatrix )
;
;
; :history:
;
;    22-Apr-2015 - ECMD (Graz), initial release
;    14-Jun-2017 - ECMD (Graz), tailing matrix now separate input
;
;-
function stx_tailing_products, eloss_mat, tailing_matrix, ein, eout, win, wout, func, func_par, area, $
    costheta = costheta,  pls_ht_mat = pls_ht_mat, smatrix = smatrix
    
  ;repeat calculation of pulse height matrix and DRM for the new energy loss matrix
  ;should be the same functionality as resp_calc.pro L211 to 224
  default, costheta, 1.0
  
  nflux = n_elements(win)
  nout = n_elements(wout)
  
  edge_products, ein, edges_2 = ein
  edge_products, eout, edges_2 = eout
  
  ps_input = { ein:ein, eout:eout, func:func, func_par:func_par }
  
  eloss_mat = eloss_mat#tailing_matrix
  
  pulse_spread, ps_input, pulse_shape, eloss_mat, pls_ht_mat
  
  pls_ht_mat = pls_ht_mat * area * costheta
  
  smatrix =  pls_ht_mat / rebin(reform( wout, nout, 1 ), nout, nflux)
  ;output rows of SMATRIX are in units of counts/keV/photon
  
  result = eloss_mat * area * costheta
  
  return, result
end
