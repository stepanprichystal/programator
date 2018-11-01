
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoExport::ProgCreator::ProgBuilder;

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Enums::EnumsGeneral';
#
 
#use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
#
#use aliased 'Packages::Export::ScoExport::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'Packages::Export::ScoExport::Enums';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"coreThick"} = shift;
	$self->{"pcbThick"}  = shift;
	$self->{"width"}     = shift;
	$self->{"height"}    = shift;
	$self->{"direction"} = shift;

	return $self;
}

sub BuildHeader {
	my $self = shift;

	my $dir = $self->{"direction"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $str = "";

	my $pcbThickStr  = sprintf( "%3.3f", $self->{"pcbThick"} );
	my $coreThickStr = sprintf( "%.3f",  $self->{"coreThick"} );

	my $id = $self->{"direction"} eq ScoEnums->Dir_VSCORE ? 1 : 2;

	my $w = sprintf( "%3.3f", $self->{"width"} );
	my $h = sprintf( "%3.3f", $self->{"height"} );

	$str .= "%%5500\n";
	$str .= "(----------------------------------)\n";
	$str .= "( Machine        : SCM411-1        )\n";
	$str .= "( Program name   : $jobId          )\n";
	$str .= "( Panel thickness: $pcbThickStr mm        )\n";
	$str .= "( Core           : $coreThickStr mm        )\n";
	$str .= "( X-Factor       : 100.0000 %      )\n";
	$str .= "( Fiducial       : -               )\n";
	$str .= "( Working        : Part $id          )\n";
	$str .= "(----------------------------------)\n";
	$str .= "M49,SEQP100P" . $w . "\n";
	$str .= "M49,SEQP101P" . $h . "\n";
	$str .= "M49,SEQP102P$pcbThickStr\n";

	return $str;

}

sub BuildBody {
	my $self = shift;
	my $type = shift;
	my @sets = @{ shift(@_) };

	#my $inCAM = $self->{"inCAM"};
	#my $jobId = $self->{"jobId"};

	my $dir = $self->{"direction"};

	#my $origin = shift;

	my $crossOver = 130;    # this value mean, cut machine goes behind pcb, by 130 mm after each score line ( "park area")

	my $xSize = $self->__GetSizeX();
	my $ySize = $self->__GetSizeY();

	#	my $PlusXsizePoj  = sprintf "%3.3f", ( $self->{"height"} + $crossOver );
	#	my $PlusYsizePoj  = sprintf "%3.3f", ( $self->{"width"} + $crossOver );
	#	my $MinusXsizePoj = sprintf "%3.3f", ( 0 - $prejezdX );
	#	my $MinusYsizePoj = sprintf "%3.3f", ( 0 - $prejezdY );

	my $osaA = sprintf "%3.2f", ( ( $self->{"pcbThick"} / 2 ) - ( $self->{"coreThick"} / 2 ) );
	my $osaZ = sprintf "%3.2f", ( $self->{"pcbThick"} - $osaA );

	my $speed = $self->__GetSpeed();
	my $str   = "";

	# vertical score, get x

	my $initLine = 0;

	my $top2Bot = 1;    # tell if machine goes from top2bot or bot2top

	foreach my $set (@sets) {

		# 1) set x position of scoring
		$str .= "T00X" . sprintf( "%3.3f", $set->GetPoint() / 1000 ) . "\n";    # position of score lines

		# 2) go behind pannel TOP/BOTTOM to park area
		#my $crossOverPos = $ySize + $crossOver;
		# put only once, position. No idea what is mean..
		unless ($initLine) {

			chop($str);                                                         #remove last new line
			$str .= "Y" . sprintf( "%3.3f", $ySize + $crossOver );              # go to TOP park area
			$str .= "T01H10.0B1.5Z" . $osaZ . "A-" . $osaA . "\n";
			$str .= "T00M38\n";
			$initLine = 1;
		}

		# 3)
		# put all line on specific position, defined by set
		my $reverse = !$top2Bot ? 1 : 0;
		foreach my $line ( $set->GetLines($reverse) ) {

			# get start, end point of score line

			my $start = $line->GetStartP()->{"y"};
			my $end   = $line->GetEndP()->{"y"};

			$start = sprintf( "%3.3f", $start / 1000 );
			$end   = sprintf( "%3.3f", $end / 1000 );

			# print line
			$str .= "T00Y" . $start . "\n";
			$str .= "G01Y" . $end . "F" . $speed . "\n";

		}

		# a) Mach. behaviour when type is CLASSIC
		if ( $type eq Enums->Type_CLASSIC ) {
			
			if ($top2Bot) {

				$str .= "T00Y" . sprintf( "%3.3f", -$crossOver ) . "\n";    # go to BOT park area
			}
			# machine goes from bot to top
			elsif ( !$top2Bot ) {

				$str .= "T00Y" . sprintf( "%3.3f", $ySize + $crossOver ) . "\n";    # go to TOP park area
			}

			# Next switch order of score lines, because machine goes from bottom of panel

			if ($top2Bot) {
				$top2Bot = 0;
			}
			else {
				$top2Bot = 1;
			}
		}

		# b) Mach. behaviour  when type is ONE DIRECTION
		if ( $type eq Enums->Type_ONEDIR ) {

			$str .= "T00Y" . sprintf( "%3.3f", $ySize + $crossOver ) . "\n";    # go back to TOP park area
		}

	}

	$str .= "T00M39\n";
	$str .= "M30";

}

# return size of panel
sub __GetSizeX {
	my $self = shift;

	if ( $self->{"direction"} eq ScoEnums->Dir_HSCORE ) {

		return $self->{"height"};
	}
	elsif ( $self->{"direction"} eq ScoEnums->Dir_VSCORE ) {

		return $self->{"width"};
	}
}

# return size of panel
sub __GetSizeY {
	my $self = shift;

	if ( $self->{"direction"} eq ScoEnums->Dir_HSCORE ) {

		return $self->{"width"};
	}
	elsif ( $self->{"direction"} eq ScoEnums->Dir_VSCORE ) {

		return $self->{"height"};
	}
}

sub __GetSpeed {
	my $self = shift;

	my $speed = undef;
	if ( $self->{"pcbThick"} > 1.9 ) {
		$speed = sprintf "%3.1f", (20.0);
	}
	elsif ( $self->{"pcbThick"} < 1.1 ) {
		$speed = sprintf "%3.1f", (15.0);

	}
	elsif ( $self->{"pcbThick"} < 0.9 ) {
		$speed = sprintf "%3.1f", (10.0);
	}
	else {
		$speed = sprintf "%3.1f", (30.0);
	}

	return $speed;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

