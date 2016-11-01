
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::ScoreInfo;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Scoring::ScoreChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"startP"} = shift;
	$self->{"endP"}   = shift;
	$self->{"dir"}    = shift;
	
	$self->{"dec"}    = shift;  # tell precision of compering score position
	
	
	

	$self->__RoundPoints();
	$self->__SetCourse();

	return $self;
}


sub GetStartP {
	my $self = shift;
	return $self->{"startP"};
}

sub GetEndP {
	my $self = shift;
	return $self->{"endP"};
}


# Return position of x/y, depand on direction
# this position value uniquely determine placement of score line
sub GetScorePoint {
	my $self = shift;

	if ( $self->{"dir"} eq Enums->Dir_HSCORE ) {

		return $self->{"startP"}->{"y"};

	}
	elsif ( $self->{"dir"} eq Enums->Dir_VSCORE ) {

		return $self->{"startP"}->{"x"};
	}
}

sub ExistOnPosition {
	my $self = shift;
	my $dir  = shift;
	my $pos  = shift;

	$pos = sprintf( "%.".$self->{"dec"}."f", $pos );

	my $exist = 0;

	if ( $self->{"dir"} ne $dir ) {
		return 0;
	}

	if ( $dir eq Enums->Dir_HSCORE ) {

		if ( $pos == $self->{"startP"}->{"y"} ) {
			$exist = 1;
		}

	}
	elsif ( $dir eq Enums->Dir_VSCORE ) {

		if ( $pos == $self->{"startP"}->{"x"} ) {
			$exist = 1;
		}
	}

}

sub GetDirection {
	my $self = shift;
	return $self->{"dir"};
}

sub __RoundPoints {
	my $self = shift;
	
	my $dec= $self->{"dec"};

	$self->{"startP"}->{"x"} = sprintf( "%.".$dec."f", $self->{"startP"}->{"x"} );
	$self->{"startP"}->{"y"} = sprintf( "%.".$dec."f", $self->{"startP"}->{"y"} );

	$self->{"endP"}->{"x"} = sprintf( "%.".$dec."f", $self->{"endP"}->{"x"} );
	$self->{"endP"}->{"y"} = sprintf( "%.".$dec."f", $self->{"endP"}->{"y"} );

}

# we want to  all:
# -  horizontal line starts in left
# -  verticall line starts from top
sub __SetCourse {
	my $self = shift;

	if ( $self->{"dir"} eq Enums->Dir_HSCORE ) {

		# test x points

		if ( $self->{"startP"}->{"x"} > $self->{"endP"}->{"x"} ) {

			my $val = $self->{"startP"}->{"x"};
			$self->{"startP"}->{"x"} = $self->{"endP"}->{"x"};
			$self->{"endP"}->{"x"}   = $val;

		}
	}
	elsif ( $self->{"dir"} eq Enums->Dir_VSCORE ) {

		# test y points

		if ( $self->{"startP"}->{"y"} < $self->{"endP"}->{"y"} ) {

			my $val = $self->{"startP"}->{"y"};
			$self->{"startP"}->{"y"} = $self->{"endP"}->{"y"};
			$self->{"endP"}->{"y"}   = $val;

		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

