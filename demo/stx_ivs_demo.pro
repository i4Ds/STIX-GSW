;+---------------------------------------------------------------------------
; Document name: stx_ivs_demo.pro
; Created by:    Nicky Hochmuth, 2013/06/17
;---------------------------------------------------------------------------
;
; PROJECT:
;       STIX
;
; PURPOSE:
;       runs a the interval selection algorithm for imaging and spectroscopy on a spectrogram
;       the spectrogram is defined by a given observation time  
;
; CATEGORY:
;       Stix on Board Algorithm - Simulation
;
; CALLING SEQUENCE:
;       stx_ivs_demo, obs_time = '2002/07/23 ' + ['00:10:00', '00:55:00']
;
; HISTORY:
;       2012/03/05, Nicky.Hochmuth@fhnw.ch, initial release
;
; :keywords:
;    obs_time : in, optional, type="date array [start,end]", default="'2002/07/23 ' + ['00:10:00', '00:55:00']"
;    flare time for the simulation/demo
;    
;    thermalboundary_idx : in, optional, type="int index", 
;    split of the thermal and non_thermal band 
;    
;    min_time_img : in, optional, type="float(2) [thermal,nonthermal]", default="[10.0,4]"
;    minimum time span for image intervals in the thermal and non_thermal band 
;    
;    min_count_img : in, optional, type="int(2,2) [[n1 thermal, n1 nonthermal],[n2 thermal, n2 nonthermal]]", default=" [1000,4000]"
;    minimum not corrected detector counts over all pixel and detectors counts in the thermal and nonthermal range for spliting the time/energy cell further on
;    
;    min_time_spc : in, optional, type="float", default="4.0 sec"
;    the minimum time span for spectroscopy colums 
;    
;    min_count_spc : in, optional, type="long(2) [thermal,nonthermal]", default="[400000,800000]"
;    minimum not corrected detector counts over all pixel and detectors counts in the thermal and nonthermal range for spliting the column further on
;
;    hide_spectroscopy_intervals : in, optional, type="bool", default="1"
;    hide all intervals for spectroscopy
;    
;    hide_imaging_intervals : in, optional, type="bool", default="0"
;    hide all intervals for imaging
;    
;    intervals_out : out, optional, type="array(stx_ivs_interval)"
;    a list of all found intervals for imaging and spectroscopy
;
;    ps : in, optional, type="flag" default="off"
;    print, the spectrogram with found intervals as post script to the local file system
;    
;    plotting: optional, in, type="flag[0|1]" 
;    do some plotting
;    
;    
; :author: nicky.hochmuth
;-
pro stx_ivs_demo, obs_time=obs_time, thermalboundary_idx=thermalboundary_idx, min_time_img=min_time_img, $
    min_count_img=min_count_img,min_time_spc=min_time_spc,min_count_spc=min_count_spc, $
    hide_spectroscopy_intervals=hide_spectroscopy_intervals, $
    hide_imaging_intervals=hide_imaging_intervals, intervals_out=intervals_out, plotting=plotting, ps=ps 
    
  ;default, obs_time,              '2002/07/23 ' + ['00:10:00', '00:55:00']
  default, obs_time,              '2002/02/20 ' + ['11:00:00', '11:29:00']
  default, min_time_img,          [4.0,4]
  ;default, min_count_img,         [[4000,500],[8000,1000]] 
  default, min_time_spc,          4.0; sec
  default, min_count_spc,         [800000,400000] ;[thermal,non_thermal] not corrected detector counts over all pixel and detectors counts
  default, hide_spectroscopy_intervals, 1b
  default, hide_imaging_intervals, 0b
  default, ps, 0
  default, plotting, 1
  
  spg = stx_datafetch_rhessi2stix(obs_time,50000, 30000,[0.1,10],histerese=0.5,plot=0,obj=0)
  
  intervals=stx_ivs(spg, thermalboundary_idx=thermalboundary_idx,  min_time_img=min_time_img, min_count_img=min_count_img,$
    min_count_spc=min_count_spc, min_time_spc=min_time_spc, plotting=plotting,$
    hide_spectroscopy_intervals=hide_spectroscopy_intervals, hide_imaging_intervals=hide_imaging_intervals,ps=ps)
  
  intervals_out = intervals
  
end