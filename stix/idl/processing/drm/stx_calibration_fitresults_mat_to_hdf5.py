#Use Python to convert the matlab file to an hdf5 file which can be read in idl
#This is specifically to read the fit results obtained by O Grimm in the
#STIX TVAC calibration runs from May/June 2017
import scipy.io
import csv
import h5py


data = scipy.io.loadmat('FitResults.mat')

hf = h5py.File('fitsresults.h5', 'w')
for k in ('Entries_31_34', 'FWHM_31', 'FWHM_81', 'FitGain', 'FitOffset', 'TotalEntries'):

	hf.create_dataset(k, data=data[k])

hf.close()