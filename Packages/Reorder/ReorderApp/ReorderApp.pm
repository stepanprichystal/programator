
#-------------------------------------------------------------------------------------------#
# Description:  Reorder app which check and proces reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::ReorderApp;

#3th party library
use strict;
use warnings;
use Wx;

#local library
use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderAppFrm';
use aliased 'Packages::Reorder::CheckReorder::CheckReorder';
use aliased 'Packages::Reorder::ProcessReorder::ProcessReorder';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Reorder::ReorderApp::Enums';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Reorder::ReorderApp::ReorderPopup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"form"} = ReorderAppFrm->new( -1, "Reorder app - " . $self->{"jobId"} );

	$self->{"reorderPopup"} = ReorderPopup->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->__Init();
	$self->__DoChecks();
	$self->__Run();

	return $self;
}

sub __Init {
	my $self = shift;

	#set handlers for main app form
	$self->__SetHandlers();

	$self->{"reorderPopup"}->Init( $self->{"form"}  );

}

sub __Run {
	my $self = shift;
	$self->{"form"}->{"mainFrm"}->Show(1);
 
	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnErrIndicatorHandler {
	my $self = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	if ( scalar( @{ $self->{"manChanges"} } ) ) {

		my $str = "";

		foreach my $check ( @{ $self->{"manChanges"} } ) {

			$str .= $check->{"desc"} . "\n";

			if ( defined $check->{"detail"} ) {
				$str .= "Detail:" . $check->{"detail"} . "\n\n";
			}
			else {
				$str .= "\n";
			}

		}

		my @mess = ($str);

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
	}

}

sub __OnProcessReorderEvent {
	my $self = shift;
	my $type = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	# 1) Check if exist reorder with aktualni krok zpracovani-rucni
	my @orders = HegMethods->GetPcbReorders($jobId);
	@orders = grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN } @orders;    # filter only order zpracovani-rucni
	unless ( scalar(@orders) ) {
		
		my @mess = ("No reorders for pcbid: $jobId where \"Aktualni krok\" = \"zpracovani-rucni\"!\n");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
		return 0;	
	}

	

	# 2 ) Check if no errors
	if ( scalar( @{ $self->{"manChanges"} } ) ) {

		my @mess = ("You didn't process all manual changes correctly (see errors). Are you sure you want to continue?");
		my @btn = ( "Yes, continue", "No, I check errros again" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, \@btn );

		my $btnNumber = $messMngr->Result();

		if ( $btnNumber == 1 ) {
			return 0;
		}
	}

	# 3) show reorder popup

	$self->{"reorderPopup"}->Run($type);

	return 1;
}

 

sub __OnClosePopupHandler {
	my $self = shift;

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __DoChecks {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $checkReorder = CheckReorder->new( $inCAM, $jobId );
	my @manCh = $checkReorder->RunCheck();

	$self->{"manChanges"} = \@manCh;

	$self->{"form"}->SetErrIndicator( scalar(@manCh) );

}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"errIndClickEvent"}->Add( sub    { $self->__OnErrIndicatorHandler(@_) } );
	$self->{"form"}->{"processReorderEvent"}->Add( sub { $self->__OnProcessReorderEvent(@_) } );

	$self->{"reorderPopup"}->{'onClose'}->Add( sub { $self->__OnClosePopupHandler(@_) } )

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ReorderApp::ReorderApp';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $form = ReorderApp->new( $inCAM, $jobId );

}

1;

