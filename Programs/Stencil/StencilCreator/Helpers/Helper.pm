
#-------------------------------------------------------------------------------------------#
# Description: Basic helper for stencils
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::Helpers::Helper;

#3th party library
use utf8;
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Stencil::StencilCreator::Enums';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 
# Return info from HEG
sub GetStencilInfo {
	my $self  = shift;
	my $jobId = shift;

	my $pcbInfo = ( HegMethods->GetAllByPcbId($jobId) )[0];

	my $name = $pcbInfo->{"board_name"};
	my $note = $pcbInfo->{"poznamka"};
	my $inf  = $name . $note;

	$inf =~ s/\s//g;

	my %stencilInf = ();
	$stencilInf{"type"}   = undef;
	$stencilInf{"tech"}   = undef;
	$stencilInf{"width"}  = undef;
	$stencilInf{"height"} = undef;
	$stencilInf{"thick"}  = undef;
	$stencilInf{"schema"} = undef;

	# parse technology
	if ( $pcbInfo->{"sablona_typ"} =~ /l/i ) {
		$stencilInf{"tech"} = Enums->Technology_LASER;
	}
	elsif ( $pcbInfo->{"sablona_typ"} =~ /p/i ) {
		$stencilInf{"tech"} = Enums->Technology_ETCH;
	}
	elsif ( $pcbInfo->{"sablona_typ"} =~ /v/i ) {
		$stencilInf{"tech"} = Enums->Technology_DRILL;
	}

	# parse type
	if ( $inf =~ /top/i ) {
		$stencilInf{"type"} = Enums->StencilType_TOP;
	}
	elsif ( $inf =~ /bot/i ) {
		$stencilInf{"type"} = Enums->StencilType_BOT;
	}

	if ( ( $inf =~ /top/i && $inf =~ /bot/i ) || $inf =~ /slou/i ) {
		$stencilInf{"type"} = Enums->StencilType_TOPBOT;
	}

	# parse schema

	if ( $inf =~ /vlep|r.*mu/i ) {
		$stencilInf{"schema"} = Enums->Schema_FRAME;
	}

	# parse dim
	if ( $inf =~ /(\d+)x(\d+)/i ) {

		if ( $1 > $2 ) {

			$stencilInf{"height"} = $1;
			$stencilInf{"width"}  = $2;

		}
		else {
			$stencilInf{"height"} = $2;
			$stencilInf{"width"}  = $1;
		}

	}

	# parse thick
	if ( $inf =~ /\d+x\d+x(\d+.?\d*)/i ) {
		$stencilInf{"thick"} = $1;
	}
	elsif ( $inf =~ /tl.*(\d+[\.,]\d+)/i ) {
		$stencilInf{"thick"} = $1;
	}
	elsif ( $inf =~ /(\d+)[µu]m/i ) {

		$stencilInf{"thick"} = sprintf( "%.3f", $1 / 100 );
	}

	return %stencilInf;

}

sub GetStencilOriLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $side  = shift;    # top/bot

	my @pasteL = grep { $_->{"gROWname"} =~ /^s[ab][-]((ori)|(made))+$/ } CamJob->GetAllLayers( $inCAM, $jobId );

	my $name = "sa";
	if ( $side eq "bot" ) {
		$name = "sb";
	}

	my $layer = ( grep { $_->{"gROWname"} =~ /^$name-ori/ } @pasteL )[0];
	unless ($layer) {
		$layer = ( grep { $_->{"gROWname"} =~ /^$name-made/ } @pasteL )[0];
	}
	
	return $layer;
}

# Return steps, which data paste are taken from
sub GetStencilSourceSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	
	my @steps = grep { $_ =~ /^ori_/i } CamStep->GetAllStepNames( $inCAM, $jobId );
 
	return @steps;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Stencil::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

