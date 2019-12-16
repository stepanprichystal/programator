#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;

use aliased 'Packages::Events::Event';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupFrm';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupSeparatorFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"groupFrmInput"} = [];
	$self->{"groupFrmPress"} = [];

	$self->{"titleExpanders"} = [];

	$self->__SetLayout();

	#EVENTS

	$self->{"sigLayerSettChangedEvt"} = Event->new();
	$self->{"technologyChangedEvt"}   = Event->new();
	$self->{"etchingChangedEvt"}      = Event->new();

	return $self;

}

sub AddGroup {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;

	# Add separator if any group exist
	if ( $productType eq StackEnums->Product_INPUT && scalar( @{ $self->{"groupFrmInput"} } ) ) {
		$self->AddSeparator(2, Wx::Colour->new( 200, 200, 200 ),4);
	}
	elsif ( $productType eq StackEnums->Product_PRESS && scalar( @{ $self->{"groupFrmPress"} } ) ) {
		$self->AddSeparator(2, Wx::Colour->new( 200, 200, 200 ),4);
	}

	my $group = GroupFrm->new( $self, $productId, $productType );

	$group->{"sigLayerSettChangedEvt"}->Add( sub { $self->{"sigLayerSettChangedEvt"}->Do(@_) } );
	$group->{"technologyChangedEvt"}->Add( sub   { $self->{"technologyChangedEvt"}->Do(@_) } );
	$group->{"etchingChangedEvt"}->Add( sub      { $self->{"etchingChangedEvt"}->Do(@_) } );

	$self->{"szGroups"}->Add( $group, 0, &Wx::wxALL | &Wx::wxEXPAND, 0 );

	if ( $productType eq StackEnums->Product_INPUT ) {
		push( @{ $self->{"groupFrmInput"} }, $group );
	}
	elsif ( $productType eq StackEnums->Product_PRESS ) {
		push( @{ $self->{"groupFrmPress"} }, $group );
	}

	#$self->__SetJobOrder();

	return $group;

}

sub GetGroups {
	my $self = shift;
	my $type = shift;

	my @groupsFrm = ();

	@groupsFrm = @{ $self->{"groupFrmInput"} } if ( defined $type && $type eq StackEnums->Product_INPUT );
	@groupsFrm = @{ $self->{"groupFrmPress"} } if ( defined $type && $type eq StackEnums->Product_PRESS );
	@groupsFrm = ( @{ $self->{"groupFrmInput"} }, @{ $self->{"groupFrmPress"} } ) if ( !defined $type );

	return @groupsFrm;

}

sub AddCategoryTitle {
	my $self = shift;
	my $type = shift;
	my $text = shift;

	# DEFINE SIZERS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $groupTitleSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $groupClmnSz  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $groupTitlePnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
	my $groupTitleTxt = Wx::StaticText->new( $groupTitlePnl, -1, $text, [ -1, -1 ], [ 90, -1 ] );

	if ( $type eq StackEnums->Product_INPUT ) {

		$groupTitlePnl->SetBackgroundColour( Enums->Color_PRODUCTINPUT );

	}
	elsif ( $type eq StackEnums->Product_PRESS ) {
		$groupTitlePnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS );

	}

	my $fontLblBold = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );

	$groupTitleTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupTitleTxt->SetFont($fontLblBold);

	my $groupClmnsPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
	$groupClmnsPnl->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );
	my $groupClThickTxt = Wx::StaticText->new( $groupClmnsPnl, -1, "EtchCu [µm]",, [ -1, -1 ], [ 50, -1 ] );
	my $groupClPolarTxt = Wx::StaticText->new( $groupClmnsPnl, -1, "Polar",,        [ -1, -1 ], [ 40, -1 ] );
	my $groupClMirrTxt  = Wx::StaticText->new( $groupClmnsPnl, -1, "Mirror",,       [ -1, -1 ], [ 40, -1 ] );
	my $groupClCompTxt  = Wx::StaticText->new( $groupClmnsPnl, -1, "Comp [µm]",,   [ -1, -1 ], [ 50, -1 ] );
	my $groupClShrXTxt  = Wx::StaticText->new( $groupClmnsPnl, -1, "StretchX [%]",,  [ -1, -1 ], [ 50, -1 ] );
	my $groupClShrYTxt  = Wx::StaticText->new( $groupClmnsPnl, -1, "StretchY [%]",,  [ -1, -1 ], [ 50, -1 ] );
	my $technoClTxt     = Wx::StaticText->new( $groupClmnsPnl, -1, "Technology",,   [ -1, -1 ], [ 80, -1 ] );
	my $technoDrillTxt  = Wx::StaticText->new( $groupClmnsPnl, -1, "Plt NC",,       [ -1, -1 ], [ 70, -1 ] );

	# BUILD LAYOUT STRUCTURE
	$groupTitleSz->Add( 0, 22, 0 );    #expander vertical
	$groupTitleSz->Add( $groupTitleTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	my $expandH = Wx::Panel->new( $groupTitlePnl, -1, [ -1, -1 ], [ 25, -1 ] );
	$groupTitleSz->Add( $expandH, 0 );    #expander horizontal
	$groupTitlePnl->SetSizer($groupTitleSz);

	$groupClmnSz->Add( 0, 22, 0 );        #expander
	$groupClmnSz->Add( $groupClThickTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 10 );
	$groupClmnSz->Add( $groupClPolarTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $groupClMirrTxt,  0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $groupClCompTxt,  0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $groupClShrXTxt,  0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $groupClShrYTxt,  0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $technoClTxt,     0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );
	$groupClmnSz->Add( $technoDrillTxt,  0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL, 6 );

	$groupClmnsPnl->SetSizer($groupClmnSz);

	$szMain->Add( $groupTitlePnl, 0, &Wx::wxLEFT, 0 );
	$szMain->Add( $groupClmnsPnl, 1, &Wx::wxLEFT, 0 );

	$self->{"szGroups"}->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP | &Wx::wxBOTTOM, 4 );

	# SET REFERENCES
	push( @{ $self->{"titleExpanders"} }, $expandH );

	#$self->__SetJobOrder();

}

sub SetLayerValues {
	my $self = shift;
	my $l    = shift;

	my $layerRow = ( grep { $_->GetLayerName() eq $l->{"name"} } map { $_->GetAllCopperRows() } $self->GetAllGroupStackup() )[0];

	$layerRow->SetLayerValues($l);
}

sub GetLayerValues {
	my $self      = shift;
	my $layerName = shift;

	my $layerRow = ( grep { $_->GetLayerName() eq $layerName } map { $_->GetAllCopperRows() } $self->GetAllGroupStackup() )[0];

	return $layerRow->GetLayerValues();
}

sub GetCopperFrms {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $resRowFrm      = undef;
	my $resSubGroupFrm = undef;

	foreach my $groupFrm ( $self->GetGroups() ) {

		foreach my $subGroupFrm ( $groupFrm->GetSubGroups() ) {

			foreach my $copperRowFrm ( $subGroupFrm->GetAllCopperRows() ) {

				if (    $copperRowFrm->GetCopperName() eq $copperName
					 && $copperRowFrm->GetOuterCore() eq $outerCore
					 && $copperRowFrm->GetPlugging() eq $plugging 
					 && !$copperRowFrm->GetCuFoilOnly())
				{

					$resRowFrm      = $copperRowFrm;
					$resSubGroupFrm = $subGroupFrm;
					last;
				}
			}
			last if ( defined $resRowFrm );
		}
		last if ( defined $resRowFrm );
	}

	return ( $resRowFrm, $resSubGroupFrm );
}

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#
sub HideControls {
	my $self = shift;

	# 1) Hide input sub group title
	# Input product Sub group head can be hidden, if there no groups has more than one sobgroup
	my $hide = 1;

	foreach my $groupFrm ( $self->GetGroups( StackEnums->Product_INPUT ) ) {

		if ( scalar( $groupFrm->GetSubGroups() ) > 1 ) {

			$hide = 0;
			last;
		}
	}

	if ($hide) {

		# Hide title
		$_->HideSubGroupTitle() foreach ( map { $_->GetSubGroups() } $self->GetGroups() );

		# Resize header because of hiding group title

		foreach my $titleExp ( @{ $self->{"titleExpanders"} } ) {

			$titleExp->Hide();

		}

	}

	# 2) Hide technology controls if there is no copper
	foreach my $subGroup ( map { $_->GetSubGroups() } $self->GetGroups() ) {

		my $hide = 1;
		if ( scalar( grep { !$_->GetCuFoilOnly() } $subGroup->GetAllCopperRows() ) ) {
			$hide = 0;
		}
		$subGroup->HideSubGroupTechnology() if ($hide);
	}

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	#$self->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );

	# Group head

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szGroups"} = $szMain;

}

sub AddSeparator {
	my $self   = shift;
	my $height = shift;
	my $color  = shift;
	my $margin = shift // 0;

	# DEFINE SIZERS
	#my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $sepPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, $height ] );
	$sepPnl->SetBackgroundColour($color) if(defined $color);

	# BUILD LAYOUT STRUCTURE

	$self->{"szGroups"}->Add( $sepPnl, 0, &Wx::wxEXPAND | &Wx::wxTOP | &Wx::wxBOTTOM, $margin );

}

sub __GetCopperRow {
	my $self      = shift;
	my $layerName = shift;

}

#
#sub __OnStop {
#	my $self = shift;
#
#	$self->{"onStop"}->Do( $self->{"taskId"} );
#}
#
#sub __OnContinue {
#	my $self = shift;
#
#	$self->{"onContinue"}->Do( $self->{"taskId"} );
#}
#
#sub __OnAbort {
#	my $self = shift;
#
#	$self->{"onAbort"}->Do( $self->{"taskId"} );
#}
#
#sub __OnRestart {
#	my $self = shift;
#
#	$self->{"onRestart"}->Do( $self->{"taskId"} );
#}
#
#sub __OnRemove {
#	my $self = shift;
#
#	$self->{"onRemove"}->Do( $self->{"taskId"} );
#}
#
#sub __OnSelectItem {
#	my $self = shift;
#	my $item = shift;
#
#}

#sub __SetJobOrder {
#	my $self = shift;
#
#	my @queue = @{ $self->{"jobItems"} };
#
#	#find index of item
#	for ( my $i = 0 ; $i < scalar(@queue) ; $i++ ) {
#
#		$queue[$i]->SetItemOrder();
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
