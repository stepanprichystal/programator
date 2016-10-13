#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
use Wx;

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotList';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	$self->__SetLayout();

	#$self->Disable();

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	#my $settingsStatBox  = $self->__SetGroup1($self);
	#my $settingsStatBox2  = $self->__SetGroup2($self);

	my $settingsStatBox = $self->__SetLayoutQuickSettings($self);
	my $optionsStatBox  = $self->__SetLayoutOptions($self);
	my $layersStatBox   = $self->__SetLayoutControlList($self);

	#my $layersStatBox = $self->__SetLayoutControlList($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $settingsStatBox, 70, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $optionsStatBox,  30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $layersStatBox,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutQuickSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Quick settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS
	my $allChb = Wx::CheckBox->new( $statBox, -1, "Select all", &Wx::wxDefaultPosition );
	my @polar = ( "-", "positive", "negative" );
	my $polarityCb = Wx::ComboBox->new( $statBox, -1, $polar[0], &Wx::wxDefaultPosition, [70, 25 ], \@polar, &Wx::wxCB_READONLY );
	my $mirrorChb = Wx::CheckBox->new( $statBox, -1, "", [ -1, -1 ], [70, 25 ] );
	my $compTxt = Wx::TextCtrl->new( $statBox, -1, "0", &Wx::wxDefaultPosition, [70, 25 ] );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );
	Wx::Event::EVT_COMBOBOX( $polarityCb, -1, sub { $self->__OnPolarityChangeHandler(@_) } );
	Wx::Event::EVT_CHECKBOX( $mirrorChb, -1, sub { $self->__OnMirrorChangeHandler(@_) } );
	Wx::Event::EVT_TEXT( $compTxt, -1, sub { $self->__OnCompChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $allChb, 0, &Wx::wxEXPAND | &Wx::wxALL,0 );
	$szStatBox->Add( $polarityCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $mirrorChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $compTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"allChb"}     = $allChb;
	$self->{"polarityCb"} = $polarityCb;
	$self->{"mirrorChb"}  = $mirrorChb;
	$self->{"compTxt"}    = $compTxt;

	return $szStatBox;
}

sub __SetLayoutOptions {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Options' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS
	my $plotterChb = Wx::CheckBox->new( $statBox, -1, "Send to plotter", &Wx::wxDefaultPosition );

	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $plotterChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $plotterChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References

	return $szStatBox;
}

sub __SetLayoutControlList {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS
	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my $plotList = PlotList->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $plotList, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"plotList"} = $plotList;

	return $szStatBox;
}

#
## Set layout for Quick set box
#sub __SetLayoutControlList {
#	my $self   = shift;
#	my $parent = shift;
#
#	#define staticboxes
#	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
#	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );
#
#
#	# DEFINE CONTROLS
#	#my $allChb     = Wx::CheckBox->new( $statBox, -1, "Select all",      &Wx::wxDefaultPosition);
#
#
#	my $widget = PlotList->new($statBox  );
#
#
#	# SET EVENTS
#	#Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );
#
#	# BUILD STRUCTURE OF LAYOUT
#	#$szStatBox->Add( $allChb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#
#
#	# Set References
#	#$self->{"allChb"} = $allChb;
#
#	return $szStatBox;
#}

# Select/unselect all in plot list
sub __OnSelectAllChangeHandler {
	my $self = shift;
	my $chb  = shift;

	if ( $self->{"allChb"}->IsChecked() ) {

		$self->{"plotList"}->SelectAll();
	}
	else {

		$self->{"plotList"}->UnselectAll();
	}

}

# Change polarity of  all in plot list
sub __OnPolarityChangeHandler {
	my $self = shift;
	my $chb  = shift;

	my $val = $self->{"polarityCb"}->GetValue();


	 $self->{"plotList"}->SetPolarity($val);
}

# Control handlers
sub __OnMirrorChangeHandler {
	my $self = shift;
	my $chb  = shift;

	my $isMirror = $self->{"mirrorChb"}->IsChecked();
	
	$self->{"plotList"}->SetMirror($isMirror);

}

# Control handlers
sub __OnCompChangeHandler {
	my $self = shift;
	my $chb  = shift;

	my $val = $self->{"compTxt"}->GetLabel();
	
	$self->{"plotList"}->SetComp($val);
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetSingle_x {
	my $self  = shift;
	my $value = shift;
	$self->{"singlexValTxt"}->SetLabel($value);
}

sub GetSingle_x {
	my $self = shift;
	return $self->{"singlexValTxt"}->GetLabel();
}

1;
