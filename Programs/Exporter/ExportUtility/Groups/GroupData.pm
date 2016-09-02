
#-------------------------------------------------------------------------------------------#
# Description: Class contain state properties, used as model for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::GroupData;

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Programs::Exporter::ExportUtility::Groups::GroupResultMngr';
use aliased 'Programs::Exporter::ExportUtility::Enums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	 
	$self->{"itemsMngr"} = GroupResultMngr->new();
	
	# state of whole group. Value is enum GroupState_xx
	$self->{"state"} = Enums->GroupState_WAITING;
	
	$self->{"progress"} = 0;

	return $self;
}

 
 sub SetProgress {
	my $self  = shift;
	$self->{"progress"} = shift;
}

sub GetProgress {
	my $self  = shift;
	return $self->{"progress"};
}
 
sub SetGroupState {
	my $self  = shift;
	$self->{"state"} = shift;
}

sub GetGroupState {
	my $self  = shift;
	return $self->{"state"};
}


sub GetAllItems {
	my $self  = shift;
	
	return $self->{"itemsMngr"}->GetAllItems();
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

