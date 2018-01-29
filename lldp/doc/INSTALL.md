Setup LLDP-STIX VM, Updated 26.01.2018 (lie)
------------------
*	Update INSTR
	*	$HOME/svn/scripts/config_paths -> INSTR=STIX
	
*	Update common/solo_telemetry__define.pro with FHNW-fix
	*	Line 226 needs an IF-THEN-ELSE statement, since ALPHA_IX can be NULL
	
*	Create IO folders
	*	<root>\top_input
	*	<root>\instr_output
	*	<root>\top_input\STIX
	*	<root>\top_input\STIX\requests <- this is the place to put test requests

*	Link IO folders from host system to guest system
	*	<root>\top_input to top_input
	*	<root>\instr_output to instr_output
	*	(Virtual Machine Settings -> Options -> Shared Folders: e.g. C:\Users\LaszloIstvan\Development\stix\lldp\testing\TEST_INPUT to top_input)

*	Edit startup_config for FHNW testing (no NFS use VMware Player Shared Folders)
	*	$HOME/svn/scripts/startup_config
		*	Edit "sudo mount $LLVM_OUTPUTDIR $instr_output -o lookupcache=none,nfsver=3,instr" with "sudo mount -t vmhgfs $LLVM_OUTPUTDIR $instr_output"
		*	Edit "sudo mount $LLVM_OUTPUTDIR $instr_output -o lookupcache=none,nfsver=3,instr" with "sudo mount -t vmhgfs $LLVM_INPUTDIR $top_input"
		
*	Configure configuration ISO file
	* 	Update $HOME/svn/iso-config/Low_Latency_VM_props/UIO.cfg
		*	LLVM_IDL_LIC=1700@soleil-int.cs.technik.fhnw.ch
		*	LLVM_INPUTDIR=.host:/top_input
		*	LLVM_OUTPUTDIR=.host:/instr_output
	*	Generate ISO file
		*	$HOME/svn/scripts/iso-commands UIO
		*	New ISO is at $HOME/svn/iso-config/Low_Latency_VM_props.iso
	* 	Load Low_Latency_VM_props.iso in CD/DVD of VM

*	Copy updated STIX IDL sources
	*	Use Git to download IDL repository to $HOME/svn/idl/stix/STIX-ASW
	*	(removed) NB: There is a .gitignore in STIX-ASW/lldp/common that must not be uploaded. It is there to keep "common" empty and to only use $HOME/svn/idl/common!
	
*	Convert TMTC binary to hex
	*	hexdump -v -e '1/1 "%02x"' FILE > OUTFILE
	
	
BEFORE SENDING VM TO ESA:
*	Undo the startup_config edit!