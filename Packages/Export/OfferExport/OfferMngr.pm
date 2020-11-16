
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::OfferExport::OfferMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use File::Path 'rmtree';

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Stackup::StackupCode';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 0;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"specifToIS"} = shift;    # store specification to email.

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $self->{"specifToIS"} ) {

		my @jobPar = ();

		# KT
		push( @jobPar, [ "konstr_trida", CamJob->GetJobPcbClass( $inCAM, $jobId ) ] );

		# Dimension
		my %dim = JobDim->GetDimension( $inCAM, $jobId );

		# 1) clear old values (there are some constraints nasobnost must bz able devide to nasobnost_panelu)
		push( @jobPar, [ "rozmer_x", "" ] );
		push( @jobPar, [ "rozmer_y", "" ] );

		# There are integrity checks, panel multiple must be able to devide by mpanel multiple
		# So check if there is filled mpanel multiple and first set it to panel multiple
		my $formerDim = HegMethods->GetInfoDimensions($jobId);
		if ( defined $formerDim->{"nasobnost_panelu"} ) {
			push( @jobPar, [ "nasobnost", $formerDim->{"nasobnost_panelu"} ] );
		}
		push( @jobPar, [ "nasobnost_panelu", "" ] );
		push( @jobPar, [ "nasobnost",        "" ] );
		push( @jobPar, [ "panel_x",          "" ] );
		push( @jobPar, [ "panel_y",          "" ] );
		push( @jobPar, [ "kus_x",            "" ] );
		push( @jobPar, [ "kus_y",            "" ] );

		# 2) Set new dim
		push( @jobPar, [ "kus_x", $dim{"single_x"} ] );
		push( @jobPar, [ "kus_y", $dim{"single_y"} ] );

		if ( CamHelper->StepExists( $inCAM, $jobId, "mpanel" ) ) {

			push( @jobPar, [ "panel_x",          $dim{"panel_x"} ] );
			push( @jobPar, [ "panel_y",          $dim{"panel_y"} ] );
			push( @jobPar, [ "nasobnost_panelu", $dim{"nasobnost_panelu"} ] );

		}
		push( @jobPar, [ "nasobnost", $dim{"nasobnost"} ] );
		push( @jobPar, [ "rozmer_x",  $dim{"vyrobni_panel_x"} ] );
		push( @jobPar, [ "rozmer_y",  $dim{"vyrobni_panel_y"} ] );

		HegMethods->UpdateOfferSpecification( $jobId, \@jobPar, 1 );
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1 if ( $self->{"specifToIS"} );    # OfferStep Created

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::OfferExport::OfferMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d222769";

	my $Offer = OfferMngr->new( $inCAM, $jobId, "panel", 1, 1, 1 );

	$Offer->Run()

}

1;

