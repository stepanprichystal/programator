
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep1::WizardStep1Frm;
use base('Programs::Coupon::CpnWizard::Forms::WizardStepFrmBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::ConstraintList';
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetLayout {
	my $self   = shift;
	my $parent = shift;

	my $pnlMain      = Wx::Panel->new( $parent, -1 );
	my $rowHeight    = 27;
	my $scrollPnl    = MyWxScrollPanel->new( $pnlMain, $rowHeight, );
	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );

	my $szMain      = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRowBtns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRowList = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $btnCheckAllGroup = Wx::Button->new( $pnlMain, -1, "Uncheck all",     &Wx::wxDefaultPosition, [ 100, 25 ] );
	my $btnDelGroup      = Wx::Button->new( $pnlMain, -1, "Reset groups",    &Wx::wxDefaultPosition, [ 120, 25 ] );
	my $btnGenGroup      = Wx::Button->new( $pnlMain, -1, "Generate groups", &Wx::wxDefaultPosition, [ 120, 25 ] );

	#	my $p = 'c:\Perl\site\lib\TpvScripts\Scripts\Programs\Coupon\CpnWizard\Resources\small_se_uncoated_microstrip.bmp';
	#		my $btmIco = Wx::Bitmap->new( $p, &Wx::wxBITMAP_TYPE_BMP );#wxBITMAP_TYPE_PNG
	#	$btnGenGroup->SetBitmap($btmIco);
	my $list = ConstraintList->new( $containerPnl, $self->{"inCAM"}, $self->{"jobId"} );

	$containerPnl->SetBackgroundColour( Wx::Colour->new( 0, 255, 0 ) );

	$containerPnl->SetSizer($containerSz);
	$scrollPnl->SetSizer($scrollSizer);

	# addpanel to siyers
	$containerSz->Add( $list, 1, &Wx::wxEXPAND );

	#$containerSz->Add( 1, 1, &Wx::wxEXPAND );

	$scrollSizer->Add( $containerPnl, 1, &Wx::wxEXPAND );

	$szMain->Add( $szRowBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	#$szMain->Add( $szRowList, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $scrollPnl, 1, &Wx::wxEXPAND );

	# SET EVENTS

	$list->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChangeList(@_) } );
	$list->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChangeSetGroupList(@_) } );
	$list->{"onGroupChanged"}->Add( sub    { $self->__OnGroupChangeList(@_) } );
	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );
	Wx::Event::EVT_BUTTON( $btnGenGroup,      -1, sub { $self->__ShowGenerator() } );
	Wx::Event::EVT_BUTTON( $btnCheckAllGroup, -1, sub { $self->__UnCheckAll() } );
	Wx::Event::EVT_BUTTON( $btnDelGroup,      -1, sub { $self->__ResetGroups() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRowBtns->Add( $btnCheckAllGroup, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowBtns->Add( $btnDelGroup,      0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowBtns->Add( $btnGenGroup,      0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$pnlMain->SetSizer($szMain);

	# SET REFERENCES

	$self->{"constrList"}   = $list;
	$self->{"scrollPnl"}    = $scrollPnl;
	$self->{"parent"}       = $parent;
	$self->{"containerPnl"} = $containerPnl;

	#my ( $width, $height ) = $containerPnl->GetSizeWH();

	return $pnlMain;

}

sub Update {
	my $self       = shift;
	my $wizardStep = shift;

	$self->{"coreWizardStep"} = $wizardStep;    # Update current step wizard

	my @constr       = $self->{"coreWizardStep"}->GetConstraints();
	my $constrGroup  = $self->{"coreWizardStep"}->GetConstrGroups();
	my $constrFilter = $self->{"coreWizardStep"}->GetConstrFilter();

	my $listFirstInit = 0;

	unless ( $self->{"constrList"}->ConstraintsSet() ) {

		$self->{"constrList"}->SetConstraints( \@constr );
		$listFirstInit = 1;
	}

	foreach my $c (@constr) {

		my $r = $self->{"constrList"}->GetRowById( $c->GetId() );

		$r->SetSelected( $constrFilter->{ $c->GetId() } );
		$r->SetGroup( $constrGroup->{ $c->GetId() } );

	}

	$self->{"scrollPnl"}->FitInside();
	$self->{"scrollPnl"}->Layout();
	$self->{"scrollPnl"}->SetRowCount( scalar(@constr) );

}

sub __OnSelectedChangeList {
	my $self    = shift;
	my $list    = shift;
	my $listRow = shift;

	$self->{"coreWizardStep"}->UpdateConstrFilter( $listRow->GetRowId(), $listRow->IsSelected() );

}

sub __OnSelectedChangeSetGroupList {
	my $self    = shift;
	my $list    = shift;
	my $listRow = shift;

	my $groupVal = $listRow->IsSelected() ? 1 : "";

	$listRow->SetGroup($groupVal);
	$self->{"coreWizardStep"}->UpdateConstrGroup( $listRow->GetRowId(), $groupVal );
}

sub __OnGroupChangeList {
	my $self    = shift;
	my $list    = shift;
	my $listRow = shift;

	$self->{"coreWizardStep"}->UpdateConstrGroup( $listRow->GetRowId(), $listRow->GetGroup() );

}

sub __OnScrollPaint {
	my $self      = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$self->{"parent"}->Layout();

	$scrollPnl->FitInside();
	$scrollPnl->Refresh();
}

sub __ShowGenerator {
	my $self = shift;

	my $result = 0;
	my $frm = GeneratorFrm->new( $self->{"parentFrm"}, $self->{"coreWizardStep"}, \$result );

	$frm->ShowModal();

	# update layout
	if ($result) {

		$self->Update( $self->{"coreWizardStep"} );
	}

}

sub __UnCheckAll {
	my $self = shift;

	my $rowCnt = scalar( $self->{"constrList"}->GetAllRows() );

	my $check = $rowCnt == scalar( grep { !$_->IsSelected() } $self->{"constrList"}->GetAllRows() ) ? 1 : 0;

	foreach my $r ( $self->{"constrList"}->GetAllRows() ) {

		$r->SetSelected($check);

		$self->__OnSelectedChangeList( $self->{"constrList"}, $r );
		$self->__OnSelectedChangeSetGroupList( $self->{"constrList"}, $r );

	}
}

sub __ResetGroups {
	my $self = shift;

	foreach my $r ( $self->{"constrList"}->GetAllRows() ) {

		if ( $r->IsSelected() ) {
			$r->SetGroup(1);
			$self->__OnGroupChangeList( $self->{"constrList"}, $r );
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

}

1;

