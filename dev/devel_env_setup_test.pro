;---------------------------------------------------------------------------
; Document name: devel_env_setup_test.pro
; Created by:    Laszlo I. Etesi, 2012/04/18
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX/HESPE
;
; NAME:
;       STIX/HESPE Development Environment Setup test script 
;
; PURPOSE: 
;       Runs a few tests to see if the development environment setup was successful
;
; CATEGORY:
;       STIX/HESPE developer support
; 
; CALLING SEQUENCE: 
;       @devel_env_setup_test
;
; HISTORY:
;       2012/04/18, laszlo.etesi@fhnw.ch, initial release
;       2012/10/10, laszlo.etesi@fhnw.ch, replaced "file_exist" with "dir_exist" where necessary
;
;-
project_name = getenv("IDL_PROJECT_NAME")
workspace = getenv("IDL_WORKSPACE_PATH")
status = getenv("IDL_DEVEL_STATUS")
path = workspace + get_delim() + project_name

which, 'devel_env_setup', out=develpath, /quiet
develpath = file_dirname(develpath)

dummy_file = "devel_env_setup_dummy"
dummy_test_folder = list_dir(path)
dummy_test_folder = dummy_test_folder[n_elements(dummy_test_folder)-1]
dummy_file_path = dummy_test_folder + get_delim() + dummy_file + ".pro"

print, "***********************************************************************************************"
print, "** The development environment setup script was found..."
print, "** Selected status: " + status
print, "** Selected workspace: " + workspace
print, "** Selected project: " + project_name

if(status ne "on") then print, "** Development environment varialbe is set to 'off'. Call: devel_env_setup, 'on' and re-run this script."
if(workspace eq "") then print, "** Workspace variable is empty. Please edit your SSW IDL startup script and add 'IDL_WORKSPACE_PATH' to point the workspace where the project sources are located."
if(~dir_exist(workspace)) then print, "** The workspace path does not exist. Please check the value of your 'IDL_WORKSPACE_PATH' variable."
if(project_name eq "") then print, "** The project name is emtpy. Please edit your SSW IDL startup script and add 'IDL_PROJECT_NAME'. This is the main source folder inside the workspace (e.g. stix)"
if(~dir_exist(path)) then print, "** A project with name '" + project_name + "' was not found in workspace '" + workspace + "'."
if(file_exist(path)) then file_copy, develpath + get_delim() + dummy_file + ".pro", dummy_test_folder, /overwrite

devel_env_setup, status, /quiet

which, dummy_file, out=out, /quiet, /all

idx = where(out eq dummy_file_path)

if(file_exist(dummy_file_path)) then file_delete, dummy_file_path

if(idx ge 0) then print, "** Your " + project_name + " developtment environment is properly set up and working!" $
else print, "** Could not find test routine '" + dummy_file + "'. " + project_name + " development environment may not be working."
print, "***********************************************************************************************"