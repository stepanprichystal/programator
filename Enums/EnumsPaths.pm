
package Enums::EnumsPaths;

use constant {
	Client_EXPORTFILES => "c:\\Export\\ExportFiles\\Pcb\\",
	Client_EXPORTFILESPOOL => "c:\\Export\\ExportFiles\\Pool\\",
	Client_PCBLOCAL    => "c:\\pcb\\",
	Client_EXPORTLOCAL => "c:\\Export\\",
	Client_ELTESTS     => "c:\\Boards\\",

	#Client_MULTICALDB => "c:\\Program Files (x86)\\Multical5-1\\ml.xml",
	Client_INCAMVERSION => "c:\\opt\\InCAM\\",
	Client_IMAGEMAGICK  => "c:\\im\\",

	# Paths for log
	Client_INCAMTMPAOI     => "c:\\tmp\\InCam\\scripts\\aoi_export\\",
	Client_INCAMTMPNC      => "c:\\tmp\\InCam\\scripts\\nc_export\\",
	Client_INCAMTMPCHECKER => "c:\\tmp\\InCam\\scripts\\export_checker\\",
	Client_INCAMTMPOTHER   => "c:\\tmp\\InCam\\scripts\\other\\",
	Client_INCAMTMPSCRIPTS => "c:\\tmp\\InCam\\scripts\\",
	Client_INCAMTMPJOBMNGR => "c:\\tmp\\InCam\\scripts\\job_mngr\\",
	Client_INCAMTMPLOGS 	=> "c:\\tmp\\InCam\\scripts\\logs\\",
	Client_INCAMTMP        => "c:\\tmp\\InCam\\",

};


# Disc R
use constant {

	#    Jobs_ARCHIV => "r:\\Archiv\\",
	#    Jobs_STACKUPS => "r:\\PCB\\pcb\\VV_slozeni\\",
	#    Jobs_PCBMDI => "r:\\pcb\\mdi\\",
	#    Jobs_MDI => "r:\\mdi\\",
	#    Jobs_JETPRINT => "r:\\potisk\\",
 
#	Jobs_ARCHIV   => "\\\\dc2.gatema.cz\\r\\Archiv\\",
#	Jobs_STACKUPS => "\\\\dc2.gatema.cz\\r\\PCB\\pcb\\VV_slozeni\\",
#	Jobs_PCBMDI   => "\\\\dc2.gatema.cz\\r\\pcb\\mdi\\",
#	Jobs_MDI      => "\\\\dc2.gatema.cz\\r\\mdi\\",
#	Jobs_JETPRINT => "\\\\dc2.gatema.cz\\r\\potisk\\",
#	Jobs_ELTESTS =>  "\\\\dc2.gatema.cz\\EL_DATA\\",
#	Jobs_ELTESTSIPC =>  "\\\\dc2.gatema.cz\\r\\El_tests\\",
#	
		
	Jobs_ARCHIV   => "\\\\gatema.cz\\fs\\r\\Archiv\\",
	Jobs_ARCHIVOLD   => "\\\\gatema.cz\\fs\\r\\Archiv_old\\",
	Jobs_ARCHIVREMOVED   => "\\\\gatema.cz\\fs\\r\\Archiv_removed\\",
	Jobs_STACKUPS => "\\\\gatema.cz\\fs\\r\\PCB\\pcb\\VV_slozeni\\",
	Jobs_PCBMDI   => "\\\\gatema.cz\\fs\\r\\pcb\\mdi\\",
	Jobs_MDI      => "\\\\gatema.cz\\fs\\r\\mdi\\",
	Jobs_JETPRINT => "\\\\gatema.cz\\fs\\r\\potisk\\",
	Jobs_ELTESTS =>  "\\\\gatema.cz\\fs\\EL_DATA\\",
	Jobs_ELTESTSIPC =>  "\\\\gatema.cz\\fs\\r\\El_tests\\",
	Jobs_STENCILDATA   => "\\\\gatema.cz\\fs\\r\\Kooperace_sablony\\",
	Jobs_COOPERDRILL   => "\\\\gatema.cz\\fs\\r\\Kooperace_drillMap\\",
	
	# docana zmena
#	Jobs_ARCHIV   => "\\\\fs1.gatema.cz\\ps_data\\r\\Archiv\\",
#	Jobs_STACKUPS => "\\\\fs1.gatema.cz\\ps_data\\r\\PCB\\pcb\\VV_slozeni\\",
#	Jobs_PCBMDI   => "\\\\fs1.gatema.cz\\ps_data\\r\\pcb\\mdi\\",
#	Jobs_MDI      => "\\\\fs1.gatema.cz\\ps_data\\r\\mdi\\",
#	Jobs_JETPRINT => "\\\\fs1.gatema.cz\\ps_data\\r\\potisk\\",
#	Jobs_ELTESTS =>  "\\\\fs1.gatema.cz\\EL_DATA\\",
#	Jobs_ELTESTSIPC =>  "\\\\fs1.gatema.cz\\ps_data\\r\\El_tests\\"	
	
};

# Other paths
use constant {
 	
 	# AOI server
	Jobs_AOITESTS =>  "\\\\192.168.2.66\\spool\\pci\\",
	Jobs_AOITESTSFUSION =>  "\\\\192.168.2.60\\spool\\pci\\",
	Jobs_AOITESTSFUSIONDB =>  "\\\\192.168.2.60\\job_db\\",
	Jobs_JETPRINTMACHINE => "\\\\printer-pc\\jobs\\"
};

# sometimes script is run from windows service, thus mapped disc Y is not avalaible, use incam\imcam adress
use constant {
	InCAM_serverDisc => ( -e "Y:" )
	? "y:\\"
	: "\\\\incam\\InCAM\\",

	#InCAM_serverDisc => "\\\\incam\\InCAM\\",

	InCAM_server => ( -e "Y:" )
	? "y:\\server\\"
	: "\\\\incam\\incam_server\\",

	#InCAM_server => "\\\\incam\\incam_server\\",

	InCAM_users => ( -e "Y:" )
	? "y:\\server\\users\\"
	: "\\\\incam\\incam_server\\",

	#InCAM_users => "\\\\incam\\incam_server\\",

	InCAM_hooks => ( -e "Y:" )
	? "y:\\server\\site_data\\hooks\\"
	: "\\\\incam\\incam_server\\site_data\\hooks\\",

	#InCAM_hooks => "\\\\incam\\incam_server\\site_data\\hooks\\",

	InCAM_ncdMachines => ( -e "Y:" )
	? "y:\\server\\site_data\\hooks\\ncd\\config\\machines\\"
	: "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\config\\machines\\",

	#InCAM_ncdMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\config\\machines\\",

	InCAM_ncrMachines => ( -e "Y:" )
	? "y:\\server\\site_data\\hooks\\ncr\\config\\machines\\"
	: "\\\\incam\\incam_server\\site_data\\hooks\\ncr\\config\\machines\\",

	#InCAM_ncrMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncr\\config\\machines\\",

	InCAM_jobs => ( -e "Y:" )
	? "y:\\incam_db1\\incam\\jobs\\"
	: "\\\\incam\\incam_db\\incam\\jobs\\",

	#InCAM_jobs => "\\\\incam\\incam_db\\incam\\jobs\\",

	InCAM_jobsdb1 => ( -e "Y:" )
	? "y:\\incam_db1\\db1\\jobs\\"
	: "\\\\incam\\incam_db\\db1\\jobs\\",

	#InCAM_jobsdb1 => "\\\\incam\\incam_db\\db1\\jobs\\",

	InCAM_3rdScripts => ( -e "Y:" )
	? "y:\\server\\site_data\\scripts3rdParty\\"
	: "\\\\incam\\incam_server\\site_data\\scripts3rdParty\\",

	#InCAM_3rdScripts => "\\\\incam\\incam_server\\site_data\\scripts3rdParty\\",
	
	InCAM_TPVApp => ( -e "Y:" )
	? "y:\\tpvApp"
	: "\\\\incam\\InCAM\\tpvApp",

	#InCAM_server => "\\\\incam\\incam_server\\tpvApp",
};

use constant {
	Config_NCMACHINES => "\\Config\\NCMachines.txt",

};

1;
