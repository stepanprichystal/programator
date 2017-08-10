#-------------------------------------------------------------------------------------------#
# Description:  Class with definition of standard panels. Actual + historical
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ProductionPanel::StandardPanel::StandardDef;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::ProductionPanel::StandardPanel::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

 
# Return standard, or undef if no standard exist
sub GetStandardByKey {
	my $self = shift;
	my $name = shift;
	my $pcbType = shift;
	my $pcbMat = shift;
	
	my $s = (grep { $_->{"name"} eq $name &&  $_->{"pcbType"} eq $pcbType &&  $_->{"pcbMat"} eq $pcbMat } $self->GetStandards())[0];
	
	return $s;
}

# Return standard, or undef if no standard exist
# ordered by area DESC
sub GetStandardsByTypeAndMat {
	my $self = shift;
	my $pcbType = shift;
	my $pcbMat = shift;
	
	my @s = grep { $_->{"pcbType"} eq $pcbType &&  $_->{"pcbMat"} eq $pcbMat } $self->GetStandards();
	
	# order by area DESC
	@s = sort{ sub { ($b->{"w"} * $b->{"h"}) <=> ($a->{"w"} * $a->{"h"})} }  @s;
	
	return @s;
}


sub GetStandards {
	my $self = shift;
	my $active = shift;

	# 1) List of all definition standards
	#  each active standard is unique by "name + pcbType + pcbMat"

	my @list = ();

	# ======== Standard Multilayer "small" ========

	my %inf = ();

	$inf{"name"}    = Enums->Standard_307x407;
	$inf{"pcbType"} = Enums->PcbType_MULTI;
	$inf{"pcbMat"}  = Enums->PcbMat_FR4;

	# Properties
	$inf{"active"}      = 1;
	$inf{'w'}           = 307;
	$inf{'h'}           = 407;
	$inf{'borderLeft'}  = 21;
	$inf{'borderRight'} = 21;
	$inf{'borderTop'}   = 41.6;
	$inf{'borderBot'}   = 41.6;
	$inf{'wArea'}       = $inf{'w'} - ( $inf{'borderLeft'} + $inf{'borderRight'} );
	$inf{'hArea'}       = $inf{'h'} - ( $inf{'borderTop'} + $inf{'borderBot'} );

	push( @list, \%inf );

	# ======== Standard Multilayer "big" ========

	%inf = ();

	$inf{"name"}    = Enums->Standard_307x486p2;
	$inf{"pcbType"} = Enums->PcbType_MULTI;
	$inf{"pcbMat"}  = Enums->PcbMat_FR4;

	# Properties
	$inf{"active"}      = 1;
	$inf{'w'}           = 307;
	$inf{'h'}           = 486.2;
	$inf{'borderLeft'}  = 21;
	$inf{'borderRight'} = 21;
	$inf{'borderTop'}   = 41.6;
	$inf{'borderBot'}   = 41.6;
	$inf{'wArea'}       = $inf{'w'} - ( $inf{'borderLeft'} + $inf{'borderRight'} );
	$inf{'hArea'}       = $inf{'h'} - ( $inf{'borderTop'} + $inf{'borderBot'} );

	push( @list, \%inf );

	# ======== Standard Single layer "Small" ========

	%inf = ();

	$inf{"name"}    = Enums->Standard_295x355;
	$inf{"pcbType"} = Enums->PcbType_1V2V;
	$inf{"pcbMat"}  = Enums->PcbMat_FR4;

	# Properties
	$inf{"active"}      = 1;
	$inf{'w'}           = 295;
	$inf{'h'}           = 355;
	$inf{'borderLeft'}  = 15;
	$inf{'borderRight'} = 15;
	$inf{'borderTop'}   = 15;
	$inf{'borderBot'}   = 15;
	$inf{'wArea'}       = $inf{'w'} - ( $inf{'borderLeft'} + $inf{'borderRight'} );
	$inf{'hArea'}       = $inf{'h'} - ( $inf{'borderTop'} + $inf{'borderBot'} );

	push( @list, \%inf );

	# ======== Standard Single layer "Big" ========

	%inf = ();

	$inf{"name"}    = Enums->Standard_295x460;
	$inf{"pcbType"} = Enums->PcbType_1V2V;
	$inf{"pcbMat"}  = Enums->PcbMat_FR4;

	# Properties
	$inf{"active"}      = 1;
	$inf{'w'}           = 295;
	$inf{'h'}           = 460;
	$inf{'borderLeft'}  = 15;
	$inf{'borderRight'} = 15;
	$inf{'borderTop'}   = 15;
	$inf{'borderBot'}   = 15;
	$inf{'wArea'}       = $inf{'w'} - ( $inf{'borderLeft'} + $inf{'borderRight'} );
	$inf{'hArea'}       = $inf{'h'} - ( $inf{'borderTop'} + $inf{'borderBot'} );

	push( @list, \%inf );

	# 2) Check validity of list
	# active (active == 1) standards has to be unique by "name + pcbType + pcbMat"

	my %seen;

	foreach my $s ( grep { $_->{"active"} } @list ) {

		my $key = join( "-", ( $s->{"name"}, $s->{"pcbType"}, $inf{"pcbMat"} ) );    # unique key for standards
		next unless $seen{$key}++;

		die "Active panel standard: $key is duplicit. This is not allowed.";
	}

	if($active){
		
		@list = grep { $_->{"active"}  } @list;
	}


	return @list;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::ProductionPanel::StandardPanel';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#	my $jobId = "f52456";
	#
	#	print "fff";

}

1;

