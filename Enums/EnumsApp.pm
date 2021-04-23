
# Contain enums, which are related to script and applications on server

package Enums::EnumsApp;

use constant {
	App_CHECKREORDER => "checkReorder",
	App_PROCESSREORDER => "processReorder",
	App_EXPORTUTILITY => "exportUtility",
	App_POOLMERGE => "poolMerge",
	App_MDIDATA => "mdiData",
	App_MDIDATAOLD => "mdiDataOld",
	App_JETPRINTDATA => "jetprintData",
	App_ARCHIVEJOBS => "archiveJobs",
	App_CLEANJOBDB => "cleanJobDb",
	App_TASKONDEMAND => "taskOnDemand",
	App_TEST => "testService",
	App_CHECKELTESTS => "checkElTests",
	App_ETKOOPER => "ETKooper",
	App_APPCHECKER => "appChecker",
	App_JOBSREEXPORT => "jobsReExport"
};




sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown app name";
	
	if($code eq App_CHECKREORDER){
		
		$title = "Check reorder";	
	
	}elsif($code eq App_PROCESSREORDER){
		
		$title = "Process reorder";	
	
	}elsif($code eq App_EXPORTUTILITY){
		
		$title = "Export utility";	
		
	}elsif($code eq App_MDIDATA){
		
		$title = "Export mdi data";
			
	}elsif($code eq App_JETPRINTDATA){
		
		$title = "Export jet print data";	
	
	}elsif($code eq App_ARCHIVEJOBS){
		
		$title = "Archive jobs";	
		
	}elsif($code eq App_TASKONDEMAND){
		
		$title = "Task on demand";	
	
	}elsif($code eq App_CHECKELTESTS){
		
		$title = "Check electrical test";	
	
	}elsif($code eq App_CLEANJOBDB){
		
		$title = "Cleanup InCAM job DB";	
	}
	
	
	return $title;
	
}
 
1;
