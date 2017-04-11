
package Programs::PoolMerge::UnitEnums;
 

use constant {
			   UnitId_MERGE => "merge",
			   UnitId_ROUT  => "rout",
			   UnitId_EXPORT => "export"
			 
};

sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown";
	
	if($code eq UnitId_MERGE){
		
		$title = "Merge jobs";
		
	}elsif($code eq UnitId_ROUT){
		
		$title = "Rout creation";
		
	}elsif($code eq UnitId_EXPORT){
		
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

