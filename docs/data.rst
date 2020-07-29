====
Data
====

Levels, Levels, Levels
======================

The term 'level' is used in a number of different and unfortunately often confusing contexts when discussing STIX data.
To describe data levels stored in on-ground archives, data levels and structures transmitted from the spacecraft in :term:`TM` and finally integer compression levels.
At a mission level the :term:`SOLO` team has defined and agreed upon a number of levels which specify the type of content and file types as provided to the community:

- L0 - raw telemetry
- L1 - un-calibrated data
- L2 - calibrated data
- L3 - derived products.

In addition to these general data levels the type of data and structures sent from STIX to the ground in TM for bulk science data (BSD) also have a number of levels.
These level correspond to how much on-board processing is done:

- L0 - raw pixel data and triggers from the archive buffer for given time and energy range (no compression)
- L1 - pixel data and triggers compressed,
- L2 - data additionally summed over pixel elements before compression
- L3 - visibilities derived from the summed pixel counts and finally
- L4 - spectrograms see Section


STIX data in TM may also be compressed and this integer compression
has different compression ratios or as levels described in Section 4.3.

Within this document on-ground data levels will be referred to as L0,
L1, L2, STIX on-board bulk science data (BSD) levels as BSD-L0, BSD-L1,
BSD-L2, BSD-L3, BSD-L4, and where necessary compression levels as
integer compression levels.

Solar Orbiter Data Levels


There are four main categories of :term:`STIX` data products:

#. Housekeeping (HK)
#. Quick Look (QL)
#. Bulk Science (BSD)
#. Ancillary and Diagnostics

House Keeping (HK)
==================
House keeping date are

Quick Look
==========
Quick look data are low resolution (time and energy) X-ray data products designed

Light Curves
""""""""""""
X-ray flux in five energy bin every 4 seconds

Background
""""""""""
X-ray flux from the background monitor in five energy bin every 4 seconds

Variance
""""""""

Spectra
"""""""


Bulk Science Data
=================

Pixel Data

Visibilities

Spectrogram






Data Levels
===========

+-------+----------------------------------------------------------------------+
| Level | Description                                                          |
+=======+======================================================================+
| L0    | Raw :term:`TM` contain only information that was available in the    |
|       | packets (times are OBT/SCET, temperatures/voltages in ADC channels)  |
+-------+----------------------------------------------------------------------+
| L1    | Engineering data, uncalibrated FITS metadata follows Solar Orbiter   |
|       | standard for L1 (see section 3.                                      |
+-------+----------------------------------------------------------------------+
| L2    | Calibrated data, science quality FITS, metadata follows Solar Orbiter|
|       | standard for L2 full attitude information                            |
|       | in WCS coordinate frame and time in UTC.                             |
+-------+----------------------------------------------------------------------+
| L3    | Higher-level data Data format as appropriate (The format of both     |
|       | Level-3 data and Calibration data can be chosen depending on the     |
|       | type of data product and the objectives. However, as much as possible|
|       | standard formats should be used (MPEG, FITS, JPEG2000, CDF, PNG, ...)|
+-------+----------------------------------------------------------------------+




-------------------------


STIX Bulk Science Types or Levels
---------------------------------

BSD levels define to the on-board processing and data structures which
are sent to the ground via TM. BSD-L0 is the most raw form of STIX data
it is essentially a dump of the archive buffer between the given times
and energy channels. L1 data is processed on-board applying integer
compression to the pixel counts and triggers as well as removal of empty
time energy bins. L2 data is further summed on-board, summing 12 pixels
to 4 summed pixels per detector, these summed counts and triggers are
also integer compressed. L3 data convert the summed pixel counts into
complex visibilities. Finally L4 data, or spectrograms, are summed over
all pixels and detectors ….

+-------+------------------------+------------------------------+
| Level | Data Type              |  Format and Metadata content |
+=======+========================+==============================+
| L0    | Pixel Data, Triggers   | Raw archive buffer data,     |
|       |                        | no compression of counts     |
+-------+------------------------+------------------------------+
| L1    | Pixel Data, Triggers   | Triggers and pixel counts    |
|       |                        | compressed                   |
+-------+------------------------+------------------------------+
| L2    | Summed Pixel Data,     | Summed pixel counts and      |
|       | Triggers               | triggers compressed          |
+-------+------------------------+------------------------------+
| L3    | Visibilities           | Visibilities derived from the|
|       |                        | summed pixel counts          |
+-------+------------------------+------------------------------+
| L4    | Spectrogram            | All detectors summed         |
+-------+------------------------+------------------------------+





STIX Level 0 to STIX Level 1 Products
=====================================

General Purpose of Level 1 Product
----------------------------------

Create database of the TM which is minimally processed

-  Decompress

-  Bit masks converted to binary mask arrays

-  Onboard time converted to UTC

-  Physical quantities added (keV, counts/s etc)

.. _telemetry-processing-tools-in-gsw-1:

Telemetry Processing Tools in GSW
---------------------------------

Level 1 Product Structures and Contents
---------------------------------------

.. _house-keeping-1:



Quick Look
~~~~~~~~~~

All quick look data are stored in two types of structures control and
data. Control structures contain information necessary to extract the
data from TM such as compression scheme parameters and information to
interpret the data such as integration time as well as other common
information.


Common structure mapping channel to energy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



Light Curve
^^^^^^^^^^^

Control



Data



Background
^^^^^^^^^^

Control


Data



Spectra
^^^^^^^

Control



Data



Variance
^^^^^^^^

Control



Data



Flare Flag and Location
^^^^^^^^^^^^^^^^^^^^^^^

Control



Data



Energy Calibration
^^^^^^^^^^^^^^^^^^

TBD

Flare Status Word
^^^^^^^^^^^^^^^^^

TBD

TM Management Status and Flare list
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TBD

.. _bulk-science-1:

Bulk Science
~~~~~~~~~~~~

??

Level 0 FITS to Level 1 FITS
----------------------------

.. _house-keeping-2:

House Keeping
~~~~~~~~~~~~~

.. _quick-look-2:

Quick Look
~~~~~~~~~~

All quick look data are processed in a similar way the level 0 FITS
files are read and processed for each type of quick look the control
structures above are populated and the data structures are replicated
the required number of times and then filled with the data from the TM.
These two structures are then written as binary table extension to FITS
aligned with UTC days

.. _bulk-science-2:

Bulk Science
~~~~~~~~~~~~

.. _operational-considerations-1:

Operational Considerations
--------------------------

Block size for observation align with mode (it is foreseen that we will
not stay in nominal mode 24h at a time and then go back to safe). Since
these will be more human facing might make sense to align to UTC day
rather than space craft

.. _open-issues-1:

Open Issues
-----------

-  How we plan to use the generated FITS files with existing software

-  

STIX Level 1 to STIX Level 2 Products
=====================================

General Purpose of Level 2 Product
----------------------------------

Calibrated data ready for scientific use. In general, 'analog'
corrections will use fixed parameters, whose off-line calculation will
be externally provided and will assume that all detectors are the same.
Energy averages will use the broad QL energy bands, assuming a fixed but
quasi-realistic spectral shape. The numerical values of these
corrections will be documented.

Since all corrections are linear and known (for a given digital state)
they can be readily and accurately reversed to support alternate
interpretations of the output.

.. _telemetry-processing-tools-in-gsw-2:

Telemetry Processing Tools in GSW
---------------------------------

Level 2 Product Structures and Contents
---------------------------------------

As in Level 1 all Level 2 quick look data are stored in two types of
structures control and data.

Again a common structure mapping channel to energy is included as the
second extension

The correction factors applied to go from Level 1 to Level 2 are
included in the control structure.


3.1 Light curves

3.1.1 Description

The output will be labeled as 'normalized counts/cm2/second'.

Corrections will be made for:

- number of active detectors

- number of disabled pixels

- nominal, detector-averaged photopeak efficiency, averaged over each
broad QL energy band.

- detector-averaged grid transmission, averaged over each broad QL
energy band

- window transmission, averaged over each broad QL energy band

- attenuator transmission, averaged over each broad QL energy band

- detector-averaged live time.

No correction will be made for:

- off-diagonal energy response.

- background.

LC values in each energy band are roughly equivalent to photons/cm/s
when flux dominates background.

3.1.2 Structure



Data



3.2 Background Monitor

3.2.1 Description

There are two interpretations of the pixel-summed output of the
background detector: one is that for low or zero solar flux, it
represents background in 0.81 cm\ :sup:`2` of detector; alternatively,
for high flux data (even with attenuator IN) it represents the
unattenuated flux as seen with a detector of area 0.022 cm2
(corresponding to the apertures in the rear BKGD grid). Output will be
provided to support both interpretations. The user will choose which, if
either, limiting case applies for a given time/energy.

(Analysis of the bulk science data will enable both to be correctly
determined simultaneously.)

Background data will be normalized so that in the absence of solar flux
it should numerically match the light curve output. It can be labeled as
'Low flux-equivalent background [photons/cm2/second]'.

Similarly the flux interpretation output can be labeled as 'High flux
estimated photons/cm2/second'.

For the background interpretation, corrections will be made for:

Corrections will be made for:



Level 1 FITS to Level 2 FITS
----------------------------

Level 1 fits files are read, and the corrections for live time and
analog correction factors are applied.

In order to be in agreement with the HEASARC recommendation, the primary
data array is left empty. The first extension header contains the
lightcurve structure definition and the first extension data array the
lightcurve data. The second extension header contains the energy axis
structure definition and the second extension data array the actual
energy axis data. The third contains the control structure.

.. _operational-considerations-2:

Operational Considerations
--------------------------

Block size for observation align with mode (it is foreseen that we will
not stay in nominal mode 24h at a time and then go back to safe).

Correction Factors 
-------------------

Number of active detectors
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. math:: C\  = \frac{N_{\text{ActiveDetectors}}}{32}

Number of disabled pixels
~~~~~~~~~~~~~~~~~~~~~~~~~

.. math:: \mathbf{C\  =}\frac{\mathbf{N}_{\mathbf{\text{LP\ }}}\mathbf{A}_{\mathbf{\text{LP}}}\mathbf{+}\mathbf{N}_{\mathbf{\text{SP\ }}}\mathbf{A}_{\mathbf{\text{SP}}}}{\mathbf{A}_{\mathbf{D}}}

Where N\ :sub:`LP` and N\ :sub:`SP` are the numbers of enabled large and
small pixels respectively, A\ :sub:`LP` and A\ :sub:`SP` are the areas
of large and small pixels and A\ :sub:`D`

Photopeak efficiency
~~~~~~~~~~~~~~~~~~~~

The detector efficiency is estimated using the IDL procedure
stx_build_drm.

efficiency factor :

[9.21, 1.97, 1.30, 1.31, 1.24]

Grid transmission
~~~~~~~~~~~~~~~~~

Grid transmission is estimated assuming a slit faction of 25% and 0.04
cm of tungsten

grid factor:

[4.00, 4.00, 4.00, 4.00, 3.73]

Background grid transmission
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Background grid transmission is estimated assuming an aperture of 0.022
cm\ :sup:`2` and 0.04 cm of tungsten.

background grid factor:

[36.82, 36.82, 36.82, 36.82, 19.85]

Window transmission
~~~~~~~~~~~~~~~~~~~

Window transmission is estimated assuming and 0.35 cm of beryllium

window factor:

[12.80, 2.06, 1.29, 1.15, 1.10]

Attenuator transmission
~~~~~~~~~~~~~~~~~~~~~~~

Attenuator transmission is estimated assuming and 0.06 cm of aluminum

attenuator factor:

[1.72e+07, 7.39e+02, 9.07e+00, 1.70e+00, 1.06e+00]

Detector-averaged live time
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. math:: N_{\text{in}} = \frac{N_{\text{average\ triggers}}}{\ \left( 1 - \ N_{\text{average\ triggers}}\tau \right)}

.. math:: Lt = \ \frac{exp( - \ \eta\text{\ N}_{\text{in}})}{\ \left( 1 - \ \text{\ N}_{\text{in}}\tau \right)}

Detector-specific live time
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. math:: N_{\text{in}} = \frac{N_{\text{detector\ triggers}}}{\ \left( 1 - \ N_{\text{detector\ triggers}}\tau \right)}

.. math:: Lt = \ \frac{exp( - \ \eta\text{\ N}_{\text{in}})}{\ \left( 1 - \ \text{\ N}_{\text{in}}\tau \right)}

.. _open-issues-2:

Open Issues
-----------

-  Do all (HK, QL, bulk science) have a level 2?

.. |image0| image:: media/image1.emf
   :width: 1.88542in
   :height: 2.03125in
.. |page17image66385024| image:: media/image2.png

