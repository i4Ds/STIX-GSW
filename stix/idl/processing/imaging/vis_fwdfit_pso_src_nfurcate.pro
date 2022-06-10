FUNCTION VIS_FWDFIT_PSO_SRC_NFURCATE, srcstr0, n_sources
  
  ;Returns a modified source structure based on replication of input source structure (the flux is splitted between components).
  
  ; srcstr0: the structure to be replicated
  ; n_sources: the number of the sources
  
  srcstr          = CMREPLICATE(srcstr0, n_sources)      ; Create a n_sources-element structure array
  srcstr.srctype  = ' '
  srcstr.srcflux  = srcstr0.srcflux / n_sources          ; Split the flux between components.
  srcstr.srcx     = srcstr0.srcx                      
  srcstr.srcy     = srcstr0.srcy
  srcstr.srcfwhm_max = srcstr0.srcfwhm_max   
  srcstr.srcfwhm_min = srcstr0.srcfwhm_min
  srcstr.srcpa    = srcstr0.srcpa       
  srcstr.loop_angle = srcstr0.loop_angle
  
  RETURN, srcstr
END