# Script run on STIX Ground Unit data taken was then exported to the file /dbase/demo/stx_gu_calibration_test_20191001.txt 
# Closely based on example TCL Scripts in STIX-RP-0164-FHNW_PFM-Localisation-Report.pdf


source D:\\Tools\\scripts\\procedures.tcl

 
execTC "ZIX36001 {PIX00080 SAFE} {PIX00081 MANUAL_NOMINAL}"
#syslog "wait for 90 seconds"
# wait for 90 second to ensure we are in the correct state of NOMINAL 
waittime +90.0
syslog "start to configuration"
source  D:\\Tools\\GoToCONFIGURATION.tcl

#                                 Power On Detectors    

# Power on low-voltage and quarters, adapt protection limits
syslog "LvOn"
execTC "ZIX36004 {PIX00082 PSU} {PIX00083 4}"
        
syslog "Raising hardware protection threshold to 900"
execTC "ZIX36602 {PIX00090 ThldCurrent} {PIX00120 900}"
    
syslog "Raising software protection threshold for DPU_2V5_C to 1991"
execTC "ZIX36010 {PIX00107 0x00040000} {PIX00289 4} {PIX00290 1991}"

syslog "Quarters 1-4"
execTC "ZIX36004 {PIX00082 DETECTORS} {PIX00083 0xF}"

syslog "Putting hardware protection threshold back to 546"
execTC "ZIX36602 {PIX00090 ThldCurrent} {PIX00120 546}"
       
# Configure ASICs and read-out       
syslog "idefx EnableADCMask 0xFFFF"
execTC "ZIX36602 {PIX00090 EnableADCMask} {PIX00120 0xFFFF}"
	
syslog "idefx ADCModeMask 0x0000 configuration mode"
execTC "ZIX36602 {PIX00090 ADCModeMask} {PIX00120 0x0000}"


syslog "Resetting all ASICs"
execTC "ZIX39001 {PIX00248 0xFFFFFFFF}"
 
syslog "Configuring all ASICs"
 for {set i 1} {$i < 33} {incr i} {
    syslog "Detector: $i"	   
   
execTC "ZIX39019 {PIX00301 1} {PIX00203 $i} {PIX00204 0xFFF} {PIX00205 1} {PIX00206 4} {PIX00122 62} 	{PIX00123 } {PIX00124 62} {PIX00125 62} {PIX00126 62} {PIX00127 62} {PIX00128 62} {PIX00129 62} {PIX00130 62} {PIX00131 62} {PIX00132 62} {PIX00133 62} {PIX00134 62} {PIX00135 62} {PIX00136 62} {PIX00137 62} {PIX00138 62} {PIX00139 62}  {PIX00140 62} {PIX00141 62} {PIX00142 62} {PIX00143 62} {PIX00144 62}  {PIX00145 62} {PIX00146 62} {PIX00147 62} {PIX00148 62} {PIX00149 62} {PIX00150 62} {PIX00151 62} {PIX00152 62} {PIX00153 62} {PIX00208 0} {PIX00209 1} {PIX00210 1} {PIX00211 2} {PIX00212 3} 	{PIX00213 0} {PIX00214 3} {PIX00215 2} {PIX00216 0xFFFFFFFF}" 
	
 }
  
syslog "Setting latency"
    execTC "ZIX39004 {PIX00052 2}"
  
syslog "idefx ADCModeMask 0xFFFF"
	execTC "ZIX36602 {PIX00090 ADCModeMask} {PIX00120 0xFFFF}"


syslog "FINISHED"

#                                        Set ELUT 

set Value 1200
set Increment 30

set Parameters ""

# Build string with ELUT table boundaries
for {set i 1} {$i < 32} {incr i} {
	set Num [format "%05d" [expr {$i + 482}]]
	set String "{PIX$Num $Value} "
	append Parameters "$String "
	incr Value $Increment
}

# Loop to set ELUT for all pixels of all detectors	
for {set Det 1} {$Det < 33} {incr Det} {
    syslog "Setting ELUT Detector: $Det"

    for {set Pix 0} {$Pix < 12} {incr Pix} { 
        execTC "ZIX37703 {PIX00479 1} {PIX00480 $Det} {PIX00481 $Pix} {PIX00482 0} $Parameters {PIX00514 4095}"
    }
}


syslog "Applying ELUT"
execTC "ZIX37008 {PIX00261 3} {PIX00262 0}"

syslog "FINISHED"

#                                         HV ON 

# global HV value set slightly lower than usual default  
set HV 25

# Depolarization interval (in minutes) and duration (in seconds)
set DEPOL_INTERVAL 1000  
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

syslog "FINISHED"


#                                   Configure Data Taking
syslog "Configuring for TM(21,6)/SSID 41 generation"

# Config continuous accumulation
execTC "ZIX37006 {PIX00260 Disabled}"

#Config calibration (Quiet time 330 -> 5 ms)
execTC "ZIX37003 {PIX00245 200} {PIX00246 150} {PIX00248  0xFFFFFFFF} {PIX00244 0}"


# Full resolution spectrum composed of two 512 bin subspectra
 execTC "ZIX37004 {PIX00250 Enabled} {PIX00251 3} {PIX00217 511} {PIX00218 0} {PIX00219 0} {PIX00220 511} {PIX00221 0} {PIX00222 512} {PIX00223 0} {PIX00224 0} {PIX00225 0} {PIX00226 0} {PIX00227 0} {PIX00228 0} {PIX00229 0} {PIX00230 0} {PIX00231 0} {PIX00232 0} {PIX00233 0} {PIX00234 0} {PIX00235 0} {PIX00236 0} {PIX00237 0} {PIX00238 0} {PIX00239 0} {PIX00240 0} {PIX00248 0xFFFFFFFF} {PIX00249 0xFFF}"

execTC "ZIX21001 {PIX00006 0x00440000}"

source  D:\\Tools\\GoToNOMINAL.tcl

# Data accumulation
# Wait for 3 hours in NOMINAL to get a decent number of calibration spectrum counts  
waittime +3.00.000
  
# go to CONFIGURATION mode, this should cause the science data packets to be sent    
syslog "To CONFIGURATION, HV off"
source  D:\\Tools\\GoToCONFIGURATION.tcl

syslog "Setting HV to zero and switching off HV converters"

execTC "ZIX36605 {PIX00093 HV01-16Voltage} {PIX00120 0}"
execTC "ZIX36605 {PIX00093 HV17-32Voltage} {PIX00120 0}"

execTC "ZIX36005 {PIX00082 PSU} {PIX00083 3}"

syslog "FINISHED"


waittime +20.0
syslog "wait for 20 seconds"

# Go to safe mode  
execTC "ZIX36001 {PIX00080 SAFE} {PIX00081 MANUAL_NOMINAL}"


syslog "FINISHED"


