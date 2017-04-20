
#-------------------------------------------------------------------------------------------#
# Description: Base class for units. Provide necessary methods, which allow specific unit 
# to be tasked by AbstractQueue program
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Unit::UnitBase;

use Class::Interface;
&implements('Managers::AbstractQueue::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Managers::AbstractQueue::AbstractQueue::Forms::Group::GroupWrapperForm';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::AbstractQueue::Groups::GroupData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	# uique key within all units
	$self->{"unitId"} = shift;
	$self->{"jobId"} = shift;
	$self->{"unitTitle"} = shift;
	
  
	$self->{"form"}   = undef;    # reference on GroupWrapperForm object

	 

	# store, where data for units are saved
	# keep also state of group and task error information
	$self->{"groupData"} = GroupData->new(); 

	return $self;
}

# Init GroupWrapperForm for this unit
sub InitForm {
	my $self   = shift;
	my $parent = shift;

	#my $inCAM        = shift;

	my $itemResultMngr  = $self->GetGroupItemResultMngr();
	my $groupResultMngr = $self->GetGroupResultMngr();

	#$self->{"form"} = GroupWrapperForm->new( $parent);
	$self->{"form"} = GroupWrapperForm->new( $parent, $self->{"jobId"}, $itemResultMngr, $groupResultMngr );

	$self->{"form"}->Init( $self->{"unitTitle"} );

}

# ===================================================================
# Method requested by interface IUnit
# ===================================================================

sub ProcessItemResult {
	my $self       = shift;
	my $id         = shift;
	my $result     = shift;
	my $group      = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;

	my $item = $self->{"groupData"}->{"itemsMngr"}->CreateTaskItem( $id, $result, $group, $errorsStr, $warningStr );

	$self->{"form"}->AddItem($item);

	# Update group status form GUI

	$self->{"form"}->SetErrorCnt( $self->GetErrorsCnt() );
	$self->{"form"}->SetWarningCnt( $self->GetWarningsCnt() );

}

sub ProcessGroupResult {
	my $self       = shift;
	my $result     = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;

	my $id = $self->{"unitId"};

	# Update model
	my $item = $self->{"groupData"}->{"groupMngr"}->CreateTaskItem( $id, $result, undef, $errorsStr, $warningStr );

	# Update group status form GUI
	$self->{"form"}->SetErrorCnt( $self->GetErrorsCnt() );
	$self->{"form"}->SetWarningCnt( $self->GetWarningsCnt() );

}

sub Result {
	my $self = shift;

	my $itemMngr  = $self->{"groupData"}->{"itemsMngr"};
	my $groupMngr = $self->{"groupData"}->{"groupMngr"};

	# create result value
	my $result = EnumsGeneral->ResultType_OK;

	if ( !$itemMngr->Succes() || !$groupMngr->Succes() ) {
		$result = EnumsGeneral->ResultType_FAIL;
	}

	return $result;
}

sub GetErrorsCnt {
	my $self = shift;

	my $itemsErrorCnt = $self->{"groupData"}->{"itemsMngr"}->GetErrorsCnt();
	my $groupErrorCnt = $self->{"groupData"}->{"groupMngr"}->GetErrorsCnt();
	
	print STDERR "\n\n\nitems cnt:". $itemsErrorCnt." ==== Group cnt".$groupErrorCnt."\n\n\n";
	
	return $itemsErrorCnt + $groupErrorCnt;
}

sub GetWarningsCnt {
	my $self = shift;

	my $itemsWarningCnt = $self->{"groupData"}->{"itemsMngr"}->GetWarningsCnt();
	my $groupWarningCnt = $self->{"groupData"}->{"groupMngr"}->GetWarningsCnt();
	return $itemsWarningCnt + $groupWarningCnt;
}

sub GetProgress {
	my $self = shift;
	return $self->{"groupData"}->GetProgress();
}

sub GetGroupItemResultMngr {
	my $self = shift;

	return $self->{"groupData"}->{"itemsMngr"};
}

sub GetGroupResultMngr {
	my $self = shift;

	return $self->{"groupData"}->{"groupMngr"};
}

sub GetTaskClass {
	my $self = shift;

	return $self->{"unitTaskClass"};
}

sub ProcessGroupStart {
	my $self = shift;

	# Update group status form GUI
	$self->{"form"}->SetStatus("Processing...");
}
sub ProcessGroupEnd {
	my $self = shift;

	# Update group status form GUI
	$self->{"form"}->SetResult( $self->Result() );

}

sub ProcessProgress {
	my $self  = shift;
	my $value = shift;
	$self->{"groupData"}->SetProgress($value);

}


sub ProcessTaskContinue {
	my $self  = shift;
	my $value = shift;
 
	my $itemsErrorCnt = $self->{"groupData"}->{"itemsMngr"}->Clear();
	my $groupErrorCnt = $self->{"groupData"}->{"groupMngr"}->Clear();
	
	$self->{"form"}->Clear();
	
	
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
