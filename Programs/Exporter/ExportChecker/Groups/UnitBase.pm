
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::UnitBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;
	$self->{"title"} = shift;

	$self->{"groupWrapper"} = undef;    #wrapper, which form is placed in
	$self->{"form"}         = undef;    #form which represent GUI of this group
	$self->{"active"}       = undef;    # tell if group will be visibel/active
	$self->{"dataMngr"}     = undef;    # manager, which is responsible for create, update group data

	return $self;
}

sub InitDataMngr {
	my $self       = shift;
	my $inCAM      = shift;
	my $storedData = shift;
	
	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	if ($storedData) {
		$self->{"dataMngr"}->SetStoredGroupData($storedData);
	}
	else {

		 $self->{"dataMngr"}->PrepareGroupData(); 
	}
}

# tohle presunout do base class
sub CheckBeforeExport {
	my $self       = shift;
	my $inCAM      = shift;
	my $resultMngr = shift;

	# Necessery set new incam library
	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	my $succes = $self->{"dataMngr"}->CheckGroupData();

	$$resultMngr = $self->{"dataMngr"}->{'resultMngr'};

	return $succes;
}

sub _RefreshWrapper {
	my $self  = shift;
	my $inCAM = shift;

	my $isAllowed = $self->{"dataMngr"}->IsGroupAllowed();

	if ($isAllowed) {
		$self->{"groupWrapper"}->SetState( Enums->GroupState_ACTIVEOFF );
	}
	else {
		$self->{"groupWrapper"}->SetState( Enums->GroupState_DISABLE );
	}

	#refresh wrapper of form based on "group state"
	$self->{"groupWrapper"}->Refresh();

}




sub GetExportData {
	my $self = shift;
	my $inCAM = shift;
	
	# Necessery set new incam library
	$self->{"dataMngr"}->{"inCAM"} = $inCAM;

	return $self->{"dataMngr"}->ExportGroupData();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
