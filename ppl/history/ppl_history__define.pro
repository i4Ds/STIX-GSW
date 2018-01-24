;---------------------------------------------------------------------------
; Document name: ppl_history__define.pro
; Created by:    Nicky Hochmuth 2012/07/17
;---------------------------------------------------------------------------
;+
; PROJECT:
;       IDL Pipeline
;
; NAME:
;       Pipeline history class
;
; PURPOSE:
;       a object that keeps trak of all steps within a pipeline-chane
;
; CATEGORY:
;       Pipeline processing module
;
; CALLING SEQUENCE:
;       
;
;
; HISTORY:
;       2012/07/17, nicky.hochmuth@fhnw.ch, initial release
;      
;-

;+
; :description:
;    Initialization of this class
;
; :returns:
;    True if successful, otherwise false
;-
function ppl_history::init
  
  return, 1
end

;+
; :description:
;    Cleanup of this class
;
; :returns:
;    True if successful, otherwise false
;-
pro ppl_history::cleanup
  for index = 0L, self.last_step -1 do begin
    destroy, self.steps[index]
  endfor
  destroy, self.steps
end

;+
; :description:
;    prints all steps of the history to the screen
;
;
pro ppl_history::print
   for index = 0L, self.last_step -1 do begin
    s = *self.steps[index]
    print, "Step    : "+string(index)
    print, "Time    : "+string(s.TIME)
    print, "Module  : "+string(s.MODULE)
    print, "In  : "
    help, s.IN, /str
    print, "Out  : "
    help, s.OUT, /str
    print, "Config  : "
    help, s.CONFIG, /str
    print, ""
  endfor
end

;+
; :description:
;    gets the last history step
;
; :returns:
;    the last history step structure
;  
function  ppl_history::get_last_step
  return, self.last_step gt 0 ? *self.steps[self.last_step-1] : -1
end

;+
; :description:
;    gets the total number of steps in the history chain
;
; :returns:
;    the total number of steps in the history chain
;
function  ppl_history::get_steps
  return, self.last_step
end

;+
; :description:
;    gets a specific step in the history chain
; :Params:
; step: the step index (0-based)
; :returns:
;    the specific step struct if exist -1 otherwise 
;
function  ppl_history::get_step, step
  step = abs(long(step)) 
  return, self.last_step gt step ? *self.steps[step] : -1
end

;+
; :description:
;    adds a step to the history chain
; :Params:
;  module_name: the module name of the pipelinestep
;  in:  the input
;  out: the calculatet ouptu
;  configuration: the used configuration
;  
pro ppl_history::add, module_name, in,  out, configuration
  if self.last_step ge n_elements(self.steps) then self.steps = [self.steps, make_array(100,/ptr)]  
  
  new_step =ptr_new({type      : 'ppl_history_step',$
            module    : module_name,$
            in        : in,$
            out       : out,$
            config    : configuration, $
            time      : systime()},/no_copy)
                                        
  self.steps[self.last_step++]=new_step
  
end


;+
; :description:
;    Constructor
;
; :hidden:
;-
pro ppl_history__define
  compile_opt idl2, hidden
  void = { ppl_history, $
    steps     : make_array(100,/ptr), $
    last_step : 0}
end