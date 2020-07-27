@echo off
set IDL_DIR=C:\Program Files\ITT\IDL83
set SSW=D:\ssw
set IDL_STARTUP=D:\ssw\gen\idl\ssw_system\idl_startup_windows.pro

set SSW_PERSONAL_STARTUP=D:\Projekte\Stix\STIX_IDL_GIT\stix_personal_startup.pro
set SSW_INSTR=goes hessi spex xray
set IDL_WORKSPACE_PATH=D:\Projekte\Stix\STIX_IDL_GIT
set IDL_PROJECT_NAME=stix ppl iunit
set IDL_DEVEL_STATUS=on

start /WAIT idl -e stx_fsw_run_test_fd

IF %ERRORLEVEL% NEQ 0 Echo An error was found
IF %ERRORLEVEL% EQU 0 Echo No error found


