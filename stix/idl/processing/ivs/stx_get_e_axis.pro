;---------------------------------------------------------------------------
; Document name: stx_get_e_axis.pro
; Created by:    Nicky Hochmuth, 2012/02/03
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       Stix energy axis structure
;
; PURPOSE:
;       Data definition structure for the energy axis
;
; CATEGORY:
;       STIX data definition
;
; CALLING SEQUENCE:
;       eaxis = stx_get_e_axis()
;
; HISTORY:
;       2012/02/03, nicky.hochmuth@fhnw.ch, initial release
;       2013/07/25, nicky.hochmuth@fhnw.ch, add combine keyword
;       
; TODO:
;       legacy: delete this function and replace with stx_energy_axis
;-

;+
; :description:
;    This helper method creates a named structure 'energy_axis'
;    containing the energy bins for the energy axis
;
; :keywords:
;   combine: an index array of edges how to resample the native binning 
;-
function stx_get_e_axis, combine=combine
 
 ;"scientific" energy bins
 axis = [(findgen(16)+4),20d*(150/20)^(dindgen(16)/16),150]
 
 
 if keyword_set(combine) then axis = axis[combine]
 
 Edge_Products, axis, MEAN=this_mean, GMEAN=this_gmean, $
     WIDTH=this_width, EDGES_1=this_edges_1, EDGES_2=this_edges_2
     
     this_width = float( this_width )
     
      e_axis = { type:'energy_axis', $
               mean:this_mean, $
               gmean:this_gmean, $
               width:this_width, $
               edges_2:this_edges_2, $
               edges_1:this_edges_1 }
     
     RETURN, e_axis
end