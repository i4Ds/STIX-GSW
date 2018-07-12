source D:\\Tools\\scripts\\procedures.tcl

#syslog "Go to CONFIGURATION"
# execTC "ZIX36001 {PIX00080 CONFIGURATION} {PIX00081 MANUAL_NOMINAL}"


syslog "Go to CONFIGURATION manually please"


waittime +00.02.000

syslog "LvOn"
execTC "ZIX36004 {PIX00082 PSU} {PIX00083 4}"

syslog "Raising hardware protection threshold 900, then Quarter 1"
execTC "ZIX36602 {PIX00090 ThldCurrent} {PIX00120 900}"
execTC "ZIX36004 {PIX00082 DETECTORS} {PIX00083 0x1}"

waittime +00.5.000

syslog "Quarter 2"
execTC "ZIX36004 {PIX00082 DETECTORS} {PIX00083 0x2}"

waittime +00.5.000

syslog "Quarter 3"
execTC "ZIX36004 {PIX00082 DETECTORS} {PIX00083 0x4}"

waittime +00.5.000

syslog "Quarter 4"
execTC "ZIX36004 {PIX00082 DETECTORS} {PIX00083 0x8}"

waittime +00.5.000

set HV 30

# Depolarization interval (in minutes) and duration (in seconds)
# set DEPOL_INTERVAL 10
# set DEPOL_DURATION 120
set DEPOL_INTERVAL 2
set DEPOL_DURATION 10

#Switch on high voltage
syslog "Enabling and setting high voltage to setpoint $HV, set depolarization interval and duration"
  execTC "ZIX36004 {PIX00082 PSU} {PIX00083 3}"

execTC "ZIX36605 {PIX00093 HV01-16Voltage} {PIX00120 $HV}"
  execTC "ZIX36605 {PIX00093 HV17-32Voltage} {PIX00120 $HV}"

  #Set depolarization parameters
execTC "ZIX36605 {PIX00093 HV01-16RSTInt(d)} {PIX00120 $DEPOL_INTERVAL}"
  execTC "ZIX36605 {PIX00093 HVRSTIntHV17-32d} {PIX00120 $DEPOL_INTERVAL}"

  execTC "ZIX36605 {PIX00093 HV01-16RSTDur(d)} {PIX00120 $DEPOL_DURATION}"
  execTC "ZIX36605 {PIX00093 HVRSTDurHV17-32d} {PIX00120 $DEPOL_DURATION}"


  syslog "Putting hardware protection threshold back to 546"
execTC "ZIX36602 {PIX00090 ThldCurrent} {PIX00120 546}"


syslog "idefx EnableADCMask 0xFFFF"
execTC "ZIX36602 {PIX00090 EnableADCMask} {PIX00120 0xFFFF}"

syslog "idefx ADCModeMask 0x0000"
execTC "ZIX36602 {PIX00090 ADCModeMask} {PIX00120 0x0000}"

syslog "Configuring all ASICs"
for {set i 1} {$i < 33} {incr i} {
syslog "Detector: $i"

  execTC "ZIX39019 {PIX00301 1} {PIX00203 $i} {PIX00204 0xFFF} {PIX00205 1} {PIX00206 4} {PIX00122 62} {PIX00123 62} {PIX00124 62} {PIX00125 62} {PIX00126 62} {PIX00127 62} {PIX00128 62} {PIX00129 62} {PIX00130 62} {PIX00131 62} {PIX00132 62} {PIX00133 62} {PIX00134 62} {PIX00135 62} {PIX00136 62} {PIX00137 62} {PIX00138 62} {PIX00139 62} {PIX00140 62} {PIX00141 62} {PIX00142 62} {PIX00143 62} {PIX00144 62} {PIX00145 62} {PIX00146 62} {PIX00147 62} {PIX00148 62} {PIX00149 62} {PIX00150 62} {PIX00151 62} {PIX00152 62} {PIX00153 62} {PIX00208 0} {PIX00209 1} {PIX00210 1} {PIX00211 0} {PIX00212 3} {PIX00213 0} {PIX00214 3} {PIX00215 2} {PIX00216 0xFFFFFFFF}"
}

syslog "idefx ADCModeMask 0xFFFF"
execTC "ZIX36602 {PIX00090 ADCModeMask} {PIX00120 0xFFFF}"


#upload ELUT
source [file join [file dirname [info script]] "TC_237_7_ELUT.tcl"]
 

syslog "Applying ELUT"
execTC "ZIX37008 {PIX00261 3} {PIX00262 0}"


#set QL parameters
source [file join [file dirname [info script]] "TC_237_9_QL.tcl"]

#set compression schema
source [file join [file dirname [info script]] "TC_237_11_CS.tcl"]

#send custom TC for this test
source [file join [file dirname [info script]] "test_custom.tcl"]

#go to nominal
syslog "Go to NOMINAL"
execTC "ZIX36001 {PIX00080 NOMINAL} {PIX00081 MANUAL_NOMINAL}"

waittime +00.02.000


syslog "FINISHED"