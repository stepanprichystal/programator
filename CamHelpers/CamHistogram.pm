#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM histogram (features, attributes etc)
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamHistogram;

#3th party library
use strict;
use warnings;

#loading of locale modules


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return att histgram fo layer
# Histogram is hash, where keys are name of attributes
# Some keys contain array with all values of attribute
sub GetAttHistogram {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $breakSR   = shift // 1;    # Default is SR
	my $selected  = shift;

	my $sr = "break_sr+";
	if ( defined $breakSR && $breakSR == 0 ) {
		$sr = "";
	}

	my $sel = "";
	if ($selected) {
		$sel = "select+";
	}

	my $fFeatures = $inCAM->INFO(
								  units           => 'mm',
								  angle_direction => 'ccw',
								  entity_type     => 'layer',
								  entity_path     => "$jobId/$stepName/$layerName",
								  data_type       => 'FEATURES',
								  options         => $sel . $sr . "f0",
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

# Return att histgram fo layer
# Histogram is hash, where keys are name of attributes
# Some keys contain array with all values of attribute
sub GetAttCountHistogram {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $breakSR   = shift // 1;
	my $selected  = shift;

	my $sr = "break_sr+";
	if ( defined $breakSR && $breakSR == 0 ) {
		$sr = "";
	}

	my $sel = "";
	if ($selected) {
		$sel = "select+";
	}

	my $fFeatures = $inCAM->INFO(
								  units           => 'mm',
								  angle_direction => 'ccw',
								  entity_type     => 'layer',
								  entity_path     => "$jobId/$stepName/$layerName",
								  data_type       => 'FEATURES',
								  options         => $sel . $sr . "f0",
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

		# each line/symbol can contain more attributes
		foreach my $at (@attr) {

			my @parse = split( "=", $at );

			# some attributes doesn't have value
			unless ( defined $parse[1] ) {
				$parse[1] = "";
			}

			unless ( $attHist{ $parse[0] }{ $parse[1] } ) {
				$attHist{ $parse[0] }{ $parse[1] } = 1;
			}
			else {
				$attHist{ $parse[0] }{ $parse[1] }++;
			}
		}
	}

	# compute total count from all atribute values
	foreach my $k ( keys %attHist ) {

		my $att = $attHist{$k};

		my $total = 0;

		foreach my $attVal ( keys %{$att} ) {

			$total += $att->{$attVal};
		}
		$attHist{$k}->{"_totalCnt"} = $total;
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
	my $breakSR   = shift // 1;    # default is with SR

	if ($breakSR) {
		$inCAM->INFO(
					  "units"           => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'layer',
					  "entity_path"     => "$jobId/$stepName/$layerName",
					  "data_type"       => 'FEAT_HIST',
					  "parameters"      => "arc+line+pad+surf+text+total",
					  "options"         => "break_sr"
		);
	}
	else {
		$inCAM->INFO(
			"units"           => 'mm',
			"angle_direction" => 'ccw',
			"entity_type"     => 'layer',
			"entity_path"     => "$jobId/$stepName/$layerName",
			"data_type"       => 'FEAT_HIST',
			"parameters"      => "arc+line+pad+surf+text+total"

		);
	}
	my %info = ();
	$info{"line"}  = $inCAM->{doinfo}{gFEAT_HISTline};
	$info{"pad"}   = $inCAM->{doinfo}{gFEAT_HISTpad};
	$info{"surf"}  = $inCAM->{doinfo}{gFEAT_HISTsurf};
	$info{"arc"}   = $inCAM->{doinfo}{gFEAT_HISTarc};
	$info{"text"}  = $inCAM->{doinfo}{gFEAT_HISTtext};
	$info{"total"} = $inCAM->{doinfo}{gFEAT_HISTtotal};

	return %info;
}

# Return symbol historgram, for each szmbol type return:
# Standard struct - array of hashes, where each hash contain Symbol value, count of symbols
# Hahs struct - hash, where symbols are keys and values are count of symbols
sub GetSymHistogram {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $stepName      = shift;
	my $layerName     = shift;
	my $breakSR       = shift // 1;
	my $hashStructure = shift;
	
	if ($breakSR) {
		$inCAM->INFO(
					  "units"           => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'layer',
					  "entity_path"     => "$jobId/$stepName/$layerName",
					  "data_type"       => 'SYMS_HIST',
					  "parameters"      => "arc+line+pad+symbol",
					  "options"         => "break_sr"
		);
	}
	else {
		$inCAM->INFO(
			"units"           => 'mm',
			"angle_direction" => 'ccw',
			"entity_type"     => 'layer',
			"entity_path"     => "$jobId/$stepName/$layerName",
			"data_type"       => 'SYMS_HIST',
			"parameters"      => "arc+line+pad+symbol"

		);
	}

	my %result = ();

	if ($hashStructure) {

		my %lines = ();
		my %arcs  = ();
		my %pads  = ();

		%result = ( "lines" => \%lines, "arcs" => \%arcs, "pads" => \%pads );
		for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gSYMS_HISTsymbol} } ) ; $i++ ) {

			my $sym = @{ $inCAM->{doinfo}{gSYMS_HISTsymbol} }[$i];
			$lines{$sym} = @{ $inCAM->{doinfo}{gSYMS_HISTline} }[$i];
			$arcs{$sym}  = @{ $inCAM->{doinfo}{gSYMS_HISTarc} }[$i];
			$pads{$sym}  = @{ $inCAM->{doinfo}{gSYMS_HISTpad} }[$i];
		}
	}
	else {

		my @lines = ();
		my @arcs  = ();
		my @pads  = ();

		%result = ( "lines" => \@lines, "arcs" => \@arcs, "pads" => \@pads );

		for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gSYMS_HISTsymbol} } ) ; $i++ ) {

			my $sym = @{ $inCAM->{doinfo}{gSYMS_HISTsymbol} }[$i];

			my %line = ( "sym" => $sym, "cnt" => @{ $inCAM->{doinfo}{gSYMS_HISTline} }[$i] );
			my %arc  = ( "sym" => $sym, "cnt" => @{ $inCAM->{doinfo}{gSYMS_HISTarc} }[$i] );
			my %pad  = ( "sym" => $sym, "cnt" => @{ $inCAM->{doinfo}{gSYMS_HISTpad} }[$i] );

			push( @lines, \%line );
			push( @arcs,  \%arc );
			push( @pads,  \%pad );
		}
	}

	return %result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamHistogram';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d272564";
	my $stepName = "panel";

	my %hist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, "o+1", "mc" );

	die;

}

1;
