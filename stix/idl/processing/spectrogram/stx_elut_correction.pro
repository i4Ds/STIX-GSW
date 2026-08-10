;+
;
; NAME:
;
;   stx_elut_correction
;
; PURPOSE:
; 
;   Applies ELUT correction to pixel data counts before summing different energy bins.
;
;
; CALLING SEQUENCE:
; 
;   elut_data = stx_elut_correction(counts, counts_error, energy_bin_idx, $
;                                   energy_bin_low, energy_bin_high, energy_high, energy_low, energy_ind, this_energy_range, $
;                                   spectrum, spectrum_with_bkg, spectrum_bkg, $
;                                   pixel_ind, subc_index, silent=silent)
;   
; INPUTS:
; 
;   COUNTS_IN: float array (dimension: number of energy bins x number of pixels x number of detectors x number of time bins) containing the BKG subtracted counts
;   COUNTS_IN_ERROR: float array (dimension: number of energy bins x number of pixels x number of detectors ) containing the uncertainties of BKG subtracted counts
;   ENERGY_BIN_IDX: array containing the indices of the energy bins contained in the fits file.
;   ENERGY_BIN_LOW: float array of dimension 32 x 12 x 32 (number of energy bins x number of pixels x number of detectors)
;                   containing the low energy edges of the daily ELUT.
;   ENERGY_BIN_HIGH: float array of dimension 32 x 12 x 32 (number of energy bins x number of pixels x number of detectors)
;                   containing the high energy edges of the daily ELUT.
;   ENERGY_HIGH: float array containing the high energy edges of the nominal energy bins.
;   ENERGY_LOW: float array containing the low energy edges of the nominal energy bins.
;   ENERGY_IND: array containing the indices of the energy bins selected for integration along the energy dimension.
;   ENERGY_RANGE: array containing the low and high edge of the energy range selected for integration (e.g., [10,15])
;   SPECTRUM: array containing the BKG-subtracted spectrum. It is used for deriving the spectral index for each energy bin.
;   PIXEL_IND: array containing the indices of the considered pixels (e.g., [0] for top row, [0,1] for top and bottom row, etc.)
;   SUBC_INDEX: array containing the indices of the considered sub-collimators.
;
; OUTPUTS:
;   Structure containing:
;   - COUNTS: array of dimension 12 x 32 x number of time bins containing the ELUT corrected counts integrated within the selected energy interval.
;   - COUNTS_ERROR: array of dimension 12 x 32 x number of time bins containing the uncertainty associated with the ELUT corrected counts integrated within the selected energy interval. 
;   - COUNTS_NO_ELUT: array of dimension 4 (A,B,C,D) x number of rows (TOP, BOT, SMALL) x number of subcollimators x number of time bins containing the number of counts integrated in energy without ELUT correction. 
;                     It is used to compute the amount of ELUT correction for all pixels.
;   - COUNTS_ELUT: array of dimension 4 (A,B,C,D) x number of rows (TOP, BOT, SMALL) x number of subcollimators x number of time bins containing the number of counts integrated in energy after ELUT correction. 
;                     It is used to compute the amount of ELUT correction for all pixels.
;   - SP_INDEX: array containing the value of the spectral indices in the different energy bins 
; 
; KEYWORDS:
; 
;   SPECTRUM_WITH_BKG: array containing the observed spectrum (including BKG). It is used for display (if silent is not set to 0)
;   SPECTRUM_BKG: array containing the BKG spectrum. It is used for display (if silent is not set to 0)
;   SILENT: if set to 1, the spectrum plot is not displayed.
;
; HISTORY:
;   March 2026, Massa P., first release
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_elut_correction, counts_in, counts_in_error, $
                              energy_bin_idx, energy_bin_low, energy_bin_high, energy_high, energy_low, energy_ind, energy_range, $
                              spectrum, pixel_ind, subc_index, $
                              spectrum_with_bkg=spectrum_with_bkg, spectrum_bkg=spectrum_bkg, silent=silent

default, gain_offset_version, 'median'
default, silent, 0
default, spectrum_with_bkg, fltarr(spectrum.DIM)
default, spectrum_bkg, fltarr(spectrum.DIM)

;;**************** Compute spectral index to be used for ELUT correction

index_data = stx_estimate_spectral_index(energy_low, energy_high, spectrum)

sp_index = index_data.index_final
idx_peak = index_data.idx_peak

if ~silent then begin

  charsize = 1.8

  loadct,5
  device, Window_State=win_state
  if not win_state[10] then window,10,xsize=1000,ysize=500
  wset,10
  cleanplot

  !p.multi = [0,2,1]

  energy_axis = (energy_low+energy_high)/2.

  plot, energy_axis, spectrum_with_bkg, psym=10, /xst, /yst, /ylog, /xlog, yrange=[max([1.,min(spectrum)]),max(spectrum)*10.],charsize=charsize, $
    title='STIX spectrum',xtitle='Energy [keV]', ytitle = 'STIX spectrum [counts s!U-1!n keV!U-1!n]'
  oplot, [energy_range[0],energy_range[0]], [max([1.,min(spectrum)]),max(spectrum)*10.], linestyle=1
  oplot, [energy_range[1],energy_range[1]], [max([1.,min(spectrum)]),max(spectrum)*10.], linestyle=1
  oplot, energy_axis, spectrum_bkg, psym=10, linestyle=2
  oplot, energy_axis, spectrum, psym=10, color=122
  leg_text = ['Observed spectrum', 'Background', 'BKG-subtracted']
  leg_color = [255,255,122]
  leg_style = [0, 2, 0]
  ssw_legend, leg_text, color=leg_color, linest=leg_style, box=0, charsize=1.5, thick=1.5, /right


  plot,energy_axis, sp_index, psym=10, /xst, /yst, /xlog, charsize=charsize, $
    title='Estimate of the spectral index', xtitle='Energy [keV]', ytitle = 'Spectral index'
  oplot, [energy_range[0],energy_range[0]], [-20,20], linestyle=1
  oplot, [energy_range[1],energy_range[1]], [-20,20], linestyle=1
  oplot, [4,150], [0,0], linestyle=2

endif

;; Determine whether the time axis is present
if n_elements(counts_in.dim) eq 4 then begin

  dimensions = counts_in.dim
  n_times = dimensions[3]

endif else begin

  n_times = 1

endelse

;; We assume the spectrum has a powerlaw distribution E^-sp_index at any energy bin.
;
;  The number of counts in the energy range [a,b] is
;
;  C = \int_a^b E^-sp_index dE = (b^(-sp_index+1) - a^(-sp_index+1)) / (-sp_index+1)
;
;  We distinguish 3 cases:
;
; 1. The considered energy range consists of a single energy bin which is not at the peak
;    (i.e., different from 6-7 keV; example: 9-10 keV). The correction factor is
;
;    corr = (10^(-sp_index+1) - 9^(-sp_index+1)) / (10.03^(-sp_index+1) - 8.97^(-sp_index+1)),
;
;    where 10.03 and 8.97 are derived from daily ELUT
;
; 2. The considered energy range consists of a single energy bin which is at the peak of the spectrum
;    (i.e., 6-7 keV when attenuator is not inserted). We consider the middle point of the energy range (e.g., 6.5 keV)
;    and we assume that the spectrum follows a powerlaw distribution below and above the middle point, viz.
;
;             A E^-alpha if E < 6.5 keV
;     F(E) =
;             B E^-beta if E >= 6.5 keV
;
;    where alpha < 0 and beta > 0. Assuming that the spectrum is continuous at 6.5 keV,
;    we obtain that A and B are related to the following equation:
;
;    A = B 6.5^(alpha - beta)
;
;    Assuming that the ELUT edges of the considered energy bin are 5.98 and 7.05 keV, we obtain
;
;    corr = (\int_6^7 F(E) dE) / (\int_5.98^7.05 F(E) dE) ,
;
;    which leads to
;
;    corr = (6.5^(alpha - beta) * (6.5^(-alpha+1) - 6^(-alpha+1)) / (-alpha + 1) ) + (7^(-beta+1) - 6.5^(-beta+1)) / (-beta+1) ) /
;           (6.5^(alpha - beta) * (6.5^(-alpha+1) - 5.98^(-alpha+1)) / (-alpha + 1) ) + (7.05^(-beta+1) - 6.5^(-beta+1)) / (-beta+1) )
;
; 3. The considered energy range consists of multiple energy bins (e.g, 5-10 keV). Therefore, we apply a correction factor
;    only to the lowest and to the highest bin (corr_low and corr_high). Assuming that the energy edges of these bins contained
;    in the ELUT table are 5.01, 5.98 keV and 8.97, 10.02 keV, we have
;
;    corr_low = (5.98^(-alpha+1) - 5^(-alpha+1)) / (5.98^(-alpha+1) - 5.01^(-alpha+1))
;
;    and
;
;    corr_high = (10^(-beta+1) - 8.97^(-beta+1)) / (10.02^(-beta+1) - 8.97^(-beta+1))
;
;    where alpha and beta are the powerlaw indices in the first and the last energy bins, respectively.

if n_elements(energy_ind) eq 1 then begin

  if energy_ind eq idx_peak then begin

    ;; energy_bin_idx contains at least two indices (see control above)
    case energy_ind of

      0: begin

        sp_index_low = sp_index[energy_ind+1]
        sp_index_high = sp_index[energy_ind+1]

      end

      n_elements(energy_bin_idx)-1: begin

        sp_index_low = sp_index[energy_ind-1]
        sp_index_high = sp_index[energy_ind-1]

      end

      else: begin

        sp_index_low = sp_index[energy_ind-1]
        sp_index_high = sp_index[energy_ind+1]

      end

    endcase

    energy_bin_mid = (energy_high[energy_ind] + energy_low[energy_ind]) / 2.

    corr_factor_low_ELUT = (energy_bin_mid^(-sp_index_low+1.) - reform(energy_bin_low[energy_ind,*,*])^(-sp_index_low+1.)) / $
      (-sp_index_low+1.)
    corr_factor_high_ELUT = (reform(energy_bin_high[energy_ind,*,*])^(-sp_index_high+1.) - energy_bin_mid^(-sp_index_high+1.)) / $
      (-sp_index_high+1.)

    corr_factor_low_SCI = (energy_bin_mid^(-sp_index_low+1.) - energy_low[energy_ind]^(-sp_index_low+1.)) / (-sp_index_low+1.)
    corr_factor_high_SCI = (energy_high[energy_ind]^(-sp_index_high+1.) - energy_bin_mid^(-sp_index_high+1.)) / (-sp_index_high+1.)

    norm_factor = energy_bin_mid^(-sp_index_high + sp_index_low)
    energy_corr_factor = (norm_factor * corr_factor_low_SCI + corr_factor_high_SCI) / (norm_factor * corr_factor_low_ELUT + corr_factor_high_ELUT)

  endif else begin

    energy_corr_factor = (energy_high[energy_ind]^(-sp_index[energy_ind]+1.) - energy_low[energy_ind]^(-sp_index[energy_ind]+1.)) / $
      (reform(energy_bin_high[energy_ind,*,*])^(-sp_index[energy_ind]+1.) - reform(energy_bin_low[energy_ind,*,*])^(-sp_index[energy_ind]+1.)) 

  endelse
  
  energy_corr_factor = reform(cmreplicate(energy_corr_factor, n_times))
  
  ;; Compute total number of counts BEFORE ELUT correction is applied. It is used for estimating the amount of the ELUT correction
  counts_reshaped = reform(counts_in, n_elements(energy_bin_idx), 4, 3, 32, n_times)
  counts_no_elut = reform(total(counts_reshaped[energy_ind,*,pixel_ind,subc_index,*], 1))

  counts     = reform(counts_in[energy_ind,*,*,*]) * energy_corr_factor
  counts_error = reform(counts_in_error[energy_ind,*,*,*]) * energy_corr_factor

  ;; Compute total number of counts AFTER ELUT correction is applied. It is used for estimating the amount of the ELUT correction
  counts_reshaped = reform(counts, 4, 3, 32, n_times)
  counts_elut = reform(counts_reshaped[*,pixel_ind,subc_index,*])
  
 
endif else begin

  energy_corr_factor_low = (reform(energy_bin_high[energy_ind[0],*,*])^(-sp_index[energy_ind[0]]+1.) - energy_low[energy_ind[0]]^(-sp_index[energy_ind[0]]+1.)) / $
    (reform(energy_bin_high[energy_ind[0],*,*])^(-sp_index[energy_ind[0]]+1.) - reform(energy_bin_low[energy_ind[0],*,*])^(-sp_index[energy_ind[0]]+1.)) 

  energy_corr_factor_high = (energy_high[energy_ind[-1]]^(-sp_index[energy_ind[-1]]+1.) - reform(energy_bin_low[energy_ind[-1],*,*])^(-sp_index[energy_ind[-1]]+1.)) / $
    (reform(energy_bin_high[energy_ind[-1],*,*])^(-sp_index[energy_ind[-1]]+1.) - reform(energy_bin_low[energy_ind[-1],*,*])^(-sp_index[energy_ind[-1]]+1.)) 

  ;; Compute total number of counts BEFORE ELUT correction is applied. It is used for estimating the amount of the ELUT correction
  counts_reshaped = reform(counts_in, n_elements(energy_bin_idx), 4, 3, 32, n_times)
  counts_no_elut = reform(total(counts_reshaped[energy_ind,*,pixel_ind,subc_index,*], 1))
  
  energy_corr_factor_low = reform(cmreplicate(energy_corr_factor_low, n_times))
  energy_corr_factor_high = reform(cmreplicate(energy_corr_factor_high, n_times))
  
  counts = counts_in
  counts_error = counts_in_error
  
  counts[energy_ind[0],*,*,*]        *= energy_corr_factor_low
  counts[energy_ind[-1],*,*,*]       *= energy_corr_factor_high
  counts_error[energy_ind[0],*,*,*]  *= energy_corr_factor_low
  counts_error[energy_ind[-1],*,*,*] *= energy_corr_factor_high
  
  counts       = total(counts[energy_ind,*,*,*],1)
  counts_error = sqrt(total(counts_error[energy_ind,*,*,*]^2.,1))

  ;; Compute total number of counts AFTER ELUT correction is applied. It is used for estimating the amount of the ELUT correction
  counts_reshaped = reform(counts, 4, 3, 32, n_times)
  counts_elut = reform(counts_reshaped[*,pixel_ind,subc_index,*])

endelse

return, {counts: counts, $
         counts_error: counts_error, $
         counts_no_elut: counts_no_elut, $
         counts_elut: counts_elut, $
         sp_index: sp_index}


end
