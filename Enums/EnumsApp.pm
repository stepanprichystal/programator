
# Contain enums, which are related to script and applications on server

package Enums::EnumsApp;

use constant {
	App_CHECKREORDER => "checkReorder",
	App_PROCESSREORDER => "processReorder",
	#App_ARCHIVEJOBS => "archiveJobs",
	
	App_TEST => "testApp",
 
};




sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown app name";
	
	if($code eq App_CHECKREORDER){
		
		$title = "Job reorder";
		
	} 
	
	return $title;
	
}
 
1;
