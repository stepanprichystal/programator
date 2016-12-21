#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM histogram (features, attributes etc)
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamHistogram;

#3th party library
use strict;
use warnings;

#loading of locale modules

#use aliased 'Enums::EnumsPaths';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamCopperArea';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return name of all steps 'FEATURES',
sub GetAttHistogram {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $breakSR   = shift;
	my $selected   = shift;

	my $sr = "break_sr+";
	if ( defined $breakSR && $breakSR == 0 ) {
		$sr = "";
	}
	
	 my $sel = "";
	if ( $selected) {
		$sel = "select+";
	}

	my $fFeatures = $inCAM->INFO(
								  units           => 'mm',
								  angle_direction => 'ccw',
								  entity_type     => 'layer',
								  entity_path     => "$jobId/$stepName/$layerName",
								  data_type       => 'FEATURES',
								  options         => $sel.$sr . "f0",
								  parse           => 'no'
	);

	my %attHist = ();

	my $f;
	open( $f, $fFeatures );

	while ( my $l = <$f> ) {

		if ( $l =~ /###/ ) { next; }

		$l =~ m/.*;(.*)/;

		unless ($1) {
			next;
		}

		my @attr = split( ",", $1 );

		foreach my $at (@attr) {

			my @parse = split( "=", $at );

			unless ( $attHist{ $parse[0] } ) {
				my @attVal = ();
				$attHist{ $parse[0] } = \@attVal;
			}

			if ( defined $parse[1] ) {

				# check if same attribute value  exist
				my $exist = scalar( grep { $_ eq $parse[1] } @{ $attHist{ $parse[0] } } );
				unless ($exist) {
					push( @{ $attHist{ $parse[0] } }, $parse[1] );
				}

			}

		}
	}
	return %attHist;
}

# Return name of all steps
sub GetFeatuesHistogram {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $breakSR   = shift;

	my $sr = "break_sr";
	if ( defined $breakSR && $breakSR == 0 ) {
		$sr = "";
	}

	$inCAM->INFO(
				  units             => 'mm',
				  "angle_direction" => 'ccw',
				  "entity_type"     => 'layer',
				  "entity_path"     => "$jobId/$stepName/$layerName",
				  "data_type"       => 'FEAT_HIST',
				  "parameters"      => "arc+line+pad+surf+text+total",
				  "options"         => $sr
	);

	my %info = ();
	$info{"line"}   = $inCAM->{doinfo}{gFEAT_HISTline};
	$info{"pad"}   = $inCAM->{doinfo}{gFEAT_HISTpad};
	$info{"surf"}  = $inCAM->{doinfo}{gFEAT_HISTsurf};
	$info{"arc"}   = $inCAM->{doinfo}{gFEAT_HISTarc};
	$info{"text"}  = $inCAM->{doinfo}{gFEAT_HISTtext};
	$info{"total"} = $inCAM->{doinfo}{gFEAT_HISTtotal};

	return %info;
}

1;