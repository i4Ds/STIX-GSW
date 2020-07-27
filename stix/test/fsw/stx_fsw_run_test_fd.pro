pro stx_fsw_run_test_fd
  r = iut_test_runner('stx_fsw_fd_short__test', gui=0, csv_filename="idltestresult.csv", report=rep, plot=0)
  print, rep
  ;exit, status = (r eq 0 ? 1 : 0) 

end
