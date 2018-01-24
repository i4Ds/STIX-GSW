;+
; :Description:
;    stx_sim_find_accum_boundaries
;    Find the grouped accumulation bins. The input is a set of base data bins of 
;    summed counts. These must be grouped into coarser bins based on three criteria,
;    1. The bin must have be at least nmin bins wide
;    2. If nmin is reached, then close it when the summed counts exceeds mincnt or
;    3. Close the bin when it reaches nmax bins wide
;    Within this algorithm the unit of time has been transformed to a bin width as the 
;    input bins have a fixed width, so we are only counting integer numbers of bins
;    and integer numbers of counts. Time is not explicit here, but in the calling
;    routine.
;
; :Params:
;   cntbin: in, type="integer", 1d array of any size
;          counts in each input base accum bin
;   mincnt: in, type="integer", default = 1
;          minimum number of counts in a grouped accum bin
;   nmin  : in, type="integer", default = 1
;          minimum size of grouped accumulation bin 
;   nmax  : in, type="integer", default = 10
;          maximum size of grouped accumulation bin
;
;
;
; :Author: rschwartz70@nasa.gov
; :History: 13-may-2016
;           18-may-2016, added CLOSE_LAST_TIME_BIN, if set, close the time bins at the last time bin passed
;           19-may-2016, clarified units and documentation
;-
function stx_sim_find_accum_boundaries, cntbin,  mincnt, nmin, nmax, $
  close_last_time_bin = close_last_bin


  default, close_last_bin, 0

  imax   = n_elements( cntbin) -1  ;last index of input bin indice
  inext  = 0
  ibin  = lonarr(1) ;0 is the first bin of the current grouped bin
  ;The routine always begins at the start of a bin group so the counter is refreshed
  counter    = 0L
  
  binwidth = 0L
  for inext = 0L, imax do begin
    counter += cntbin[ inext ] ;increment the counts
    binwidth++                ;increment the width
    gt_minbin = binwidth ge nmin
    ;Apply the three tests to see if this bin is the last bin in the current group
    if gt_minbin && ((counter ge mincnt) or (binwidth ge nmax)) then begin ;found a bin edge, set up for the next
      ibin = append_arr( ibin, inext ) 
      
      counter  = 0L
      binwidth = 0L
    endif
  endfor
  ibin = close_last_bin ? append_arr( ibin, imax ) : ibin
   case n_elements( ibin ) of
    1: return, 0 ;no groups were found, more event times are needed 
    2: return, ibin
    else: begin

      nbin = n_elements( ibin )-1

      intervals = intarr( 2, nbin )
      intervals[ 0, * ] = [ 0, ibin[1:nbin-1] + 1] ;
      intervals[ 1, * ] = ibin[1:nbin]
    end
  endcase
  return, intervals
end