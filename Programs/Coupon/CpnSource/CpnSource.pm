
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSource::CpnSource;

#3th party library
use strict;
use warnings;

#local library
use XML::LibXML qw(:threads_shared);
use aliased 'Programs::Coupon::CpnSource::Constraint';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"xmlPath"} = shift;

	$self->{"units"} = "mm";    # xml is in INCH
	
	$self->__Init();

	return $self;
}

sub GetConstraint {
	my $self = shift;
	my $id   = shift;

	return (grep { $_->GetId() == $id } $self->GetConstraints())[0];


}

sub GetConstraints {
	my $self = shift;

 
	my @constraints = ();
	
	foreach my $constraint ( $self->{"dom"}->findnodes('/document/interfacelist/JOB/STACKUP/STACKUP/IMPEDANCE_CONSTRAINTS/IMPEDANCE_CONSTRAINT') ) {

		#se_coated_lower_embedded
		#diff_coated_lower_embedded
		#coplanar_se_coated_microstrip
		#coplanar_diff_coated_microstrip
		my ( $tInStack, $mInStack ) = undef;

		my $n = $constraint->{"MODEL_NAME"};

		if ( $constraint->{"MODEL_NAME"} =~ /^coplanar/ ) {

			( $tInStack, $mInStack ) = $constraint->{"MODEL_NAME"} =~ /^(coplanar_[a-z]*)_(.*)/;
		}
		else {

			( $tInStack, $mInStack ) = $constraint->{"MODEL_NAME"} =~ /^([a-z]*)_(.*)/;
		}



		my $c = Constraint->new(  $self->{"units"},  $constraint->{"STACKUP_ORDERING_INDEX"}, $tInStack, $mInStack, $constraint );

		push( @constraints, $c );

	}

	return @constraints;
}

sub GetCopperLayers {
	my $self = shift;

	my @layers = $self->{"dom"}->findnodes('/document/interfacelist/JOB/COPPER_LAYERS/COPPER_LAYER');

	return @layers;

}


#sub GetInCAMLayer{
#	my $self = shift;
#	my $l = shift;	
#	
#	my %t = $self->GetLTranslateTable();
#	
#	return $t{$l};
#	
#}
#
#sub GetLTranslateTable {
#	my $self = shift;
#
#	my @copperLayers = $self->GetCopperLayers();
#
#	my %t;
#	@t{ map { $_->{"NAME"} } @copperLayers } = ();
#	
#	foreach my $copperL (@copperLayers) {
#
#		# load copper layers
#		my $l =   $copperL ;
#
#		if ( $l->{"LAYER_INDEX"} == 1 ) {
#			$t{$l->{"NAME"}} = "c";
#		}
#		elsif ( $l->{"LAYER_INDEX"} == scalar(@copperLayers) ) {
#
#			$t{$l->{"NAME"}} = "s";
#
#		}
#		else {
#
#			$t{$l->{"NAME"}} = "v" . $l->{"LAYER_INDEX"};
#		}
#	}
#	
#	return %t;
#
#}


sub __Init{
	my $self = shift;
	
	die "Xml file doesn't exist" unless(-e $self->{"xmlPath"});

	$self->{"dom"} = XML::LibXML->load_xml( location => $self->{"xmlPath"} );
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

