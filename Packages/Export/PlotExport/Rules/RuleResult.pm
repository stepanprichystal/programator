#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::Rules::RuleResult;

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
	
	$self->{"rule"} = shift;
	
	
	my @layers = ();
	$self->{"layers"} = \@layers;
 
	return $self;
}


sub Complete{
	my $self = shift;
	
	my @types = $self->{"rule"}->GetLayerTypes();
	my @layers = @{$self->{"layers"}};
	
	if(scalar(@types) == scalar(@layers)){
		
		return 1;
	}else{
		
		return 1;	
	}
	
	
}

sub AddLayer{
	my $self = shift;
	my $layer = shift;	
		
	push(@{$self->{"layers"}}, $layer);
}


sub GetLayers{
	my $self = shift;
 
		
	return @{$self->{"layers"}};
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
