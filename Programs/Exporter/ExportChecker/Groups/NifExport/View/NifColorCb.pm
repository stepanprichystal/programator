#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifColorCb;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $title  = shift;
	my @colors = @{ shift(@_) };

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	$self->__SetLayout( $title, \@colors );

	return $self;
}

sub __SetLayout {
	my $self   = shift;
	my $title  = shift;
	my @colors = @{ shift(@_) };

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Load data, for filling form by values

	# Add empty item
	push( @colors, "" );

	# DEFINE CONTROLS

	my $colorCbTxt = Wx::StaticText->new( $self, -1, $title );
	my $coloCb = Wx::ComboBox->new( $self, -1, $colors[0], &Wx::wxDefaultPosition, [ 70, 20 ], \@colors, &Wx::wxCB_READONLY );

	my $colorPnl = Wx::Panel->new( $self, -1, &Wx::wxDefaultPosition, [ 20, 20 ]);

	# SET EVENTS
	Wx::Event::EVT_COMBOBOX( $coloCb, -1, sub { $self->__OnColorChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $colorCbTxt,  30, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szMain->Add( $coloCb,  10, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szMain->Add( $colorPnl, 20, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);
	
	# SAVE REFERENCES
	$self->{"colorPnl"} = $colorPnl;

}

sub GetValue {
	my $self  = shift;
	
	my $color = $self->{"colorCb"}->GetValue();
	return $color;
}

sub SetValue {
	my $self  = shift;
	my $color = shift;
	$self->{"colorCb"}->SetValue($color);
}

sub __OnColorChangeHandler {
	my $self    = shift;
	my $colorCb = shift;

	my $color = $colorCb->GetValue();

	my $wxColor = Helper->GetColorDef($color);
	$self->{"colorPnl"}->SetBackgroundColour($wxColor);
	
	$self->{"colorPnl"}->Refresh();
}

1;
