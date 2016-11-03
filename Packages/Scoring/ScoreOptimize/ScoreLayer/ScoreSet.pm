
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
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
	$self->{"dir"} = shift;
	
	my @sco = ();
	$self->{"lines"} = \@sco;
 
 
	return $self;
}


sub GetLines{
	my $self = shift;
	

return @{$self->{"lines"}};
	 
}

sub AddScoreLine{
	my $self = shift;
	my $line = shift;

	push(@{$self->{"lines"}}, $line);

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

