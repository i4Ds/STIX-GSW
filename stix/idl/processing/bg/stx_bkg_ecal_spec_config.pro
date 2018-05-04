;+
; :Description:
;    stx_cal_spec_config generates the background calibration spectrum extraction parameters.
;    Returns this structure for each background subspectrum
;  ** Structure STX_ECAL_SUBSTR, 13 tags, length=36, data length=34:
;  SID             INT              0  - subspectrum ID (0-7)
;  DID             INT              0  - detector ID (1-32)
;  PID             INT              0  - pixel ID (0-11)
;  CMP_K           INT              4  - compression k value
;  CMP_M           INT              4  - compression m value
;  CMP_S           INT              0  - compression s value
;  NPOINTS         INT              8  - number of points in telemetered subspectrum
;  NGROUP          INT              4  - grouping factor, ngroup data bins in each tm'd point
;  ICHAN_LO        INT             19  - starting channel of subsectrum of original, 0-1023
;  SUBSPEC_ORIG    POINTER   <PtrHeapVar68> - original simulated subspectrum selected from 1024 data bins
;  SUBSPEC_GROUPED POINTER   <PtrHeapVar69> - grouped subspectrum, integrated over ngroup bins
;  SUBSPEC_C       POINTER   <PtrHeapVar70> - compressed grouped subspectrum
;  SUBSPEC_RCVR    POINTER   <PtrHeapVar86>; - recovered decompressed and degrouped subspectrum
;
;
;
;
;
; :Author: richard.schwartz@nasa.gov, 21-jul-2016
; 3-may-2018, RAS, corrected the iedg to be contiguous
;-
function stx_bkg_ecal_spec_config
  ;  npoints: 0, $ number of spectral points
  ;    ngroup: 0, $  number of summed channel in spectral point
  ;    ichan_lo: 0} ;lowest channel in subspectrum

  iedg = [ [ 19,50], [51, 100],[101,140], [141,180], [181,210], [211,240] ]
  nconfig = (size( /dim, iedg))[1]
  igroup = [ 4, 1, 4, 4, 1, 4]

  width = reform(  iedg[1,*] - iedg[0,*] + 1 )
  npoints = width /igroup
  ;check that iedg[1,i] is consistent with igroup and iedg[0,i], if not change the iedg
  for i=0,nconfig-1 do begin
    iedg[1,i] = iedg[0,i] + npoints[i] * igroup[i] -1
    if i lt (nconfig-1) then iedg[0,i+1] = iedg[1,i]+1
  endfor

  ilo = reform( iedg[ 0, *] )
  config = replicate( stx_bkg_ecal_substr(), nconfig )

  config.ichan_lo = ilo
  config.ngroup   = igroup
  config.npoints  = npoints
  config.did      = 1 ;should not be zero, even for demo


  return, config
end
