
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::UnitBase;

# Abstract class #

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupWrapperForm';
use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;
	#$self->{"title"} = shift;
	
	$self->{"unitId"} = undef;
	$self->{"form"} = undef;    #form which represent GUI of this group

	$self->{"unitExport"} = undef;

	$self->{"groupData"} = undef;

	return $self;
}

 

sub InitForm {
	my $self   = shift;
	my $parent = shift;

	#my $inCAM        = shift;

	my $itemResultMngr = $self->GetGroupItemResultMngr();
	my $groupResultMngr = $self->GetGroupResultMngr();
	  
	#$self->{"form"} = GroupWrapperForm->new( $parent);
	$self->{"form"} = GroupWrapperForm->new( $parent, $self->{"jobId"}, $itemResultMngr, $groupResultMngr);

	$self->{"form"}->Init( $self->{"unitId"} );

}

sub GetExportClass{
	my $self = shift;
	
	return $self->{"unitExport"};
}


sub ProcessItemResult {
	my $self       = shift;
	my $id         = shift;
	my $result     = shift;
	my $group      = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;

	my $item = $self->{"groupData"}->{"itemsMngr"}->CreateExportItem( $id, $result, $group, $errorsStr, $warningStr );
	
	$self->{"form"}->AddItem($item);
	
	# Update group status form GUI
	
	$self->{"form"}->SetErrorCnt($self->GetErrorsCnt());
	$self->{"form"}->SetWarningCnt($self->GetWarningsCnt());
	
	
}



sub ProcessGroupResult {
	my $self       = shift;
	my $result     = shift;
	my $errorsStr  = shift;
	my $warningStr = shift;
	
	my $id = $self->{"unitId"};

	# Update model
	my $item = $self->{"groupData"}->{"groupMngr"}->CreateExportItem( $id, $result, undef, $errorsStr, $warningStr );
	
	# Update group status form GUI
	$self->{"form"}->SetErrorCnt($self->GetErrorsCnt());
	$self->{"form"}->SetWarningCnt($self->GetWarningsCnt());
  
}



sub ProcessGroupStart {
	my $self       = shift;
	
	# Update group status form GUI	
 	$self->{"form"}->SetStatus("Export...");
}

sub ProcessGroupEnd {
	my $self       = shift;
 
 	# Update group status form GUI	
	$self->{"form"}->SetResult($self->Result());
 
}



sub ProcessProgress {
	my $self       = shift;
	my $value       = shift;
	$self->{"groupData"}->SetProgress($value);
	
}

sub GetProgress {
	my $self = shift;
	return $self->{"groupData"}->GetProgress();
}



sub GetGroupItemResultMngr {
	my $self  = shift;
	
	return $self->{"groupData"}->{"itemsMngr"};
}

sub GetGroupResultMngr {
	my $self  = shift;
	
	return $self->{"groupData"}->{"groupMngr"};
}


sub GetErrorsCnt{
	my $self  = shift;
	
	my $itemsErrorCnt = $self->{"groupData"}->{"itemsMngr"}->GetErrorsCnt();
	my $groupErrorCnt = $self->{"groupData"}->{"groupMngr"}->GetErrorsCnt();
 	return $itemsErrorCnt + $groupErrorCnt;
}

sub GetWarningsCnt{
	my $self  = shift;
	
	my $itemsWarningCnt = $self->{"groupData"}->{"itemsMngr"}->GetWarningsCnt();
	my $groupWarningCnt = $self->{"groupData"}->{"groupMngr"}->GetWarningsCnt();
 	return $itemsWarningCnt + $groupWarningCnt;
}

sub Result{
	my $self  = shift;
	
	my $itemMngr = $self->{"groupData"}->{"itemsMngr"};
	my $groupMngr = $self->{"groupData"}->{"groupMngr"};
	
	# create result value
	my $result = EnumsGeneral->ResultType_OK;
	
	if(!$itemMngr->Succes() || !$groupMngr->Succes()){
		$result = EnumsGeneral->ResultType_FAIL;	
	}
	
	return $result;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
