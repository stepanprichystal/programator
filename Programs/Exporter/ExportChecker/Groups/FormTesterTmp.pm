#-------------------------------------------------------------------------------------------#
# Description: Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::FormTesterTmp;
use base 'Wx::App';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitForm';
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::MDIExport::View::MDIUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::PreUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::OfferExport::View::OfferUnitForm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $self   = shift;
	my $parent = shift;
	$self = {};

	if ( !defined $parent || $parent == -1 ) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	$self->{"inCAM"} = InCAM->new();
	$self->{"jobId"} = shift;

	my @allSteps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"step"} = undef;

	if ( scalar( grep { $_ eq "panel" } @allSteps ) ) {
		$self->{"step"} = "panel";
	}
	elsif ( scalar( grep { $_ eq "mpanel" } @allSteps ) ) {
		$self->{"step"} = "mpanel";
	}
	elsif ( scalar( grep { $_ eq "o+1" } @allSteps ) ) {
		$self->{"step"} = "o+1";
	}

	 
	my $mainFrm = $self->__SetLayout($parent);

	# Properties

	$mainFrm->Show();
	$mainFrm->Refresh();

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                       # parent window
		-1,                            # ID -1 means any
		"Checking export settings",    # title
		&Wx::wxDefaultPosition,        # window position
		[ 800, 800 ],                  # size
		&Wx::wxCAPTION | &Wx::wxCLOSE_BOX | &Wx::wxSTAY_ON_TOP |
		  &Wx::wxMINIMIZE_BOX | &Wx::wxSYSTEM_MENU | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupWrapperPnl = GroupWrapperForm->new( $mainFrm, "Test" );

	my $form = $self->_TestedForm($groupWrapperPnl);

	# Insert initialized group to group wrapper

	#$groupWrapperPnl->{"pnlBody"}->Disable();
	#$cell->{"form"}->Disable();
	#$groupWrapperPnl->{"pnlBody"}->Disable();
	#$groupWrapperPnl->Disable();

	# Add this rappet to group table
	$szMain->Add( $groupWrapperPnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$mainFrm->SetSizer($szMain);

	#$mainFrm->Layout();
	$mainFrm->Refresh();

	return $mainFrm;
}

sub _TestedForm {
	my $self         = shift;
	my $groupWrapper = shift;

	use aliased 'Packages::Export::PreExport::FakeLayers';

	#my %types = FakeLayers->CreateFakeLayers( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 1 );

	my $d = DefaultInfo->new( $self->{"jobId"}, $self->{"step"} );
	$d->Init( $self->{"inCAM"} );

	#use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit';
	#use aliased 'Programs::Exporter::ExportChecker::Groups::OfferExport::Presenter::OfferUnit';
	use aliased 'Programs::Exporter::ExportChecker::Groups::MDIExport::Presenter::MDIUnit';

	my $preUnit = MDIUnit->new( $self->{"jobId"} );

	$preUnit->SetDefaultInfo($d);
	$preUnit->InitDataMngr( $self->{"inCAM"} );

	$preUnit->InitForm( $groupWrapper, $self->{"inCAM"} );

	$groupWrapper->Init( $preUnit->GetForm() );

	$preUnit->RefreshGUI();
	$preUnit->GetForm()->DisableControls();

	return $preUnit->GetForm();

}

#sub _TestedForm {
#	my $self         = shift;
#	my $groupWrapper = shift;
#
#	use aliased 'Packages::Export::PreExport::FakeLayers';
#
#	my %types = FakeLayers->CreateFakeLayers( $self->{"inCAM"}, $self->{"jobId"}, "panel", 1 );
#
#	my $d = DefaultInfo->new( $self->{"jobId"} );
#	$d->Init( $self->{"inCAM"} );
#
#	use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit';
#
#	my $preUnit = PreUnit->new( $self->{"jobId"} );
#
#	$preUnit->SetDefaultInfo($d);
#	$preUnit->InitDataMngr( $self->{"inCAM"} );
#
#	$preUnit->InitForm( $groupWrapper, $self->{"inCAM"} );
#
#	$groupWrapper->Init( $preUnit->GetForm() );
#
#	$preUnit->RefreshGUI();
#	$preUnit->GetForm()->DisableControls();
#
#	return $preUnit->GetForm();
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;

#if ( $filename =~ /DEBUG_FILE.pl/ ) {

my $test = Programs::Exporter::ExportChecker::Groups::FormTesterTmp->new( -1, "d328262" );

$test->MainLoop();

#}

1;

