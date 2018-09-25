
#-------------------------------------------------------------------------------------------#
# Description: Structure represent one particular operation on technical procedure
# Class can be created from one operation definitin or from group operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Operation::OperationItem;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::NCExport::Helpers::NCHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"name"}           = shift;    #name of exported nc file
	$self->{"operations"}     = shift;    #operations, one or more in case of grouped operation
	$self->{"operationGroup"} = shift;    #tell if item was created from group, ref to object represent group operation

	$self->{"layerOrder"}  = undef;       #contain order of layer as they will be merged
	$self->{"headerLayer"} = undef;       # tell which file's header will be used in final nc file

	my @machines = ();
	$self->{"machines"} = \@machines;     #contain machines, which are usitable for process this operation

	$self->__SetLayerOrder();
	$self->__SetHeaderLayer();

	return $self;
}

 
sub GetName {
	my $self     = shift;

	return $self->{"name"};
}

sub GetOperationGroup{
	my $self     = shift;
	
	return $self->{"operationGroup"};
}

sub GetOperations{
	my $self     = shift;
	
	return @{$self->{"operations"}};
}

sub SetMachines {
	my $self     = shift;
	my $machines = shift;

	$self->{"machines"} = $machines;
}

sub GetMachines {
	my $self     = shift;
	my $machines = shift;

	return @{ $self->{"machines"} };
}

sub GetSortedLayers {
	my $self = shift;

	return @{ $self->{"layerOrder"} };
}

sub GetHeaderLayer {
	my $self = shift;

	return $self->{"headerLayer"};
}

# Helper method, which return pairs: layer name + machine
# these layers will be later exported on these machines
sub GetExportCombination {
	my $self = shift;

	my @machines = @{ $self->{"machines"} };

	unless ( scalar(@machines) ) {
		my @empt = ();
		return @empt;
	}

	my @comb   = ();
	my @layers = $self->GetSortedLayers();

	foreach my $l (@layers) {
#{"name"}
		my %info = ( "layer" => $l->{"gROWname"}, "machines" => \@machines );
		push(@comb, \%info);

	}
	return @comb;
}

# Tell if some layer belonging to this operation is spleted on more stages
sub StagingExist {
	my $self  = shift;
	my $exist = 0;

	my @layers = $self->GetSortedLayers();
	my @lRes = grep { $_->{"stagesCnt"} > 1 } @layers;

	if ( scalar(@lRes) ) {
		$exist = 1;
	}

	return $exist;

}

# Return press order
# Value of press order is same for oll operation definitions, thus
# take it from first operation
sub GetPressOrder {
	my $self = shift;

	return ${ $self->{"operations"} }[0]->{"pressOrder"};
}

sub __SetLayerOrder {
	my $self = shift;

	my @unsorted = ();

	foreach my $opDef ( @{ $self->{"operations"} } ) {

		push( @unsorted, @{ $opDef->{"layers"} } );
	}

	my @sorted = NCHelper->SortLayersByRules( \@unsorted );
	$self->{"layerOrder"} = \@sorted;
}

sub __SetHeaderLayer {
	my $self = shift;

	my @l = @{ $self->{"layerOrder"} };

	$self->{"headerLayer"} = NCHelper->GetHeaderLayer( \@l );
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

