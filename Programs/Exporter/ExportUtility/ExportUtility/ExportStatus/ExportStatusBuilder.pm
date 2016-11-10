#-------------------------------------------------------------------------------------------#
# OBSOLETE - DELETE THIS FILE
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::ExportStatus::ExportStatusBuilder;

#3th party library
use strict;
use warnings;
use JSON;


#local library
use aliased "Enums::EnumsGeneral";
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Exporter::UnitEnums';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	
 
	return $self;
}

sub GetStatusKeys{
	my $self = shift;
	my $exportStatus = shift;
	
	my @statusKeys = ();
	
	
	my $jobId = $exportStatus->{"jobId"};
	
	
	# Information necessary for making decision which nif builder use
	my $typeCu   = JobHelper->GetPcbType( $jobId );

	if ( $typeCu eq EnumsGeneral->PcbTyp_NOCOPPER ) {

		@statusKeys = $self->V0Builder();

	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_ONELAYER ) {

		@statusKeys = $self->V1Builder();
	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_TWOLAYER ) {

		@statusKeys = $self->V2Builder();

	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_MULTILAYER ) {

		@statusKeys = $self->VVBuilder();

	}
 
	
	return @statusKeys;
	
}


sub V0Builder{
	my $self = shift;
	
	my @statusKeys = ();
	
	push(@statusKeys, UnitEnums->UnitId_NIF);
	push(@statusKeys, UnitEnums->UnitId_NC);
	
	return @statusKeys;
		
}

sub V1Builder{
	my $self = shift;
	
	my @statusKeys = ();
	
	push(@statusKeys, UnitEnums->UnitId_NIF);
	push(@statusKeys, UnitEnums->UnitId_NC);
	
	return @statusKeys;
		
}

sub V2Builder{
	my $self = shift;
	
	my @statusKeys = ();
	
	push(@statusKeys, UnitEnums->UnitId_NIF);
	push(@statusKeys, UnitEnums->UnitId_NC);
	
	return @statusKeys;
		
}

sub VVBuilder{
	my $self = shift;
	
	my @statusKeys = ();
	
	# nif file - always
	push(@statusKeys, UnitEnums->UnitId_NIF);

	# nc files - always
	push(@statusKeys, UnitEnums->UnitId_NC);
	
#	# e test
#	
#	if($defaultInfo->GetLayerCnt() == 1 && $defaultInfo->GetPcbClass() == 3){
#		
#		$state = Enums->GroupState_DISABLE;
#		
#	}
#	
	
	push(@statusKeys, UnitEnums->UnitId_NC);
	
	
	
	
				   UnitId_NIF => "nif",
			   UnitId_NC  => "nc",
			   UnitId_ET => "et",
			   UnitId_AOI => "aoi",
			   UnitId_PLOT => "plot",
			   UnitId_PRE => "pre",
			   UnitId_GER => "ger", 
			   UnitId_PDF => "pdf",
			   UnitId_SCO => "score", 
	
	return @statusKeys;
		
}
 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

