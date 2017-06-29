
# Contain enums, which are related to script and applications on server

package Enums::EnumsApp;

use constant {
	App_CHECKREORDER => "checkReorder",
	App_PROCESSREORDER => "processReorder",
	App_EXPORTUTILITY => "exportUtility",
	App_MDIDATA => "mdiData",
	App_JETPRINTDATA => "jetPrintData",
	
	#App_ARCHIVEJOBS => "archiveJobs",
	
	App_TEST => "testApp",
 
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
	}
	
	return $title;
	
}
 
1;
