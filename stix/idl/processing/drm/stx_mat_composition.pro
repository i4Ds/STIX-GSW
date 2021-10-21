
mtrl = ptrarr(8,/alloc)

*mtrl[0] = {name: 'AL', z:[13],frc:[1.0],dens:2.7}
*mtrl[1] = {name: 'BE', z:[4], frc:[1.0], dens:1.85 }
*mtrl[2] = {name: 'KAPTON', z:[1,6,7,8], frc:[0.026362,  0.691133, 0.07327,  0.209235], dens:1.43}
*mtrl[3] = {name: 'MYLAR',  z:[1,6,8], frc:[0.041959,  0.625017,  0.333025 ], dens:1.38}
*mtrl[4] = {name: 'PET', Z:[1,6,8], frc:[0.041959,  0.625017,  0.333025 ], dens:1.37}
*mtrl[5] = {name: 'SOLARBLACK', Z:[1,8, 20, 25], frc:[0.002,  0.415,  0.396,  0.187], dens:3.2}
*mtrl[6] = {name: 'SOLARBLACK', Z:[6,20,15], frc:[0.301,  0.503,  0.195], dens:3.2}
*mtrl[7] = {name: 'TE_O2', Z:[52, 8], FRC: [ 0.7995, 0.2005], dens:5.67}