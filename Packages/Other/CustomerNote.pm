
#-------------------------------------------------------------------------------------------#
# Description: Class mapp values from db for customer. Some customers has extra request like
# add profile to paste files, no add info about customer, etc..
# Important: If some customer attribut value is null or not set, it means, customer has no special request
# for this option! So null or "" doesnt mean "no", but not defined
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::CustomerNote;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $customerId = shift;

	$self->{"notes"} = TpvMethods->GetCustomerInfo($customerId);

	return $self;
}

# Return if exist customer record in db
sub Exist {
	my $self = shift;

	if ( $self->{"notes"} ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub NoInfoToPdf {
	my $self = shift;

	# default value if note doesnt exist
	if ( !$self->Exist() || !defined $self->{"notes"}->{"NoTpvInfoPdf"} ) {
		return 0;
	}

	if ( $self->{"notes"}->{"NoTpvInfoPdf"} ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub ExportPaste {
	my $self = shift;

	# default value if customer is not in db
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"ExportPaste"};

}

sub ProfileToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"ProfileToPaste"};
}

sub SingleProfileToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"SingleProfileToPaste"};

}

sub FiducialToPaste {
	my $self = shift;

	# default value if note doesnt exist
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"FiducialsToPaste"};
}

sub ExportPdfControl {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"ExportPdfControl"};

}

sub ExportDataControl {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"ExportDataControl"};

}

sub ScoreCoreThick {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"ScoreCoreThick"};

}

sub RequiredSchema {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"RequiredSchema"};
}

# type of plated holes vrtane/vysledne/undef
sub PlatedHolesType {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	my $t = undef;

	if ( $self->{"notes"}->{"PlatedHolesType"} eq "f" ) {
		$t = EnumsDrill->DTM_VYSLEDNE;

	}
	elsif ( $self->{"notes"}->{"PlatedHolesType"} eq "d" ) {
		$t = EnumsDrill->DTM_VRTANE;
	}
	return $t;
}

# Minimal dimensions of customer panel
# Return two dimension (panel side "a" and "b")
sub MinCustPanelDim {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	my $a = $self->{"notes"}->{"MinCustPnlDim1"};
	my $b = $self->{"notes"}->{"MinCustPnlDim2"} // $a;
	
	 
	return ($a, $b); 
}

# Minimal dimensions of customer panel
# Return two dimension (panel side "a" and "b")
sub MaxCustPanelDim {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	my $a = $self->{"notes"}->{"MaxCustPnlDim1"};
	my $b = $self->{"notes"}->{"MaxCustPnlDim2"} // $a;
	
	 
	return ($a, $b); 
}

# Indicate if customer require datacode on PCB
sub InsertDataCode {
	my $self = shift;

	# default value if customer is not in db
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"InsertDataCode"};

}

# Indicate if customer require ULLogo on PCB
sub InsertULLogo {
	my $self = shift;

	# default value if customer is not in db
	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"InsertULLogo"};

}


# ======== Stencil notes ============

sub HoleDistX {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"HoleDistX"};
}

sub HoleDistY {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"HoleDistY"};
}

sub OuterHoleDist {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"OuterHoleDist"};
}

sub CenterByData {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"CenterByData"};
}

sub MinHoleDataDist {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"MinHoleDataDist"};
}

sub NoHalfHoles {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"NoHalfHoles"};
}

sub NoFiducial {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"NoFiducial"};
}

sub SizeX {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"SizeX"};
}

sub SizeY {
	my $self = shift;

	if ( !$self->Exist() ) {
		return undef;
	}

	return $self->{"notes"}->{"SizeY"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

