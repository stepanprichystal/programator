
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLayer;

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

	 
	my @sets = ();
	$self->{"scoreSets"}    = \@sets;   
 

	return $self;
}

sub GetSets{
	my $self = shift;
	my $dir = shift;
	
	my @sets = @{$self->{"scoreSets"}};
	
	if($dir){
		
		@sets = grep {$_->GetDirection() eq $dir} @sets;
	}
	
	return @sets;
}

sub AddScoreSet{
	my $self = shift;
	my $set = shift;
	
	
	push(@{$self->{"scoreSets"}}, $set);
	
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

