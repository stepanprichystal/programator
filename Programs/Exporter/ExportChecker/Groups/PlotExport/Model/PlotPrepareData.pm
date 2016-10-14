
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnGetGroupState
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotGroupData';

use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active" or "passive"
# If active, decide if group will be switched ON/OFF
# Return enum: Enums->GroupState_xxx
sub OnGetGroupState {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	#we want nif group allow always, so return ACTIVE ON
	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = PlotGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	
	# Prepare default layer settings
	my @baseLayers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	$self->__SetDefaultLayers(\@baseLayers, $defaultInfo);

	my @layers = $self->__GetFinalLayers( \@baseLayers );

 

	$groupData->SetSendToPlotter(0);
	$groupData->SetLayers(\@layers);
	 
 

	return $groupData;
}



sub __SetDefaultLayers{
	my $self   = shift;
	my $layers = shift;	
	my $defaultInfo = shift;
 

	# Set polarity of layers
	foreach my $l (@{$layers}) {

		if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {

			$l->{"polarity"} = "negative";

		}
		elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {

			$l->{"polarity"} = "positive";

		}
		elsif ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {

			my $etching = $defaultInfo->GetEtchType( $l->{"gROWname"} );

			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
				$l->{"polarity"} = "positive";
			}
			elsif ( $etching eq EnumsGeneral->Etching_TENTING ) {
				$l->{"polarity"} = "negative";
			}
		}
		else {

			$l->{"polarity"} = "positive";

		}
	}

	# Set mirror of layers
	foreach my $l (@{$layers}) {

		# whatever with "c" is mirrored
		if ( $l->{"gROWname"} =~ /^[pm]*c$/i ) {

			$l->{"mirror"} = "yes";

		}

		# whatever with "s" is not mirrored
		elsif ( $l->{"gROWname"} =~ /^[pm]*s$/i ) {

			$l->{"mirror"} = "no";

		}

		# inner layers decide by stackup
		elsif ( $l->{"gROWname"} =~ /^v\d+$/i ) {

			my $side = $defaultInfo->GetSideByLayer( $l->{"gROWname"} );

			if ( $side eq "top" ) {

				$l->{"mirror"} = "yes";

			}
			else {

				$l->{"mirror"} = "no";
			}
		}
	}

	# Set compensation of signal layer
	foreach my $l (@{$layers}) {

		if ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {

			$l->{"comp"} = 10;
		}
		else {

			$l->{"comp"} = 0;

		}
	}
	
}

sub __GetFinalLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @prepared = ();

	foreach my $l (@layers) {

		my %lInfo = ();

		$lInfo{"name"}     = $l->{"gROWname"};
		$lInfo{"polarity"} = $l->{"polarity"};
		$lInfo{"mirror"}   = $l->{"mirror"};
		$lInfo{"comp"}     = $l->{"comp"};
		
		push(@prepared, \%lInfo);
	}
	
	return @prepared;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

