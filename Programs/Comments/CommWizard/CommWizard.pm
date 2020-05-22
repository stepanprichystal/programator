
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::CommWizard;

use Class::Interface;
&implements('Packages::InCAMHelpers::AppLauncher::IAppLauncher');

#3th party library
use strict;
use warnings;
use threads;
use threads::shared;

#use strict;

#local library
use aliased 'Programs::Comments::CommWizard::Forms::CommWizardFrm';
use aliased 'Programs::Comments::Comments';

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

	$self->{"jobId"} = shift;

	$self->{"serverPort"} = shift;

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = CommWizardFrm->new( -1, $self->{"jobId"} );

	# Manage group date (store/load group data from/to disc)
	$self->{"comments"} = undef;

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # contain InCAM library conencted to server

	# 1) Get InCAm from Launcher

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();

	$self->{"comments"} = Comments->new( $self->{"inCAM"}, $self->{"jobId"} );

	#set handlers for main app form
	$self->__SetHandlers();

	$self->__RefreshForm();

}

sub Run {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Show(1);

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __SaveExitHndl {
	my $self = shift;
	my $save = shift;
	my $exit = shift;

}

sub __OnSelCommChangedHndl {
	my $self   = shift;
	my $commId = shift;

	my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommViewForm( $commId, $commLayout );

}

sub __OnRemoveFileHndl {
	my $self   = shift;
	my $commId = shift;
	my $fileId = shift;

	$self->{"comments"}->RemoveFile( $commId, $fileId );
	my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

	$self->{"form"}->RefreshCommViewForm( $commId, $commLayout );
}

sub __OnEditFileHndl {
	my $self   = shift;
	my $commId = shift;

	my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);

}

sub __OnAddFileHndl {
	my $self   = shift;
	my $commId = shift;
	my $addCAM = shift;
	my $addGS  = shift;

	my $p = undef;

	if ($addCAM) {
		$p = $self->{"comments"}->SnapshotCAM(0);
	}
	elsif ($addGS) {
		$p = $self->{"comments"}->SnapshotGS(0);
	}

	$self->{"comments"}->AddFile( $commId, undef, $p );

 
 	# Refresh Comm view
	my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
	$self->{"form"}->RefreshCommViewForm( $commId, $commLayout );
	
	# Refresh Comm list
	 

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __RefreshForm {
	my $self = shift;

	$self->{"form"}->RefreshCommListViewForm( $self->{"comments"}->GetLayout() );

	my $comments   = $self->{"comments"}->GetLayout();
	my $commId     = scalar( $comments->GetAllComments() ) - 1;
	my $commLayout = $self->{"comments"}->GetLayout()->GetCommentById($commId);
	$self->{"form"}->RefreshCommViewForm( $commId, $commLayout );

}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"saveExitEvt"}->Add( sub         { $self->__SaveExitHndl(@_) } );
	$self->{"form"}->{"onSelCommChangedEvt"}->Add( sub { $self->__OnSelCommChangedHndl(@_) } );

	$self->{"form"}->{'onRemoveFileEvt'}->Add( sub { $self->__OnRemoveFileHndl(@_) } );
	$self->{"form"}->{'onEditFileEvt'}->Add( sub   { $self->__OnEditFileHndl(@_) } );
	$self->{"form"}->{'onAddFileEvt'}->Add( sub    { $self->__OnAddFileHndl(@_) } );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

