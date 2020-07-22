
#-------------------------------------------------------------------------------------------#
# Description: Basic helper for stencils
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::Helpers::Helper;

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min];

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

	my $pcbInfo = ( HegMethods->GetBaseStencilInfo($jobId) )[0];

	my $name = $pcbInfo->{"nazev_subjektu"};
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
	if ( $pcbInfo->{"sablona_strana"} =~ /^c$/i ) {
		$stencilInf{"type"} = Enums->StencilType_TOP;
	}
	elsif ( $pcbInfo->{"sablona_strana"} =~ /^s$/i ) {
		$stencilInf{"type"} = Enums->StencilType_BOT;
	}
	elsif ( $pcbInfo->{"sablona_strana"} =~ /^2$/i ) {
		$stencilInf{"type"} = Enums->StencilType_TOPBOT;
	}

	# parse schema

	if ( $inf =~ /vlep|r.*mu/i ) {
		$stencilInf{"schema"} = Enums->Schema_FRAME;
	}

	# parse dim

	my $dim1 = max( $pcbInfo->{"kus_x"}, $pcbInfo->{"rozmer_x"} );
	my $dim2 = max( $pcbInfo->{"kus_y"}, $pcbInfo->{"rozmer_y"} );

	if ( $dim1 > $dim2 ) {

		$stencilInf{"height"} = $dim1;
		$stencilInf{"width"}  = $dim2;

	}
	else {
		$stencilInf{"height"} = $dim2;
		$stencilInf{"width"}  = $dim1;
	}

	# parse thick
	$stencilInf{"thick"} = $pcbInfo->{"material_tloustka"};
	$stencilInf{"thick"} =~ s/,/\./;

	# if mat less than 1, format is: .xx (where xx is number behind point)
	$stencilInf{"thick"} = "0" . $stencilInf{"thick"} if ( $stencilInf{"thick"} =~ /^\./ );

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
	@steps = grep { $_ !~ /coupon/ } @steps;

	return @steps;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13610";

	my %inf = Helper->GetStencilInfo($jobId);

	print "test";

}

1;

