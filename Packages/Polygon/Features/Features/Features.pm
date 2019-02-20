
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures. Parsed features, contain only
# basic info like coordinate, attrubutes etc..
# Warning, use only for layers with small amount of features (mainly surface are problematic)
# Otherwise parsin is quite slowly
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::Features::Features;

use Class::Interface;

&implements('Packages::Polygon::Features::IFeatures');

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library

use aliased 'Packages::Polygon::Features::Features::Item';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	my @features = ();
	$self->{"features"} = \@features;

	return $self;
}

# Parse features layer of job entity
sub Parse {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $layer      = shift;
	my $breakSR    = shift;
	my $selected   = shift;    # parse only selected feature
	my $featFilter = shift;    # parse only given feat id
 
	die "Parameter \"selected\" is not allowed in combination with parameter \"breakSR\""   if ( $breakSR && $selected );

	my $breakSRVal  = $breakSR  ? "break_sr+" : "";
	my $selectedVal = $selected ? "select+"   : "";

	$inCAM->COM( "units", "type" => "mm" );

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => $breakSRVal . $selectedVal . "feat_index+f0",
								 parse           => 'no'
	);
	my $f;
	open( $f, "<" . $infoFile );
	my @feat = <$f>;
	close($f);
	unlink($infoFile);

	# if filter specify feats
	if ( $featFilter && scalar( @{$featFilter} ) ) {

		my %tmp;
		@tmp{ @{$featFilter} } = ();
		my @featTmp = ();

		for ( my $i = 0 ; $i < scalar(@feat) ; $i++ ) {

			my ( $featId, $featType ) = $feat[$i] =~ m/^#(\d*)\s*#(\w)/;
			if ( exists $tmp{$featId} ) {

				push( @featTmp, $feat[$i] );

				# if features is surface, add next lines (whole surafce def)
				if ( $featType =~ /s/i ) {
					$i++;
					while ( $feat[$i] ne "\n" ) {
						push( @featTmp, $feat[$i] );
						$i++;
					}
					push( @featTmp, $feat[$i] );
				}
			}
		}

		@feat = @featTmp;
	}

	my @features = $self->__ParseLines( \@feat, $step );

	# Add inforamtion about source steps, ancestor steps to feats
	if ($breakSR) {

		$self->__AddBreakSRInfo( $inCAM, $jobId, $step, $layer, \@features );
	}

	$self->{"features"} = \@features;
}

# Parse features layer of symbol entity
sub ParseSymbol {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $symbol = shift;

	$inCAM->COM( "units", "type" => "mm" );

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'symbol',
								 entity_path     => "$jobId/$symbol",
								 data_type       => 'FEATURES',
								 options         => "feat_index+f0",
								 parse           => 'no'
	);
	my $f;
	open( $f, "<" . $infoFile );
	my @feat = <$f>;
	close($f);
	unlink($infoFile);

	my @features = $self->__ParseLines( \@feat );

	$self->{"features"} = \@features;
}

sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };

}

# Return features by feature id (unique per layer)
sub GetFeatureById {
	my $self = shift;
	my $id   = shift;

	my @features = grep { $_->{"id"} eq $id } @{ $self->{"features"} };

	# feature id are unique per layer, but when BreakSR, more feature can have same id
	if ( scalar(@features) ) {
		return @features;
	}
	else {

		return 0;
	}

}

# Return features by feature id (unique per layer)
sub GetFeatureByGroupGUID {
	my $self      = shift;
	my $groupGuid = shift;

	my @features = grep { defined $_->{"att"}->{"feat_group_id"} && $_->{"att"}->{"feat_group_id"} eq $groupGuid } @{ $self->{"features"} };

	# feature id are unique per layer, but when BreakSR, more feature can have same id

	return @features;

}

sub __ParseLines {

	my $self  = shift;
	my @lines = @{ shift(@_) };
	my $step  = shift;            # source step (default is parent step)

	my @features = ();

	my $type = undef;
	my $l    = undef;

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		$l = $lines[$i];

		if ( $l =~ /###|^\n$/ ) { next; }

		my $featInfo = Item->new();

		my @attr = ();

		($type) = $l =~ m/^#\d*\s*#(\w)\s*/;

		# line,  pads
		if (
			$l =~ m{^\#
						(\d*)\s*					 # feati id
						\#([pl])\s*					 # type
						((-?[0-9]*\.?[0-9]*\s)*)\s*	 # coordinate
						([^\s]+)\s*		 # symbol name
						([pn])\s*					 # positive/negative
						(\d+)\s*					 # d-code
						(\d+)?\s*					 # angle
						([ny])?						 # mirror
						;?(.*)						 # attributes
					}xi
		  )
		{
			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;

			my @points = split( /\s/, $3 );

			#remove sign from zero value, when after rounding there minus left

			$featInfo->{"x1"} = $points[0];
			$featInfo->{"y1"} = $points[1];
			$featInfo->{"x2"} = $points[2];
			$featInfo->{"y2"} = $points[3];

			$featInfo->{"symbol"} = $5;

			$featInfo->{"polarity"} = $6;
			$featInfo->{"angle"}    = $8;
			$featInfo->{"mirror"}   = $9;

			@attr = split( ",", $10 );

			if ( $featInfo->{"symbol"} =~ /^[rs]([0-9]*\.?[0-9]*)$/ ) {
				$featInfo->{"thick"} = $1;
			}

		}    # arc
		elsif (
			$l =~ m{^\#
						(\d*)\s*					 # feati id
						\#(a)\s*					 # type
						((-?[0-9]*\.?[0-9]*\s)*)\s*	 # coordinate
						(\w+[0-9]*\.?[0-9]*)\s*		 # symbol name
						([pn])\s*					 # positive/negative
						(\d+)\s*					 # d-code
						([ny])						 # cw/ccw
						;?(.*)						 # attributes
					}xi
		  )
		{
			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;

			my @points = split( /\s/, $3 );

			#remove sign from zero value, when after rounding there minus left

			$featInfo->{"x1"}   = $points[0];
			$featInfo->{"y1"}   = $points[1];
			$featInfo->{"x2"}   = $points[2];
			$featInfo->{"y2"}   = $points[3];
			$featInfo->{"xmid"} = $points[4];
			$featInfo->{"ymid"} = $points[5];

			$featInfo->{"symbol"}   = $5;
			$featInfo->{"polarity"} = $6;
			$featInfo->{"oriDir"}   = $8 eq "Y" ? "CW" : "CCW";

			@attr = split( ",", $9 );

			if ( $featInfo->{"symbol"} =~ /^[rs]([0-9]*\.?[0-9]*)$/ ) {
				$featInfo->{"thick"} = $1;
			}
		}

		# surfaces
		elsif ( $l =~ m/^#(\d*)\s*#(s)\s*([\w\d\s]*);?(.*)/i ) {

			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;
			@attr = split( ",", $4 );

			$i++;

			my @allSurf = ();

			my %surfInf = ();

			while ( $lines[$i] ne "\n" ) {

				my $type = undef;

				my @points = __ParseSurfDef( \@lines, \$i, \$type );

				# parsed surf is island
				if ( $type eq "i" ) {

					if ( exists $surfInf{"island"} ) {

						# determine if surface is circle
						if ( scalar( @{ $surfInf{"island"} } ) == 2 && $surfInf{"island"}->[1]->{"type"} eq "c" ) {
							$surfInf{"circle"} = 1;
						}

						push( @allSurf, dclone( \%surfInf ) );
					}

					%surfInf = ( "island" => \@points, "holes" => [], "circle" => 0 );

				}
				elsif ( $type eq "h" ) {

					push( @{ $surfInf{"holes"} }, \@points );
				}
			}

			# determine if surface is circle
			if ( scalar( @{ $surfInf{"island"} } ) == 2 && $surfInf{"island"}->[1]->{"type"} eq "c" ) {
				$surfInf{"circle"} = 1;
			}
			push( @allSurf, \%surfInf );    # push last parsed surf

			$featInfo->{"surfaces"} = \@allSurf;

		}

		# Text
		elsif (
			$l =~ m{^\#
							(\d*)\s*  					# feat id
							\#(t)\s*	 				# type - T
							((-?[0-9]*\.?[0-9]*\s)*).* 	# position
							([pn])\s 					# positive/negative
							(\d+)\s 					# rotation angle
							([ny]).* 					# mirror
							'(.*)'\s\w 					# text
							;?(.*) 						# atribites
						$}ix
		  )
		{

			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;

			my @points = split( /\s/, $3 );

			$featInfo->{"x1"} = $points[0];
			$featInfo->{"y1"} = $points[1];
			$featInfo->{"x2"} = undef;
			$featInfo->{"y2"} = undef;

			$featInfo->{"polarity"} = $5;
			$featInfo->{"angle"}    = $6;
			$featInfo->{"mirror"}   = $7;

			$featInfo->{"text"} = $8;

			@attr = split( ",", $9 );

		}
		else {

			die "Unknow feature type: $l";
		}

		# parse attributes
		foreach my $at (@attr) {

			my @attValue = split( "=", $at );

			# some attributes doesn't have value, so put there "-"
			unless ( defined $attValue[1] ) {
				$attValue[1] = "-";
			}
			$featInfo->{"att"}{ $attValue[0] } = $attValue[1];
		}

		# assing internal unique id
		$featInfo->{"uid"} = $i + 1;
		
		# set source step. Default is parent step 
		# (if breakSR, source step is set in __AddBreakSRInfo function)
		$featInfo->{"uid"} = $i + 1;
		$featInfo->{"step"} =  $step;

		push( @features, $featInfo );
	}

	return @features;
}

# parse block of surface point  and return parsed points in array
# - from start line: #     #OB
# - to end line: #     #OE
sub __ParseSurfDef {
	my $lines = shift;
	my $i     = shift;
	my $type  = shift;

	my @surfPoints = ();

	while (1) {

		my $lIn = $lines->[$$i];
		$$i++;

		if ( $lIn =~ /^#\s*#o([bsc])\s*((?:-?[0-9]+\.?[0-9]*\s*){2,4})\s*([YIH]?)/i ) {

			my %inf = ();

			# B - begin
			# E - end
			# S - standard point
			# C - point defined by circle

			#$inf{"type"} = lc($1);
			# Decide if surface is island or hole

			my $lType = lc($1);

			$inf{"type"} = $lType;

			if ( $lType eq "b" ) {

				$$type = lc($3);
			}

			my @points = split( " ", $2 );
			s/\s+$// for @points;

			$inf{"x"} = $points[0];
			$inf{"y"} = $points[1];

			# C - point defined by circle, store center point of circle
			if ( $lType eq "c" ) {

				$inf{"xmid"} = $points[2];
				$inf{"ymid"} = $points[3];

			}

			push( @surfPoints, \%inf );

		}
		elsif ( $lIn =~ /^#\s*#oe/i ) {

			last;
		}

	}

	return @surfPoints;
}

# Add infto about sorce step and ancestor steps when breakSR
sub __AddBreakSRInfo {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $features = shift;

	my %stepFeatsCnt = ();
	my @allSteps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );

	return 0 unless ( scalar(@allSteps) );    # SR doesn't exist, return 0

	push( @allSteps, $step );
	foreach my $step (@allSteps) {

		my %featHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $layer, 0 );
		$stepFeatsCnt{$step} = $featHist{"total"};

	}
	my @stepsInfo = ();
	$self->__GetBreakSRInfo( $inCAM, $jobId, \@stepsInfo, $step, [] );

	my $curIdx = 0;
	foreach my $stepInfo (@stepsInfo) {

		my $ancestorStr = join( "/", reverse( @{ $stepInfo->{"SRAncestors"} } ) );

		my $stepCnt = $stepFeatsCnt{ $stepInfo->{"step"} };

		for ( my $i = 0 ; $i < $stepCnt ; $i++ ) {
			$features->[$curIdx]->{"step"}        = $stepInfo->{"step"};
			$features->[$curIdx]->{"SRAncestors"} = $ancestorStr;

			$curIdx++;

		}
	}

	die "$step feature cnt (" . scalar( @{$features} ) . ") don't equal to SR parsed feature cnt ($curIdx)" if ( scalar( @{$features} ) != $curIdx );

	return 1;
}

sub __GetBreakSRInfo {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $srFeatures   = shift;
	my $curStepName  = shift;
	my @stepAncestor = @{ shift(@_) };

	my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $curStepName );

	foreach my $repeat (@repeats) {

		my @ancestor = ( @stepAncestor, $curStepName );

		$self->__GetBreakSRInfo( $inCAM, $jobId, $srFeatures, $repeat->{"stepName"}, \@ancestor );
	}

	my %featInf = ();
	$featInf{"step"}        = $curStepName;
	$featInf{"SRAncestors"} = \@stepAncestor;

	push( @{$srFeatures}, \%featInf );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Features::Features::Features';
	use aliased 'Packages::InCAM::InCAM';

	my $f = Features->new();

	my $jobId = "d208968";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "mc";

	my @feat = (293);
	$f->Parse( $inCAM, $jobId, $step, $layer, 1, 0, \@feat );

	my @features = $f->GetFeatures();

	die;

}

1;
