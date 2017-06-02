
# Contain enums, which are related to script and applications on server

package Enums::EnumsApp;

use constant {
	App_REORDER => "reOrderApp",
	#App_ARCHIVEJOBS => "archiveJobs",
	
	App_TEST => "testApp",
 
};




sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown app name";
	
	if($code eq App_REORDER){
		
		$title = "Job reorder";
		
	} 
	
	return $title;
	
}
 
1;
