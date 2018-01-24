PRO stx_fsw_randomtest_sequencegenerator, NSTIM=nstim, SEED=seed, OUTFILE=outfile, ECHANRANGE=echanrange, DTRANGE=dtrange, $
                                          POISSON=pflag, AVRATE=avrate
; Procedure for defining random sequences of pixel, detector, energy channel and time delay 

; 2-Jul-2015 (gh)  Initial version
; 6-Jul-2015 (lie) Minor bugfix: properly assigning simulated values
; 8-jul-2015 gh   Added keywords for nstim, seed, outfile, echanrange, dtrange
; 20-aug-2015 gh  Fixed bug which suppressed last energy, pixel and detector
; 21-aug-2015 gh  Renamed to clarify purpose.
; 26-Aug-2015 gh  Print test duration (s)
;                 Add POISSON keyword to create an exponential distribution of delay times
;                 >>>>>>>>>>>>>NOT YET WORKING<<<<<<<<<<<<<<<<<<<<
;                 
; nstim = number of stimuli to generate
; seed = an initial random number seed
; POISSON = 1 ==> Exponential distribution of delays
; AVRATE = average rate of events

const = 2000
adc1  = 1500
timestep = 2.D-8                ; digitized time step of EGSE in seconds
prange  = [0,11]
drange  = [1,32]

DEFAULT, seed, 15197          ;a random seed
DEFAULT, nstim, 100L
DEFAULT, nprt, 40
DEFAULT, outfile, 'TESTOUT'
DEFAULT, dtmode, 'uniformLOGdelay'
DEFAULT, dtrange, [2.0E-9, 5.]
DEFAULT, echanrange, [0, 4095 - const + adc1] 
DEFAULT, pflag, 0
DEFAULT, avrate, 1000.


rantab  = FLTARR(4,nstim)     ; will contain random numbers [0,1]

timeset = DBLARR (nstim)    

logdlamin = ALOG(dtrange[0])
logdlamax = ALOG(dtrange[1])

lineout = { det:      1,  $
            pixel:    0,  $
            adc2:     0,  $
            reltime:  0.D  }  
tableout = REPLICATE(lineout, nstim)

inparm  = { outfile:      outfile,    $
            nstim:        nstim,      $
            seed:         seed,      $
            const:        const,      $
            adc1:         adc1,       $ 
            echanrange:   echanrange, $
            prange:       prange,     $
            drange:       drange,     $ 
            dtrange:      dtrange,    $
            dtmode:       dtmode,     $
            poissonflag:  pflag,      $
            avrate:       avrate      } 
;
inparm.outfile    = outfile
inparm.nstim      = nstim
inparm.seed       =seed
inparm.const      =const
inparm.adc1       =adc1
inparm.echanrange =echanrange
inparm.prange     =prange
inparm.drange     =drange
inparm.dtrange    =dtrange
inparm.dtmode     =dtmode
inparm.poissonflag = pflag
inparm.avrate     = avrate

;; Get set of random numbers
rantab = RANDOMU(seed, 4, nstim)

;
; Detector, pixels
dset    = FIX(rantab[0, *]   * (drange[1]     - drange[0]    +1)  + drange[0])       ; 20-aug  added +1s to fix bug
pset    = FIX(rantab[1, *]   * (prange[1]     - prange[0]    +1)) + prange[0]
eset    = FIX(rantab[2, *]   * (echanrange[1] - echanrange[0]+1)  + echanrange[0])
;
; Time distribution
IF pflag EQ 0 THEN BEGIN
  dlaset  = timestep * LONG(EXP(rantab[3,*] * (logdlamax - logdlamin) + logdlamin)/timestep)   ; = delay BEFORE this event.
ENDIF
IF pflag NE 0 THEN dlaset = timestep * (1 > LONG(-ALOG(rantab[3,*]) / avrate / timestep))   ; Eliminates zero delays
  
timeset(0) = 0.5                           ; arbitrary delay for 1st event is ignored to ensure enough time for presetting fixed values
FOR n=1, nstim-1 DO timeset(n) = timeset(n-1) + dlaset(n)

; assigning simulated values to output structures
tableout.det      = reform(dset)
tableout.pixel    = reform(pset)
tableout.adc2     = reform(eset)
tableout.reltime  = reform(timeset)

; 
; Print a few lines...
nline = nprt < nstim 
;print, nline

PRINT, 'Duration(s) = ', timeset[nstim-1]

FOR n=0, nline-1 DO PRINT, n, dset[n], pset[n], eset[n], dlaset[n], timeset[n], FORMAT="(4I6, 2F14.8)"
SAVE, FILE=outfile, inparm, tableout
END
