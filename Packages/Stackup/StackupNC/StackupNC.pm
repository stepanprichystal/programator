
#-------------------------------------------------------------------------------------------#
# Description: Class, which provides information about NC operation on each press, each cores
# Source of stackup information is Stackup.pm class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNC;
use base('Packages::Stackup::Stackup::Stackup');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::Stackup::StackupNC::StackupNCProduct';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new( $inCAM, $jobId );
	bless $self;

	# SET PROPERTIES

	$self->{"inCAM"} = $inCAM;

	$self->{"NCPresses"} = [];
	$self->{"NCInputs"}  = [];
	$self->{"NCCores"}   = [];

	my @pltLayers = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @npltLayers = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @NCLayers = ( @pltLayers, @npltLayers );

	#get info which layer drilling/millin starts from/ end in
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	$self->{"ncLayers"} = \@NCLayers;

	# INIT STACKUP

	$self->__InitPress();
	$self->__InitInputs();
	$self->__InitCores();

	return $self;
}

# Return all StackupNCproduct based on StackupProduct::StackupPress
sub GetNCPressProducts {
	my $self = shift;

	return @{ $self->{"NCPresses"} };
}

# Return all StackupNCproduct  based on StackupProduct::StackupInput (include parent and child StackupInput)
sub GetNCInputProducts {
	my $self = shift;

	return @{ $self->{"NCInputs"} };
}

# Return all StackupNCproduct based on StackupProduct::StackupInput (NOT include parent StackupInput)
sub GetNCCoreProducts {
	my $self = shift;

	return @{ $self->{"NCCores"} };
}

# Return specific StackupNCproduct which have source Press product
sub GetNCPressProduct {
	my $self       = shift;
	my $pressOrder = shift;

	my @press = @{ $self->{"NCPresses"} };
	my $idx = ( grep { $press[$_]->GetIProduct()->GetPressOrder() eq $pressOrder } 0 .. $#press )[0];

	if ( defined $idx ) {

		return $press[$idx];
	}
}

# Return specific StackupNCproduct which have source Input product product
sub GetNCCoreProduct {
	my $self    = shift;
	my $coreNum = shift;

	my $core = first { $_->GetIProduct()->GetCoreNumber() eq $coreNum } @{ $self->{"NCCores"} };

	return $core;
}

sub GetNCProductByLayer {
	my $self      = shift;
	my $lName     = shift;
	my $outerCore = shift;    # indicate if copper is located on the core and on the outer of press package in the same time
	my $plugging  = shift;    # indicate if layer contain plugging

	# Get IProduct
	my $p = $self->SUPER::GetProductByLayer( $lName, $outerCore, $plugging );
	my @arr = ( @{ $self->{"NCPresses"} }, @{ $self->{"NCInputs"} } );
	my $NCProduct =
	  first { $_->GetIProduct()->GetId() eq $p->GetId() && $_->GetIProduct()->GetProductType() eq $p->GetProductType() } @arr;

	return $NCProduct;
}

sub GetCoreCnt {
	my $self = shift;

	return scalar( @{ $self->{"NCCores"} } );
}

sub __InitPress {
	my $self = shift;

	foreach my $p ( $self->SUPER::GetPressProducts(1) ) {

		my $pressNC = StackupNCProduct->new( $self->{"inCAM"}, $self->{"jobId"}, $p, $self->{"ncLayers"} );

		push( @{ $self->{"NCPresses"} }, $pressNC );
	}
}

sub __InitCores {
	my $self = shift;

	foreach my $p ( map { $_->GetChildProducts() } $self->SUPER::GetInputProducts() ) {

		my $coreNC = StackupNCProduct->new( $self->{"inCAM"}, $self->{"jobId"}, $p->GetData(), $self->{"ncLayers"} );

		push( @{ $self->{"NCCores"} }, $coreNC );
	}
}

sub __InitInputs {
	my $self = shift;

	my @input = $self->SUPER::GetInputProducts();
	my @inputChild = map { $_->GetData() } map { $_->GetChildProducts() } @input;

	foreach my $p ( @input, @inputChild ) {

		my $inputNC = StackupNCProduct->new( $self->{"inCAM"}, $self->{"jobId"}, $p, $self->{"ncLayers"} );

		push( @{ $self->{"NCInputs"} }, $inputNC );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupNC::StackupNC';
	use aliased 'Packages::Stackup::Stackup::Stackup';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d244516";
	my $stackupNC = StackupNC->new( $inCAM, $jobId );

	my $press = $stackupNC->GetNCPressProduct(2);

	my @layers  = $press->GetNCLayers("top");
	my @layers2 = $press->GetNCLayers("bot");

	die;

}

1;

