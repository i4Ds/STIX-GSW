;+
; :file_comments:
;   The default styles for the STIX line plots.
;   
; :categories:
;   plotting, GUI
; :examples:
;
; :history:
;    07-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-


;+
; :description:
; 	 Returns the default style for a STIX line plot.
; 	 By setting the according keyword, the default style for a lightcurve or
; 	 a background plot is returned.
;
; :Keywords:
;    lightcurve
;    background
;
; :returns:
;
; :history:
; 	 07-Apr-2015 - Roman Boutellier (FHNW), Initial release
; 	 23-Jan-2017 – ECMD (Graz), Added default x-axis title of 'Time (s)' to plots of type:
; 	                            line, lightcurve, background, archive_buffer and state
;-
function stx_line_plot_styles, default_line=default_line, lightcurve=lightcurve, background=background, archive_buffer=archive_buffer, spectra=spectra, $
                              state_plot=state_plot, detector_health=detector_health, energy_calibration_pixel=energy_calibration_pixel, aspect=aspect
  ; Set the default line styles
  default_line_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      showlegend: 1, $
      dimension: [800,400], $
      styles: ["m-", "b-", "g-", "r-", "k-", "m-.", "b-.", "g-.", "r-.", "k-."], $
      names: ["STIX Plot 1", "STIX Plot 2", "STIX Plot 3", "STIX Plot 4", "STIX Plot 5", "STIX Plot 6", "STIX Plot 7", "STIX Plot 8", "STIX Plot 9", "STIX Plot 10"], $
      ytitle: 'Energy', $
      xtitle: 'Time (s)', $
      ylog: 1, $
      xstyle: 3, $
      ystyle: 3, $
      histogram: 1, $
      starttime: 0 $
    }
  
  ; Set the default lightcurve styles
  default_lightcurve_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      showlegend: 1, $
      dimension: [800,400], $
      styles: ["m-", "b-", "g-", "r-", "k-", "c-", "y-", "p-", "m-.", "b-.", "g-.", "r-.", "k-.","m+", "b+", "g+", "r+", "k+", "m+.", "b+.", "g+.", "+-.", "k+.","m-", "b-", "g-", "r-", "k-", "m-.", "b-.", "g-.", "r-.", "k-.","m+", "b+", "g+", "r+", "k+", "m+.", "b+.", "g+.", "+-.", "k+."], $
      ytitle: '', $;data.unit
      xtitle: 'Time (s)', $
      name_prefix: "LC", $
      ylog: 1, $
      xstyle: 3, $
      ystyle: 3, $
      histogram: 1, $
      starttime: 0 $;data.time_axis.time_start[0]
    }
    
    ; Set the default spectra styles
    default_spectra_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.75,0.85], $
      showlegend: 1, $
      dimension: [800,900], $
      styles: ["m-", "b-", "g-", "r-", "k-", "c-", "y-", "p-",  "m-+", "b-+", "g-+", "r-+", "k-+", "c-+", "y-+", "p-+", "m-.", "b-.", "g-.", "r-.", "k-.", "c-.", "y-.", "p-.",  "m--+", "b--+", "g--+", "r--+", "k--+", "c--+", "y--+", "p--+"   ], $
      ytitle: 'counts', $ 
      xtitle: 'Energy Channel (#)', $
      name_prefix: "Det ", $
      ylog: 0, $
      xstyle: 3, $
      ystyle: 3, $
      histogram: 1, $
      starttime: 0 $;data.time_axis.time_start[0]
    }
    
    ; Set the default aspect styles
    default_aspect_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      showlegend: 1, $
      dimension: [800,400], $
      styles: ["m-", "b-", "g-", "r-"], $
      ytitle: 'diode voltage', $;data.unit
      xtitle: 'Time (s)', $
      name_prefix: "Diode", $
      ylog: 0, $
      xstyle: 3, $
      ystyle: 3, $
      histogram: 1, $
      starttime: 0 $;data.time_axis.time_start[0]
    }
    
  ; Set the default background styles
  default_background_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      showlegend: 1, $
      dimension: [800,400], $
        styles: ["m-.", "b-.", "g-.", "r-.", "k-.","c-.", "y-.", "p-."], $
      ytitle: '', $;data.unit
      xtitle: 'Time (s)', $
      name_prefix: "BG", $
      ylog: 1, $
      xstyle: 3, $
      ystyle: 3, $
      histogram: 1, $
      starttime: 0 $;data.time_axis.time_start[0]
    }
    
  ; Set the default archive buffer styles
  default_archive_buffer_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      dimension: [800,400], $
      styles: ["b-","r","g-","m:"], $
      names: ["Variance [var \ tot. counts]", "AB acc. duration [s]", "AB total counts", "AB trigger count"], $
      thick: 2, $
      xstyle: 3, $
      ystyle: 3, $
      ytitle: "", $
      xtitle: 'Time (s)', $
      ylog: 1 $
    }
    
  ; Set the default state plot styles
  default_state_plot_styles = { $
      showxlabels: 1, $
      position: [0.1,0.1,0.65,0.95], $
      dimension: [800,400], $
      styles: ["k-","c-","rD-","gD-"], $
      names: ["flare", "rate control", "cfl x", "cfl y"], $
      thick: 2, $
      xstyle: 3, $
      ystyle: 3, $
      ytitle: ['States', 'Flare Location'], $
      xtitle: 'Time (s)', $
      ylog: 0 $
    }
  
  ; Set the detector health plot styles
  default_detector_health_plot_values = { $
    dimensions: [500,500], $
    plot_position: [[0.05,0.1055,0.8,0.1255],[0.05,0.131,0.8,0.151],[0.05,0.1565,0.8,0.1765],[0.05,0.182,0.8,0.202],[0.05,0.2075,0.8,0.2275],[0.05,0.233,0.8,0.253], $
                [0.05,0.2585,0.8,0.2785],[0.05,0.284,0.8,0.304],[0.05,0.3095,0.8,0.3295],[0.05,0.335,0.8,0.355],[0.05,0.3605,0.8,0.3805],[0.05,0.386,0.8,0.406], $
                [0.05,0.4115,0.8,0.4315],[0.05,0.437,0.8,0.457],[0.05,0.4625,0.8,0.4825],[0.05,0.488,0.8,0.508],[0.05,0.5135,0.8,0.5335],[0.05,0.539,0.8,0.559], $
                [0.05,0.5645,0.8,0.5845],[0.05,0.59,0.8,0.61],[0.05,0.6155,0.8,0.6355],[0.05,0.641,0.8,0.661],[0.05,0.6665,0.8,0.6865],[0.05,0.692,0.8,0.712], $
                [0.05,0.7175,0.8,0.7375],[0.05,0.743,0.8,0.763],[0.05,0.7685,0.8,0.7885],[0.05,0.794,0.8,0.814],[0.05,0.8195,0.8,0.8395],[0.05,0.845,0.8,0.865], $
                [0.05,0.8705,0.8,0.8905],[0.05,0.896,0.8,0.916],[0.05,0.9215,0.8,0.9415]], $
    base_position: [0.05,0.1,0.8,0.95], $
    styles: ['green','yellow','red','black'], $
    axis_style: 0, $
    name_prefix: 'bar', $
    ytitle: 'Detectors', $
    names: ['1a','1b','1c','2a','2b','2c','3a','3b','3c','4a','4b','4c','5a','5b','5c','6a','6b','6c','7a','7b','7c','8a','8b','8c','9a','9b','9c','10a','10b','10c','cfl','bkg','flare'], $
    fill_level: 0, $
    linestyle: ' ', $
    showxlabels: 1, $
    thick: 10, $
    flare_thick: 5 $
  }
  
  ; Set the energy calibration spectra plot styles
  default_energy_calibration_plot_values = { $
    dimensions: [600,400], $
    position: {nmbr_subplot1:[0.15,0.1,0.75,0.9], $
                nmbr_subplot2:[[0.15,0.1,0.4,0.9],[0.5,0.1,0.75,0.9]], $
                nmbr_subplot3:[[0.15,0.55,0.39,0.9],[0.51,0.55,0.75,0.9],[0.15,0.1,0.39,0.45]], $
                nmbr_subplot4:[[0.15,0.55,0.39,0.9],[0.51,0.55,0.75,0.9],[0.15,0.1,0.39,0.45],[0.51,0.1,0.75,0.45]], $
                nmbr_subplot5:[[0.15,0.55,0.29,0.9],[0.385,0.55,0.515,0.9],[0.61,0.55,0.75,0.9],[0.15,0.1,0.29,0.45],[0.385,0.1,0.515,0.45]], $
                nmbr_subplot6:[[0.15,0.55,0.29,0.9],[0.385,0.55,0.515,0.9],[0.61,0.55,0.75,0.9],[0.15,0.1,0.29,0.45],[0.385,0.1,0.515,0.45],[0.61,0.1,0.75,0.45]], $
                nmbr_subplot7:[[0.15,0.66,0.29,0.9],[0.385,0.66,0.515,0.9],[0.61,0.66,0.75,0.9],[0.15,0.385,0.29,0.615],[0.385,0.385,0.515,0.615],[0.61,0.385,0.75,0.615],[0.15,0.1,0.29,0.34]], $
                nmbr_subplot8:[[0.15,0.66,0.29,0.9],[0.385,0.66,0.515,0.9],[0.61,0.66,0.75,0.9],[0.15,0.385,0.29,0.615],[0.385,0.385,0.515,0.615],[0.61,0.385,0.75,0.615],[0.15,0.1,0.29,0.34],[0.385,0.1,0.515,0.34]]}, $
    colors: ['blue', 'green', 'red', 'aqua', 'purple', 'orange', 'gold', 'fuchsia', 'maroon', 'navy', 'gray', 'lime'], $
    names: ['Top 1','Top 2','Top 3','Top 4','Bottom 1','Bottom 2','Bottom 3','Bottom 4','Small 1','Small 2','Small 3','Small 4'], $
    adc_x_title: 'AD Channel', $
    adc_y_title: 'Entries per ADC bin', $
    adc_title: 'ADC count spectrum', $
    fit_x_title: 'ADC value', $
    fit_y_title: 'Entries per ADC bin', $
    fit_title: 'Fit to spectrum for channel ', $
    calibrated_x_title: 'Energy (keV)', $
    calibrated_y_title: 'Entries per energy bin (gain dependent)', $
    calibrated_title: 'Calibration Spectrum mean over detectors ' $
  }
  
  ; Set the energy calibration spectra plot styles
  default_energy_calibration_plot_pixel_styles = { $
  position: [0.1,0.3,0.65,0.95], $ $
  dimensions: [600,500], $
  colors: ['blue', 'green', 'red', 'aqua', 'purple', 'orange', 'gold', 'fuchsia', 'maroon', 'navy', 'gray', 'lime'], $
  names: ['Top 1','Top 2','Top 3','Top 4','Bottom 1','Bottom 2','Bottom 3','Bottom 4','Small 1','Small 2','Small 3','Small 4'], $
  x_title: 'AD Channel', $
  y_title: 'mean counts per AD Channel', $
  title: 'Calibration Spectrum mean over detectors ' $
}
    
  ; Return the requested default style values
  if keyword_set(spectra) then return, default_spectra_styles
  if keyword_set(default_line) then return, default_line_styles
  if keyword_set(aspect) then return, default_aspect_styles
  if keyword_set(lightcurve) then return, default_lightcurve_styles
  if keyword_set(background) then return, default_background_styles
  if keyword_set(archive_buffer) then return, default_archive_buffer_styles
  if keyword_set(state_plot) then return, default_state_plot_styles
  if keyword_set(detector_health) then return, default_detector_health_plot_values
  if keyword_set(energy_calibration_pixel) then return, default_energy_calibration_plot_pixel_styles
  
  ; If no keyword is set, return 0
  return, 0
end