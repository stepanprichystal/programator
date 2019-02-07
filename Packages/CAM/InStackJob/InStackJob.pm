
#-------------------------------------------------------------------------------------------#
# Description: Parser InStack xml job
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::InStackJob::InStackJob;

#3th party library
use strict;
use warnings;

#local library
use XML::LibXML qw(:threads_shared);
use aliased 'Packages::CAM::InStackJob::Constraint';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"units"} = "mm";    # xml is in INCH

	$self->{"constraints"} = [];    # InStack job impedance constraints
	
	$self->{"layerCnt"} = 0;

	$self->__Init();

	return $self;
}

sub GetConstraint {
	my $self = shift;
	my $id   = shift;

	return ( grep { $_->GetId() == $id } $self->GetConstraints() )[0];

}

sub GetConstraints {
	my $self = shift;

	return @{ $self->{"constraints"} };
}

 

sub __Init {
	my $self = shift;

	my $xmlPath = EnumsPaths->Jobs_COUPONS . $self->{"jobId"} . ".xml";

	die "Xml file ($xmlPath) doesn't exist" unless ( -e $xmlPath );

	$self->{"dom"} = XML::LibXML->load_xml( location => $xmlPath );
	
	my @sigL = $self->{"dom"}->findnodes('/document/interfacelist/JOB/COPPER_LAYERS/COPPER_LAYER');
	$self->{"layerCnt"} = scalar(@sigL );
	
	$self->{"constraints"} = $self->__ParseConstraints();
}

sub __ParseConstraints {
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

		my $c = Constraint->new( $self->{"layerCnt"}, $self->{"units"}, $constraint->{"STACKUP_ORDERING_INDEX"}, $tInStack, $mInStack, $constraint );

		push( @constraints, $c );

	}

	return \@constraints;
}


sub __GetInCAMLayer {
	my $self     = shift;
	my $lName    = shift;
	my $layerCnt = shift;
	
	return undef if( $lName =~ /no copper layer/i);

	die "Wrong InStack stackup layer name" if ( $lName !~ /l\d+/i  );

	my $lInCAM;

	# load copper layers
	my ($lNum) = $lName =~ /l(\d+)/i;

	if ( $lNum == 1 ) {
		$lInCAM = "c";
	}
	elsif ( $lNum == $layerCnt ) {

		$lInCAM = "s";
	}
	else {

		$lInCAM = "v" . $lNum;
	}

	return $lInCAM;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

