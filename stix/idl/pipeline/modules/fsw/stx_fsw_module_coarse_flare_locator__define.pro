;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW)
;    "Coarse Flare Locator".
;
; :categories:
;    Flight Software Simulation, flare location, module
;
; :examples:
;    obj = stx_fsw_module_coarse_flare_locator()
;
; :history:
;    28-mar-2014 - Laszlo I. Etesi (FHNW), initial release
;    18-nov-2014 - ECMD (Graz), get background duration from
;                  stx_fsw_background_determination config file
;    15-jun-2015 - ECMD (Graz), calculation of total background and summing
;                  counts over energy bands moved here from stx_fsw_ql_flare_locator.pro
;    30-jun-2015 - Laszlo I. Etesi (FHNW), fixed n most recent background
;    01-Feb-2016 - ECMD (Graz) added normalisation_factor
;    10-May-2016 - Laszlo I. Etesi (FHNW), changed variable names, updated call to CFL routine, and adjusted code to work with new data structures
;
;-
;+
; :description:
;    This internal routine calls the coarse flare locator algo
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_fsw_ql_accumulators structure
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
;   this function returns a two element array with the calculated [x, y] source position
;-
function stx_fsw_module_coarse_flare_locator::_execute, in, configuration
  compile_opt hidden

  ; extract input from in
  cfl_acc_summed = in.ql_cfl1_acc
  cfl_acc_cfl = in.ql_cfl2_acc
  background = in.background.background

  conf = *configuration->get(module=self.module)

  self->update_io_data, conf


  ; extract optional parameters
  energy_band = conf.energy_band
  lower_limit_counts = conf.lower_limit_counts
  upper_limit_counts = conf.upper_limit_counts
  bk_weights = conf.bkg_weigths
  out_of_range_factor = conf.out_of_range_factor
  tot_bk_factor = conf.tot_bk_factor
  quad_bk_factor = conf.quad_bk_factor
  cfl_bk_factor = conf.cfl_bk_factor
  use_last_n_intervals = conf.use_last_n_intervals
  normalisation_factor = conf.normalisation_factor
  
  ;take the accumulated counts for the required energy range
  cfl_counts_energy = cfl_acc_cfl.accumulated_counts
  quad_counts_energy = cfl_acc_summed.accumulated_counts


  ;get the counts only over the specified energy range.
  cfl_counts = total(cfl_counts_energy[energy_band,*],1)
  quad_counts = total(quad_counts_energy[energy_band,*],1)
  
  ; new implementation of FSW SIM handles correct number of backgrounds externally
  bk_counts = mean(transpose(background), dim=1)

  ;background correction
  total_background = total(bk_weights*bk_counts)

  cfl_coords = stx_fsw_ql_flare_locator(cfl_counts, quad_counts, total_background, $
    lower_limit_counts = lower_limit_counts, $
    upper_limit_counts = upper_limit_counts, $
    out_of_range_factor = out_of_range_factor, $
    tot_bk_factor = tot_bk_factor, $
    quad_bk_factor = quad_bk_factor, $
    cfl_bk_factor = cfl_bk_factor, $
    normalisation_factor = normalisation_factor, $
    tab_dat = (self.lut_data)["cfl_lut"], $
    sky_y = (self.lut_data)["sky_y"])
    
    ;if(min(cfl_coords) ge 0) then stop
    
    return, stx_fsw_m_coarse_flare_locator(x_pos=cfl_coords[0], y_pos=cfl_coords[1])
end

pro stx_fsw_module_coarse_flare_locator::update_io_data, conf

  ;read in sky vector reference table and corresponding step sizes from file
  ;curreltly using same reference table as analysis CFL algorithm
  if self->is_invalid_config("cfl_lut", conf.cfl_lut) then begin
    t_file = exist(conf.cfl_lut) ? conf.cfl_lut : loc_file( 'stx_fsw_cfl_skyvec_table.txt', path = getenv('STX_CFL') )
    tab_data = stx_cfl_read_skyvec(t_file, sky_x = sky_x, sky_y = sky_y)
    (self.lut_data)["cfl_lut"] = tab_data
    (self.lut_data)["sky_x"] = sky_x
    (self.lut_data)["sky_y"] = sky_y
  end

end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_fsw_module_coarse_flare_locator__define
  compile_opt idl2, hidden

  void = { stx_fsw_module_coarse_flare_locator, $
    inherits ppl_module_lut }
end
