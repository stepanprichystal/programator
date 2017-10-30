
#-------------------------------------------------------------------------------------------#
# Description: Prepare object fith stencil parameters and serialize it
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::Helpers::Output;

#3th party library
use threads;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Stencil::StencilCreator::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Stencil::StencilSerializer::StencilParams';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"dataMngr"}    = shift;
	$self->{"stencilMngr"} = shift;

	#my %inf = Helper->GetStencilInfo( $self->{"jobId"} );
	#$self->{"stencilInfo"} = \%inf;

	# PROPERTIES
	$self->{"stencilStep"} = "o+1";

	#$self->{"finalLayer"} = $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ? "f" : "ds";

	return $self;
}

sub SaveStencilParams {
	my $self       = shift;
	my $stencilSrc = shift;    # existing job or customer data
	my $jobIdSrc   = shift;    # if source job, contain job id

	my $dMngr     = $self->{"dataMngr"};
	my $stnclMngr = $self->{"stencilMngr"};

	my $p = StencilParams->new();

	$p->SetStencilStep( $dMngr->GetStencilStep() );
	$p->SetStencilType( $dMngr->GetStencilType() );
	$p->SetStencilSizeX( $dMngr->GetStencilSizeX() );
	$p->SetStencilSizeY( $dMngr->GetStencilSizeY() );

	$p->SetAddPcbNumber( $dMngr->GetAddPcbNumber() );

	if ( $dMngr->GetStencilType() eq Enums->StencilType_TOP || $dMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {
		my %topPos = $stnclMngr->GetTopProfilePos();
		$p->SetTopProfilePos( \%topPos );
	}

	if ( $dMngr->GetStencilType() eq Enums->StencilType_BOT || $dMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {
		my %botPos = $stnclMngr->GetBotProfilePos();
		$p->SetBotProfilePos( \%botPos );
	}

	my %area = $stnclMngr->GetStencilActiveArea();
	$p->SetStencilActiveArea( \%area );

	if ( $dMngr->GetStencilType() eq Enums->StencilType_TOP || $dMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my $topProf  = $stnclMngr->GetTopProfile();
		my $topPd    = $topProf->GetPasteData();
		my $topPdPos = $stnclMngr->GetTopDataPos();
		$p->SetTopProfile(
						   {
							 "isRotated"    => $topProf->GetIsRotated(),
							 "h"            => $topProf->GetHeight(),
							 "w"            => $topProf->GetWidth(),
							 "pasteData"    => { "w" => $topPd->GetWidth(), "h" => $topPd->GetHeight() },
							 "pasteDataPos" => $topProf->GetPDOrigin()
						   }
		);
	}

	if ( $dMngr->GetStencilType() eq Enums->StencilType_BOT || $dMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {
		my $botProf  = $stnclMngr->GetBotProfile();
		my $botPd    = $botProf->GetPasteData();
		my $botPdPos = $stnclMngr->GetBotDataPos();
		$p->SetBotProfile(
						   {
							 "isRotated"    => $botProf->GetIsRotated(),
							 "h"            => $botProf->GetHeight(),
							 "w"            => $botProf->GetWidth(),
							 "pasteData"    => { "w" => $botPd->GetWidth(), "h" => $botPd->GetHeight() },
							 "pasteDataPos" => $botProf->GetPDOrigin()
						   }
		);
	}

	my $schema  = $stnclMngr->GetSchema();
	my @holePos = $schema->GetHolePositions();
	$p->SetSchema(
				   {
					 "holePositions" => \@holePos,
					 "holeSize"      => $dMngr->GetHoleSize(),
					 "type"          => $dMngr->GetSchemaType()
				   }
	);

	$p->SetDataSource(
		{
		  "sourceType"      => $stencilSrc,
		  "sourceJob"       => $jobIdSrc,
		  "sourceJobIsPool" => $stencilSrc eq Enums->StencilSource_JOB ? HegMethods->GetPcbIsPool($jobIdSrc) : 0,
		}
	);

	my $ser = StencilSerializer->new( $self->{"jobId"} );
	$ser->SaveStencilParams($p);

	return $p;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
