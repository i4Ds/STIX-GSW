;+
; :file_comments:
;    This is the main Data Simulation software
;    TODO: Extend description
;
; :categories:
;    data simulation, software
;
; :examples:
;    dss = obj_new('stx_data_simulation')
;    dss->set, /stop_on_error
;    help, dss->getdata(scenario_name='stx_scenario_1')
;
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi (FHNW), * updated code to allow multiple input parameters for modules
;                                   * removed routines provided by ppl_processor
;    19-Aug-2014 - Laszlo I. Etesi (FHNW), complete redesign of data simulation; new initial release
;    16-Sep-2014 - Laszlo I. Etesi (FHNW), - fixed filtering and now allowing to request data in a multile of 4 seconds intervals
;                                          - added support for rate control regimes (0, 1)
;    18-Sep-2014 - Laszlo I. Etesi (FHNW), fixed boundary handling
;    03-Nov-2014 - Roman Boutellier (FHNW), added execute routine which simulates one source
;    12-Nov-2014 - Roman Boutellier (FHNW), - added getdata2 (doing the same as getdata, but split up in several sub-routines)
;                                           - split up _run_data_simulation into several sub-routines
;    29-Nov-2014 - Shaun Bloomfield (TCD), added source structure input to stx_sim_photon_path.pro
;    02-Dec-2014 - Shaun Bloomfield (TCD), fixed use of background
;                  flux in determining number of events. Previously
;                  did not multiply by area to be distributed over.
;    03-Dec-2014 - Shaun Bloomfield (TCD), added 32-element array of
;                  detector background multiplication factors to
;                  simulate over and under noisy detectors. Element
;                  values scale detector areas into effective areas.
;    04-Dec-2014 - Shaun Bloomfield (TCD), 1) DRM used to determine
;                  the photon-spectrum-weighted efficiency factor in
;                  stx_sim_split_sources.pro. This calculates correct
;                  numbers of counts to draw (based on source flux
;                  and spectral form) and passes an array of these
;                  factors on to save being recalculated in
;                  stx_sim_multisource_sourcestruct2photon.pro
;                  2) background energy spectrum form and parameters
;                  is now used to draw background count and photon
;                  source energies (supplied by scenario_name files)
;    04-Dec-2014 - Lazslo I. Etesi (FHNW), updated code to work with background-only scenarios
;    05-Dec-2014 - Laszlo I. Etesi (FHNW), resolved ambiguity with scenario_name and scenario_file
;    05-Dec-2014 - Shaun Bloomfield (TCD), modified to use background
;                  effective area multiplier array from the background
;                  source structure
;    22-Jan-2014 - Laszlo I. Etesi (FHNW), - renamed object to stx_data_simulation
;                                          - merged some routines
;                                          - removed extra routines (clean up)
;    05-Feb-2014 - Laszlo I. Etesi (FHNW), added functionality to request time duration of a scenario
;    30-Oct-2015 - Laszlo I. Etesi (FHWN), renamed event_list to eventlist, and trigger_list to triggerlist
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated DSS to work with new structures
;-

;+
; :description:
;    this function initialises this module
;
; :params:
;    configuration_manager : in, optional, type='string', default="stx_configuration_manager(configfile='stx_data_simulation_default.config')"
;      this is a stx_configuration_manager object that has been
;      initialized with a stx_data_simulation configuration
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_data_simulation::init, configuration_manager
  default, configuration_manager, stx_configuration_manager(application_name='stx_data_simulation')

  ; dss is not yet state ready, temporary workaround
  ; TODO: introduce state
  internal_state = { $
    type: 'stx_dss_internal_state' $
  }

  res = self->ppl_processor::init(configuration_manager, internal_state)
  self.available_used_filter_look_ahead_bins = ptr_new(list())
  self.used_filter_look_ahead_events = ptr_new(list())
  return, res
end

;+
; :description:
;    this is the main processing routine; data can be requested by providing the proper input
;    and specifying the desired 'output_target'; allowed combinations are:
;
;    input_data                             | output_target
;    ----------------------------------------------------------------------
;    source=stx_sim_source_structure        | stx_sim_photon_structure
;                 "                         | stx_sim_detector_eventlist
;                 "                         | stx_ds_result_data
;                 "                         | (empty) -> stx_ds_result_data
;    source=stx_sim_source_structure    and | stx_sim_detector_eventlist
;    events=stx_sim_photon_structure(*) and | stx_ds_result_data
;    (optional) start_time=stx_time()       | (empty) -> stx_ds_result_data
;
;    (*)also as arrays
;
; :keywords:
;    _extra : in, required, type=any
;      this data input is used to start the processing (see 'description')
;    output_target : in, optional, type='string', default='stx_ds_result_data'
;      specifies the desired output type
;      valid targets are: stx_sim_photon_structure, stx_sim_detector_eventlist, stx_ds_result_data, (empty)
;    history : out, optional, type='ppl_history'
;      this variable is set internally and outputs a history structure that contains debugging information
;      on the processing
;
; :returns:
;    this routine returnes the desired 'output_target' or a ppl_exception structure
;
; :history:
;    29-Apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi (FHNW), adapted to new input handling
;    19-Aug-2014 - Laszlo I. Etesi (FHNW), new release of getdata routine
;    08-Feb-2017 - Shane Maloney (TCD), passed _extra to _run_data_simulation
;
; :todo:
;    19-Aug-2014 - Laszlo I. Etesi (FHNW), - verify why detector index goes from 1..32 and pixel index from 0..11
;                                          - verify if the randomu detector index is ok, or if the detector index should be generated based on detector size
;-
function stx_data_simulation::getdata, output_target=output_target, history=history, _extra=extra
  ; detect level of this call on stack
  help, /traceback, out=tb
  ; only install error handler if this routine has not been previously called
  ppl_state_info, out_filename=this_file_name
  found = where(stregex(tb, this_file_name) ne -1, level)

  if(level -1 eq 0) then begin
    ; activate error handler
    ; setup debugging and flow control
    mod_global = self->get(module='global')
    debug = mod_global.debug
    stop_on_error = mod_global.stop_on_error
    !EXCEPT = mod_global.math_error_level

    ; make sure we start fresh
    message, /reset

    ; install error handler if no stop_on_error is set; otherwise skip and let IDL stop where
    ; the error occurred
    if(~stop_on_error) then begin
      error = 0
      catch, error
      if(error ne 0) then begin
        catch, /cancel
        help, /last_message, out=last_message
        error = ppl_construct_error(message=last_message, /parse)
        ppl_print_error, error
        return, error
      endif
    endif
  endif

  ; specify defaults
  default, history, ppl_history()
  default, output_target, 'data_simulation'

  switch (output_target) of
    'data_simulation': begin
      ; TODO: return special data simulation structure containing information on simulation
      return, self->_run_data_simulation(history=history, _extra=extra)
      break
    end
    'stx_sim_detector_eventlist': begin
      return, self->_read_detector_events(history=history, apply_time_filter=0, _extra=extra)
      break
    end
    'stx_ds_result_data': begin
      return, self->_read_detector_events(history=history, apply_time_filter=1, _extra=extra)
      break
    end
    'scenario_output_path': begin
      self->_prepare_scenario, out_output_path=output_path, /ignore_not_empty, _extra=extra
      return, output_path
      break
    end
    'scenario_length': begin
      return, self->_calculate_scenario_length_t(_extra=extra)
      break
    end
    else: begin
      message, 'Unknown output_target'
    end
  endswitch
end

;+
; :description:
;    This is the main processing routine. By providing the name of a scenario_name, the scenario_name is processed
;    and all the background as well as sources are created.
;
; :keywords:
;    scenario_name : in, required, type='string', default='stx_scenario_1'
;      specifies the scenario_name to be used
;
;    seed : in/out, optional, type='long'
;      the random seed used for all random number generators
;
; :returns:
;    this routine returnes the desired 'output_path'
;
; :history:
;    12-Nov-2014 - Roman Boutellier (FHNW), initial release
;    22-Jan-2015 - Laszlo I. Etesi (FHNW), updated routine, removed default scenario
;    05-Mar-2015 - Laszlo I. Etesi (FHNW), using user feedback from prepare scenario to skip simulation if necessary
;    10-Mar-2015 - Roman Boutellier (FHNW), changed usage of user feedback (returning without simulation in case out_skip_sim is not 0 (either -1, 1 or 2)
;    26-Feb-2016 - Laszlo I. Etesi (FHNW), pulling out the random seed keyword
;  03-Mar-2017 - Laszlo I. Etesi (FHNW), lowered max photons
;
; :todo:
;
;-
function stx_data_simulation::_run_data_simulation, history=history, scenario_name=scenario_name, scenario_file=scenario_file, seed=seed

  ; 1. define sources
  ;   1.1 read scenario_name, input source list
  ;   1.2 split psources into managable vsources using duration * flux and memory limitation; make sure to split by time
  ; 2. loop over all vsources
  ;   2.1 generate Nph = flux * duration energy samples from DRM * countrate spectrum (Richard)
  ;   2.2 generate photon list Ncnts with Nph elements, assign energies
  ;   2.3 distribute Ncnts uniformly over detector area
  ;   2.4 use source location and check window shadow to drop some counts
  ;   2.5 back project path to rear and front grid planes and drop some counts
  ;   2.6 test for probability of transmission (front + rear) drop failed counts, AND test for
  ;       attenuator transmission (set flag)
  ;   2.7 generate and assign transmission time
  ;   2.8 sort by time
  ;   2.9 convert photon structure to detector event
  ;   2.10 write (append) to vsource file
  ; 3. generate background file
  ; 4. combine all vsource files into psource file
  ; 5. combine background and all all psource files into 'one' time-sorted unfiltered event list

  dsconf = self->get(module='data_simulation')

  default, seed, dsconf.seed

  if dsconf.seed eq 0 then seed = !NULL

  ; Prepare the scenario_name
  self->_prepare_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_subc_str=subc_str, out_output_path=output_path, out_bkg_sources=bkg_sources, out_sources=sources, out_skip_sim=out_skip_sim


  if ((out_skip_sim eq -1) || (out_skip_sim gt 0)) then return, output_path


  ; Split the background struct and then process the backgrounds
  if(ppl_typeof(bkg_sources, compareto='stx_sim_source', /raw)) then begin
    bg_str_split = stx_sim_split_sources(sources=bkg_sources, max_photons=10L^6, subc_str=subc_str, /background)

    ; Process the background
    for bg_idx = 0L, n_elements(bg_str_split)-1 do begin
      ; Extract current background
      curr_bg_str = bg_str_split[bg_idx]

      ; Generate data
      void = self->_run_background_simulation(background_str=curr_bg_str, subc_str=subc_str, output_path=output_path, seed=seed, attenuator_thickness=dsconf.attenuator_thickness)
    endfor
  endif

  ; Split the sources struct and then process the sources
  if (isvalid(sources)) then src_str_split = stx_sim_split_sources(sources=sources, max_photons=10L^7, $
    subc_str=subc_str, all_drm_factors=all_drm_factors, drm0=drm0 )
  for src_idx = 0L, n_elements(src_str_split)-1 do begin
    ; Extract current source
    curr_src_str = src_str_split[src_idx]

    ;    error = 0
    ;    catch, error
    ;    if(error ne 0) then begin
    ;      stop
    ;      help, /last_message, out=last_message
    ;      error = ppl_construct_error(message=last_message, /parse)
    ;      ppl_print_error, error
    ;    endif

    ; Generate data
    void = self->_run_source_simulation(source=curr_src_str, subc_str=subc_str, all_drm_factors=all_drm_factors, drm0=drm0, index=src_idx, output_path=output_path, seed=seed, attenuator_thickness=dsconf.attenuator_thickness)
  endfor

  if(isvalid(bkg_sources)) then complete_set_src = bkg_sources
  if(isvalid(complete_set_src)) then complete_set_src = [complete_set_src, sources] $
  else complete_set_src = sources

  ; Finish the processing of the scenario_name
  ret = self->_wrapup_scenario(scenario_file=sc_file, output_path=output_path, source_str=complete_set_src)

  return, ret
end

;+
; :description:
;    this function reads the given scenario_name
;
; :keywords:
;    scenario_name : in, optional, type='string'
;      this is the scenario name; either this keyword or 'scenario_file' must be specified
;    scenario_file : in, optional, type='string'
;      this is the scenario file path; either this keyword or 'scenario_name' must be specified
;    out_bkg_sources : out, type='stx_sim_source_structure'
;      flat array of background sources
;    out_sources : out, type='stx_sim_source_structure'
;      flat array of sources
;    out_scenario_file: out, optional, type='string'
;      path of the scenario file
;
;
; :history:
;    12-Nov-2014 - Roman Boutellier (FHNW), initial release
;    22-Jan-2015 - Laszlo I. Etesi (FHNW), changed to procedure and updated keyword list
;-
pro stx_data_simulation::_read_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_sources=out_sources, out_bkg_sources=out_bkg_sources
  out_sources = stx_sim_read_scenario(scenario_name=scenario_name, scenario_file=scenario_file, out_bkg_str=out_bkg_sources)
end


;+
; :description:
;    describe the procedure.
;
;
;
; :Keywords:
;    scenario_name
;    scenario_file
;
; :returns:
;
; :history:
;    09-Nov-2014 - Roman Boutellier (FHNW), initial release
;    22-Jan-2015 - Laszlo I. Etesi (FHNW), renamed keywords and added option to ignore non-empty folders
;    05-Mar-2015 - Laszlo I. Etesi (FHNW), - routine is now checking for existing data and let's user choose what to do
;                                          - added keyword out_skip_sim to return user choice when output folder is not empty
;    11-Mar-2015 - Roman Boutellier (FHNW), Added keyword gui to distinguish between calling this method from the GUI or the CLI
;-
pro stx_data_simulation::_prepare_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_subc_str=out_subc_str, out_output_path=out_output_path, out_bkg_sources=out_bkg_sources, out_sources=out_sources, ignore_not_empty=ignore_not_empty, out_skip_sim=out_skip_sim, gui=gui
  default, ignore_not_empty, 1

  ; used to inform the calling program not to call the simulation again.
  ; set this to zero and let the user decide later (if needed)
  out_skip_sim = 0

  ; Read configuration structure
  conf = self->get(module='data_simulation')

  ; Get the base output path
  base_output_path = conf.target_output_directory

  ; check that exactly one is given
  if(ppl_typeof(scenario_name, compareto='string') && ppl_typeof(scenario_file, compareto='string')) then message, 'Please only specify a scenario name or a scenario file'
  if(~ppl_typeof(scenario_name, compareto='string') && ~ppl_typeof(scenario_file, compareto='string')) then message, 'Please specify exactly one: scenario name or a scenario file'

  self->_read_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_sources=out_sources, out_bkg_sources=out_bkg_sources

  print, 'Running simulation using the scenario name ' + scenario_name + ' and file ' + scenario_file

  ; Prepare the output path
  out_output_path = concat_dir(base_output_path, scenario_name)

  ; test if output_path is emtpy or not
  ; this test can be skipped, otherwise the output directory is scanned for old data
  ; there are three possible outcomes:
  ; 1. directory does not exist or is empts -> simulation starts
  ; 2. directory exists and is not empty; a 'sources.fits' does not exist -> let user choose between abort and cleanup -> simulate if cleaned up
  ; 3. directory exists and is not empty and a 'sources.fits' exists -> if sources.fits contains a list of sources that match this scenario -> skip simulation, otherwise let user choose next action (remove "old" files or use them)
  ;  if(~ignore_not_empty) then begin
  ;    all_files = file_search(out_output_path, '*.*', count=count)
  ;
  ;    if(count gt 0) then begin
  ;      source_file_found = file_search(out_output_path, 'sources.fits', count=count)
  ;
  ;      if(count eq 0) then begin
  ;        print, 'Output directory contains unknown data. Please check path ' + out_output_path
  ;
  ;        usr_input = ''
  ;        while (usr_input ne '0' && usr_input ne '1') do begin
  ;          read, 'Would you like to clean the output directory and continue [0] or abort [1]: ', usr_input
  ;        endwhile
  ;
  ;        if(usr_input eq '0') then file_delete, all_files $
  ;        else message, 'Output directory contains unknown data. User requested abort.'
  ;
  ;      endif else begin
  ;        existing_source = mrdfits(source_file_found, 1, structyp='stx_sim_source')
  ;
  ;        ; checking for strings and running trim to ensure the str_diff does not fail
  ;        ; because of white spaces
  ;        for tag_idx = 0L, n_tags(existing_source)-1 do begin
  ;          val = existing_source.(tag_idx)
  ;          if(ppl_typeof(val, compareto='string', /raw)) then existing_source.(tag_idx) = trim(existing_source.(tag_idx))
  ;        endfor
  ;
  ;        ; checking if the existing_source is a valid source and if
  ;        ; they match the sources and background sources currently being processed (need array concat,
  ;        ; and assuming background sources come first, followed by physical sources
  ;        if(~ppl_typeof(existing_source, compareto='stx_sim_source', /raw) || str_diff(existing_source, [out_bkg_sources, out_sources])) then begin
  ;          print, 'Output directory contains outdated simulation data for this scenario (sources.fits does not match source description from ' + scenario_file + ')'
  ;
  ;          usr_input = ''
  ;          while (usr_input ne '0' && usr_input ne '1') do begin
  ;            read, 'Would you like to delete all old data and re-run the simulation [0] or use existing data [1]: ', usr_input
  ;          endwhile
  ;
  ;          if(usr_input eq '0') then begin
  ;            print, 'Deleting outdated data.'
  ;            file_delete, all_files
  ;          endif else out_skip_sim = 1
  ;        endif else out_skip_sim = 1
  ;      endelse
  ;    endif
  ;  endif
  out_skip_sim = self->test_output_path_emtpy(scenario_name=scenario_name, scenario_file=scenario_file, conf=conf,out_bkg_sources=out_bkg_sources, out_sources=out_sources, gui=gui)

  ;  Build subcollimator geometry structure from look-up file
  out_subc_str = stx_construct_subcollimator()

  ;  Check valid subcollimator structure exists
  if(~ppl_typeof(out_subc_str, compareto='stx_subcollimator_array')) then message, 'Invalid subcollimator definition structure.'
end


;+
; :description:
;    Tests if the output path for a data simulation is empty or not. This function also
;    deletes any already computed data if the user agrees to do so. It thereby respects if
;    it has been called from the command line or the GUI (keyword GUI set to 1) and reacts
;    accordingly by asking the user for any input using either the command line or dialog
;    windows. In the end the function returns an integer value which describes what actions
;    have been done.
;
; :Keywords:
;    scenario_name, in, required, type='String'
;       The name of the scenario
;    gui, in, optional, type='Integer'
;       Set to 1 to tell the function it has been called from the GUI
;
; :returns:
;   There are different values which may be returned:
;     - 0     A 0 is returned in case the directory does not exist or is empty. This is the
;             case in the following situations:
;                 - The directory did not exist at the time this function was called
;                 - The directory was empty at the time this function was called
;                 - The directory existed and was not empty at the time this function was called but
;                   the contents have been deleted on request of the user
;     - -1    A -1 is returned in case the user wants to abort simulation of data. This is the case
;             if the directory existed at the time this function was called and the directory was not
;             empty but no 'sources.fits' file existed and the user then requested an abort.
;     - 1     Returning a 1 is done in case the directory existed and was not empty at the time this
;             function was called and a 'sources.fits' file existed. This file contains a list of sources
;             that does not match the scenario, so the simulated file represent an older version of the
;             scenario. The user decided to use the files anyway. This means the scenario does not have to be
;             simulated again.
;     - 2     A 2 is returned in only one case: the directory existed and was not empty at the time this
;             function has been called. A 'sources.fits' file existed and the file contains a list of sources
;             that matches this scenario. This means that the scenario does not have to be simulated again.
;
;     The following actions should be taken, according to the value returned:
;     0:    Simulate the scenario
;     -1:   Abort, i.e. do not simulate the scenario (attention: the files in the directory may contain errors)
;     1, 2: Do not simulate the scenario, as it has already been simulated and the user wants to use the already
;           created files.
;
; :history:
;    09-Mar-2015 - Roman Boutellier (FHNW), Initial release (coded by Laszlo I. Etesi (FHNW))
;    26-Mar-2015 - Laszlo I. Etesi (FHNW), small bugfix: testing if background source is valid before using it
;    20-May-2015 - Laszlo I. Etesi (FHNW), bugfix: could not handle bg-only scenarios
;    21-May-2015 - Laszlo I. Etesi (FHNW), fixing the bugfix: minor error (incorrect order of adding bg and regular sources)
;    10-Jun-2015 - Roman Boutellier (FHNW), adding support for paths of scenarios
;-
function stx_data_simulation::test_output_path_emtpy, scenario_name=scenario_name, gui=gui, conf=conf, out_bkg_sources=out_bkg_sources, out_sources=out_sources, scenario_file=scenario_file
  ; Set the default value for gui to 0 (i.e. no gui used)
  default, gui, 0

  if ~arg_present(conf) then begin
    ; Read configuration structure
    conf = self->get(module='data_simulation')
  endif

  ; Get the base output path
  base_output_path = conf.target_output_directory
  ; Prepare the output path
  if(isvalid(scenario_file)) then begin
    out_output_path = concat_dir(base_output_path, file_basename(scenario_file, '.csv'))
  endif else begin
    out_output_path = concat_dir(base_output_path, scenario_name)
  endelse

  ; Read the scenario in case the out_bkg_sources or out_sources keywords are not set
  if (~arg_present(out_bkg_sources) || ~arg_present(out_sources)) then begin
    self->_read_scenario, scenario_name=scenario_name, scenario_file=scenario_file, out_sources=out_sources, out_bkg_sources=out_bkg_sources
  endif

  ; Read all files within the directory
  all_files = file_search(out_output_path, '*.*', count=count)

  ; Test if output_path is emtpy or not
  ; There are three possible outcomes:
  ; 1. directory does not exist or is empty -> return 0
  ; 2. directory exists and is not empty; a 'sources.fits' does not exist -> let user choose between abort (return -1) and cleanup (return 0)
  ; 3. directory exists and is not empty and a 'sources.fits' exists -> if sources.fits contains a list of sources that match this scenario -> return 2
  ;       otherwise let user choose next action (remove "old" files (return 0) or use them (return 1))
  if(count gt 0) then begin
    source_file_found = file_search(out_output_path, 'sources.fits', count=count)

    if(count eq 0) then begin
      ; No 'sources.fits' file exists. So either return -1 (in case the user wants to abort) or 0 (in case
      ; the user wants to delete all entries in the directory and then continue).

      ; Distinguish between GUI version and CLI version
      if gui eq 1 then begin
        clicked_answer = dialog_message('Output directory contains unknown data. Please check path ' + out_output_path + '. Would you like to clean the output directory ' + $
          ' and continue [yes] or abort [no]?',/question)
        ; Check the answer of the user
        if clicked_answer eq 'Yes' then begin
          ; Delete all files
          file_delete, all_files
          return, 0
        endif else begin
          return, -1
        endelse
      endif else begin
        ; The function has been called from the CLI
        print, 'Output directory contains unknown data. Please check path ' + out_output_path
        ; Ask the user to decide upon which action to take
        usr_input = ''
        while (usr_input ne '0' && usr_input ne '1') do begin
          read, 'Would you like to clean the output directory and continue [0] or abort [1]: ', usr_input
        endwhile
        ; Either delete all files and return 0 or return -1
        if(usr_input eq '0') then begin
          file_delete, all_files
          return, 0
        endif else begin
          message, 'Output directory contains unknown data. User requested abort.'
          return, -1
        endelse
      endelse
    endif else begin
      ; A 'sources.fits' file has been found. So either return 0, 1 or 2

      ; Read the 'sources.fits' file
      existing_source = mrdfits(source_file_found, 1, structyp='stx_sim_source')

      ; checking for strings and running trim to ensure the str_diff does not fail
      ; because of white spaces
      for tag_idx = 0L, n_tags(existing_source)-1 do begin
        val = existing_source.(tag_idx)
        if(ppl_typeof(val, compareto='string', /raw)) then existing_source.(tag_idx) = trim(existing_source.(tag_idx))
      endfor

      ; checking if the existing_source is a valid source and if
      ; they match the sources and background sources currently being processed (need array concat,
      ; and assuming background sources come first, followed by physical sources
      is_valid_out_sources = ppl_typeof(out_sources, compareto='stx_sim_source', /raw)
      is_valid_out_bkg_sources = ppl_typeof(out_bkg_sources, compareto='stx_sim_source', /raw)
      if(is_valid_out_sources && is_valid_out_bkg_sources) then tbc_sources = [out_bkg_sources, out_sources] $
      else if(is_valid_out_sources) then tbc_sources = out_sources $
      else tbc_sources = out_bkg_sources

      if(~ppl_typeof(existing_source, compareto='stx_sim_source', /raw) || str_diff(existing_source, tbc_sources)) then begin

        ; Distinguish between the GUI version and the CLI version
        if gui eq 1 then begin
          clicked_answer = dialog_message('Output directory contains outdated simulation data for this scenario (sources.fits does not match source description from ' + $
            scenario_file + '). Would you like to delete all old data and re-run the simulation [yes] or use the existing data [no]?', $
            /question)
          ; Check the answer of the user
          if clicked_answer eq 'Yes' then begin
            ; Delete the old data and return 0
            file_delete, all_files
            return, 0
          endif else begin
            ; The old data will be used, so return 1
            return, 1
          endelse
        endif else begin ; Start of CLI version
          print, 'Output directory contains outdated simulation data for this scenario (sources.fits does not match source description from ' + scenario_file + ')'

          usr_input = ''
          while (usr_input ne '0' && usr_input ne '1') do begin
            read, 'Would you like to delete all old data and re-run the simulation [0] or use existing data [1]: ', usr_input
          endwhile

          if(usr_input eq '0') then begin
            ; Delete the old data and return 0
            print, 'Deleting outdated data.'
            file_delete, all_files
            return, 0
          endif else begin
            ; The old data will be used, so return 1
            return, 1
          endelse
        endelse ; End of CLI version
      endif else begin
        ; The data files are present and match the 'sources.fits' file. Therefore return 2
        return, 2
      endelse
    endelse
  endif

  ; There are no files in the directory, therefore return 0
  return, 0
end

function stx_data_simulation::_wrapup_scenario, scenario_file=scenario_file, output_path=output_path, source_str=source_str
  ; Copy scenario_name file if available
  if(ppl_typeof(scenario_file, compareto='string') and file_exist(scenario_file)) then file_copy, scenario_file, output_path, /overwrite

  ; save source structures
  mwrfits, source_str, concat_dir(output_path, 'sources.fits'), /create

  return, output_path
end


;+
; :description:
;    Generate the data for the given background
;
; :Keywords:
;    background_str
;    subc_str
;    output_path
;
; :returns:
;
; :history:
;    09-Dec-2014 - Roman Boutellier (FHNW), initial release
;    08-Jan-2014 - Aidan O'Flannagain (TCD), bugfix: changed param input from [param1, param1] to [param1, param2]
;    05-Mar-2014 - Laszlo I. Etesi (FHNW), added failover in case input data is incorrect and leads to no_counts eq zero
;    08-Jul-2015 - ECMD (Graz), replacing stx_sim_energy2ad_channel() with call to stx_sim_energy_2_pixel_ad()
;    30-Sep-2015 - Laszlo I. Etesi (FHNW), fixed an issue which could lead to a det index of 33 (pointed out by Ewan); also changed
;                                          precision of totals from float to double to help avoid precision issue
;    02-Feb-2016 - ECMD (Graz), If uniform distribution is given in a scenario background with the keywords energy_spectrum_param1
;                               and energy_spectrum_param2 they are interpreted as the upper and lower energy limits
;    26-Feb-2016 - Laszlo I. Etesi (FHNW), slightly changed the default background handling
;    11-Oct-2016 - Laszlo I. Etesi (FHNW), updated code to allow overriding pixel and detector id
;    06-Mar-2017 - Laszlo I. Etesi (FHNW), added seed keyword
;-
function stx_data_simulation::_run_background_simulation, background_str=background_str, subc_str=subc_str, output_path=output_path, seed=seed, attenuator_thickness=attenuator_thickness
  default , attenuator_thickness, 1.0

  ; determine number of detector events to simulate from time,
  ; count flux [events/cm^2/s] and total detector effective
  ; area (detectors with bkg_mult_mask = 0 are not simulated)
  no_counts = ceil( background_str.duration * $
    background_str.flux * $
    total( subc_str.det.area * background_str.background_multiplier ) )

  if(no_counts le 0) then message, 'Number of counts less or equal to zero. Please check your source structure.'

  conf = self->get(module='data_simulation')

  ; set default background
  bkg_erange = conf.background_energy_range

  ; override default
  if(background_str.energy_spectrum_type eq 'uniform') then begin
    bkg_erange_override = [background_str.energy_spectrum_param1, background_str.energy_spectrum_param2]

    ; only override it if values set
    bkg_erange = max(bkg_erange_override) gt 0 ? bkg_erange_override : bkg_erange
  endif

  ; TEMPORARY: generate uniform energy distribution. Use Richard's routine later
  edist = stx_sim_energy_distribution(nofelem=no_counts, type=background_str.energy_spectrum_type, $
    param=[background_str.energy_spectrum_param1, background_str.energy_spectrum_param2], energy_range=bkg_erange, seed=seed)

  ; generate time profile
  tdist = stx_sim_time_distribution(data_granulation=data_granulation, nofelem=no_counts, $
    type=background_str.time_distribution, length=background_str.duration, seed=seed) * data_granulation

  if(background_str.detector_override le 0) then begin
    ; uniformly select detector index using detector effective
    ; areas to generate CDF for all detectors
    det_cdf = rebin( total( ( subc_str.det.area * background_str.background_multiplier ) / $
      total(subc_str.det.area * background_str.background_multiplier, /double ), /cumulative, /double ), 32, no_counts )

    ; uniformly select detector indices
    ddist_idx = transpose(rebin(randomu(seed, no_counts, /double), no_counts, 32))

    ; test detectors (generate boolean mask of where ddist_idx is
    ; lower than the detector cdf entry then use the number of '1's
    ; directly as index) RECALL subcollimators numbered 1-32
    ; NB: In very rare cases (precision issue) all det_cdf are greater than ddist_idx which leads to a detector index of 33,
    ; this is worked around by using "<32"; also changed precision of totals from float to double to help avoid precision issue
    det_match_idx = 33 - fix(total(ddist_idx le det_cdf, 1, /double)) < 32
  endif else begin ; do this if detector override is active
    det_match_idx = intarr(no_counts) + background_str.detector_override < 32
  endelse

  if(background_str.pixel_override le 0) then begin
    ; uniformly select pixel index using pixel size
    ; generate CDF (pixels) for all detectors
    pxl_cdf = total(subc_str.det.pixel.area / $
      rebin(total(subc_str.det.pixel.area, 1), 32, 12), /cumulative, 1)

    ; INCONSISTENT PIXEL AND DETECTOR NUMBERING 1.. 32 and 0...11

    ; uniformly select pixel indeces
    pdist_idx = transpose(rebin(randomu(seed, no_counts), no_counts, 12))

    ; test pixels (generate boolean mask of where pdist_idx is lower than the pixel cdf entry; then use the number of '1's directly as index)
    pxl_match_idx = 12 - fix(total(pdist_idx le pxl_cdf[*,det_match_idx-1], 1))
  endif else begin ; do this if pixel override is active
    pxl_match_idx = intarr(no_counts) + background_str.pixel_override - 1 < 11
  endelse

  ; combine all data
  ; convert photons to detector events
  ; TODO update stx_construct_sim_detector_event to work on arrays
  ;transform the passed photons into detector events
  bg_events = replicate({stx_sim_detector_event}, no_counts)
  bg_events.relative_time = tdist + background_str.start_time
  bg_events.detector_index = det_match_idx
  bg_events.pixel_index = pxl_match_idx
  bg_events.energy_ad_channel = stx_sim_energy_2_pixel_ad(edist, det_match_idx, pxl_match_idx )

  bg_events.attenuator_flag = 0b ; bg_events aren't passing through the grids
  ;bg_events.attenuator_flag = stx_attenuator_filter(edist, attenuator_thickness, seed=seed)

  bg_events = stx_sim_timeorder_eventlist(bg_events)

  bg_file_prefix = trim(string(bg_events[0].relative_time)) + '_' + trim(string(fix(background_str.source_id))) + '-' + trim(string(fix(background_str.source_sub_id)))

  stx_sim_detector_events_fits_writer, bg_events, bg_file_prefix, base_dir=output_path, warn_not_empty=1

  return, output_path
end

;+
; :description:
;    Generate the data for the source model(s)
; :Keywords:
;    source
;    subc_str
;    all_drm_factors
;    drm0
;    index
;    output_path
;    seed - seed to control random variable generaton
;
;
; :history:
;   15-Oct-2013 - Shaun Bloomfield (TCD)
;   19-feb-2016 - Richard Schwartz (gsfc) increased performance by using stream format
;   structures instead of packet format. Also, events incident for each detector are kept
;   together until the time codes are assigned to make for faster access to geometry
;   information and to reduce repeated of scanning (using where) of the photon locations
;   as compared to the detector and pixel boundaries. What is stream vs packet format for
;   a data structure?
;
;    IDL> help, replicate( {a:5, b:6}, 10),/st  - PACKET FORMAT
;    ** Structure <f10d030>, 2 tags, length=4, data length=4, refs=1:
;    A               INT              5
;    B               INT              6
;    IDL> help, {a:intarr(10)+5, b:intarr(10)+6 },/st -STREAM FORMAT
;    ** Structure <de51a60>, 2 tags, length=40, data length=40, refs=1:
;    A               INT       Array[10]
;    B               INT       Array[10]

; While for many operations packet format is easier to write programs for there are times
; you need to use stream format as when you have to operate on an entire field in a
; structure. In stream format the data should be in consecutive storage location enabling
; direct access while in packet format the data have to be obtained through indirect addessing
;
;
;    After code speed up it takes 4.6 seconds through the energy filter step for 10117696 events
;    Here are the details from the Profiler
;    Routine                                 Hit count  Time self(ms)   Time/hit(ms)   Time+sub(ms)   Time+sub/hit
;    STX_SIM_PHOTON_PATH                             1         555.21         555.21         2362.1         2362.1
;    INTERPOL                                      829         425.19         0.5129         1268.9         1.5306
;    STX_SIM_MULTISOURCE_SOURCESTRUCT2PHOTON         1         613.21         613.21         1121.9         1121.9
;    STX_SIM_ENERGYFILTER                            1         104.69         104.69         1009.2         1009.2
;    STX_SIM_GRID_TRAN                              64         296.40         4.6313         947.69         14.808
;    VALUE_LOCATE                                  420         842.86         2.0068         842.86         2.0068
;    STX_RANDOM_SAMPLE_COUNT_SPECTRUM                2         8.0395         4.0197         785.51         392.76
;    STX_RANDOM_SAMPLE_COUNT_SPECTRUM_GET_DI         2         91.364         45.682         776.99         388.50
;    STX_SIM_PERIODIC_TRAN                         110         589.75         5.3613         643.51         5.8501
;    STX_SIM_SPLIT_SOURCES                           1         0.1882         0.1882         633.43         633.43
;    STX_SIM_DET_PIX                                32         348.34         10.886         403.19         12.600
;    RANDOMU                                        36         222.43         6.1785         222.43         6.1785
;    HISTOGRAM                                       3         164.63         54.878         164.63         54.878
;
;    Using the old code it took 23.4 seconds
;    Here are the Profiler details
;    Routine                                 Hit count  Time self(ms)   Time/hit(ms)   Time+sub(ms)   Time+sub/hit
;    STX_SIM_PHOTON_PATH                             1         5966.8         5966.8         9765.8         9765.8
;    STX_SIM_MULTISOURCE_SOURCESTRUCT2PHOTON         1         6624.8         6624.8         8723.8         8723.8
;    STX_SIM_ENERGYFILTER                            1         699.72         699.72         4297.3         4297.3
;    XSEC                                          420         315.48         0.7511         3354.1         7.9860
;    XCROSS                                        438         2161.2         4.9343         2974.3         6.7906
;    STX_SIM_GRID_TRAN                              64         1946.7         30.417         2861.0         44.703
;    STX_RANDOM_SAMPLE_COUNT_SPECTRUM                2         13.058         6.5292         1308.5         654.24
;    STX_RANDOM_SAMPLE_COUNT_SPECTRUM_GET_DI         2         132.26         66.130         1294.9         647.47
;    INTERPOL                                      827         501.08         0.6059         928.52         1.1228
;    STX_SIM_PERIODIC_TRAN                         110         743.27         6.7570         796.60         7.2419
;-


function stx_data_simulation::_run_source_simulation, source=source, subc_str=subc_str, all_drm_factors=all_drm_factors, drm0=drm0, index=index, output_path=output_path,attenuator_thickness=attenuator_thickness, seed = seed
  ; energy assigned bag of detected counts,
  ; yet to have photon paths ray traced
  default , attenuator_thickness, 1.0

  ;clock1 = tic('all')

  ph_bag = stx_sim_multisource_sourcestruct2photon( source, $
    subc_str=subc_str, all_drm_factors=all_drm_factors[index], drm0=drm0, seed = seed)

  ;  Determine detector pixel and subcollimator indices for each
  ;  simulated count (i.e., all sources and background)

  det_sub = stx_sim_photon_path( ph_bag, subc_str, source, $
    ph_loc = ph_loc, _extra = _extra )

  ;do the hit test for each count candidate
  ixph   = stx_sim_energyfilter(ph_bag) ;use these indices
  ;Only reporting the index of the surviving photons. We'll use these when
  ;we create the output eventlist.

  ; generate time profile, as the events are independent at this stage
  ;we only pass in the number of surviving events
  time = stx_sim_time_distribution(data_granulation=data_granulation, nofelem=n_elements(ixph), $
    type=source.time_distribution, length=source.duration, seed = seed) * data_granulation
  ;toc, clock1

  ; adjust start times in case of splitting
  time += source.start_time

  ; convert photons to detector events
  ; TODO update stx_construct_sim_detector_event to work on arrays
  ;transform the passed photons into detector events
  events = replicate({stx_sim_detector_event}, n_elements(ixph))
  events.relative_time = time
  events.detector_index = ph_bag.subc_d_n[ixph]
  events.pixel_index = ph_bag.pixel_n[ixph]
  events.energy_ad_channel = stx_sim_energy_2_pixel_ad(ph_bag.energy[ixph], ph_bag.subc_d_n[ixph],  ph_bag.pixel_n[ixph] )
  ; TODO the attenuator_flag is constant 0! should be dynamic dependent on energy channel?
  ;events.attenuator_flag = 0b
  events.attenuator_flag = stx_attenuator_filter(ph_bag.energy[ixph], attenuator_thickness, seed=seed)

  events = stx_sim_timeorder_eventlist(events)

  ; write to file
  events_file_prefix = trim(string(events[0].relative_time,format="(d32)")) + '_' + trim(string(fix(source.source_id))) + '-' + trim(string(fix(source.source_sub_id)))
  ;toc, clock1
  stx_sim_detector_events_fits_writer, events, events_file_prefix, base_dir=output_path, warn_not_empty=1

  return, output_path
end

;+
; :description:
;   This routine reads detector events for a specific scenario_name or data folder. The data are read bin by bin (4s interval) in
;   continuous time intervals, startint at 0 (no "jumping" to later times/bins witout processing all preceeding bins).
;
; :keywords:
;   time_bins : in, required, type='long'
;     specifies for which time bin (in 4s intervals) data are processed; starts at 0 (for interval 0 to 4s)
;   scenario_name : in, optional, type='string'
;     the scenario_name name (e.g. 'stx_scenario_2'); must exist as a folder inside the base_output_path (see application configuration);
;     'scenario_name' or 'data_folder' must be present
;   data_folder : in, optional, type='string'
;     the path to the data folder (containing FITS files with detector counts)
;     'scenario_name' or 'data_folder' must be present
;   rate_control_regime : in, optional, type='integer', default='0'
;     allows specifying a rate control regime state; 0 and 1 are possible (all others are currently ignored)
;   apply_time_filter : in, optional, type='boolean', default='1'
;     if set to 1, the detector counts are filtered for co-incidences
;   history : in/out, optional, type='ppl_history'
;     this structure contains history information on the processing
;
; :returns:
;   the return value is a ds_result_data structure or !NULL in case there are no
;   data for given time bin
;
; :history:
;   19-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;   18-Sep-2014 - Laszlo I. Etesi (FHNW), proper boundary handling
;   30-Nov-2014 - Laszlo I. Etesi (FHNW), speed improvements to data reading
;   15-Jan-2015 - Laszlo I. Etesi (FHNW), the internal coincidence structure (that is keeping a record of filtered counts)
;                                         is now also updated when no data are returned due to data gaps (DSS)
;   30-Jun-2015 -            ECMD (Graz), added t_l, t_r and t_b keywords
;   02-Jul-2015 - Aidan O'Flannagain (TCD), added coarse_flare_row keyword for rcr states > 1
;   02-Jul-2015 - Aidan O'Flannagain (TCD), added implementation of pixel removal and cycling for rcr states > 1
;   17-Jul-2015 - Laszlo I. Etesi (FHNW), fixed an issue with the filtering; some future trigger events were not properly removed
;   01-Feb-2016 -            ECMD (Graz), Now removing small pixel counts in rcr 2 - 4
;   26-Feb-2016 -            ECMD (Graz), Defaults for timefilter parameter moved to config file
;   06-Sep-2016 -            ECMD (Graz), bugfix in pixel cycling
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), added failover in case of data gaps, and updated input parameters/keywords
;   30-Oct-2019 -            ECMD (Graz), added _extra keyword            
;
;-
function stx_data_simulation::_read_detector_events, history=history, scenario_name=scenario_name, data_folder=data_folder, rate_control_regime=rate_control_regime, north=north,$
   t_l = t_l, t_r = t_r, t_b = t_b, t_ig=t_ig, time_bins=time_bins, apply_time_filter=apply_time_filter, coarse_flare_row, $
   split_reading_duration=split_reading_duration, split_reading_threshold=split_reading_threshold, pileup_type=pileup_type, _extra=extra
   
  dsrconf = self->get(module='simulated_data_reader')
  default, rate_control_regime, dsrconf.rate_control_regime
  default, split_reading_threshold, dsrconf.split_reading_threshold
  default, split_reading_duration, dsrconf.split_reading_duration
  default, T_L, dsrconf.T_L
  default, T_R, dsrconf.T_R
  default, T_Ig, dsrconf.T_Ignore
  default, T_B, T_L + T_R + T_Ig
  default, allow_discont, 0
  default, north, 1b
  default, cycle_duration, 0.1d


  ;the background monitor detector
  default, bgm_det_number, 10


  if (~ptr_valid(self.rcr_states)) then begin
    self.rcr_states = ptr_new(stx_fsw_rcr_table2struct(dsrconf.rcr_states_definition_file))
  endif

  rcr_states = *self.rcr_states



  ppl_require, type='long*', keyword='time_bins', time_bins=time_bins

  ; try setting up the data reader
  self->_setup_data_reader, scenario_name=scenario_name, out_output_folder=data_folder 

  ; validate time bins
  if(max(where(time_bins lt 0)) ge 0) then message, 'All bins keyword must be greater than zero.'

  ; sort time bins
  time_bins = time_bins[bsort(time_bins)]

  ; read all data for all time bins
  ; read "a little more" when processing filtered event list to check for "boundary conditions"
  if(apply_time_filter) then extend_t = T_B $
  else extend_t = 0d

  ; set convenience variables
  this_time_bin_start = time_bins[0] * 4d
  this_time_bin_end = (time_bins[-1] + 1) * 4d ; non-inclusive

  ; TODO fix access problem for empty list
  ; before reading check if we have coincidence information for last bin
  if(apply_time_filter and time_bins[0] ne 0 and (*self.available_used_filter_look_ahead_bins).where(time_bins[0]-1) eq !NULL) then $
    message, 'Cannot process given time bins due to lack of coincidence information for previous bins. ' + (((*self.available_used_filter_look_ahead_bins).count() eq 0) ? 'You must start at bin 0.' : 'Available start bins: ' + arr2str(trim(string((*self.available_used_filter_look_ahead_bins).toarray()))))

  ; read detector events for this bin + add first events in next bin (if available)
  ; NB: Assuming sorted input

  count_estimate = self.fits_det_event_reader->countEstimate(t_start=this_time_bin_start, t_end=this_time_bin_end + extend_t)


  if count_estimate gt split_reading_threshold then begin
    ;if count_estimate gt 1000 then begin
    subbins_n = floor((this_time_bin_end-this_time_bin_start)/split_reading_duration)
    subbins = dblarr(2,subbins_n)
    subbins[0,*] = this_time_bin_start + lindgen(subbins_n)*split_reading_duration
    subbins[1,*] = this_time_bin_start + (lindgen(subbins_n)+1)*split_reading_duration
    subbins[-1] = this_time_bin_end + extend_t
    print, "Split FITS Read into intervals: ", subbins_n
  endif else begin
    subbins_n = 1
    subbins = [this_time_bin_start,this_time_bin_end + extend_t]
  endelse

  all_detector_events = []

  total_source_counts = ulon64arr(32)

  ;get the current pixel and attenuator states depending on cfl and rcr
  current_states = rcr_states[where(rcr_states.level eq rate_control_regime)]
  pixel_states = north ? *current_states.north : *current_states.south
  pixel_cycles = n_elements(pixel_states) / 12
  bkg_pixel_states = *current_states.BACKGROUND



  for index = 0L, subbins_n-1 do begin

    detector_events = self.fits_det_event_reader->read(t_start=subbins[0,index], t_end=subbins[1,index], sort=1, /safe)

    if detector_events eq !NULL then continue

    ;sum all events by detector
    total_source_counts[detector_events.detector_index-1]++

    print, index, " Read Events from file: ", n_elements(detector_events)

    ;todo: n.h. remove
    ;for debug and testing only
    ;directory = self.fits_det_event_reader.data_directory
    ;directory +=  path_sep()
    ;if this_time_bin_start gt 108 then save, detector_events, filename= directory + "EL"+trim(this_time_bin_start)+"_"+trim(this_time_bin_end)+"_"+trim(index)+".sav"

    ; fits reader returns an event with relative time eq -1 when no data were found
    ; making sure to update internal coincidence structure in case the data have gaps
    if(detector_events[0].relative_time eq -1) then begin
      if((*self.available_used_filter_look_ahead_bins).where(time_bins[0]) eq !NULL) then begin
        ; add last bin to "used bin list"
        (*self.available_used_filter_look_ahead_bins).add, time_bins[-1]

        ; add !NULL since no events were used
        (*self.used_filter_look_ahead_events).add, !NULL
      endif
      return, !NULL
    endif



    ;remove the attenuator events
    ;but not if overriden by config
    if(current_states.ATTENUATOR && ~dsrconf.attenuator_out) then begin
      ;the background monitor is not covered by attenuator
      attenuator_detector_event_idx = where(detector_events.attenuator_flag eq 1 AND detector_events.DETECTOR_INDEX ne bgm_det_number, no_rcr_1)
      if(no_rcr_1 gt 0) then remove, attenuator_detector_event_idx, detector_events
      destroy, attenuator_detector_event_idx
    endif

    ;use the background pixel mask in any case
    ;there is no background cycling
    bkg_off_pixels = where(bkg_pixel_states eq 0)
    bkg_off_pixel_event_idx = where(is_member(detector_events.pixel_index, bkg_off_pixels) and detector_events.detector_index eq bgm_det_number, nr_off_pixel_events)
    if(nr_off_pixel_events gt 0) then remove, bkg_off_pixel_event_idx, detector_events

    ;no real cycling
    if pixel_cycles eq 1 then begin
      ;use the pixel mask for all detectors beside background
      off_pixels = where(pixel_states eq 0)
      off_pixel_event_idx = where(is_member(detector_events.pixel_index, off_pixels) and detector_events.detector_index ne bgm_det_number, nr_off_pixel_events)
      if(nr_off_pixel_events gt 0) then remove, off_pixel_event_idx, detector_events
    endif else begin

      for c = 0, pixel_cycles-1 do begin
        off_pixels = where(pixel_states[*,c] eq 0)
        modTimes = (detector_events.relative_time-this_time_bin_start) mod (cycle_duration*pixel_cycles)
        off_pixel_and_time_event_idx = where(modTimes ge (c*cycle_duration) and modTimes lt ((c+1)*cycle_duration) and detector_events.detector_index ne bgm_det_number and is_member(detector_events.pixel_index, off_pixels), nr_off_pixel_events)
        if (nr_off_pixel_events gt 0) then remove, off_pixel_and_time_event_idx, detector_events
      endfor

    endelse

    all_detector_events = temporary([temporary(all_detector_events), detector_events])
    print, rate_control_regime, " AFTER RCR Filter: ", n_elements(detector_events)
    print, "Total: ", n_elements(all_detector_events);

  endfor ;sub time interval reading

  detector_events = temporary(all_detector_events)

  ; if we end up here with detector_events being !NULL, we must have lost all events in the section above;
  ; making sure to update internal coincidence structure in case the data have gaps
  if(detector_events eq !NULL) then begin
    if((*self.available_used_filter_look_ahead_bins).where(time_bins[0]) eq !NULL) then begin
      ; add last bin to "used bin list"
      (*self.available_used_filter_look_ahead_bins).add, time_bins[-1]

      ; add !NULL since no events were used
      (*self.used_filter_look_ahead_events).add, !NULL
    endif
    return, !NULL
  endif

  ;if detector_events eq !NULL then return, !NULL

  if(apply_time_filter) then begin
    if(time_bins[0] gt 0) then begin
      ; remove events used in previous bin
      used_det_events_idx = (*self.available_used_filter_look_ahead_bins).where(time_bins[0]-1)

      detector_events_used_last_bin = ((*self.used_filter_look_ahead_events)[used_det_events_idx])[0]

      ; very bulky way of finding and matching the used detector events
      ; TODO better use of where
      if(isvalid(detector_events_used_last_bin)) then begin
        for used_det_event_index = 0L, n_elements(detector_events_used_last_bin)-1 do begin
          current_used_detector = detector_events_used_last_bin[used_det_event_index]
          detector_events_used_last_time_idx = where(detector_events.relative_time eq current_used_detector.relative_time,  detector_events_used_last_time_idx_count)
          if(detector_events_used_last_time_idx_count gt 0) then begin
            detector_events_used_last_idx_extract = detector_events[detector_events_used_last_time_idx]
            detector_events_used_last_time_idx_extract = where(detector_events_used_last_idx_extract.detector_index eq current_used_detector.detector_index $
              and detector_events_used_last_idx_extract.pixel_index eq current_used_detector.pixel_index $
              and detector_events_used_last_idx_extract.energy_ad_channel eq current_used_detector.energy_ad_channel, detector_events_used_last_time_idx_extract_count)
            if(detector_events_used_last_time_idx_extract_count gt 0) then remove, detector_events_used_last_time_idx[detector_events_used_last_time_idx_extract], detector_events
          endif
        endfor
      endif
    endif

    ; test filter (coincidence); this is just done to find all the detector events that are NOT used
    ; in the next bin; fresh filting later; has the potential to be improved
    filtered_events_test = stx_sim_timefilter_eventlist(detector_events, triggers_out=triggers_out_test, event=event, T_L=T_L, T_R=T_R, T_ig = T_Ig, pileup_type=pileup_type)

    ; find all events with triggers in next bin; those will be left
    ; in the next bin and removed from this event list
    extra_events_next_bin_idx = where(event.relative_time ge this_time_bin_end and event.trigger eq 1, no_extra_events_next_bin)

    if(no_extra_events_next_bin gt 0) then begin
      ; now find all events w/o triggers that belong to
      ; the extra events; those will be also removed from this event list

      associated_extra_event_idx_complete = list()

      for extra_idx = 0L, no_extra_events_next_bin-1 do begin
        current_extra_event = event[extra_events_next_bin_idx[extra_idx]]
        associated_extra_event_idx = where(event.relative_time ge current_extra_event.relative_time and event.adgroup_index eq current_extra_event.adgroup_index, no_associated_extra_event)
        ;        associated_extra_event_idx = self->_compare_times_adgroupindices(event, current_extra_event, nmbr_associated_extra_event=no_associated_extra_event)
        associated_extra_event_idx_complete.add, associated_extra_event_idx, /extract

        ; clean-up filtered_events_test (the associated events have no trigger, thus won't be in the filtered_events_test list)
        ; first test only time (for speed reasons), then test for all other properties to identify the exact id(s)
        clean_up_time_idx = where(filtered_events_test.relative_time eq current_extra_event.relative_time, no_clean_up_time_idx_count)
        if(no_clean_up_time_idx_count gt 0) then begin
          filtered_event_test_extract = filtered_events_test[clean_up_time_idx]
          clean_up_idx = where(filtered_event_test_extract.detector_index eq filtered_events_test[clean_up_time_idx].detector_index and $
            filtered_event_test_extract.pixel_index eq filtered_events_test[clean_up_time_idx].pixel_index and $
            filtered_event_test_extract.energy_ad_channel eq filtered_events_test[clean_up_time_idx].energy_ad_channel, clean_up_idx_count)
          if(clean_up_idx_count gt 0) then remove, clean_up_time_idx[clean_up_idx], filtered_events_test
        endif

        ; clean-up triggers_out_test
        clean_up_trgr_time_idx = where(triggers_out_test.relative_time eq current_extra_event.relative_time and current_extra_event.trigger, no_clean_up_trgr_time_idx_count)
        if(no_clean_up_trgr_time_idx_count gt 0) then begin
          triggers_out_test_extract = triggers_out_test[clean_up_trgr_time_idx]
          clean_up_trgr_idx = where(triggers_out_test_extract.detector_index eq triggers_out_test[clean_up_trgr_time_idx].detector_index and $
            triggers_out_test_extract.adgroup_index eq triggers_out_test[clean_up_trgr_time_idx].adgroup_index, clean_up_trgr_idx_count)
          if(clean_up_trgr_idx_count gt 0) then remove, clean_up_trgr_time_idx[clean_up_trgr_idx], triggers_out_test
        endif
      endfor

      ; remove the associated extra events that must stay in the next bin
      associated_extra_event_idx_complete_array = associated_extra_event_idx_complete.toarray()
      associated_extra_event_idx_complete_uniq = associated_extra_event_idx_complete_array[uniq(associated_extra_event_idx_complete_array, bsort(associated_extra_event_idx_complete_array))]

      remove, associated_extra_event_idx_complete_uniq, detector_events
      remove, associated_extra_event_idx_complete_uniq, event

      ; collect all future events that must not be used in the next bin
      remove_future_event_idx = where(event.relative_time ge this_time_bin_end, no_remove_future_event_idx)
    endif

    if((*self.available_used_filter_look_ahead_bins).where(time_bins[0]) eq !NULL) then begin
      ; add last bin to "used bin list"
      (*self.available_used_filter_look_ahead_bins).add, time_bins[-1]

      ; add used events to "used events list" or !NULL if no events were used
      if(isvalid(no_remove_future_event_idx) && no_remove_future_event_idx gt 0) then (*self.used_filter_look_ahead_events).add, detector_events[remove_future_event_idx] $
      else (*self.used_filter_look_ahead_events).add, !NULL
    endif
  endif

  ; restore sources
  sources = mrdfits(concat_dir(data_folder, 'sources.fits'), 1)

  ; set start time for this event list
  start_time = fix(detector_events[0].relative_time /4d) * 4d
  end_time = start_time + 4d

  ; generate detector eventlist
  det_eventlist = stx_construct_sim_detector_eventlist(start_time=start_time, end_time=end_time, detector_events=detector_events, sources=sources)

  if(apply_time_filter) then begin
    ; filter (coincidence); may not be necessary -> reuse filter_events_test

    ; NB: changed this to improve speed; may need more testing to gain more confidence that it is actually working
    ;filtered_events = stx_sim_timefilter_eventlist(detector_events, triggers_out=triggers_out, T_L=T_L, T_R=T_R)
    filtered_events = filtered_events_test
    triggers_out = triggers_out_test

    ;if(str_diff(filtered_events_test, filtered_events)) then stop
    ;if(str_diff(triggers_out_test, triggers_out)) then stop

    ; create filtered event list
    filtered_eventlist = stx_construct_sim_detector_eventlist(start_time=start_time, end_time=end_time, detector_events=filtered_events, sources=sources)

    ; create trigger event list
    trigger_eventlist = stx_construct_sim_detector_eventlist(start_time=start_time, end_time=end_time, detector_events=triggers_out, sources=sources)

    return, stx_construct_ds_result_data(eventlist=det_eventlist, filtered_eventlist=filtered_eventlist, triggers=trigger_eventlist, sources=sources, total_source_counts=total_source_counts)
  endif else return, det_eventlist
end

pro stx_data_simulation::_setup_data_reader, scenario_name=scenario_name, out_output_folder=out_output_folder
  dsconf = self->get(module='data_simulation')
  base_output_path = dsconf.target_output_directory

  ; try locating data folder
  if(ppl_typeof(scenario_name, compareto='string')) then out_output_folder = concat_dir(base_output_path, scenario_name) $
  else if(~ppl_typeof(out_output_folder, compareto='string')) then message, 'Please set either a valid scenario_name name or give a data folder.'

  if(~file_exist(out_output_folder)) then message, 'Could not locate data folder for given scenario_name: ' + out_output_folder

  if(obj_valid(self.fits_det_event_reader)) then return

  self.fits_det_event_reader = obj_new('stx_sim_detector_events_fits_reader_indexed', out_output_folder)
end

;   30-Oct-2019 - ECMD (Graz), added _extra keyword for passthrough to stx_data_simulation::_setup_data_reader 
function stx_data_simulation::_calculate_scenario_length_t, scenario_name=scenario_name, _extra=extra
  self->_setup_data_reader, scenario_name=scenario_name, _extra=extra
  return, self.fits_det_event_reader->total_time_span()
end

;+
; :description:
;    Finds all events w/o triggers that belong to the extra events by comparing the relative_time
;    and the adgroup_index.
;    Returns the index of similar events.
;
; :Params:
;    event
;    extra_event
;
; :Keywords:
;    nmbr_associated_extra_event, out, required
;
; :returns:
;
; :history:
;    22-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_data_simulation::_compare_times_adgroupIndices, event, extra_event, nmbr_associated_extra_event=nmbr_associated_extra_event
  ; Get the indices of greater/equal relative times
  time_indices = where(event.relative_time ge extra_event.relative_time)

  ; Get the indices of equal adgroup_index
  adgroup_indices_list = list()
  event_adgroup_index = event.adgroup_index
  for i=0L, (size(event_adgroup_index))[2]-1 do begin
    if array_equal(event_adgroup_index[*,i],extra_event.adgroup_index) then adgroup_indices_list.add, i
  endfor
  adgroup_indices = adgroup_indices_list.toarray()

  ; Get the indices which are present in adgroup_indices and time_indices, set nmbr_ associated_extra_event to the number of indices and return the indices
  res_indices = self->_set_intersection(time_indices,adgroup_indices)

  nmbr_associated_extra_event = size(res_indices,/n_elements)

  return, res_indices
end

;+
; :description:
;    Creates the intersection of two arrays.
;    Created by IDL founder David Stern.
;
; :Params:
;    a
;    b
;
;
;
; :returns:
;
; :history:
;    22-Apr-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_data_simulation::_set_intersection, a, b
  ; Get maximum and minimum
  minab = min(a, MAX=maxa) > min(b, MAX=maxb)
  maxab = maxa < maxb

  ;If either set is empty, or their ranges don't intersect: result = NULL.
  if maxab lt minab or maxab lt 0 then return, -1
  r = where((histogram(a, MIN=minab, MAX=maxab) ne 0) and  $
    (histogram(b, MIN=minab, MAX=maxab) ne 0), count)
  if count eq 0 then return, -1 else return, r + minab
end

pro stx_data_simulation__define
  compile_opt hidden, idl2
  void = { stx_data_simulation, $
    inherits ppl_processor, $
    used_filter_look_ahead_events : ptr_new(), $
    available_used_filter_look_ahead_bins : ptr_new(), $
    fits_det_event_reader : obj_new(), $
    rcr_states : ptr_new() $
  }
end

