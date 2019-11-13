
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

		my %lInfo = $self->__ParseCopperLayerName( $l->{"gROWname"} );

		# 2) Find copper row form

		my ($copperRowFrm, $subGroupFrm) = $procViewerFrm->GetCopperFrms( $lInfo{"nameCopper"}, $lInfo{"outerCore"}, $lInfo{"plugging"} );
		 
		# 3) Create matrix item

		my $mItem =
		  ProcViewerMatrixItem->new( $l->{"gROWname"}, $l, $lInfo{"nameCopper"}, $lInfo{"outerCore"}, $lInfo{"plugging"}, $copperRowFrm, $subGroupFrm );
		push( @{ $self->{"matrixItems"} }, $mItem );
	}
}

sub GetItemsByProduct {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;
	my $side        = shift;

	die "Side is not defined" unless ( defined $side );

	my @items =
	  grep { $_->GetSubGroupFrm()->GetProductId() eq $productId && $_->GetSubGroupFrm()->GetProductType() eq $productType }
	  @{ $self->{"matrixItems"} };

	return @items;
}

sub GetItemByOriName {
	my $self    = shift;
	my $oriName = shift;

	my $item = first { $_->GetLayerName() eq $oriName } @{ $self->{"matrixItems"} };

	return $item;
}


sub BuildCopperLayerName {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $name = "";

	$name .= "outer" if ($outerCore);
	$name .= "plg"   if ($plugging);
	$name .= $copperName;

	return $name;
}


sub __ParseCopperLayerName {
	my $self        = shift;
	my $copperLName = shift;

	my %lInfo = ();
 
	$lInfo{"nameCopper"} = ( $copperLName =~ /([csv]\d*)/ )[0];
	$lInfo{"outerCore"}  = $copperLName =~ /outer([csv]\d*)/ ? 1 : 0;
	$lInfo{"plugging"}   = $copperLName =~ /plg([csv]\d*)/ ? 1 : 0;

	return %lInfo;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

