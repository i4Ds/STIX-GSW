;+
; :file_comments:
;   This object stores all data needed for more than one
;   window in the analysis software gui. It provides for
;   every field a setter and a getter.
;   
; :categories:
;   analysis software, gui
;   
; :examples:
;
; :history:
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
; 	 This function initializes the object. It is called automatically upon creation of the object.
;    All the default values are set within this function.
;
; :returns:
;    1 in case the intialization was successfull.
;
; :history:
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::init

  ; Set the observation start and end time default values
  self.observation_start_time = 1306995323
  self.observation_end_time = 1306995672
  self.observation_flare_id = 20060104
  
  return, 1
end


;+
; :description:
; 	 Setter method for the observation start time
;
; :Keywords:
;    new_start_time, in, required
;           The start time in seconds from 79/01/01, 00:00:00 (anytim)
;
; :returns:
;    1 in case of success, -1 otherwise
;    
; :history:
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::set_observation_time_interval_start_time, new_start_time=new_start_time
  if n_elements(new_start_time) eq 0 then return, -1
  
  self.observation_start_time = new_start_time
  return, 1
end

;+
; :description:
; 	 Get the observation time interval start time
;
; :returns:
;    The observation time interval start time in seconds from
;    79/01/01, 00:00:00 (anytim)
;
; :history:
; 	 01.09.2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::get_observation_time_interval_start_time
  return, self.observation_start_time
end

;+
; :description:
;    Setter method for the observation end time
;
; :Keywords:
;    new_end_time, in, required
;           The end time in seconds from 79/01/01, 00:00:00 (anytim)
;
; :returns:
;    1 in case of success, -1 otherwise
;    
; :history:
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::set_observation_time_interval_end_time, new_end_time=new_end_time
  if n_elements(new_end_time) eq 0 then return, -1
  
  self.observation_end_time = new_end_time
  return, 1
end

;+
; :description:
;    Get the observation time interval end time
;
; :returns:
;    The observation time interval end time in seconds from
;    79/01/01, 00:00:00 (anytim)
;
; :history:
;    01.09.2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::get_observation_time_interval_end_time
  return, self.observation_end_time
end

;+
; :description:
;    Setter method for the observation flare
;
; :Keywords:
;    new_flare_id, in, required
;           The of the flare which is observed at the moment
;
; :returns:
;    1 in case of success, -1 otherwise
;    
; :history:
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::set_observation_flare, new_flare_id=new_flare_id
  if n_elements(new_flare_id) eq 0 then return, -1
  
  self.observation_flare_id = new_flare_id
  return, 1
end

;+
; :description:
;    Get the id of the flare which is observed at the moment
;
; :returns:
;    The id of the flare under observation
;
; :history:
;    01.09.2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_data_object::get_observation_flare
  return, self.observation_flare_id
end

pro stx_asw_data_object__define
  compile_opt idl2
  
  define = {stx_asw_data_object, $
      observation_start_time: 0L, $
      observation_end_time: 0L, $
      observation_flare_id: 0L $
    }
end