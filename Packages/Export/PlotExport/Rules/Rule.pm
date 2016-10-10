#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::Rules::Rule;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

 sub new {
	my $class     = shift;
	my $self ={};
	 
	bless $self;
	
	$self->{"orientation"} = shift;

	my @layerTypes = ();
	$self->{"layerTypes"} = \@layerTypes;
	 

	return $self;
}

 


sub AddSingleTypes{
	
	my $self = shift;
	@{$self->{"layerTypes"}} = @_;
 
}

sub AddType2{
	
	my $self = shift;
	my @types = @{shift(@_)};
	
	unless(scalar(@types)){
		
		return 0;
	}
 
	push($self->{"layerTypes"},\@types)
}

sub AddType1{
	
	my $self = shift;
	my @types = @{shift(@_)};
	
	unless(scalar(@types)){
		
		return 0;
	}
 
	push($self->{"layerTypes"},\@types)
}

sub AddTypes{
	
	my $self = shift;
	my @types = @{shift(@_)};
	
	unless(scalar(@types)){
		
		return 0;
	}
 
	push($self->{"layerTypes"},\@types)
}

sub GetLayerTypes{
	my $self = shift;
	
	
	return @{$self->{"layerTypes"}};
	
}

 
sub GetOrientation{
	my $self = shift;

	return $self->{"orientation"};
	
	
}
 
1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
