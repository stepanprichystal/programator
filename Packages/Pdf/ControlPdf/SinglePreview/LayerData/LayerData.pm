
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerData;


#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataSingle';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self  = {};
	bless $self;

	$self->{"type"} = shift;
	$self->{"output"} = undef;

	my @l = ();
	$self->{"singleLayers"}    = \@l; 
 
	return $self;  
}

sub GetType{
	my $self = shift;
	 
	return $self->{"type"};
}

sub GetOutputLayer{
	my $self = shift;
	 
	return $self->{"output"};
}

 
sub SetOutputLayer{
	my $self = shift;
	my $lName = shift;
	
	
	$self->{"output"} = $lName;
}
 
sub AddSingleLayer{
	my $self = shift;
 
	
	my $singleLayer = LayerDataSingle->new(@_);
	
	push(@{$self->{"singleLayers"}}, $singleLayer);
}
 
sub GetSingleLayers{
	my $self = shift;
	return @{$self->{"singleLayers"}};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

