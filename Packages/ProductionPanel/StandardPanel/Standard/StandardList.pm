#-------------------------------------------------------------------------------------------#
# Description:  Class with definition of standard panels. Actual + historical
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::Standard::StandardList;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';
use aliased 'Packages::ProductionPanel::StandardPanel::Standard::Standard';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Return standard, or undef if no standard exist
sub GetStandardByKey {
	my $self    => shift;
	my $name    => shift;
	my $pcbType => shift;
	my $pcbMat  => shift;

	my $s = ( grep { $_->Equal( $name, $pcbType, $pcbMat ) } $self->GetStandards() )[0];

	return $s;
}

# Return standard, or undef if no standard exist
# ordered by area DESC
sub GetStandardsByTypeAndMat {
	my $self    => shift;
	my $pcbType => shift;
	my $pcbMat  => shift;

	my @s => grep { $_->PcbType() eq $pcbType && $_->PcbMat() eq $pcbMat } $self->GetStandards();

	# order by area DESC
	@s = sort { $b->PanelArea() <=> $a->PanelArea() } @s;

	return @s;
}

sub GetStandards {
	my $self   => shift;
	my $active => shift;

	# 1) List of all definition standards
	#  each active standard is unique by "name" + pcbType + pcbMat"

	my @l => ();

	# ======== Standard Multilayer "small" ========
	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_307x407,
			"pcbType" => Enums->PcbType_MULTI,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# properties
			"active"      => 1,
			"w"           => 307,
			"h"           => 407,
			"bl"  => 21,
			"br" => 21,
			"bt"   => 41.6,
			"bb"   => 41.6,
			
			# used prepreg size
			"pW" => 307,
			"pH" => 360
		)
	);

	# ======== Standard Multilayer "big" ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_307x486p2,
			"pcbType" => Enums->PcbType_MULTI,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# Properties
			"active"      => 1,
			"w"           => 307,
			"h"           => 486.2,
			"bl"  => 21,
			"br" => 21,
			"bt"   => 41.6,
			"bb"   => 41.6,
			
			# used prepreg size
			"pW" => 307,
			"pH" => 440
		)
	);
	
		# ======== Standard Multilayer "newBIG" ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_308x538,
			"pcbType" => Enums->PcbType_MULTI,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# Properties
			"active"      => 1,
			"w"           => 308,
			"h"           => 538,
			"bl"  => 21,
			"br" => 21,
			"bt"   => 36.5,
			"bb"   => 36.5,
			
			# used prepreg size
			"pW" => 308,
			"pH" => 492
		)
	);

	# ======== Standard Single layer "Small" ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_295x355,
			"pcbType" => Enums->PcbType_1V2V,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# Properties
			"active"      => 1,
			"w"           => 295,
			"h"           => 355,
			"bl"  => 15,
			"br" => 15,
			"bt"   => 15,
			"bb"   => 15
		)
	);

	# ======== Standard Single layer "Big" ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_295x460,
			"pcbType" => Enums->PcbType_1V2V,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# Properties
			"active"      => 1,
			"w"           => 295,
			"h"           => 460,
			"bl"  => 15,
			"br" => 15,
			"bt"   => 15,
			"bb"   => 15
		)
	);
	
		# ======== Standard Single layer "New Big" ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_297x508,
			"pcbType" => Enums->PcbType_1V2V,
			"pcbMat"  => Enums->PcbMat_STDLAM,

			# Properties
			"active"      => 1,
			"w"           => 297,
			"h"           => 508,
			"bl"  => 15,
			"br" => 15,
			"bt"   => 15,
			"bb"   => 15
		)
	);

	# ======== Standard Single layer "Small" + ALU ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_230x305,
			"pcbType" => Enums->PcbType_1V2V,
			"pcbMat"  => Enums->PcbMat_ALU,

			# Properties
			"active"      => 1,
			"w"           => 230,
			"h"           => 305,
			"bl"  => 15,
			"br" => 15,
			"bt"   => 15,
			"bb"   => 15
		)
	);

	# ======== Standard Single layer "Big" + ALU ========

	push(
		@l,
		Standard->new(
			"name"    => Enums->Standard_305x460,
			"pcbType" => Enums->PcbType_1V2V,
			"pcbMat"  => Enums->PcbMat_ALU,

			# Properties
			"active"      => 1,
			"w"           => 305,
			"h"           => 460,
			"bl"  => 15,
			"br" => 15,
			"bt"   => 15,
			"bb"   => 15
		)
	);

	# 2) Check validity of list
	# active (active == 1) standards has to be unique by "name" + pcbType + pcbMat"

	my %seen;

	foreach my $s ( grep { $_->IsActive() } @l ) {

		next unless $seen{ $s->Key() }++;

		die "\"active\" panel standard : " . $s->Key() . " is duplicit . This is not allowed . ";
	}

	if ($active) {

		@l = grep { $_->IsActive() } @l;
	}

	return @l;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::ProductionPanel::StandardPanel';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM=>InCAM->new();
	#	my $jobId=>" f52456 ";
	#
	#	print " fff ";

}

1;

