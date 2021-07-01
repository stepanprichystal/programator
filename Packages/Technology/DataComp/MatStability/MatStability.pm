#-------------------------------------------------------------------------------------------#
# Description: Return information about material stability
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Technology::DataComp::MatStability::MatStability;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"matKinds"} = shift;

	# Tables with material stability values (loaded on demand, during first request)
	$self->{"tables"} = undef;

	return $self;
}

# Return how much is material shrinked at X/Y direction after process in PPM unit
sub GetMatStability {
	my $self     = shift;
	my $matKind  = shift;
	my $matThick = shift;    # µm
	my $cuThick  = shift;    # µm
	my $cuUsage  = shift;    # %

	die "Material kind is not defined"         unless ( defined $matKind );
	die "Material thickness is not defined"    unless ( defined $matThick );
	die "Material cu thickness is not defined" unless ( defined $cuThick );
	die "Material cu ussage is not defined"    unless ( defined $cuUsage );
	
	# 0) Load material stability
	unless ( defined $self->{"tables"} ) {

		my %tables = $self->__LoadMatTables();
		$self->{"tables"} = \%tables;
	}

	# 1) indicate what is orientation of panel in production
	my $ori = $self->__GetPanelOrientation($matKind);

	# 2) Get dimension stability at % for panel x/y side

	my $cuUsageCat = undef;
	$cuUsageCat = "u1" if ( $cuUsage < 33 );
	$cuUsageCat = "u2" if ( $cuUsage >= 33 && $cuUsage <= 66 );
	$cuUsageCat = "u3" if ( $cuUsage > 66 );

	my $p = GeneralHelper->Root() . "\\Packages\\Technology\\DataComp\\MatStability\\" . $matKind . ".csv";

	# check available material thickness. Tolerance +-10%

	my @thicks = sort { $a <=> $b } keys %{ $self->{"tables"}->{$matKind} };
	my $selMatThick = first { abs( $_ - $matThick ) < $_ * 0.1 } @thicks;

	die "Dim stability for: $matKind; thickness: $selMatThick µm is not defined at: $p"
	  unless ( defined $self->{"tables"}->{$matKind}->{$selMatThick} );

	die "Dim stability for: $matKind; thickness: $selMatThick µm; Cu thickness: $cuThick µm is not defined at: $p"
	  unless ( defined $self->{"tables"}->{$matKind}->{$selMatThick}->{$cuThick} );


	my $vals = $self->{"tables"}->{$matKind}->{$selMatThick}->{$cuThick}->{$cuUsageCat};


	die "Dim stability of 'X' dir for: $matKind; thickness: $selMatThick µm; Cu thickness: $cuThick µm is not defined at: $p"
	  if ( !defined $vals->{"x"} || $vals->{"x"} eq "");

	die "Dim stability of 'Y' dir for: $matKind; thickness: $selMatThick µm; Cu thickness: $cuThick µm is not defined at: $p"
	   if ( !defined $vals->{"y"} || $vals->{"y"} eq "");

	

	my $x = $ori eq "transverse" ? $vals->{"y"} : $vals->{"x"};
	my $y = $ori eq "transverse" ? $vals->{"x"} : $vals->{"y"};

	my $xPPM = $x;
	my $yPPM = $y;

	return ( $xPPM, $yPPM );

}

# Return panel orientation depands on usage of basic material
# - machine - longer panel side is in machine direction (direction which machine output material)
# - transverse - shorter panel side is in machine direction (cross direction which machine output material)
sub __GetPanelOrientation {
	my $self    = shift;
	my $matKind = shift;

	my %pnlOrient = ();
	$pnlOrient{"PYRALUX"} = "machine"; # Pyralux AP - produced as sheets 600x900mm
	$pnlOrient{"THINFLEX"} = "transverse"; # Twhiflex W - produced as rolles with 500mm width

	my $ori = $pnlOrient{$matKind};
	$ori = "machine" unless ( defined $ori );

	return $ori;
}

sub __LoadMatTables {
	my $self = shift;

	my $matKinds  = $self->{"matKinds"};
	my %matTables = ();

	# 1) Load material table and check format

	# material file has to have folowing format:
	# Legend:
	# - <Core>           = Core thickness in µm
	# - <Cu thickness>   = Cu thickness in µm
	# - <1.usage>        = Cu usage <33%
	# - <2.usage>        = Cu usage 33%-66%
	# - <3.usage>        = Cu usage >66%
	# - <xs>             = Stretch of material at x in PPM => TRANSVERSAL direction
	# - <ys>             = Stretch of material at y axis in PPM => MACHINE direction
	#
	# File format
	# Cu     ;<Cu thickness>     ;         ;         ;<Cu thickness>;    ;         ;
	# Usage  ;<1.usage>;<2.usage>;<3.usage>;<1.usage>;<2.usage>;<3.usage>;<1.usage>;<2.usage>
	# Core   ;tdir;mdir;tdir;mdir;tdir;mdir;tdir;mdir;tdir;mdir;tdir;mdir;tdir;mdir;
	# <Core> ;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;
	# <Core> ;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;<xs>;<ys>;
	# ...

	foreach my $mat ( @{$matKinds} ) {

		my $p = GeneralHelper->Root() . "\\Packages\\Technology\\DataComp\\MatStability\\" . $mat . ".csv";

		die "\"$mat\" material stability file doesn't exist at: $p" unless ( -e $p );

		my @lines = grep { $_ ne "" } @{ FileHelper->ReadAsLines($p) };
		@lines = grep( s/\s$//g, @lines );

		die "Wrong formated Cu thickness line at Material stability file: $p" if ( $lines[0] !~ /^cu;(\d+(µm)?;{5};?)+$/i );
		die "Wrong formated Cu usage line at Material stability file: $p"     if ( $lines[1] !~ /^usage;([<\->\w%]+;;?)+$/i );
		die "Wrong formated tdir/mdir colums line at Material stability file: $p"   if ( $lines[2] !~ /^core;((tdir;mdir;?){3})+$/i );

		# 2) Build search structure

		$lines[0] =~ s/µm//ig;    # Remove units from Cu
		my @cuThickness = grep { defined $_ && $_ =~ /\d+/ } split( ";", $lines[0] );

		my %matrix = ();

		my %coreInf = ();

		foreach my $l ( @lines[ 3 .. scalar(@lines) - 1 ] ) {

			my @lineVals = split( ";", $l );

			my $coreThickness = shift @lineVals;
			$coreThickness =~ s/µm//ig;

			#my $cuInc  = 0;
			my $currCu = $cuThickness[0];

			my %cuVals = ();

			for ( my $i = 0 ; $i < scalar(@lineVals) ; $i += 6 ) {

				if ( $i > 0 && ($i) % 6 == 0 ) {
					$currCu = $cuThickness[ ($i) / 6 ];

					#$coreInf{$currCu} = \%cuVals;

					#%cuVals = ();
				}

				my %cuVal = ();

				#for ( my $j = $i ; $j < 6 ; $j++ ) {

				my %usage1 = ( "x" =>, $lineVals[ $i + 0 ], "y" => $lineVals[ $i + 1 ] );
				my %usage2 = ( "x" =>, $lineVals[ $i + 2 ], "y" => $lineVals[ $i + 3 ] );
				my %usage3 = ( "x" =>, $lineVals[ $i + 4 ], "y" => $lineVals[ $i + 5 ] );

				$cuVal{"u1"} = \%usage1;
				$cuVal{"u2"} = \%usage2;
				$cuVal{"u3"} = \%usage3;

				#$i += 6;

				#}

				$cuVals{$currCu} = \%cuVal;

			}

			$coreInf{$coreThickness} = \%cuVals;
		}

		$matTables{$mat} = \%coreInf;
	}

	return %matTables;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Technology::DataComp::MatStability::MatStability';

	my $t = MatStability->new("PYRALUX");
	die $t;

}

1;
