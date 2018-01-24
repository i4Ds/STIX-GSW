;+
; Project     : STIX
;
; Name        : stx_readJavaSimulationData
;
; Category    : instrument simulation
;
; Explanation : This routine reads data from the Java gridSimulation 
;               and converts the data into the STX_PIXEL_DATA structure
;               
; Inputs      : filename  ; path and name of the sav.file
;               plot      ; plot the readed data?
;
; Calls       : stx_pixel_data = stx_readJavaSimulationData('test.sav',/plot)
;
; Outputs     : stx_pixel_data
;
; History     : 25-Aug-2012, Version 1 written by Nicky Hochmuth (nicky.hochmuth@fhnw.ch)
;
;*******************************************************************************

function stx_readJavaSimulationData, filename, plot=plot

  restore, file=filename
  
  col_names = col_names[sort(col_names)]
  
  
  pxl = stx_pixel_data(ltime=1, taxis=1, eaxis=1)
  
  c = 0
  
  for index = 0L, n_elements(col_names)-1 do begin
    a = execute(" sc = subcollimator_" + col_names[index])
    data = make_array(12, /double)
    data[0:3]=sc[1,*]
    data[4:7]=sc[0,*]
    data[8:11]=[0,0,0,0]
    
    pxl.data[0,0,(index mod 3)*10+index/3,*]=data[*]
        
    print, col_names[index]
  endfor


  if keyword_set(plot) then begin
    p = stx_processor_image(pxl)
    stx_pixel_data_viewer, pxl, p.getvisibilities(), title=filename
  end
  
  return, pxl

end