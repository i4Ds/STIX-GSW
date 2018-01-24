;+
; :Description:
;    This procedure looks at thermal and non-thermal flare models to find scalar correction values for the qlook count
;    rates when the attenuator is in.  Attenuator is assumed to be triggered at a level of 150,000 total counts per sec
;
; :Params:
;    cnts - output structure:
;    IDL> help, cnts
;        ** Structure <1f2ff060>, 9 tags, length=15320, data length=15312, refs=1:
;        VTH0            FLOAT     Array[5, 8]              - counts from each qlook channel for each temp, without attenuator
;        DRM0            STRUCT    -> <Anonymous> Array[1]  - response structure from stx_build_drm
;        VTH1            FLOAT     Array[5, 8]              - counts from each qlook channel for each temp, with attenuator
;        ATT             FLOAT     Array[180]               - attenuation from 600 microns Al
;        POW0            FLOAT     Array[5, 8]              - power law count rates no attenuator for each gamma
;        POW1            FLOAT     Array[5, 8]              - power law count rates with attenuator for each gamma
;        KT              FLOAT     Array[8]                 - temperatures in keV for vth model
;        GAMMA           FLOAT     Array[8]                 - f_pow gamma values (2nd free parameter)
;        A0              FLOAT     Array[8]                 - normalization parameter for each vth0 to get to 150,000
;    ktrange - 2 element range of vth temp parameter in keV
;
; :Keywords:
;    nvths  - number of temperatures between ktrange
;    qlcorr - quicklook correction factors based on 1-dec-2016 ql energy bins 4-10-15-25-50-150
;
; :Author: richard.schwartz@nasa.gov, 1-dec-2016
;-
pro stx_qlook_corrfac, cnts, nvths = nvths, ktrange, qlcorr = qlcorr

qlcorr =   [3000., 50, 3.5, 1.5, 1.1] ;based on cnts.vth0/cnts.vth1 for KT of 1.37 keV
default, nvths, 8
default, ktrange, [0.6, 2.4]
eout = stx_science_energy_channels(/ql)

ein = findgen(181)+3
att = exp( -xsec( ein, 13, 'ab') * 0.06) ;600 microns alum attenuator

rcrs = stx_rcr_area(/all)


einm = get_edges( ein, /mean)
ein2 = get_edges( ein, /edges_2 )
drm0= stx_build_drm( eout.edges_1, ph_energ=ein, att=0)
att = exp( -xsec( einm, 13, 'ab') * 600 / 1e6 * 100)

kt  = interpol( ktrange, nvths)
vths = fltarr( nvths, 180)
pows  = fltarr( nvths, 180 )
gmma  = reverse( 3 + findgen(nvths) )
for i=0,nvths-1 do pows[i, *] = f_pow( einm, [1., gmma[i]])

for i=0, nvths-1 do vths[i,*] = f_vth( ein2, [1., kt[i]])

atts = transpose( reproduce( att, nvths) )

smx = drm0.smatrix
cnts = { vth0: smx#transpose( vths ), drm0: drm0, vth1:smx#transpose( vths * atts), att: att, $
  pow0: smx#transpose(pows), pow1: smx#transpose(pows*atts), kt:kt, gamma:gmma, a0: fltarr( nvths )}
;rescale vth0 and vth1 to 150,000 cnts for each kt
s150 = 1.5e5 /transpose( reproduce( total( cnts.vth0, 1), 5) )
cnts.a0 = reform(s150[0,*])
cnts.vth0 *= s150
cnts.vth1 *= s150
print, ';;;;;;;;;;Temp (keV);;;;;;;;;;;;;
print, kt
print, ';;;;;;;;;;ql counts no atten ;;;;;;;;;;;;;
print, cnts.vth0
print, ';;;;;;;;;;ql counts with atten ;;;;;;;;;;;;;
print, cnts.vth1
print, ';;;;;;;;;;Temp (keV);;;;;;;;;;;;;
print, kt
print, ';;;;;;;;;;Ratios from AL atten ;;;;;;;;;;;;;

print, transpose( cnts.vth0/cnts.vth1 )
print, ';;;;;;;;;;Channel Ratios;;;;;;;;;;;;; ql0 no atten / ql1 with atten
print, transpose( cnts.vth0[0,*]/cnts.vth1[1,*] ) 
print, ';;;;;;;;;;Gamma;;;;;;;;;;;;;
print, gmma
print, ';;;;;;;;;;Ratios from AL atten ;;;;;;;;;;;;;

print, transpose( cnts.pow0/cnts.pow1 )

end
