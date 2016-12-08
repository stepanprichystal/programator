
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::LayerData::LayerData;


#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::LayerData::SingleLayerData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self  = {};
	bless $self;

	$self->{"type"}    = shift;  
 
	my @l = ();
	$self->{"layers"}    = \@l;  

	
	return $self;  
}


 
sub AddSingleLayer{
	my $self = shift;
	my $l = shift;
	my $lTitle = shift;
	my $lInfo = shift;
	
	my $d = SingleLayerData->new($l, $lTitle, $lInfo);
	
	push(@{$self->{"layers"}}, $d);
	
}
 
 
sub GetLayerByName{
	my $self = shift;
	my $name = shift;
	
	my $sl = (grep {$_->{"gROWname"} eq $name} @{$self->{"layers"}})[0];
	return $sl;

}  
 
sub GetSingleLayers{
	my $self = shift;

	return @{$self->{"layers"}};

} 


sub GetLayerCnt{
	my $self = shift;
	
	
	return @{$self->{"layers"}};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

