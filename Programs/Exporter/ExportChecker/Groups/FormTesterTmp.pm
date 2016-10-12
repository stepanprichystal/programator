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
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm';
use aliased 'Packages::InCAM::InCAM';

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
	
	my $mainFrm = $self->__SetLayout($parent);

	# Properties
	
	$mainFrm->Show();
	

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
		[ 800, 800 ],                                             # size
		&Wx::wxCAPTION | &Wx::wxCLOSE_BOX | &Wx::wxSTAY_ON_TOP |
		  &Wx::wxMINIMIZE_BOX   |  &Wx::wxSYSTEM_MENU   | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $groupWrapperPnl = GroupWrapperForm->new($mainFrm, "Test");

	my $form = $self->_TestedForm($groupWrapperPnl);

	# Insert initialized group to group wrapper
	$groupWrapperPnl->Init($form );

	#$groupWrapperPnl->{"pnlBody"}->Disable();
	#$cell->{"form"}->Disable();
	#$groupWrapperPnl->{"pnlBody"}->Disable();
	#$groupWrapperPnl->Disable();

	# Add this rappet to group table
	$szMain->Add( $groupWrapperPnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$mainFrm->SetSizer($szMain);
	$mainFrm->Layout();

	return $mainFrm;
}

sub _TestedForm {
	my $self         = shift;
	my $groupWrapper = shift;

	my $parent = $groupWrapper->GetParentForGroup();
	my $nif = PlotUnitForm->new( $parent, $self->{"inCAM"}, $self->{"jobId"}, "PLot" );

	return $nif;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	my $test = Programs::Exporter::ExportChecker::Groups::FormTesterTmp->new(-1, "f13609" );
	 
	$test->MainLoop();
}

1;

1;

