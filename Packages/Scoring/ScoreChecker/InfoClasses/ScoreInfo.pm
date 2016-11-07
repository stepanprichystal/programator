
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::InfoClasses::ScoreInfo;

#3th party library
use strict;
use warnings;
use Math::Round;

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
	$self->{"length"}    = shift;
	
	
	#$self->{"dec"}    = shift;  # tell precision of compering score position
	
	
	

	#$self->__RoundPoints();
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


sub GetLength{
	my $self = shift;
	return $self->{"length"};
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



sub GetDirection {
	my $self = shift;
	return $self->{"dir"};
}

sub __RoundPoints {
	my $self = shift;
	
	my $dec= $self->{"dec"};

#	$self->{"startP"}->{"x"} = sprintf( "%.".$dec."f", $self->{"startP"}->{"x"} );
#	$self->{"startP"}->{"y"} = sprintf( "%.".$dec."f", $self->{"startP"}->{"y"} );
#
#	$self->{"endP"}->{"x"} = sprintf( "%.".$dec."f", $self->{"endP"}->{"x"} );
#	$self->{"endP"}->{"y"} = sprintf( "%.".$dec."f", $self->{"endP"}->{"y"} );

	$self->{"startP"}->{"x"} = int($self->{"startP"}->{"x"} + 0.5);
	$self->{"startP"}->{"y"} = int( $self->{"startP"}->{"y"} + 0.5);

	$self->{"endP"}->{"x"} = int($self->{"endP"}->{"x"} + 0.5);
	$self->{"endP"}->{"y"} = int( $self->{"endP"}->{"y"} + 0.5);
	
	
	if($self->GetDirection() eq Enums->Dir_HSCORE ){
				
				if($self->GetStartP()->{"y"} != $self->GetEndP()->{"y"}){
					
					print STDERR sprintf("%10.20f", $self->GetEndP()->{"y"})."\n";
					print STDERR sprintf("%10.20f",$self->GetEndP()->{"y"})."\n";
					
					print STDERR sprintf("%10.20f", int($self->GetStartP()->{"y"}*100)/100)."\n";
					print STDERR sprintf("%10.20f",int($self->GetEndP()->{"y"}*100)/100)."\n";
					
					print STDERR "22222\n";
				}
				
			}


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

