
#-------------------------------------------------------------------------------------------#
# Description: Contain all information about pcb stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Stackup;
use base('Packages::Stackup::StackupBase::StackupBase');

#3th party library
use strict;
use warnings;
use Cache::MemoryCache;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Packages::Stackup::StackupBase::StackupHelper';
use aliased 'Packages::Stackup::Stackup::StackupBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create new Stackup
# Before initialization new object, chceck cache
sub new {
	my $class = shift;
	my $self  = {};

	my $inCAM = shift;
	my $jobId = shift;    # pcb id

	my $cache = Cache::MemoryCache->new();

	my $key     = "stackup_" . $jobId;
	my $stackup = $cache->get($key);     #check cache

	#if doesnt exist in cache, do normal initialization
	if ( !defined $stackup ) {

		$self = $class->SUPER::new( $jobId, @_ );
		$cache->set( $key, $self, 200 );
	}
	else {
		$self = $stackup;
	}

	bless $self;

	# Properties

	$self->{"inCAM"} = $inCAM;

	# Is stackup progressive lamination
	$self->{"sequentialLam"} = 0;

	# Number of pressing
	$self->{"pressCount"} = 0;

	#info (hash) for each pressing, which layer are pressed (most top/bot layers)
	# type of item is <ProductPress>
	$self->{"productPress"} = {};

	# type of item is <ProductInput>
	$self->{"productInputs"} = [];

	# Structure contains IProduct reference to each copper layer
	# which depand on attributes: PLugging, Outer core, etc..
	$self->{"copperMatrix"} = [];

	my $builder = StackupBuilder->new( $inCAM, $jobId, $self );
	$builder->BuildStackupLamination();

	return $self;
}

# Return number of pressing
sub GetPressCount {
	my $self = shift;

	return $self->{"pressCount"};
}

# Return info about each pressing
# -  in hash structure where first press start with key 1
# -  or sorted list structure
sub GetPressProducts {
	my $self = shift;
	my $array = shift // 0;    # Retturn in sorted array by press order ASC

	if ($array) {

		my @arr = ();
		foreach my $k ( sort { $a <=> $b } keys %{ $self->{"productPress"} } ) {

			push( @arr, $self->{"productPress"}->{$k} );
		}

		return @arr;

	}
	else {
		return %{ $self->{"productPress"} };
	}

}

# Return info about each pressing
sub GetLastPress {
	my $self = shift;

	my $lastPress = $self->{"productPress"}->{ $self->{"pressCount"} };

	return $lastPress;
}

# Return info about each input products
sub GetInputProducts {
	my $self = shift;

	return @{ $self->{"productInputs"} };
}

# Return total thick of this stackup in µm
# Do not consider extra plating (drilled core, progress lamination)
sub GetFinalThick {
	my $self = shift;
	my $inclPlating = shift // 1;    # include plating on outer product layers

	my $thick = $self->GetLastPress()->GetThick($inclPlating);

	return $thick;
}

sub GetSequentialLam {
	my $self = shift;

	return $self->{"sequentialLam"};
}

sub GetSideByCuLayer {
	my $self = shift;

	die "Not implemented";

}

# Return final thickness of Input/Press product in µm by given copper name
sub GetThickByCuLayer {
	my $self        = shift;
	my $lName       = shift;
	my $outerCore   = shift;         # indicate if copper is located on the core and on the outer of press package in the same time
	my $plugging    = shift;         # indicate if layer contain plugging
	my $inclPlating = shift // 1;    # include plating on outer product layers

	# Check format of layer name
	die "Wrong signal layer name: $lName" if ( $lName !~ /^([cs])|(v\d+)$/ );

	my $product = $self->__GetProductByLayer( $lName, $outerCore, $plugging );

	my $thick = $product->GetThick($inclPlating);

	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __GetProductByLayer {
	my $self      = shift;
	my $lName     = shift;
	my $outerCore = shift;    # indicate if copper is located on the core and on the outer of press package in the same time
	my $plugging  = shift;    # indicate if layer contain plugging

	# Check format of layer name
	die "Wrong signal layer name: $lName" if ( $lName !~ /^([cs])|(v\d+)$/ );

	my $product = first {
		$_->{"name"} eq $lName
		  && $_->{"outerCore"} == $outerCore
		  && $_->{"plugging"} == $plugging
	}
	@{ $self->{"copperMatrix"} };

	die "Product was not found by copper layer: $lName (outerCore=$outerCore; plugging=$plugging)" if ( !defined $product );

	return $product;
}

sub __GetAllProducts {
	my $self        = shift;
	my $currProduct = shift;
	my $pList       = shift;

	my @childProducts = $currProduct->GetLayers( Enums->ProductL_PRODUCT );
	foreach my $childP ( map { $_->GetData() } @childProducts ) {

		$self->__GetAllProducts( $childP, $pList );
	}

	push( @{$pList}, $currProduct );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::Stackup::Stackup';
	use aliased 'Packages::Stackup::Stackup::StackupTester';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152456";
	my $stackup = Stackup->new( $inCAM, $jobId );

	#my $thick = $stackup->GetFinalThick();

	StackupTester->PrintStackupTree($stackup);

	die;

}
1;

