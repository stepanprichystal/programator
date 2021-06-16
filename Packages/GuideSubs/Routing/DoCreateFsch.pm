#-------------------------------------------------------------------------------------------#
# Description: Create fsch rout layer
# Show errors and warnings if exist
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::DoCreateFsch;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
use aliased 'Packages::ItemResult::ItemResult';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub CreateFsch {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $mainResultItem = ItemResult->new("Final result");

	my $fsch = CreateFsch->new( $inCAM, $jobId, );
	$fsch->{"onItemResult"}->Add( sub { $self->__ProcesResult( $mainResultItem, @_ ) } );

	$result = $fsch->Create();

	unless ($result) {

		# Show error and warnings

		my $messMngr = MessageMngr->new( $self->{"jobId"} );

		if ( $mainResultItem->GetErrorCount() ) {

			my @mess = $mainResultItem->GetErrors();
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );    #  Script se zastavi

		}

		if ( $mainResultItem->GetWarningCount() ) {

			my @mess = $mainResultItem->GetWarnings();
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );    #  Script se zastavi
		}

	}

	return $result;
}

sub __ProcesResult {
	my $self           = shift;
	my $mainResultItem = shift;
	my $res            = shift;

	# 1) store partial results to main resultItem
	foreach my $e ( $res->GetErrors() ) {

		$mainResultItem->AddError($e);
	}

	foreach my $w ( $res->GetWarnings() ) {

		$mainResultItem->AddWarning($w);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::DoSetDTM';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d297280";
	
	 

 

}

1;

