#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsIS';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Comments::CommMail::CommMail';
use aliased 'Programs::Comments::Comments';
use aliased 'Programs::Comments::CommMail::Enums' => 'MailEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Types of aproval
use constant APPROVAL_NO        => "No approval";
use constant APPROVAL_OFFERDONE => "Offer DONE";
use constant APPROVAL_OFFERPROC => "Offer PROCESSING";
use constant APPROVAL_JOBDONE   => "Job DONE";
use constant APPROVAL_JOBPROC   => "Job PROCESSING";

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;
	$self->{"defaultInfo"} = $defaultInfo;

	$self->{"commMail"} = CommMail->new( $self->{"defaultInfo"}->GetComments(), $self->{"inCAM"}, $self->{"jobId"} );

	# Load data

	$self->__SetLayout();

	# EVENTS
	$self->{'exportEmailEvt'} = Event->new();
	$self->{"switchAppEvt"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $approvalTypeTxt = Wx::StaticText->new( $self, -1, "Approval type", &Wx::wxDefaultPosition, [ 100, -1 ] );
	my @types = (APPROVAL_NO);
	if ( JobHelper->GetJobIsOffer( $self->{"jobId"} ) ) {
		push( @types, APPROVAL_OFFERDONE, APPROVAL_OFFERPROC );

	}
	else {
		push( @types, APPROVAL_JOBDONE, APPROVAL_JOBPROC );
	}

	my $approvalTypeCb = Wx::ComboBox->new( $self, -1, $types[0], &Wx::wxDefaultPosition, [ 140, -1 ], \@types, &Wx::wxCB_READONLY );

	#my $commViewerHL = my $btnSync = Wx::HyperlinkCtrl->new( $self, -1, "Comments viewer", "", &Wx::wxDefaultPosition, [ 100, 25 ] );

	my $statusLyt = $self->__SetLayoutStatus($self);
	my $emailLyt  = $self->__SetLayoutEmail($self);

	# SET EVENTS
	Wx::Event::EVT_COMBOBOX( $approvalTypeCb, -1, sub { $self->__OnApprovalTypeChange(@_) } );

	#Wx::Event::EVT_HYPERLINK( $commViewerHL, -1, sub { $self->__OnCommViewerHndl() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $approvalTypeTxt, 0, &Wx::wxEXPAND );
	$szRow1->Add( $approvalTypeCb,  0, &Wx::wxEXPAND );

	#$szRow1->Add( $commViewerHL,  0, &Wx::wxEXPAND );

	$szRow3->Add( $statusLyt, 40, &Wx::wxEXPAND );
	$szRow3->Add( $emailLyt,  60, &Wx::wxEXPAND );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 3 );
	$szMain->Add( 5,       5, 0,                          &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 3 );
	$szMain->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 3 );

	$self->SetSizer($szMain);

	# SAVE CONTROL REFERENCE
	$self->{"approvalTypeCb"} = $approvalTypeCb;

}

sub __SetLayoutStatus {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $title = "IS " . ( JobHelper->GetJobIsOffer( $self->{"jobId"} ) ? "offer" : "order" ) . ' status';
	my $statBox = Wx::StaticBox->new( $parent, -1, $title );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szAction = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $changeOrderStatusChb = Wx::CheckBox->new( $statBox, -1, "Change", &Wx::wxDefaultPosition, [ -1, -1 ] );

	my $orderStatusTxt = Wx::StaticText->new( $statBox, -1, "Status", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my @statuses = ( EnumsIS->CurStep_HOTOVOODSOUHLASIT, EnumsIS->CurStep_POSLANDOTAZ );
	my $orderStatusCb =
	  Wx::ComboBox->new( $statBox, -1, $statuses[0], &Wx::wxDefaultPosition, [ 70, -1 ], \@statuses, &Wx::wxCB_READONLY );

	# SComm EVENTS
	#Wx::Event::EVT_CHECKBOX( $changeOrderStatusChb, -1, sub { $self->__OnChangeOrderStatusHndl(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $changeOrderStatusChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $orderStatusTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $orderStatusCb,  70, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 6,       6, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"changeOrderStatusChb"} = $changeOrderStatusChb;
	$self->{"orderStatusCb"}        = $orderStatusCb;
	$self->{"statBoxStatus"}        = $statBox;

	return $szStatBox;
}

sub __SetLayoutEmail {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Approval email' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow5   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow6   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow7   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow8   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szAction = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $exportEmailChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $mailPreviewHL = my $btnSync = Wx::HyperlinkCtrl->new( $statBox, -1, "Mail preview", "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $emailActionTxt = Wx::StaticText->new( $statBox, -1, "Email action", &Wx::wxDefaultPosition, [ -1, -1 ] );

	my $emailActionSentRb = Wx::RadioButton->new( $statBox, -1, "Sent directly", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $emailActionOpenRb = Wx::RadioButton->new( $statBox, -1, "Open in MS Outlook", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $emailToAddressTxt = Wx::StaticText->new( $statBox, -1, "Adress To", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $emailToAddressCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	my $emailCCAddressTxt = Wx::StaticText->new( $statBox, -1, "Adress CC", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $emailCCAddressCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	my $emailSubjectTxt = Wx::StaticText->new( $statBox, -1, "Subject", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my @subject = ();

	if ( JobHelper->GetJobIsOffer( $self->{"jobId"} ) ) {
		push( @subject, MailEnums->Subject_OFFERFINIFHAPPROVAL, MailEnums->Subject_OFFERPROCESSAPPROVAL );
	}
	else {
		push( @subject, MailEnums->Subject_JOBFINIFHAPPROVAL, MailEnums->Subject_JOBPROCESSAPPROVAL );
	}

	my $emailSubjectCb =
	  Wx::ComboBox->new( $statBox, -1, $subject[0], &Wx::wxDefaultPosition, [ -1, -1 ], \@subject, &Wx::wxCB_READONLY );

	my $includeOfferInfTxt = Wx::StaticText->new( $statBox, -1, "Incl. offer data", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $includeOfferInfChb = Wx::CheckBox->new( $statBox, -1, "(basic specification ...)", &Wx::wxDefaultPosition, [ -1, -1 ] );

	$includeOfferInfChb->Disable();

	if ( !JobHelper->GetJobIsOffer( $self->{"jobId"} ) ) {
		$includeOfferInfTxt->Hide();
		$includeOfferInfChb->Hide();
	}

	my $includeOfferStckpTxt = Wx::StaticText->new( $statBox, -1, "Incl. offer stackup", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $includeOfferStckpChb = Wx::CheckBox->new( $statBox, -1, "(PDF stackup ...)", &Wx::wxDefaultPosition, [ -1, -1 ] );

	$includeOfferStckpChb->Disable();

	if ( !JobHelper->GetJobIsOffer( $self->{"jobId"} ) ) {
		$includeOfferStckpTxt->Hide();
		$includeOfferStckpChb->Hide();
	}

	my $clearCommentsTxt = Wx::StaticText->new( $statBox, -1, "Clear comments", &Wx::wxDefaultPosition, [ -1, -1 ] );
	my $clearCommentsChb = Wx::CheckBox->new( $statBox, -1, "(if mail was properly sent/opened)", &Wx::wxDefaultPosition, [ -1, -1 ] );

	# EVENTS

	Wx::Event::EVT_HYPERLINK( $mailPreviewHL, -1, sub { $self->__OnMailPreviewHndl() } );
	Wx::Event::EVT_CHECKBOX( $exportEmailChb, -1, sub { $self->{"exportEmailEvt"}->Do( $exportEmailChb->GetValue() ) } );
	
	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $exportEmailChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow1->Add( 5, 5, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow1->Add( $mailPreviewHL, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow2->Add( $emailActionTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow2->Add( $szAction,       70, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szAction->Add( $emailActionSentRb, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szAction->Add( $emailActionOpenRb, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow3->Add( $emailToAddressTxt,  30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow3->Add( $emailToAddressCtrl, 70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow4->Add( $emailCCAddressTxt,  30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow4->Add( $emailCCAddressCtrl, 70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow5->Add( $emailSubjectTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow5->Add( $emailSubjectCb,  70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow6->Add( $includeOfferInfTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow6->Add( $includeOfferInfChb, 70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow7->Add( $includeOfferStckpTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow7->Add( $includeOfferStckpChb, 70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow8->Add( $clearCommentsTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow8->Add( $clearCommentsChb, 70, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 6,       6, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow5, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow6, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow7, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow8, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"exportEmailChb"}       = $exportEmailChb;
	$self->{"emailActionSentRb"}    = $emailActionSentRb;
	$self->{"emailActionOpenRb"}    = $emailActionOpenRb;
	$self->{"emailToAddressCtrl"}   = $emailToAddressCtrl;
	$self->{"emailCCAddressCtrl"}   = $emailCCAddressCtrl;
	$self->{"emailSubjectCb"}       = $emailSubjectCb;
	$self->{"includeOfferInfChb"}   = $includeOfferInfChb;
	$self->{"includeOfferStckpChb"} = $includeOfferStckpChb;
	$self->{"clearCommentsChb"}     = $clearCommentsChb;
	$self->{"statBoxEmail"}         = $statBox;

	return $szStatBox;
}

# =====================================================================
# FORM HANDLERS
# =====================================================================

sub __OnApprovalTypeChange {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->DisableControls();

	if ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_NO ) {

		$self->{"changeOrderStatusChb"}->SetValue(0);

		# status
		$self->{"orderStatusCb"}->SetValue("");

		$self->{"exportEmailChb"}->SetValue(0);
		$self->{"exportEmailEvt"}->Do( $self->{"exportEmailChb"}->GetValue() ); # SetValue doesn't emmit event

		# adress To
		$self->{"emailToAddressCtrl"}->SetValue("");

		# adress CC
		$self->{"emailCCAddressCtrl"}->SetValue("");

		# subject
		$self->{"emailSubjectCb"}->SetValue("");

	}

	# Set status by approval type
	if ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_JOBDONE ) {

		# Set status
		$self->{"changeOrderStatusChb"}->SetValue(1);

		# status
		$self->{"orderStatusCb"}->SetValue( EnumsIS->CurStep_HOTOVOODSOUHLASIT );

	}
	elsif ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_JOBPROC ) {

		$self->{"changeOrderStatusChb"}->SetValue(1);

		# status
		$self->{"orderStatusCb"}->SetValue( EnumsIS->CurStep_POSLANDOTAZ );
	}

	# Set email by approval type
	if ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_JOBDONE ) {

		# export email
		$self->{"exportEmailChb"}->SetValue(1);
		$self->{"exportEmailEvt"}->Do( $self->{"exportEmailChb"}->GetValue() ); # SetValue doesn't emmit event

		# email action
		$self->{"emailActionSentRb"}->SetValue(1);

		# adress To
		$self->{"emailToAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATSALES );

		# adress CC
		$self->{"emailCCAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATCAM );

		# subject
		$self->{"emailSubjectCb"}->SetValue( MailEnums->Subject_JOBFINIFHAPPROVAL );

		# include offer data
		$self->{"includeOfferInfChb"}->SetValue(0);

		# include offer steckup
		$self->{"includeOfferStckpChb"}->SetValue(0);

		# clear comments
		$self->{"clearCommentsChb"}->SetValue(1);

	}
	elsif ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_JOBPROC ) {

		# export email
		$self->{"exportEmailChb"}->SetValue(1);
		$self->{"exportEmailEvt"}->Do( $self->{"exportEmailChb"}->GetValue() ); # SetValue doesn't emmit event

		# email action
		$self->{"emailActionOpenRb"}->SetValue(1);

		# adress To
		my $emailTo = "";
		my @orders  = $self->{"commMail"}->GetCurrOrderNumbers();
		if (@orders) {

			my %ordInf   = HegMethods->GetAllByOrderId( $orders[0] );
			my $contInfo = HegMethods->GetContactPersonInfo( $ordInf{"predano_komu"} );
			$emailTo = $contInfo->{"e_mail"};
		}

		$self->{"emailToAddressCtrl"}->SetValue($emailTo);

		# adress CC
		$self->{"emailCCAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATCAM . "; " . EnumsPaths->MAIL_GATSALES );

		# subject
		$self->{"emailSubjectCb"}->SetValue( MailEnums->Subject_JOBPROCESSAPPROVAL );

		# include offer data
		$self->{"includeOfferInfChb"}->SetValue(0);

		# include offer steckup
		$self->{"includeOfferStckpChb"}->SetValue(0);

		# clear comments
		$self->{"clearCommentsChb"}->SetValue(1);
	}
	elsif ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_OFFERDONE ) {

		# export email
		$self->{"exportEmailChb"}->SetValue(1);
		$self->{"exportEmailEvt"}->Do( $self->{"exportEmailChb"}->GetValue() ); # SetValue doesn't emmit event

		# email action
		$self->{"emailActionSentRb"}->SetValue(1);

		# adress To
		$self->{"emailToAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATSALES );

		# adress CC
		$self->{"emailCCAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATCAM );

		# subject
		$self->{"emailSubjectCb"}->SetValue( MailEnums->Subject_OFFERFINIFHAPPROVAL );

		# include offer data
		$self->{"includeOfferInfChb"}->SetValue(1);

		# include offer steckup
		$self->{"includeOfferStckpChb"}->SetValue(1);

		# clear comments
		$self->{"clearCommentsChb"}->SetValue(1);

	}
	elsif ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_OFFERPROC ) {

		# export email
		$self->{"exportEmailChb"}->SetValue(1);
		$self->{"exportEmailEvt"}->Do( $self->{"exportEmailChb"}->GetValue() ); # SetValue doesn't emmit event

		# email action
		$self->{"emailActionOpenRb"}->SetValue(1);

		# adress To
		my $emailTo = "";
		my @orders  = $self->{"commMail"}->GetCurrOrderNumbers();
		if (@orders) {

			my %ordInf   = HegMethods->GetAllByOrderId( $orders[0] );
			my $contInfo = HegMethods->GetContactPersonInfo( $ordInf{"predano_komu"} );
			$emailTo = $contInfo->{"e_mail"};
		}

		$self->{"emailToAddressCtrl"}->SetValue($emailTo);

		# adress CC
		$self->{"emailCCAddressCtrl"}->SetValue( EnumsPaths->MAIL_GATCAM . "; " . EnumsPaths->MAIL_GATSALES );

		# subject
		$self->{"emailSubjectCb"}->SetValue( MailEnums->Subject_OFFERPROCESSAPPROVAL );

		# include offer data
		$self->{"includeOfferInfChb"}->SetValue(0);

		# include offer steckup
		$self->{"includeOfferStckpChb"}->SetValue(0);

		# clear comments
		$self->{"clearCommentsChb"}->SetValue(1);
	}

	#	use constant APPROVAL_NO        => "No approval";
	#use constant APPROVAL_OFFERDONE => "Price offer done";
	#use constant APPROVAL_OFFERPROC => "Price offer processing";
	#use constant APPROVAL_JOBDONE   => "Job done";
	#use constant APPROVAL_JOBPROC   => "Job processing";
}

sub __OnMailPreviewHndl {
	my $self = shift;

	# Init comments
	my $c = $self->{"defaultInfo"}->GetComments();

	my %inf = %{ HegMethods->GetCustomerInfo( $self->{"jobId"} ) };
	my $lang = $inf{"zeme"} eq 25 ? "cz" : "en";

	my $mail = CommMail->new( $self->{"inCAM"}, $self->{"jobId"}, $c->GetLayout(),$lang, $self->GetIncludeOfferInf(), $self->GetIncludeOfferStckp() );

	unless ( $mail->Open( $self->GetEmailToAddress(), $self->GetEmailCCAddress(), $self->GetEmailSubject() ) ) {

		my $messMngr = MessageMngr->new( $self->{"jobId"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during creating mail preview"] );
	}

}

#sub __OnCommViewerHndl {
#	my $self = shift;
#	
#	my $appName = "Test";
#	
#	$self->{"switchAppEvt"}->Do($appName);
#
#}

# =====================================================================
# HANDLERS FOR ANOTHER GROUP EVENTS
# =====================================================================

sub OnOfferGrouAddSpecifToMail {
	my $self      = shift;
	my $addSpecif = shift;

	$self->{"includeOfferInfChb"}->SetValue($addSpecif);

}

sub OnOfferGrouAddStackupToMail {
	my $self       = shift;
	my $addStackup = shift;

	$self->{"includeOfferStckpChb"}->SetValue($addStackup);

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Enable/disable controls by approval type
	if ( $self->{"approvalTypeCb"}->GetValue() eq APPROVAL_NO ) {

		$self->{"statBoxStatus"}->Disable();
		$self->{"statBoxEmail"}->Disable();

	}
	else {
		$self->{"statBoxStatus"}->Enable();
		$self->{"statBoxEmail"}->Enable();
	}

	# Enable/disable controls by offer type
	if ( JobHelper->GetJobIsOffer( $self->{"jobId"} ) ) {

		# Do not change status when offer
		$self->{"statBoxStatus"}->Disable();

	}

}

# =====================================================================
# SComm/GComm CONTROLS VALUES
# =====================================================================

# Change status of order in CAM department

sub SetChangeOrderStatus {
	my $self  = shift;
	my $value = shift;

	$self->{"changeOrderStatusChb"}->SetValue($value);
}

sub GetChangeOrderStatus {
	my $self = shift;

	if ( $self->{"changeOrderStatusChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Value of new order status

sub SetOrderStatus {
	my $self  = shift;
	my $value = shift;
	$self->{"orderStatusCb"}->SetValue($value);
}

sub GetOrderStatus {
	my $self = shift;
	return $self->{"orderStatusCb"}->GetValue();
}

# Indicate if export email with comments

sub SetExportEmail {
	my $self  = shift;
	my $value = shift;
	$self->{"exportEmailChb"}->SetValue($value);
}

sub GetExportEmail {
	my $self = shift;

	if ( $self->{"exportEmailChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Action after create email: Open/Sent

sub SetEmailAction {
	my $self  = shift;
	my $value = shift;

	if ( $value eq MailEnums->EmailAction_SEND ) {

		$self->{"emailActionSentRb"}->SetValue(1);
	}
	elsif ( $value eq MailEnums->EmailAction_OPEN ) {

		$self->{"emailActionopenRb"}->SetValue(1);
	}
	else {
		die "Unable to set action value: $value";
	}

}

sub GetEmailAction {
	my $self = shift;

	my $value = "";

	if ( $self->{"emailActionSentRb"}->GetValue() == 1 ) {

		$value = MailEnums->EmailAction_SEND;

	}
	elsif ( $self->{"emailActionOpenRb"}->GetValue() == 1 ) {

		$value = MailEnums->EmailAction_OPEN;
	}
	else {

		die "Unable to get action value";
	}

	return $value;
}

# Email adresses
sub SetEmailToAddress {
	my $self  = shift;
	my $value = shift;

	my $adressTxt = join( ", ", @{$value} );

	$self->{"emailToAddressCtrl"}->SetValue($adressTxt);
}

sub GetEmailToAddress {
	my $self = shift;

	my $adressTxt = $self->{"emailToAddressCtrl"}->GetValue();

	$adressTxt =~ s/\s//g;

	return [ split( /[,;]/, $adressTxt ) ];
}

# Email copy adresses
sub SetEmailCCAddress {
	my $self      = shift;
	my $value     = shift;
	my $adressTxt = join( ", ", @{$value} );

	$self->{"emailCCAddressCtrl"}->SetValue($adressTxt);
}

sub GetEmailCCAddress {
	my $self = shift;

	my $adressTxt = $self->{"emailCCAddressCtrl"}->GetValue();

	$adressTxt =~ s/\s//g;

	return [ split( /[,;]/, $adressTxt ) ];
}

# Email subjects
sub SetEmailSubject {
	my $self  = shift;
	my $value = shift;
	$self->{"emailSubjectCb"}->SetValue($value);
}

sub GetEmailSubject {
	my $self = shift;

	return $self->{"emailSubjectCb"}->GetValue();
}

# Include offer inf
sub SetIncludeOfferInf {
	my $self  = shift;
	my $value = shift;

	$self->{"includeOfferInfChb"}->SetValue($value);
}

sub GetIncludeOfferInf {
	my $self = shift;

	if ( $self->{"includeOfferInfChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Include offer stackup
sub SetIncludeOfferStckp {
	my $self  = shift;
	my $value = shift;

	$self->{"includeOfferStckpChb"}->SetValue($value);
}

sub GetIncludeOfferStckp {
	my $self = shift;

	if ( $self->{"includeOfferStckpChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Clear comments
sub SetClearComments {
	my $self  = shift;
	my $value = shift;

	$self->{"clearCommentsChb"}->SetValue($value);
}

sub GetClearComments {
	my $self = shift;

	if ( $self->{"clearCommentsChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
