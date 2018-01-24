function stx_fsw_plot, fsw, _extra=extra
  return, obj_new('stx_flight_software_simulator_plotter', fsw, /plot, _extra=extra)
end