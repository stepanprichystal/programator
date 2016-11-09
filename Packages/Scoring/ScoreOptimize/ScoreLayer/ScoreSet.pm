
#-------------------------------------------------------------------------------------------#
# Description: Set contain position, where is score line placed
# Contain all score lines on this position also
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreSet;

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

	$self->{"point"} = shift;
	$self->{"dir"}   = shift;

	my @sco = ();
	$self->{"lines"} = \@sco;

	return $self;
}

# if reverse, switch order of score in array, switch start and end points
sub GetLines {
	my $self    = shift;
	my $reverse = shift;

	my @lines = @{ $self->{"lines"} };
	if ($reverse) {

		my @lines = reverse(@lines);

		foreach my $line (@lines) {

			my $v = $line->{"startP"};
			$line->{"startP"} = $line->{"endP"};
			$line->{"endP"}   = $v;

		}

	}

	return @lines;

}

sub GetPoint {
	my $self = shift;

	return $self->{"point"};

}

sub SetPoint {
	my $self = shift;

	$self->{"point"} = shift;

}

sub AddScoreLine {
	my $self = shift;
	my $line = shift;

	push( @{ $self->{"lines"} }, $line );

}

sub GetDirection {
	my $self = shift;
	return $self->{"dir"};
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

