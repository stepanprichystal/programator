
#-------------------------------------------------------------------------------------------#
# Description: Parse pad countersink from layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC;
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

use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKSURF';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKARC';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::COUNTERSINKPAD';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISSLOTCHAMFER';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISSURFCHAMFER';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISSURF';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISSLOT';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ZAXISPAD';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::DRILL';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::ROUT';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputClasses::SCORE';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new( @_ );
	bless $self;
	return $self;
}

# 
sub InitParser {
	my $self   = shift;
	my $l      = shift;
	my $parser = shift;

	my $NCType = $l->{"type"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Init layer with some info

	if (    $NCType eq EnumsGeneral->LAYERTYPE_plt_nDrill
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_cDrill
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
		 || $NCType eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot )
	{
		$parser->AddClass( DRILL->new( $inCAM, $jobId, $step, $l ) );
	}
	elsif (    $NCType eq EnumsGeneral->LAYERTYPE_plt_nMill
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_nMill )
	{
		$parser->AddClass( DRILL->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ROUT->new( $inCAM, $jobId, $step, $l ) );
	}
	elsif (    $NCType eq EnumsGeneral->LAYERTYPE_nplt_rsMill
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_kMill )
	{
		$parser->AddClass( DRILL->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ROUT->new( $inCAM, $jobId, $step, $l ) );

	}
	elsif (    $NCType eq EnumsGeneral->LAYERTYPE_plt_bMillTop
			|| $NCType eq EnumsGeneral->LAYERTYPE_plt_bMillBot
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop
			|| $NCType eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot )
	{
		$parser->AddClass( COUNTERSINKSURF->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( COUNTERSINKARC->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( COUNTERSINKPAD->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ZAXISSLOTCHAMFER->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ZAXISSURFCHAMFER->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ZAXISSURF->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ZAXISSLOT->new( $inCAM, $jobId, $step, $l ) );
		$parser->AddClass( ZAXISPAD->new( $inCAM, $jobId, $step, $l ) );

	}
	elsif ( $NCType eq EnumsGeneral->LAYERTYPE_nplt_score ) {

		$parser->AddClass( SCORE->new( $inCAM, $jobId, $step, $l ) );
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

	 use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'CamHelpers::CamStep';
	use aliased 'CamHelpers::CamHelper';

	my $inCAM = InCAM->new();

	my $jobId = "d152457";

	my $mess = "";
	
	CamStep->CreateFlattenStep( $inCAM, $jobId, "o+1", "flat", 1, [ "fzc", "f"] );
	
	

	my $control = OutputParserNC->new( $inCAM, $jobId, "flat" );

	my %lInfo = ( "gROWname" => "f", "gROWlayer_type" => "rout" );

	my $result = $control->Prepare( \%lInfo );

	#$control->Clear();

}

1;
