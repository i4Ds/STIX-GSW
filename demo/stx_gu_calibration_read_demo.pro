;+
; :description:
;
;    This demonstration procedure reads in and plots background calibration spectra data retrieved from the STIX Ground Unit using the
;    stx_energy_calibration_spectrum_plot routines. A list containing a 1024 [adc bins] x 12 [pixels] x 32 [detectors] for each calibration
;    spectrum is optionally returned.
;
;    The procedure run on the Ground Unit to generate the data is found at:
;     /stix/dbase/demo/gu_calibration_test/stx_run_gu_caibration_test1.tcl
;
;    It was set up to produce background calibration spectra packets (pid = 93, packet_category = 12, service_type =  21,
;    service_subtype =  6, sid_ssid = 41) over several hours of running the Ground Unit. Three test spectra of duration 3 minutes
;    are first generated then a longer spectrum is accumulated over 5 hours.
;
;    The corresponding data file of telemetry retrieved from the Ground Unit is found at:
;     /stix/dbase/demo/gu_calibration_test/stx_gu_calibration_test_20191001.txt
;
;
;    :params:
;
;    filename   : in, required, type="string"
;                the name of the file to be read and processed it should be in the format readable by stx_read_ascii_single_packet_type
;
;    data_directory :  in, type="string"
;                   the path to the directory of the data file
;
;    :keywords:
;
;    calibration_spectrum_array : out, type="list"
;                                 the calibration
;
;    separate_plots             : in, optional, type='boolean'
;                                 if set to 1, each plot corresponding to a calibration spectrum data run will be plot in a separate window
;                                 if set to 0 each plot will be displayed for 5 seconds and then replaced with the next run
;
;    :categories:
;
;     telemetry, demo
;
;
; :history:
;    25-Oct-2019 - ECMD (Graz), initial release
;
;-
pro stx_gu_calibration_read_demo, filename , data_directory, calibration_spectrum_array= calibration_spectrum_array, $
  separate_plots = separate_plots

  default, separate_plots, 0

  default, data_directory, concat_dir(concat_dir( concat_dir('SSW_STIX','dbase'),'demo'),'gu_calibration_test')

  default, filename,    concat_dir(data_directory, 'stx_gu_calibration_test_20191001.txt')

  asw_ql_calibration_spectrum = stx_read_ascii_single_packet_type(filename, packet_type= 'stx_tmtc_ql_calibration_spectrum', verbose = 1 )


  cs_plot = stx_energy_calibration_spectrum_plot()

  if separate_plots then begin
    plot1 =list()
    plot2 =list()
  endif else begin
    op = window()
    op2 = window()
  endelse


  cs_plot = stx_energy_calibration_spectrum_plot()
  calibration_spectrum_array = list()
  foreach spec,asw_ql_calibration_spectrum do begin
    subspec = (spec.SUBSPECTRA)[0]
    if max(subspec.SPECTRUM) gt 0  and (size(subspec.SPECTRUM))[1] gt 1 then begin
      print, stx_time_diff(spec.end_time, spec.start_time)/60

      if separate_plots then begin

        cs_plot->plot, spec, /add_legend, title="Energy Calibration Spectra", /recalculate_data, xrange = [300,550]
        plot1.add, cs_plot

        cs_plot->plot2, spec, /add_legend, title="Energy Calibration Spectra", /recalculate_data, xrange = [300,550]
        plot2.add, cs_plot

      endif else begin
        op.erase
        op2.erase
        cs_plot->plot, spec, /add_legend, title="Energy Calibration Spectra", /recalculate_data, current = op, xrange = [300,550]
        cs_plot->plot2, spec, /add_legend, title="Energy Calibration Spectra", /recalculate_data, current = op2, xrange = [300,550]
        wait, 5
      endelse

      calibration_spectrum = stx_calibration_data_array(spec)
      calibration_spectrum_array.add, calibration_spectrum

    endif
  endforeach


end
