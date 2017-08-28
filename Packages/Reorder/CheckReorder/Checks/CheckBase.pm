#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::CheckBase;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self     = shift;
	my $checkKey = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift;
	my $isPool   = shift;

	$self = {};
	bless $self;

	my @changes = ();
	$self->{"changes"} = \@changes;

	$self->{"key"}      = $checkKey;
	$self->{"inCAM"}    = $inCAM;
	$self->{"jobId"}    = $jobId;
	$self->{"jobExist"} = $jobExist;
	$self->{"isPool"}   = $isPool;

	return $self;
}

sub _AddChange {
	my $self       = shift;
	my $changeMess = shift;
	my $critical = shift || 0; # It means, reorder can be processed, until critical changes are ok

	

	my %inf = ("text" => $changeMess, "critical" => $critical);

	push( @{ $self->{"changes"} }, \%inf );

}

sub GetChanges {
	my $self = shift;

	return @{ $self->{"changes"} };

}

sub GetCheckKey {
	my $self = shift;

	return $self->{"key"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	print "ee";
}

1;

