
# STIX-GSW (STIX Ground Software)
Ground-analysis software repository

## Setup of local development repository ##

### Pre-requisites ###
* In order to work with GitHub, you need to install a GIT client on your development workstation. For simplicity, we suggest *SourceTree* (available at: https://www.sourcetreeapp.com/). 
* The scripting language *Perl* needs to be available. A Windows Perl version is *Strawberry Perl* (available at: http://strawberryperl.com/). 
* You also need *SSW (Solar SoftWare)* installed (available at: http://www.mssl.ucl.ac.uk/surf/sswdoc/solarsoft/ssw_install_howto.html), with at least the packages: *GEN, GOES, HESSI, SPEX, XRAY*. SSW will need Perl to run (see pre-requisite above).
* Finally, *IDL (Interactive Data Language)* in version 8.0 or above is required to run the STIX ground analysis software. You also need a valid 

### Step 1: Checkout code ###
1. Start SourceTree (or your Git client). 
2. Go to *File > Clone/New*. This opens the *Clone* dialogue. 
3. In the *Clone* dialogue, set *Source Path / URL:* to https://github.com/i4Ds/STIX-GSW.git, and *Destination Path:* to your desired STIX ground analysis software location on your workstation (referred to as *STIX_SW_DEST* later on). The field *Name:* will be filled automatically, and *Local Folder: \[ROOT\]* should be left as is. Once you clicked on the *Clone* button, **SourceTree will ask for your GitHub credentials**, so it can log you in. **SourceTree will also ask you, under which Name and Email your changes shall be registered. The Name and email does not have to correspond with the information you use to log in to GitHub. Please make sure it is a clear and identifiable Name (e.g. *John Doe*) and an email you want to be affiliated with.** 
4. Once the checkout completed successfully, you should find the sources in the *STIX_SW_DEST* folder you specified in step 3. 

### Step 2: Create personal STIX IDL startup script (PRO-file for IDL) ###
Create an IDL script file with name *stix_personal_startup.pro* file inside your *STIX_SW_DEST* folder with the following content:
```
add_path, getenv('IDL_WORKSPACE_PATH')+get_delim()+'dev', /expand, /quiet
add_path, getenv('IDL_WORKSPACE_PATH')+get_delim()+'iunit', /expand, /quiet
devel_env_setup, 'on'
```

### Step 3: Create STIX-specific startup shell script ###
1. Create a script file with name *startup_stix_sswidl.\[bat,sh\]* (\*.bat on Windows or \*.sh on Unix/Mac systems), e.g. inside your *STIX_SW_DEST* folder.
2. Add the following content to the script file (**make sure that you choose the correct version for your system!**), and replace the variables indicated by *$$VARNAME$$* with the appropriate values for your system:

*$$IDL_DIR$$:* Full path to your IDL directory, e.g. *C:\Program Files\Exelis\IDL85*
*$$SSW$$:* Full path to your Solar SoftWare installation directory, e.g. *C:\SSW*
*$$SSW_PERSONAL_STARTUP$$:* Full path to your personal startup file that was created in *Step 2*, e.g. *C:\Users\johndoe\development\stix\stix_personal_startup.pro*
*$$IDL_WORKSPACE_PATH$$:* Full path to your STIX ground-analysis software installation folder (*STIX_SW_DEST*), e.g. *C:\Users\johndoe\development\stix_git*

**Windows: *startup_stix_sswidl.bat***
```DOS.bat
@echo off
set IDL_DIR=$$IDL_DIR$$
set SSW=$$SSW$$
set IDL_STARTUP=%SSW%\gen\idl\ssw_system\idl_startup_windows.pro

set SSW_PERSONAL_STARTUP=$$SSW_PERSONAL_STARTUP$$
set SSW_INSTR=goes hessi spex xray
set IDL_WORKSPACE_PATH=$$IDL_WORKSPACE_PATH$$
set IDL_PROJECT_NAME=stix ppl
set IDL_DEVEL_STATUS=on

start idlde -data "%IDL_WORKSPACE_PATH%"
```

**Mac/Unix: *startup_stix_sswidl.sh***
```bash
#!/bin/csh -f
setenv IDL_DIR $$IDL_DIR$$
setenv SSW $$SSW$$

setenv SSW_INSTR "goes hessi spex xray"
setenv IDL_STARTUP $$SSW_PERSONAL_STARTUP$$
setenv IDL_WORKSPACE_PATH $$IDL_WORKSPACE_PATH$$
setenv IDL_PROJECT_NAME "stix ppl"
setenv IDL_DEVEL_STATUS on
cd $IDL_WORKSPACE_PATH

source $$SSW$$/gen/setup/setup.ssw

idlde -data $IDL_WORKSPACE_PATH
```

### Step 4: Start development environment ###
SSW IDL can now be started by executing the startup script, created in *Step 3*.

## Troubleshooting ##
### SourceTree keeps asking for your login information and rejects your username/password ###
Make sure your username and password are actually correct and try again. If all looks in order, but the password is still not accepted, try the following:

1. Open the STIX repository in SourceTree
1. Go to your STIX repository slider/page
1. To the upper-right you see the gear symbol labelled "Settings". Click on it.
1. In new dialog window, you should see the repository link in the box labelled "Remote repository paths". In our case it should be *https://github.com/i4Ds/STIX-GSW.git*. Please double click that entry and add your username between the "//" and "github", followed by an "at" sign, e.g. *https://your-user-name@github.com/i4Ds/STIX-GSW.git*.
1. Save your changes and try again logging in. NB: You can provoke a login by clicking on *Fetch*

### The STIX project folder does not show up in your IDL development environment ###
If you cannot see the project folder named "stix" inside the IDL workbench, you may need to create the project manually yourself. Go to *File > New Project* and create a new project called "stix". Make sure you select *Create the new project in the workspace*.
