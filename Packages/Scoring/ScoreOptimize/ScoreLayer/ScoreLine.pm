
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLine;

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
 
 	$self->{"dir"}    = shift;
 
	$self->{"startP"} = undef;
	$self->{"endP"}   = undef;

 
 
	return $self;
}



sub GetStartP{
	my $self = shift;
	return $self->{"startP"};
	 
}

sub GetEndP{
	my $self = shift;
	return $self->{"endP"};
	 
}


sub SetStartP{
	my $self = shift;
	$self->{"startP"} = shift;
	 
}

sub SetEndP{
	my $self = shift;
	 $self->{"endP"} = shift;
	 
}

 
sub Complete{
	my $self = shift;
	
	if($self->StartPExist() && $self->EndPExist()){
		return 1;
	}else{
		return 0;
	}
	
	
} 
 
sub StartPExist{
	my $self = shift;
	
	if($self->{"startP"}){
		return 1;
	}else{
		return 0;
	}
}

sub EndPExist{
	my $self = shift;
	
	if($self->{"endP"}){
		return 1;
	}else{
		return 0;
	}
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

