
package Programs::Exporter::UnitEnums;
 

use constant {
			   UnitId_NIF => "nif",
			   UnitId_NC  => "nc",
			   UnitId_ET => "et",
			   UnitId_AOI => "aoi"
	 
};

sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown";
	
	if($code eq UnitId_NIF){
		
		$title = "Nif file";
		
	}elsif($code eq UnitId_NC){
		
		$title = "NC programs";
		
	}elsif($code eq UnitId_ET){
		
		$title = "Electric testing";
		
	}elsif($code eq UnitId_AOI){
		
		$title = "Optic testing";
		
	}
	
	return $title;
}


#sub GetDescriptions{
#	my $self = shift;
#	my $unit = shift;
#	
#	use aliased 'Programs::Exporter::UnitEnums';
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
