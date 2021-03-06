
package Enums::EnumsPaths;

# paths on client computer
use constant {
	Client_EXPORTFILES     => "c:\\Export\\ExportFiles\\Pcb\\",
	Client_EXPORTFILESPOOL => "c:\\Export\\ExportFiles\\Pool\\",
	Client_PCBLOCAL        => "c:\\pcb\\",
	Client_EXPORTLOCAL     => "c:\\Export\\",
	Client_ELTESTS         => "c:\\Boards\\",

	#Client_MULTICALDB => "c:\\Program Files (x86)\\Multical5-1\\ml.xml",
	Client_INCAMVERSION => "c:\\opt\\InCAM\\",
	Client_IMAGEMAGICK  => "c:\\im\\",

	# Paths for log
	Client_INCAMTMPAOI     => "c:\\tmp\\InCam\\scripts\\aoi_export\\",
	Client_INCAMTMPNC      => "c:\\tmp\\InCam\\scripts\\nc_export\\",
	Client_INCAMTMPCHECKER => "c:\\tmp\\InCam\\scripts\\export_checker\\",
	Client_INCAMTMPIMPGEN  => "c:\\tmp\\InCam\\scripts\\imp_generator\\",
	Client_INCAMTMPPNLCRE  => "c:\\tmp\\InCam\\scripts\\pnl_creator\\",
	Client_INCAMTMPOTHER   => "c:\\tmp\\InCam\\scripts\\other\\",
	Client_INCAMTMPSCRIPTS => "c:\\tmp\\InCam\\scripts\\",
	Client_INCAMTMPJOBMNGR => "c:\\tmp\\InCam\\scripts\\job_mngr\\",
	Client_INCAMTMPLOGS    => "c:\\tmp\\InCam\\scripts\\logs\\",
	Client_INCAMTMP        => "c:\\tmp\\InCam\\",

};

# Disc R
use constant {

	Jobs_ARCHIV        => "\\\\gatema.cz\\fs\\r\\Archiv\\",
	Jobs_ARCHIVOLD     => "\\\\gatema.cz\\fs\\p\\Archiv_old\\",
	Jobs_ARCHIVREMOVED => "\\\\gatema.cz\\fs\\r\\Archiv_removed\\",
	Jobs_STACKUPS      => "\\\\gatema.cz\\fs\\r\\PCB\\pcb\\VV_slozeni\\",
	Jobs_COUPONS       => "\\\\gatema.cz\\fs\\r\\PCB\\pcb\\VV_InStackCoupon\\",
	Jobs_PCBMDI        => "\\\\gatema.cz\\fs\\r\\pcb\\mdi\\",
	Jobs_PCBMDITT      => "\\\\gatema.cz\\fs\\r\\pcb\\mditt\\",
	Jobs_PCBMDITTWAIT  => "\\\\gatema.cz\\fs\\r\\pcb\\mditt\\WaitToProduction\\",
	Jobs_MDI             => "\\\\gatema.cz\\fs\\r\\mdi\\",
	Jobs_MDITT           => "\\\\gatema.cz\\fs\\r\\mditt\\",
	Jobs_JETPRINT        => "\\\\gatema.cz\\fs\\r\\potisk\\",
	Jobs_ELTESTS         => "\\\\gatema.cz\\fs\\EL_DATA\\",
	Jobs_ELTESTSIPC      => "\\\\gatema.cz\\fs\\r\\El_tests\\",
	Jobs_STENCILDATA     => "\\\\gatema.cz\\fs\\r\\Kooperace_sablony\\",
	Jobs_COOPERDRILL     => "\\\\gatema.cz\\fs\\r\\Kooperace_drillMap\\",
	Jobs_APPLOGS         => "\\\\fs2.gatema.cz\\Log\\",
	Jobs_EXPORTFILES     => "\\\\gatema.cz\\fs\\r\\Export\\ExportFiles\\",
	Jobs_EXPORTFILESPCB  => "\\\\gatema.cz\\fs\\r\\Export\\ExportFiles\\Pcb\\",
	Jobs_EXPORTFILESPOOL => "\\\\gatema.cz\\fs\\r\\Export\\ExportFiles\\Pool\\",
	Jobs_EXPORT          => "\\\\gatema.cz\\fs\\r\\Export\\",
	Jobs_JOBSREEXPORT    => "\\\\gatema.cz\\fs\\r\\AutoExport\\",

};

# Other paths
use constant {

	# AOI server
	Jobs_AOITESTS         => "\\\\192.168.2.66\\spool\\pci\\",
	Jobs_AOITESTSFUSION   => "\\\\192.168.2.60\\spool\\pci\\",
	Jobs_AOITESTSFUSIONDB => "\\\\192.168.2.60\\job_db\\",

	# Jet print paths
	Jobs_JETPRINTMACHINE => "\\\\printer-pc\\jobs\\",

	# Paths where helper logs are stored
	App_LOGS => "\\\\fs2.gatema.cz\\Log\\"

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
	: "\\\\incam\\incam_server\\users\\",

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

# Config files
use constant {
	Config_NCMACHINES => "\\Config\\NCMachines.txt",

};

# Web adress
use constant {

	URL_GATEMASMTP => 'gatema-cz.mail.protection.outlook.com',    # new servr from 29.1.2019

};

# Email adress
use constant {

	MAIL_GATSALES => 'pcb@gatema.cz',
	MAIL_GATCAM   => 'cam@gatema.cz',
	MAIL_GATTPV   => 'tpv@gatema.cz'
};

1;
