
package Programs::Exporter::UnitEnums;
 

use constant {
			   UnitId_NIF => "nif",
			   UnitId_NC  => "nc",
			   UnitId_NC2 => "nc2",
			   UnitId_NC3 => "nc3",
			   UnitId_NC4 => "nc4",
			   UnitId_NC5 => "nc5",
			   UnitId_NC6 => "nc6",
};

sub GetTitle{
	my $self = shift;
	my $code = shift;
	
	my $title = "Unknown";
	
	if($code eq UnitId_NIF){
		
		$title = "Nif soubor";
		
	}elsif($code eq UnitId_NC){
		
		$title = "NC programy";
		
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

