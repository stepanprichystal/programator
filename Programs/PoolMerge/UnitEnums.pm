
package Programs::PoolMerge::UnitEnums;
 

use constant {
			   UnitId_CHECK => "check",
			   UnitId_MERGE => "merge",
			   UnitId_ROUT  => "rout",
			   UnitId_OUTPUT => "output"
			 
};

sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown";
	
	if($code eq UnitId_CHECK){
		
		$title = "Checks";
		
	}
	elsif($code eq UnitId_MERGE){
		
		$title = "Merge jobs";
		
	}elsif($code eq UnitId_ROUT){
		
		$title = "Rout creation";
		
	}elsif($code eq UnitId_OUTPUT){
		
		$title = "Export prepare";
		
	} 
	
	return $title;
}


#sub GetDescriptions{
#	my $self = shift;
#	my $unit = shift;
#	
#	use aliased 'Programs::PoolMerge::UnitEnums';
#	
#	my $description;
#	
#	if($unit eq UnitEnums->UnitId_NIF ){
#		
#		$description =  "Nif";
#	}
# 	
#}

1;

