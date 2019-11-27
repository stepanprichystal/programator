#-------------------------------------------------------------------------------------------#
# Description: Helper class, which is used by Stackup.pm class for testing and visualising stackup tree
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupTester;

#3th party library
use strict;
use warnings;
use Tree::Simple;
use Tree::Visualize;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#	my $tree = Tree::Simple->new("test")->addChildren( Tree::Simple->new("test-1")->addChildren( Tree::Simple->new("test-1-1") ),
#													   Tree::Simple->new("test-2"),
#													   Tree::Simple->new("test-3") );

sub PrintStackupTree {
	my $self    = shift;
	my $stackup = shift;

	my $last = $stackup->GetLastPress();

	my $infoChild = $self->__GetProductInfo($last);
	my $tree      = Tree::Simple->new($infoChild);
	$self->__BuildTree( $last, $tree );

	my $visualize = Tree::Visualize->new( $tree, 'ASCII', 'TopDown' );
	print $visualize->draw();

}

sub __BuildTree {
	my $self        = shift;
	my $currProduct = shift;
	my $tree        = shift;

	my @childProducts = $currProduct->GetLayers( Enums->ProductL_PRODUCT );

	foreach my $childP ( map { $_->GetData() } @childProducts ) {

		my $infoChild = $self->__GetProductInfo($childP);

		my $childTree = Tree::Simple->new($infoChild);
		$self->__BuildTree( $childP, $childTree );

		$tree->addChildren($childTree);
	}

}

sub __GetProductInfo {
	my $self    = shift;
	my $product = shift;

	my $t    = $product->GetProductType();
	my $tTxt = $t eq Enums->Product_INPUT ? "I" : "P";
	my $info = "" . $tTxt . $product->GetId()."; ";
	$info .= int( $product->GetThick(1) ) . "; ";
	$info .= "Cu:" . $product->GetTopCopperLayer() . "-" . $product->GetBotCopperLayer() . "; ";
	$info .= "Plt:" . $product->GetIsPlated() . "; ";
	$info .= "Plg:" . $product->GetPlugging() . "; ";
	$info .= "Out:";
	$info .= "top" if ( $product->GetOuterCoreTop() );
	 
	$info .= "bot" if ( $product->GetOuterCoreBot() );
	
	my $stackupLFirst = $product->GetProductOuterMatLayer("first");
	my $stackupLLast = $product->GetProductOuterMatLayer("last");
	
	
	$info .=  "; ".$stackupLFirst->GetData()->GetType(). " / ".$stackupLLast->GetData()->GetType();
	

	return $info;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print 1;
	#my $test = Connectors::HeliosConnector::HegMethods->GetMaterialType("F34140");

	#print $test;

}

1;
