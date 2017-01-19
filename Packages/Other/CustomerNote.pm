
#-------------------------------------------------------------------------------------------#
# Description: Class mapp values from db for customer. Some customers has extra request like
# add profile to paste files, no add info about customer, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::CustomerNote;

#3th party library
use strict;
use warnings;


#local library
use aliased 'Connectors::TpvConnector::TpvMethods';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $customerId = shift;
		
	$self->{"notes"} = TpvMethods->GetCustomerInfo( $customerId );
 
	return $self;
}

sub Exist {
	my $self = shift;

	if ($self->{"notes"} ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub NoInfoToPdf {
	my $self = shift;
	
	# default value if note doesnt exist
	if(!$self->Exist() || !defined $self->{"notes"}->{"NoTpvInfoPdf"}){
		return 0;
	}

	if($self->{"notes"}->{"NoTpvInfoPdf"}){
		return 1;
	}else{
		return 0;
	}
}

sub PasteRequested {
	my $self = shift;

	# default value if note doesnt exist
	if(!$self->Exist() || !defined $self->{"notes"}->{"PasteRequested"}){
		return 0;
	}
	
	if($self->{"notes"}->{"PasteRequested"}){
		return 1;
	}else{
		return 0;
	}
}
 
sub ProfileToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if(!$self->Exist()){
		return undef;
	}
	
	return $self->{"notes"}->{"ProfileToPaste"};
}

sub SingleProfileToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if(!$self->Exist()){
		return undef;
	}
	
	return $self->{"notes"}->{"SingleProfileToPaste"};

}

sub FiducialToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if(!$self->Exist()){
		return undef;
	}
	
	return $self->{"notes"}->{"FiducialToPaste"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

