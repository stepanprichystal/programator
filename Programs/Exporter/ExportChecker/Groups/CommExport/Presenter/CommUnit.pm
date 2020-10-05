
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommExportData';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitFormEvt';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_COMM;

	my $checkData   = CommCheckData->new();
	my $prepareData = CommPrepareData->new();
	my $exportData  = CommExportData->new();

	$self->{"dataMngr"} = GroupDataMngr->new( $self->{"jobId"}, $prepareData, $checkData, $exportData );

	return $self;    # Return the reference to the hash.
}

#posloupnost volani metod
#1) new()
#2) InitForm()
#3) BuildGUI()
#4) InitDataMngr()
#5) RefreshGUI()
#==> export
#6) CheckBeforeExport()
#7) GetGroupData()

sub InitForm {
	my $self         = shift;
	my $groupWrapper = shift;
	my $inCAM        = shift;

	$self->{"groupWrapper"} = $groupWrapper;

	my $parent = $groupWrapper->GetParentForGroup();
	$self->{"form"} = CommUnitForm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"dataMngr"}->GetDefaultInfo() );

	# init base class with event class
	$self->{"eventClass"} = CommUnitFormEvt->new( $self->{"form"} );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetChangeOrderStatus( $groupData->GetChangeOrderStatus() );
	$self->{"form"}->SetOrderStatus( $groupData->GetOrderStatus() );
	$self->{"form"}->SetExportEmail( $groupData->GetExportEmail() );
	$self->{"form"}->SetEmailAction( $groupData->GetEmailAction() );
	$self->{"form"}->SetEmailToAddress( $groupData->GetEmailToAddress() );
	$self->{"form"}->SetEmailCCAddress( $groupData->GetEmailCCAddress() );
	$self->{"form"}->SetEmailSubject( $groupData->GetEmailSubject() );
	$self->{"form"}->SetEmailIntro( $groupData->GetEmailIntro() );
	$self->{"form"}->SetIncludeOfferInf( $groupData->GetIncludeOfferInf() );
	$self->{"form"}->SetIncludeOfferStckp( $groupData->GetIncludeOfferStckp() );
	$self->{"form"}->SetClearComments( $groupData->GetClearComments() );

}

# Update groupd data with values from GUI
sub UpdateGroupData {
	my $self = shift;

	my $frm = $self->{"form"};

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		my $groupData = $self->{"dataMngr"}->GetGroupData();

		$groupData->SetChangeOrderStatus( $frm->GetChangeOrderStatus() );
		$groupData->SetOrderStatus( $frm->GetOrderStatus() );
		$groupData->SetExportEmail( $frm->GetExportEmail() );
		$groupData->SetEmailAction( $frm->GetEmailAction() );
		$groupData->SetEmailToAddress( $frm->GetEmailToAddress() );
		$groupData->SetEmailCCAddress( $frm->GetEmailCCAddress() );
		$groupData->SetEmailSubject( $frm->GetEmailSubject() );
		$groupData->SetEmailIntro( $frm->GetEmailIntro() );
		$groupData->SetIncludeOfferInf( $frm->GetIncludeOfferInf() );
		$groupData->SetIncludeOfferStckp( $frm->GetIncludeOfferStckp() );
		$groupData->SetClearComments( $frm->GetClearComments() );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

