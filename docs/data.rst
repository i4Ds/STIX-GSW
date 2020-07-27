===========================================
Creation and Format of Level 0-1-2 Database
===========================================

Levels, Levels, Levels
======================

The term level is used in a number of different and unfortunately often
confusing contexts when discussing STIX data, describing data levels
stored in on-ground archives [RD01], data levels and structures
transmitted from the spacecraft in TM [RD02] and finally integer
compression levels [RD03]. At a mission level the Solar Orbiter team has
defined a number of levels which specify the type of content and file
types as they will be stored in on-ground archives outlined in Section
4.1, L0 raw telemetry, L1 uncalibrated data, L2 calibrated data and L3
derived products. Further the type of data and structures sent from STIX
to the ground in TM for bulk science data (BSD) also have a number of
levels which correspond to how much onboard processing is done, L0 raw
pixel counts and triggers from the archive buffer for given time and
energy range (no compression), L1 pixel and trigger counts compressed,
L2 data additionally summed over pixel elements, L3 visibilities derived
from the summed pixel counts and finally L4 spectrograms see Section
4.2. STIX data in TM may also be compressed and this integer compression
has different compression ratios or as levels described in Section 4.3.

Within this document on-ground data levels will be referred to as L0,
L1, L2, STIX on-board bulk science data (BSD) levels as BSD-L0, BSD-L1,
BSD-L2, BSD-L3, BSD-L4, and where necessary compression levels as
integer compression levels.

Solar Orbiter Data Levels
-------------------------

The key idea behind the L0 data is it should only contain information
which is contained in the raw TM packet itself and is thus a standalone
archive of TM. L1 data are processed incorporating external data, for
example conversion of on-board SCET to UT times, to a level which is
usable for engineering, monitoring and planning purposes. L2 data is
science grade with all necessary calibration and conversion steps
performed, it should be noted they can be different version of L2 data
as better calibrations may become available. Finally L3 data is derived
data products for STIX this could consist of flare images and movies
derived from the L2 data.

========= =================================
================================
============================================================================================================================================================================================================================================================
**Level** |page17image66385024|\ **Source** **Data Type**                    **Format and Metadata content**
========= =================================
================================
============================================================================================================================================================================================================================================================
L0        IT                                Raw TM                           FITS metadata reflect the information that was available in the TM packets only.
L1        IT                                Engineering data, uncalibrated   FITS metadata follows Solar Orbiter standard for L1 (see section 3.
L2        IT                                Calibrated data, science quality FITS, metadata follows Solar Orbiter standard for L2 (see section 3. [RD.09]): full attitude information in WCS coordinate frame and time in UTC.
L3        IT                                Higher-level data                Data format as appropriate (The format of both Level-3 data and Calibration data can be chosen depending on the type of data product and the objectives. However, as much as possible standard formats should be used (MPEG, FITS, JPEG2000, CDF, PNG, ...).
========= =================================
================================
============================================================================================================================================================================================================================================================

Table 4‑1 Ground Archive Levels

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

========= =============================
==========================================================
**Level** **Data Type**                 **Format and Metadata content**
========= =============================
==========================================================
L0        Pixel Counts, Triggers        Raw archive buffer data, no compression of photonic counts
L1        Pixel Counts, Triggers        Trigger and pixel counts compressed
L2        Summed Pixel Counts, Triggers Summed pixel and triggers counts compressed
L3        Visibilities                  Visibilities derived from the summed pixel counts
L4        Spectrogram                   Descrition
========= =============================
==========================================================

Table 4‑2 Bulk Science Data Levels

STIX Integer Compression 
-------------------------

============= =======================
================================================
**Parameter** **Meaning**             **Description**
============= =======================
================================================
S             Sign                    1 if datum may be signed, 0 if strictly positive
K             Number of exponent bits
M             Number of mantissa bits
============= =======================
================================================

Table 4‑3 Integer compression Parameters

Telemetry Acquisition Process
=============================

Solar Orbiter telemetry will be retrieved from the EDDS via routine
queries [RD04]. The timing of SO downlink passes is known and will be
communicated through the E-FECS files [RD05] distributed via GFTS
[RD06]. The pass timings will be used to schedule queries against the
EDDS, this will ensure timely acquisition of either TM data or problem
detection.

**The EDDS is not a long term data storage system TM will only be
temporally stored so it is critical that all TM be obtain in a timely
manner.**

The EDDS stores raw data in a self-descrying and extensible format
consisting of a raw header describing the header fields followed by N
tuples of header fields and data elements as shown in Table 5‑1.

=================
Raw Header
=================
Header Fields (1)
Data Element (1)
Header Field (2)
Data Element (2)
…
Header Field (N)
Data Element (N)
=================

Table 5‑1 EDDS Binary Structure

For TM the fields in Table 5‑2 should be available in the header and in
this case the data field itself consist of the raw packet as generated
on the spacecraft preceded by and EDDS sequence number and packet length
see Table 5‑3.

========== ============================== ================
============================================================================================================================================
**Number** **Field**                      **Type**         **Description**
========== ============================== ================
============================================================================================================================================
1          Source Sequence Counter        Unsigned Integer The sequential binary count of each source packet generated by an application process identified by a unique application process identifier.
2          APID                           Unsigned Integer The PUS Service Application Process Identifier
3          PID                            Unsigned Integer The Packet ID, calculated from the APID
4          Category                       Unsigned Integer Packet category, calculated from the APID
5          P1val                          Unsigned Integer ?? mission specific ??
6          P2val                          Unsigned Integer ?? mission specific ??
7          Data Stream                    Unsigned Integer
8          Generation-Time                CCSDS CUC        On-board generation time
9          Reception-Time                 CCSDS CUC        Time extracted from frame on-ground
10         Packet Length                  Unsigned Integer
11         SPID                           Unsigned Integer Packet ID
12         Ground Station                 Unsigned Integer ID of ground station that received packet
13         Virtual Channel                Unsigned Integer virtual channel of on-board source
14         Data Unit Type                 Unsigned Integer
15         Type                           Unsigned Integer PUS Service Type
16         SubType                        Unsigned Integer PIS Service Sub Type
17         SleServieID                    Unsigned Integer
18         Time Quality                   Unsigned Integer
19         Quality Flag / Time Stamp Type Unsigned Integer
20         Database Version               Unsigned Integer
21         Domain                                         
========== ============================== ================
============================================================================================================================================

Table 5‑2 EDDS TM Packet Raw Headers

========= =================== ========
=========================================================================================================
**Field** **Content**         **Size** **Description**
========= =================== ========
=========================================================================================================
Count     EDDS Sequence Count 1 byte   Data element sequence count applied by EDDS. Clients can use this to detect missing data during transfer.
Length    Date Length         4 bytes  Size of the data field in octets
Data      TM Packet           Raw      Raw packet
========= =================== ========
=========================================================================================================

Table 5‑3 TM Raw Packet Element

TM can be retrieved from the EDDS in a number of formats with a number
of fields or headers and the TM itself. Specific SO headers may be added
in the future TBD. The EDDS supports XML format for TM delivery in this
format the header data and binary TM blob are contained within XML tags
which are both human and machine readable.

Currently not clear if all headers are available in all format types!

Ancillary Data from SolO
========================

Ancillary data products are those products that are not strictly science
data, but are still helpful in scientific analysis or the preparation of
higher-level science data products, for example orbit files containing
the position and velocity of the spacecraft or time conversation data.
The SOC is responsible for the production and distribution of these
ancillary data products that are not relevant to only a single
instruments, and that are not based on instrument telemetry, but rather
platform telemetry (e.g. AOCS parameters in housekeeping) or other data
available on ground. This is not only to reduce duplication of effort,
but also to ensure consistency in the ephemerides etc. that are used in
producing the higher-level science data products on the ground, and
therefore make multi-instrument data analysis as simple as possible.
Ancillary data consists of:

-  Time conversion

-  Orbit

-  Attitude

-  Coordinate Systems, Reference Frames, Fields of View

-  Operation misalignments

for more detailed information on this data see [RD07]

This ancillary data products will be produced in the form of SPICE
kernels for use with the NAIF SPICE toolkit. A limited subset of
ancillary data will be provide in the form of CDF file for planning and
situational awareness around the low latency data.

The ancillary data (spice kernels) will primary be distributed via the
**GFTS mechanism and these files will be the most recent and should be
used for any operational workflow**. The SPICE kernels will also be
available via the ESA SPICE SFTP server and all ancillary data on the
SOAR although not necessarily immediately after they are created.

Telemetry from SOC to STIX Level 0 Products
===========================================

General Purpose of Level 0 Product
----------------------------------

Create a database of unaltered timestamped copies of time-ordered TM
from SOC.

Telemetry Processing Tools in GSW
---------------------------------

Level 0 Product Structures and Contents
---------------------------------------

Until we gain access to the actual EDDS the exact structure of the L0
data cannot be completely defined however we can make some assumptions
about what will be available. Given the EDDS packed structure is
repeated for each TM packet and plan to filter by APID, PID, Category
and possibly Type and Subtype by definition we can at least extract
these into a fixed header and have a single binary table extension where
each packet is a row in the table. There may be additional fields that
remain static which can also be moved to static header.

Header:

APID

PID

Category

SPID

Data Unit Type

Type

SubType

SleServieID

Min-Generation-Time

Max-Generation-Time

Extension (bin table) columns:

Source Sequence Counter

P1val

P2val

Packet Length

Data Stream

   Generation-Time

Reception-Time

Ground Station

Virtual Channel

Time Quality

Quality Flag / Time Stamp Type

Database Version

Domain

House Keeping
~~~~~~~~~~~~~

Remove?

Quick Look
~~~~~~~~~~

Remove?

Bulk Science
~~~~~~~~~~~~

Remove?

Telemetry Acquisition from SOC
------------------------------

Telemetry will be acquired from the EDDS in XML format the header data
will then be use to filter data into silos base on APID, packet category
and SID or SSID. Table 7‑1 list the APIDs and packet categories for STIX
the three main sources of data will be:

-  90-4 housekeeping

-  91-12 BSD and

-  93-12 quick look

however data of other types for example 90-8 diagnostics must also be
handled.

============== ============================================= ==
=========================================================
**Process ID** **Packet Category**                             
============== ============================================= ==
=========================================================
90             Command & Control Application                 1  Telecommand Acknowledgment
\                                                            3  Table Generation
\                                                            4  HK (routine) – service 3
\                                                            6  Functional non-cyclic
\                                                            7  Event Generation -service 5
\                                                            8  Diagnostics
\                                                            9  Dump TM
\                                                            11 Context – service 22
\                                                              
91             Onboard data processing application           12 Science data
92             -                                             -  -
93             Auxiliary Science data processing application 12 Quick look data
94             Auxiliary control data                        5  Functional cyclic (high frequency) – Instrument heartbeat
============== ============================================= ==
=========================================================

Table 7‑1 APIDs and Packet Categories

============== ============================= ====================== =
====================================
**Process ID** **Packet Category**           **Structure ID (SID)**  
============== ============================= ====================== =
====================================
90             Command & Control Application 4                      1 Housekeeping data report mini (SuSW)
\                                                                   2 Housekeeping data report maxi (ASW)
============== ============================= ====================== =
====================================

Table 7‑2 Housekeeping Struture IDs (SIDs)

==============
==============================================================================
====== =======================================
**Process ID** **Science Structure ID (SSID)**                                                      
==============
==============================================================================
====== =======================================
91             Onboard data processing application – Autonomously reported X-ray science data 10, 20 BSD-L0 (autonomous, user selected)
\                                                                                             11, 21 BSD-L1 (autonomous, user selected)
\                                                                                             12, 22 BSD-L2 (autonomous, user selected)
\                                                                                             13, 23 BSD-L3 (autonomous, user selected)
\                                                                                             14,24  BSD-L4 (autonomous, user selected)
\                                                                                             42     Aspect Data (autonomous, user selected)
92             -                                                                              -      -
93             Auxiliary Science data processing application                                  30     QL – light curves
\                                                                                             31     QL – background
\                                                                                             32     QL – Spectra
\                                                                                             33     QL – Variance
\                                                                                             34     QL – Flare flag & location
\                                                                                             40     QL – Flare list
\                                                                                             41     Calibration Spectrum
\                                                                                             43     TM Management status
==============
==============================================================================
====== =======================================

Table 7‑3 Science Struciure IDs (SSIDs)

Telemetry to Level 0 FITS
-------------------------

The telemetry acquired from the EDDS will be process and populated into
the data structures defined above these data structure will then be
serialised to FITS files. These fits file will be

truncated to cover a predefined time period TBD.

Current suggestion include:

-  Instrument safe mode to safe mode (see below)

   -  Not guaranteed to be steady would possible need to keep a record

-  Spacecraft day

   -  Simple but a packet could extend over the boundary

-  By downlink pass

   -  

Operational Considerations
--------------------------

Block size for observation align with mode (it is foreseen that we will
not stay in nominal mode 24h at a time and then go back to safe).

Open Issues
-----------

-  HK and QL very different from bulk science processing don’t
   necessarily fit together

-  How can data be requested from the EDD, by day by hour, service etc?

   -  by pass creation date, request date, should have access to EDDS
      now

-  What is the data format, XML with embedded binary?

   -  ??

-  Do we have example file?

   -  ??

-  How do we know when to re-request data for incomplete sequences?

   -  Need to derive from generation data and length

-  How will this work with current TM reader/writer

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

House Keeping
~~~~~~~~~~~~~

\*\* Does the FSS generate housekeeping TM if not do we have any example
TM? Do the readers /writers currently support HK tm

Header
^^^^^^

FILENAME = ‘solo_LL02_stix-lightcurves_0000086399.1234.fits’

DATE = ‘YYYY-MM-DDThh:mm:ss.SSS’ / FITS file creation date in UTC

OBT-START = 0.0

OBT-END = 0.0

DATE-OBS = ‘YYYY-MM-DDThh:mm:ss.SSS’ / nominal UT date when integration
of this

DATE-END = ‘YYYY-MM-DDThh:mm:ss.SSS’ / nominal UT date when integration
of this

LEVEL = ‘LL02’

OBSRVTRY = ‘Solar Orbiter’

TELESCOP = ‘SOLO/STIX’

INSTRUME = ‘STIX’

OBS_MODE = ‘NOMINAL’

XPOSURE = 0

COMPLETE = ‘C’

Version number

Packet type

Data field header flag

APID – PID

APID – Packet Category

segmentation grouping flags

Source sequence count

Packet data field length - 1

PUS version

Service Type

Service Subtype

destination ID

SCET – coarse part

SCET – fine part

Data – SID1
^^^^^^^^^^^

SW running

Instrument number

Instrument mode

HK_DPU_PCB_T

HK_DPU_FPGA_T

HK_DPU_3V3_C

HK_DPU_2V5_C

HK_DPU_1V5_C

HK_DPU_SPW_C

HK_DPU_SPW0_V

HK_DPU_SPW1_V

HW/SW status 1

HW/SW status 2

HK_DPU_1V5_V

HK_REF_2V5_V

HK_DPU_2V9_V

HK_PSU_TEMP_T

FDIR function status^

FDIR status mask of HK temperature checks**\*

FDIR status mask of HK voltage checks**\*

HKSelftest is execution status flag

Memory services execution status flag

FDIR status mask of HK current checks**\*

Number of executed TC packets

Number of sent TM packets

Number of failed TM generations

Data SID 2
^^^^^^^^^^

SW running = 0

Instrument number = 1

Instrument mode

HK_DPU_PCB_T

HK_DPU_FPGA_T

HK_DPU_3V3_C

HK_DPU_2V5_C

HK_DPU_1V5_C

HK_DPU_SPW_C**\*

HK_DPU_SPW0_V

HK_DPU_SPW1_V

HK_ASP_REF_2V5A_V

HK_ASP_REF_2V5B_V

HK_ASP_TIM01_T

HK_ASP_TIM02_T

HK_ASP_TIM03_T

HK_ASP_TIM04_T

HK_ASP_TIM05_T

HK_ASP_TIM06_T

HK_ASP_TIM07_T

HK_ASP_TIM08_T

HK_ASP_VSENSA_V

HK_ASP_VSENSB_V

HK_ATT_V

ATT_T

HK_HV_01_16_V

HK_HV_17_32_V

DET_Q1_T

DET_Q2_T

DET_Q3_T

DET_Q4_T

HK_DPU_1V5_V

HK_REF_2V5_V

HK_DPU_2V9_V

HK_PSU_TEMP_T

HW/SW status 1*\*

HW/SW status 2*\*

HW/SW status 3*\*

HW/SW status 4*\*

Median value of trigger accumulators \***\*

Maximum value of trigger accumulators

HV regulators mask on/off (see Table 26)

Sequence count of the last TC(20,128) ^

Total number of attenuator motions over the mission

HK_ASP_PHOTOA0_V

HK_ASP_PHOTOA1_V

HK_ASP_PHOTOB0_V

HK_ASP_PHOTOB1_V

Attenuator currents\*

HK_ATT_C

HK_DET_C

FDIR function status

Data SID 4 (heartbeat)
^^^^^^^^^^^^^^^^^^^^^^

Structure ID=4

Heartbeat value - OBT Coarse Time

Flare Message (defined in Table 108)

Z Location (**)

Y Location (**)

Flare Duration

Attenuator motion flag

.. _quick-look-1:

Quick Look
~~~~~~~~~~

All quick look data are stored in two types of structures control and
data. Control structures contain information necessary to extract the
data from TM such as compression scheme parameters and information to
interpret the data such as integration time as well as other common
information.

.. _header-1:

Header
^^^^^^

SIMPLE = T / Primary Header created by MWRFITS v1.13

BITPIX = 8 /

NAXIS = 0 /

EXTEND = T / Extensions may be present

FILENAME= 'solo_l1_stix-background_19790101T000000_V.fits' /FITS
filename

DATE = '2019-01-08T15:47:50.000' /FITS file creation date in UTC

OBT-BEG = '0.0000000' /Start of acquisition time in OBT

TIMESYS = 'OBT ' /System used for time keywords

LEVEL = 'L1 ' /Processing level of the data

CREATOR = 'mwrfits ' /FITS creation software

ORIGIN = 'Solar Orbiter SOC, ESAC' /Location where file has been
generated

VERS_SW = '2.4 ' /Software version

VERSION = '201810121423' /Version of data product

OBSRVTRY= 'Solar Orbiter' /Satellite name

TELESCOP= 'SOLO/STIX' /Telescope/Sensor name

INSTRUME= 'STIX ' /Instrument name

EXPOSURE= ' 320' /[s] Integration time

HISTORY test

DATE-OBS= '1979-01-01T00:00:00.000' /Start of acquisition time in UT

HISTORY test

END

Common structure mapping channel to energy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

{

CHANNEL: 0L, ;

E_MIN: 0.0, ; keV

E_MAX: 0.0 ; keV

}

Light Curve
^^^^^^^^^^^

Control

{

integration_time : 0, ; s

detector_mask : bytarr(32), ;

pixel_mask : bytarr(12), ;

energy_bin_mask : bytarr(32), ;

compression_scheme_counts : intarr(3), ; k, m ,s

compression_scheme_triggers : intarr(3) ; k, m ,s

}

Data

{

COUNTS: lonarr(n_energies), ; Counts

TRIGGERS: 0L, ;

RATE_CONTROL_REGEIME: 0b, ;

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ; s

TIMEDEL: 0.0 ; s

}

Background
^^^^^^^^^^

Control

{

integration_time : 0, ; s

energy_bin_mask : bytarr(32), ;

compression_schema_background : intarr(3), ; k, m, s

compression_schema_trigger : intarr(3) ; k, m, s

}

Data

{

BACKGROUND: lonarr(n_energies), ; Counts

TRIGGERS: 0L, ;

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ;

TIMEDEL: 0 ;

}

Spectra
^^^^^^^

Control

{

pixel_mask : bytarr(16), ;

integration_time : 0, ; s

compression_scheme_spec : intarr(3), ; k, m, s

compression_scheme_trigger : intarr(3) ; k, m ,s

}

Data

{

COUNTS: lonarr(n_energies, n_detectors), ; Counts

TRIGGERS: 0L, ;

CHANNEL: lonarr(n_energies), ;

DETECTOR_MASK: bytarr(32), ;

TIME: 0.0d, ; s

TIMEDEL: 0.0 ; s

}

Variance
^^^^^^^^

Control

{

integration_time : 0.0, ; s

detector_mask : bytarr(32), ;

pixel_mask : bytarr(16), ;

energy_bin_mask : bytarr(32), ;

compression_scheme_variance : intarr(3), ; k, m, s

samples_per_variance: 0 ;

}

Data

{

VARIANCE: 0L, ; ??

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ; s

TIMEDEL: 0.0 ; s

}

Flare Flag and Location
^^^^^^^^^^^^^^^^^^^^^^^

Control

{

integration_time : 0 ; s

n_samples : 0 ;

}

Data

{

flare_flag : 0, ; Flare status

loc_z : 0, ; ?

loc_y : 0 ; ?

time: ; ?

timedel: ; ?

}

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

{

CHANNEL: 0L, ;

E_MIN: 0.0, ; keV

E_MAX: 0.0 ; keV

}

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

Control

{

integration_time : 0, ; s

detector_mask : bytarr(32), ;

pixel_mask : bytarr(12), ;

energy_bin_mask : bytarr(32), ;

correction_factor_active_detectors: 0, ;

correction_factor_disabled_pixels: 0,

detector_efficiency : fltarr(n_energies), ;

grid_transmission: fltarr(n_energies) , ;

window_transmission: fltarr(n_energies) , ;

attenuator_transmission: fltarr(n_energies) , ;

detector_averaged_livetime: 0 ;

}

Data

{

COUNTS: lonarr(n_energies), ; 'normalized counts/cm2/second'

TRIGGERS: 0L, ;

RATE_CONTROL_REGEIME: 0b, ;

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ; s

TIMEDEL: 0.0 ; s

}

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

\* number of disabled pixels in BKGD detector. (If none are disabled,
default area is 0.81 cm2)

\* nominal, photopeak efficiency, averaged over the broad QL energy
bands.

\* Background detector live time.

No correction will be made for:

\* off-diagonal energy response.

For the unattenuated flux interpretation:

Corrections will be made for:

\* specific disabled pixels

\* nominal photopeak efficiency, averaged over the broad QL energy
bands.

\* window transmission, averaged over the broad QL energy bands

\* rear BKGD grid transmission, averaged over the QL energy bands

\* detector-averaged live time.

No correction will be made for:

\* off-diagonal energy response.

\* background.

High flux Background

Control

{

integration_time : 0, ; s

energy_bin_mask : bytarr(32), ;

nbkg_disabled_pixels : 0, ;

detector_efficiency: fltarr(n_energies), ;

bkg_livetime: 0

}

Data

{

BACKGROUND: lonarr(n_energies), ; 'Low flux-equivalent background
[photons/cm2/second]

TRIGGERS: 0L, ;

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ;

TIMEDEL: 0 ;

}

High flux Background

Control

{

integration_time : 0, ; s

energy_bin_mask : bytarr(32), ;

bkg_disabled_pixels: 0 ;

detector_efficiency: fltarr(n_energies), ;

bkg_livetime: 0, ;

bkg_grid_transmission: fltarr(n_energies), ;

window_transmission: fltarr(n_energies) ;

}

Data

{

BACKGROUND: lonarr(n_energies), ; 'High flux estimated
photons/cm2/second'

TRIGGERS: 0L, ;

CHANNEL: lonarr(n_energies), ;

TIME: 0.0d, ;

TIMEDEL: 0 ;

}

Detector-specific spectra

Description

Corrections will be made for:

\* Detector-specific live time

No corrections will be made for:

\* Grid transmission

\* Energy response

\* Window or attenuator transmission

Output can be labeled as 'counts/second'

Control

{

pixel_mask : bytarr(16), ;

integration_time : 0, ; s

detector_livetime: 0 ;

}

Data

{

COUNTS: lonarr(n_energies, n_detectors), ; Counts/s

TRIGGERS: 0L, ;

CHANNEL: lonarr(n_energies), ;

DETECTOR_MASK: bytarr(32), ;

TIME: 0.0d, ; s

TIMEDEL: 0.0 ; s

}

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

Primary Header
^^^^^^^^^^^^^^

FILENAME = ‘solo_LL02_stix-lightcurves_0000086399.1234.fits’

DATE = ‘YYYY-MM-DDThh:mm:ss.SSS’ / FITS file creation date in UTC

OBT-START = 0.0

OBT-END = 0.0

DATE-OBS = ‘YYYY-MM-DDThh:mm:ss.SSS’ / nominal UT date when integration
of this

DATE-END = ‘YYYY-MM-DDThh:mm:ss.SSS’ / nominal UT date when integration
of this

LEVEL = ‘LL02’

OBSRVTRY = ‘Solar Orbiter’

TELESCOP = ‘SOLO/STIX’

INSTRUME = ‘STIX’

OBS_MODE = ‘NOMINAL’

XPOSURE = 0

COMPLETE = ‘C’

**Primary Data array**

No primary array

Lightcurve Extension 1, Header

XTENSION= ‘BINTABLE’

BITPIX = 8

NAXIS = 2

NAXIS1 = 5

NAXIS2 = N_DATA_POINTS

TFIELDS = 3

TUNIT1 = ‘normalized counts/cm2/second’

TUNIT2 = ‘’

TUNIT3 = ‘s

TTYPE1 = ‘COUNTS’

TTYPE2 = ‘CHANNEL’

TTYPE3 = ‘RELATIVE_TIME’

Background Extension 1, Header

XTENSION= ‘BINTABLE’

BITPIX = 8

NAXIS = 2

NAXIS1 = 5

NAXIS2 = N_DATA_POINTS

TFIELDS = 3

TUNIT1 = 'Low flux-equivalent background [photons/cm2/second’

TUNIT2 = ‘’

TUNIT3 = ‘s

TTYPE1 = ‘COUNTS’

TTYPE2 = ‘CHANNEL’

TTYPE3 = ‘RELATIVE_TIME’

Background Extension 1, Header

XTENSION= ‘BINTABLE’

BITPIX = 8

NAXIS = 2

NAXIS1 = 5

NAXIS2 = N_DATA_POINTS

TFIELDS = 3

TUNIT1 = High flux-equivalent background [photons/cm2/second’

TUNIT2 = ‘’

TUNIT3 = ‘s

TTYPE1 = ‘COUNTS’

TTYPE2 = ‘CHANNEL’

TTYPE3 = ‘RELATIVE_TIME’

Background Extension 4, Header

XTENSION= ‘BINTABLE’

BITPIX = 8

NAXIS = 2

NAXIS1 = 30

NAXIS2 = N_DATA_POINTS

TFIELDS = 3

TUNIT1 = ‘counts/s’

TUNIT2 = ‘’

TUNIT3 = ‘s

TTYPE1 = ‘COUNTS’

TTYPE2 = ‘CHANNEL’

TTYPE3 = ‘RELATIVE_TIME’

Extension 2, Header

XTENSION= ‘BINTABLE’

BITPIX = 8

NAXIS = 2

NAXIS1 = 10

NAXIS2 = 5

TFIELDS = 3

EXTNAME = ‘ENEBAND’

TUNIT1 = ‘’

TUNIT2 = ‘keV’

TUNIT3 = ‘keV’

TTYPE1 = ‘CHANNEL’

TTYPE2 = ‘E_MIN’

TTYPE3 = ‘E_MAX’

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

