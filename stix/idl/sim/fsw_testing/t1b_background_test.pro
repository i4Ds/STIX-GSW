restore, filename='D:\temp\v20170123\T1b\T1b_dss-fsw.sav', /ver
result = fsw->getdata(output_target='stx_fsw_tmtc', filename='d:\temp\t1b_sim.bin', /ql_light_curves, /ql_background_monitor)

tmtc_reader_fsw_sim = stx_telemetry_reader(filename='d:\temp\t1b_sim.bin', /scan_mode)
tmtc_reader_fsw = stx_telemetry_reader(filename='D:\Dropbox (STIX)\FSW_Test_Data\Data\Published\20170124_221151\ESC\20170126\T1b\QL Update\ut_test_QL_TM.txt', /scan_mode)
tmtc_reader_fsw_sim->getdata, asw_ql_background_monitor=sim_bg, solo_packets=sim_sp
tmtc_reader_fsw->getdata, asw_ql_background_monitor=esc_bg, solo_packets=esc_sp
esc_bg = esc_bg[0]
sim_bg = sim_bg[0]
fsw->getproperty, current_bin=cb, current_time=ct
fsw->getproperty,  stx_fsw_m_background=bkg, /complete, /combine

print, "ESC TM"
help, esc_bg

print, "SIM TM"
help, sim_bg

print, "SIM"
help, bkg

print, "COUNTS"

print, "ESC TM", total(esc_bg.background[*,0:2], /pre)
print, "SIM TM", total(sim_bg.background, /pre)
print, "SIM", total(bkg.background, /pre)

print, "ESC - SIM TM", esc_bg.background[*,0:2] - sim_bg.background
assert_array_equals, esc_bg.background[*,0:2], sim_bg.background


print, "TRGGERS"

print, "ESC TM", total(esc_bg.triggers[0:2], /pre)
print, "SIM TM", total(sim_bg.triggers, /pre)
print, "SIM", total(bkg.triggers, /pre)

print, "ESC - SIM TM", esc_bg.triggers[0:2] - sim_bg.triggers
assert_array_equals, esc_bg.triggers[0:2], sim_bg.triggers

assert_array_equals, esc_bg.energy_axis.edges_1, sim_bg.energy_axis.edges_1
