#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Create directory structure needed for runing tpv scripts
# Author:SPR
#-------------------------------------------------------------------------------------------#

package HelperScripts::FeatureDrawing;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolArc';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
# Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

sub Draw {
	my $self         = shift;
	my $step         = shift;
	my $layer        = shift;
	my $features     = shift;
	my $createLayer  = shift;
	my $sourceStep   = shift;
	my $ancestorStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $step );

	if ($createLayer) {
		CamMatrix->DeleteLayer( $inCAM, $jobId, $layer );
		CamMatrix->CreateLayer( $inCAM, $jobId, $layer, "document", "positive", 0 );
	}

	CamLayer->WorkLayer( $inCAM, $layer );

	if ($sourceStep) {

		@{$features} = grep { $_->{"SRStep"} eq $sourceStep } @{$features};
	}

	if ($ancestorStep) {

		@{$features} = grep { $_->{"SRAncestors"} eq $ancestorStep } @{$features};
	}

	foreach my $feat ( @{$features} ) {

		if ( $feat->{"type"} eq "P" ) {

			CamSymbol->AddPad( $inCAM, $feat->{"symbol"}, { "x" => $feat->{"x1"}, "y" => $feat->{"y1"} } );

		}
		elsif ( $feat->{"type"} eq "L" ) {

			CamSymbol->AddLine( $inCAM,
								{ "x" => $feat->{"x1"}, "y" => $feat->{"y1"} },
								{ "x" => $feat->{"x2"}, "y" => $feat->{"y2"} },
								$feat->{"symbol"} );
		}
		elsif ( $feat->{"type"} eq "A" ) {

			CamSymbolArc->AddArcStartCenterEnd( $inCAM,
												{ "x" => $feat->{"x1"},   "y" => $feat->{"y1"} },
												{ "x" => $feat->{"xmid"}, "y" => $feat->{"ymid"} },
												{ "x" => $feat->{"x2"},   "y" => $feat->{"y2"} },
												$feat->{"oriDir"}, $feat->{"symbol"} );
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
