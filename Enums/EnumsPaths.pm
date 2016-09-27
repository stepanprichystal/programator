
package Enums::EnumsPaths;

use constant {
    Client_EXPORTFILES => "c:\\Export\\ExportFiles\\",
    Client_PCBLOCAL => "c:\\pcb\\",
    Client_EXPORTLOCAL => "c:\\Export\\",
    Client_ELTESTS => "c:\\Boards\\",
    Client_MULTICALDB => "c:\\Program Files (x86)\\Multical5-1\\ml.xml",
    Client_INCAMVERSION => "c:\\opt\\InCAM\\",
   

 	# Paths for log
    Client_INCAMTMPAOI => "c:\\tmp\\InCam\\scripts\\aoi_export\\",
    Client_INCAMTMPNC => "c:\\tmp\\InCam\\scripts\\nc_export\\",
    Client_INCAMTMPCHECKER => "c:\\tmp\\InCam\\scripts\\export_checker\\",
    Client_INCAMTMPOTHER => "c:\\tmp\\InCam\\scripts\\other\\",
    Client_INCAMTMPSCRIPTS => "c:\\tmp\\InCam\\scripts\\",
    Client_INCAMTMPJOBMNGR => "c:\\tmp\\InCam\\scripts\\job_mngr\\",
};
		

use constant {
	
    Jobs_ARCHIV => "r:\\Archiv\\",  
    Jobs_STACKUPS => "r:\\PCB\\pcb\\VV_slozeni\\"
    
};


use constant {
    InCAM_server => "\\\\incam\\incam_server\\", 
    InCAM_users => "\\\\incam\\incam_server\\users\\",
    InCAM_hooks => "\\\\incam\\incam_server\\site_data\\hooks\\",
    InCAM_ncdMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\config\\machines\\",
    InCAM_ncrMachines => "\\\\incam\\incam_server\\site_data\\hooks\\ncr\\config\\machines\\",
    InCAM_jobs => "\\\\incam\\incam_db\\incam\\jobs\\",
    InCAM_jobsdb1 => "\\\\incam\\incam_db\\db1\\jobs\\",
    

};



use constant {
    Config_NCMACHINES => "\\Config\\NCMachines.txt", 
  
};




1;