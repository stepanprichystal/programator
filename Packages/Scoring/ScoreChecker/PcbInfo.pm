
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::PcbInfo;

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

	$self->{"origin"} = shift;

	#$self->{"originY"}     = shift;
	$self->{"width"}  = shift;
	$self->{"height"} = shift;

	my @sco = ();
	$self->{"score"} = \@sco;

	return $self;
}

sub AddScoreLine {
	my $self = shift;
	my $line = shift;

	push( @{ $self->{"score"} }, $line );

}



sub GetOrigin {
	my $self = shift;
 

	return $self->{"origin"};

}

sub GetScore {
	my $self = shift;
	my $dir  = shift;

	my @score = @{ $self->{"score"} };

	if ($dir) {
		@score = grep { $_->GetDirection() eq $dir } @score;
	}

	return @score;

}

sub ScoreExist {

}

sub IsScoreOnPos {
	my $self = shift;
	my $dir  = shift;
	my $pos  = shift;

	my $exist = 0;

	foreach my $sco ( @{ $self->{"score"} } ) {

		if ( $sco->ExistOnPosition( $dir, $pos ) ) {

			$exist = 1;
			last;
		}
	}

	return $exist;
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

