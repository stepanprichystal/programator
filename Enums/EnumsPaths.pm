
package Enums::EnumsPaths;

use constant {
	Client_EXPORTFILES => "c:\\Export\\ExportFiles\\",
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
	Client_INCAMTMP        => "c:\\tmp\\InCam\\",

};

use constant {

	#    Jobs_ARCHIV => "r:\\Archiv\\",
	#    Jobs_STACKUPS => "r:\\PCB\\pcb\\VV_slozeni\\",
	#    Jobs_PCBMDI => "r:\\pcb\\mdi\\",
	#    Jobs_MDI => "r:\\mdi\\",
	#    Jobs_JETPRINT => "r:\\potisk\\",

	Jobs_ARCHIV   => "\\\\dc2.gatema.cz\\r\\Archiv\\",
	Jobs_STACKUPS => "\\\\dc2.gatema.cz\\r\\PCB\\pcb\\VV_slozeni\\",
	Jobs_PCBMDI   => "\\\\dc2.gatema.cz\\r\\pcb\\mdi\\",
	Jobs_MDI      => "\\\\dc2.gatema.cz\\r\\mdi\\",
	Jobs_JETPRINT => "\\\\dc2.gatema.cz\\r\\potisk\\",

};

use constant {

	InCAM_serverDisc => "y:\\",
	#InCAM_serverDisc => "\\\\incam\\InCAM\\",

	#InCAM_server => "y:\\server\\",
	InCAM_server => "\\\\incam\\incam_server\\",

	#InCAM_users => "y:\\server\\users\\",
	InCAM_users => "\\\\incam\\incam_server\\",

	#InCAM_hooks => "y:\\server\\site_data\\hooks\\",
	InCAM_hooks => "\\\\incam\\incam_server\\site_data\\hooks\\",

	#InCAM_ncdMachines => "y:\\server\\site_data\\hooks\\ncd\\config\\machines\\",
	InCAM_ncdMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\config\\machines\\",

	#InCAM_ncrMachines => "y:\\server\\site_data\\hooks\\ncr\\config\\machines\\",
	InCAM_ncrMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncr\\config\\machines\\",

	#InCAM_jobs => "y:\\incam_db1\\incam\\jobs\\",
	InCAM_jobs => "\\\\incam\\incam_db\\incam\\jobs\\",

	#InCAM_jobsdb1 => "y:\\incam_db1\\db1\\jobs\\",
	InCAM_jobsdb1 => "\\\\incam\\incam_db\\db1\\jobs\\",

	#InCAM_3rdScripts => "y:\\server\\site_data\\scripts3rdParty\\",
	InCAM_3rdScripts => "\\\\incam\\incam_server\\site_data\\scripts3rdParty\\",

};

use constant {
	Config_NCMACHINES => "\\Config\\NCMachines.txt",

};

1;
