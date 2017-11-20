
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
	if ($featFilter) {
		my %tmp;
		@tmp{ @{$featFilter} } = ();
		@feat = grep { exists $tmp{ ( $_ =~ /^#(\d+)/i )[0] } } @feat;
	}

	my @features = $self->__ParseLines( \@feat );

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

			#
			#			my @envelop = ();
			#			while ( $lines[$i] =~ m/^#\s*#o[besc]\s*((-?[0-9]*\.?[0-9]*\s)*)/i ) {
			#
			#				my $lll  = $lines[$i];
			#				my $lll2 = $1;
			#
			#				my @points = split( /\s/, $1 );
			#
			#				for ( my $ip = 0 ; $ip < scalar(@points) ; $ip += 2 ) {
			#
			#					my @p = ( sprintf( "%.2f", $points[$ip] ), sprintf( "%.2f", $points[ $ip + 1 ] ) );    # x and y
			#					push( @envelop, \@p );
			#				}
			#
			#				$i++;
			#			}
			#
			#			$i--;
			#
			#			# 1) Reduce same point from surface
			#			my @envReduced = ();
			#			foreach my $e (@envelop) {
			#
			#				unless ( grep { @{$_}[0] == @{$e}[0] && @{$_}[1] == @{$e}[1] } @envReduced ) {
			#
			#					push( @envReduced, $e );
			#				}
			#			}
			#
			#			# 2 ) If points cnt is smaller than 3, do not envelop
			#			my @envelopFinal = ();
			#			if ( scalar(@envReduced) < 3 ) {
			#				push( @envelopFinal, $envReduced[0] );
			#			}
			#			else {
			#				@envelopFinal = PolygonPoints->GetConvexHull( \@envelop );
			#
			#			}
			#
			#			my @envelopFinalHash = ();
			#			foreach my $p (@envelopFinal) {
			#				my %pInf = ( "x" => @{$p}[0], "y" => @{$p}[1] );
			#				push( @envelopFinalHash, \%pInf );
			#			}
			#
			#			$featInfo->{"envelop"} = \@envelopFinalHash;

			# 3) Set center point of surface
			#my $centroid = PolygonPoints->GetCentroid( \@envelopFinal );
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

			next;
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Features::Features::Features';
	use aliased 'Packages::InCAM::InCAM';

	my $f = Features->new();

	my $jobId = "f52457";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "mc";

	my @feat = (1388);
	$f->Parse( $inCAM, $jobId, $step, $layer, 1, 0 );

	my @features = $f->GetFeatures();

	my @textFeats = grep { $_->{"type"} eq "T" } @features;

	print @textFeats;

}

1;
