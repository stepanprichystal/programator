#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::Rules::RuleResult;

#3th party library
use strict;
use warnings;

#local library
 use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

 
 sub new {
	my $class     = shift;
	my $self ={};
	 
	bless $self;
	
	$self->{"rule"} = shift;
	
	$self->{"filmSize"} = undef;
	
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
		
		return 0;	
	}
	
	
}

sub SetDimenison{
		my $self = shift;
	my $filmSize = shift;	
	
	$self->{"filmSize"} = $filmSize;
	
}

sub GetFilmSize{
	my $self = shift;
	return $self->{"filmSize"};
	
}

sub GetOrientation{
	my $self = shift;
	
	return $self->{"rule"}->GetOrientation();
	
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


# return onli for verticall type

sub GetTotalX{
	my $self = shift;
	
	my $ori = $self->{"rule"}->GetOrientation();
	
	my $total = 0;
	
	if($ori eq Enums->Ori_VERTICAL){
		
		foreach my $l (@{$self->{"layers"}}){
			
			$total += $l->{"sizeX"};
		}

	} 
	 return $total;
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
