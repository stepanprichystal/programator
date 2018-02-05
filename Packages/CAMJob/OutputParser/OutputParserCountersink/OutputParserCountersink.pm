
#-------------------------------------------------------------------------------------------#
# Description: Parse pad countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserCountersink::OutputParserCountersink;
use base('Packages::CAMJob::OutputParser::OutputParserBase::OutputParserBase');

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Tooling::CountersinkHelper';

use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Polygon::Features::Features::Features';

use aliased 'Packages::CAMJob::OutputParser::OutputParserCountersink::OutputClasses::COUNTERSINKPAD';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;
	return $self;
}

sub InitParser {
	my $self   = shift;
	my $l      = shift;
	my $parser = shift;

	my $NCType = $l->{"type"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Init layer with some info

	if (    $NCType eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		 || $NCType eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		 || $NCType eq EnumsGeneral->LAYERTYPE_nplt_bMillBot )
	{
		$parser->AddClass( COUNTERSINKPAD->new( $inCAM, $jobId, $step, $l ) );

	}
	else {
		die "No parser class for this NC type: $NCType";
	}

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::OutputParser::OutputParserCountersink::OutputParserCountersink';

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'CamHelpers::CamStep';
	use aliased 'CamHelpers::CamHelper';

	my $inCAM = InCAM->new();

	my $jobId = "d152457";

	my $mess = "";

	CamStep->CreateFlattenStep( $inCAM, $jobId, "o+1", "flat", 1, [ "fzc", "f" ] );

	CamHelper->SetStep( $inCAM, "flat" );

	my $control = OutputParserCountersink->new( $inCAM, $jobId, "flat" );

	my %lInfo = ( "gROWname" => "fzc", "gROWlayer_type" => "rout" );

	my $result = $control->Prepare( \%lInfo );

	#$control->Clear();

}

1;
