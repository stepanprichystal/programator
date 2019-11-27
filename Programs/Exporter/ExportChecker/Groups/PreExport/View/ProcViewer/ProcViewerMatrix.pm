
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewerMatrix;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewerMatrixItem';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Helpers::JobHelper';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"matrixItems"} = [];

	return $self;
}

sub BuildMatrix {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;

	foreach my $l ( @{ $signalLayers } ) {

		# 1) parse layer by name

		my %lInfo = JobHelper->ParseSignalLayerName( $l->{"gROWname"} );

		# 2) Find copper row form

		my ($copperRowFrm, $subGroupFrm) = $procViewerFrm->GetCopperFrms( $lInfo{"sourceName"}, $lInfo{"outerCore"}, $lInfo{"plugging"} );
		 
		# 3) Create matrix item

		my $mItem =
		  ProcViewerMatrixItem->new( $l->{"gROWname"}, $l, $lInfo{"sourceName"}, $lInfo{"outerCore"}, $lInfo{"plugging"}, $copperRowFrm, $subGroupFrm );
		push( @{ $self->{"matrixItems"} }, $mItem );
	}
}

sub GetItemsByProduct {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;
	 

	die "Product Id is not defined" unless ( defined $productId );
	die "Product Id is not defined" unless ( defined $productType );

	my @items =
	  grep { $_->GetSubGroupFrm()->GetProductId() eq $productId && $_->GetSubGroupFrm()->GetProductType() eq $productType }
	  @{ $self->{"matrixItems"} };

	return @items;
}

sub GetItemByOriName {
	my $self    = shift;
	my $oriName = shift;
	
	die "Original layer name is not defined" unless ( defined $oriName );

	my $item = first { $_->GetLayerName() eq $oriName } @{ $self->{"matrixItems"} };

	return $item;
}


sub GetAllSignalLayers{
	my $self    = shift;
	
	return  map { $_->GetLayerName() } @{ $self->{"matrixItems"} };
}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

