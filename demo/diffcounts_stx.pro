



;Script used to compute consequences of rate offsets and mitigation strategies
;author: Richard Schwartz, 13-oct-2017
edg=stx_science_energy_channels()
default, nflux, 600
ph_edg = findgen( nflux + 1) * 0.3 + 2.0
drm6 = stx_build_drm( ph_edg, ph_energy_edges = ph_edg, /atten)
drm06 = stx_build_drm( ph_edg, ph_energy_edges = ph_edg, atten = 0)
flux = fltarr( nflux,100)
tlux = flux
g = interpol( [2, 8],100)
tp = interpol( [1.,3.], 100)

e600 = get_edges( ph_edg, /edges_2)
e600m = get_edges( ph_edg, /mean )
for i= 0, 99 do flux[ 0, i] = f_pow( e600, [1.0, g[i]] )
for i= 0, 99 do tlux[0,i] = f_vth( e600, [1.,tp[i]])

true_counts = fltarr( nflux, 100, 4)

; att0 & therm, att1 & therm, att0 & pflux, att1 & pflux
true_counts[ 0, 0, 0 ] = drm06.smatrix # tlux
true_counts[ 0, 0, 1 ] = drm6.smatrix # tlux
true_counts[ 0, 0, 2 ] = drm06.smatrix # flux
true_counts[ 0, 0, 3 ] = drm6.smatrix # flux
edg2=edg.edges_2
wedg = get_edges( edg2, /width)
edgm = get_edges( edg2, /mean)

c32 = fltarr( 32, 100, 100, 4 ); counts in 32 channels, 100 energy offset steps, 100 gamma indices

help, true_counts ;600 energy bins from 2-182 keV in 0.3 keV steps with the count/keV spectra from p-law 2-8 in 100 steps
;Integral = INTERP2INTEG( Xlims, Xdata, Ydata)

for k= 0, 3 do for i = 0, 99 do for j = 0, 99 do c32[ 0, j, i, k] = interp2integ( edg2 - .01*j, e600, true_counts[*, i, k] )

r32 = c32 * 0.0
;simple interpolation
for k=0, 3 do for i = 0, 99 do for j = 0, 99 do begin &$
  ssw_rebinner,  c32[*, i, j, k], edg2 - i*0.01, out, edg2 & r32[0, i, j, k] = out & endfor
;The r32 are the first order corrected counts, let's see how they affect imaging of a point source
;which would have the most contrast
subc_str = stx_construct_subcollimator()
svis = stx_construct_visibility( subc_str )
mapdata = hsi_gauss_source( [3.,3.], [5,5], 0, 0.5, src=src)
source = hsi_gauss_source_def()
source.xysigma = [3., 2.] & source.xyshift_asec = [4,8]
source_map =  hsi_source_map( source, dpx=0.5, /str )
svm = vis_map2vis( source_map, xy, svis)
;add the totflux which we take as the max of abs(obsvis)
svm.totflux = total( source_map.data ) * 2.2 ;totflux relative to obsvis, independent of units of source_map, max( abs( svm.obsvis ))
;need that factor of 2.2, figure it out later
zphase_sense = where( svm.phase_sense eq -1 )

svm.time_range.value = reform( reproduce( anytim(/mjd,'4-oct-2017'), 60), 2, 30)
out = vis_clean( svm, image_dim = [131,131], pixel= 0.5,/no_resid, /make_map)
pix = fltarr(100,4)
pix[*] = cos( interpol( [0, 2*!pi], 400)) + 1
thetai = interpol( [0., 2*!pi], 1000)
pix_theta = fltarr( 4, 1000 )
for i=0,999 do pix_theta[0,i] = cos_sec( thetai[i] )
cmina = pix_theta[2,*]-pix_theta[0,*]
dminb = pix_theta[3,*]-pix_theta[1,*]
abcd_tot = total( pix_theta, 1)
; Compute some numbers we'll use later
; 45 degrees in people units
vphase_shift = !PI / 4.0

; Express phase shift as complex number in cartesian representation
vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
viscomp = complex( cmina, dminb ) * vphase_shift
viscompm = reform(viscomp)
viscompm = complex( real_part( viscompm ), -imaginary( viscompm) )
stheta = atan( imaginary( -svm.obsvis ), real_part( svm.obsvis ) )+!pi
istheta = interpol( dindgen( 1000), thetai, stheta )
ristheta = round( istheta )
ptheta = cos_sec( stheta ) ;These are the relative pixel values after subtracting the DC component
cma = ptheta[2,*] - ptheta[0,*]
dmb = ptheta[3,*] - ptheta[1,*]
obsvis = complex( cma, dmb ) * vphase_shift
;obsvis[ zphase_sense ] = complex( real_part( obsvis[ zphase_sense ] ), -imaginary( obsvis[ zphase_sense ] ))
;Ratio of abs( obsvis ) /totflux
ratio = abs( svm.obsvis ) / svm.totflux ;coarse grids closer to 1
;
;scale ptheta by ratio
tptheta = total( ptheta, 1)
;normalize to 1
ptheta /= rebin( reform(  tptheta, 1, 30), 4, 30 )
;scale to ratio
ptheta *= rebin( reform( ratio, 1, 30), 4, 30 )
cspec = c32[*,*, 50, 1] ; 2 keV thermal, att state 1
rspec = r32[*,*, 50, 1] ;count spectra corrected by simple interpolation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stx_energy_offset_evaluation, source_map, cspec, rspec, allvis, allsrc
default, table_name, 'Offset_evaluation_'
default, spec_name, 'thermal_2_keV_att1_'
table_type = ['no_offset', 'offset', 'corr_offset']
this_table_name = table_name + spec_name + table_type + '.csv'
for j = 0, 2 do write_csv, this_table_name[j], allsrc[*,j],$
    header=tag_names(allsrc), table_header = this_table_name[j]
 
end