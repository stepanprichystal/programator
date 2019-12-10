#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::OtherLayerList::OtherLayerListRow;
use base qw(Widgets::Forms::CustomControlList::ControlListRow);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::LayerColorPnl';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class     = shift;
	my $parent    = shift;
	my $layerName = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( -1, $parent, $layerName, $rowHeight );

	bless($self);

	# PROPERTIES

	$self->{"layerName"} = $layerName;
	$self->{"rowHeight"} = $rowHeight;

	# this values are not represented  by controls
	$self->{"comp"}    = undef;
	$self->{"stretchX"} = undef;
	$self->{"stretchY"} = undef;

	$self->__SetLayout();

	# EVENTS
	$self->{"otherLayerSettChangedEvt"} = Event->new();

	return $self;
}

sub SetPolarityVal {
	my $self = shift;
	my $val  = shift;

	if ( $val eq "positive" ) {
		$self->{"polarityCb"}->SetValue("+");
	}
	elsif ( $val eq "negative" ) {
		$self->{"polarityCb"}->SetValue("-");
	}
}

sub GetPolarityVal {
	my $self = shift;

	return $self->{"polarityCb"}->GetValue() eq "+" ? "positive" : "negative";
}

sub SetMirrorVal {
	my $self = shift;
	my $val  = shift;

	$self->{"mirrorChb"}->SetValue($val);
}

sub GetMirrorVal {
	my $self = shift;

	if ( $self->{"mirrorChb"}->IsChecked() ) {
		return 1;
	}
	else {
		return 0;

	}
}

sub SetCompVal {
	my $self = shift;
	my $val  = shift;

	$self->{"comp"} = $val;
}

sub GetCompVal {
	my $self = shift;

	return $self->{"comp"};
}

sub SetStretchXVal {
	my $self = shift;
	my $val  = shift;

	$self->{"stretchX"} = $val;
}

sub GetStretchXVal {
	my $self = shift;

	return $self->{"stretchX"};
}

sub SetStretchYVal {
	my $self = shift;
	my $val  = shift;

	$self->{"stretchY"} = $val;
}

sub GetStretchYVal {
	my $self = shift;

	return $self->{"stretchY"};
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS

	my $layerColor = LayerColorPnl->new( $self->{"parent"}, $self->{"layerName"}, $self->{"rowHeight"} );

	my @polar = ( "+", "-" );
	my $polarityCb =
	  Wx::ComboBox->new( $self->{"parent"}, -1, $polar[0], &Wx::wxDefaultPosition, [ 10, $self->{"rowHeight"} ], \@polar, &Wx::wxCB_READONLY );

	my $fontPolar = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_MAX );

	#$polarityCb->SetFont($fontPolar);
	my $mirrorChb = Wx::CheckBox->new( $self->{"parent"}, -1, "", [ -1, -1 ], [ 10, $self->{"rowHeight"} ] );
	$self->_AddCell($layerColor);
	$self->_AddCell($polarityCb);
	$self->_AddCell($mirrorChb);

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $mirrorChb, -1, sub { $self->{"otherLayerSettChangedEvt"}->Do( $self->{"layerName"} ) } );
	Wx::Event::EVT_COMBOBOX( $polarityCb, -1, sub { $self->{"otherLayerSettChangedEvt"}->Do( $self->{"layerName"} ) } );

	# SET REFERENCES

	$self->{"polarityCb"} = $polarityCb;
	$self->{"mirrorChb"}  = $mirrorChb;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# layers
sub SetLayerValues {
	my $self  = shift;
	my %lInfo = %{ shift(@_) };

	$self->SetSelected( $lInfo{"plot"} );

	if ( $lInfo{"polarity"} eq "positive" ) {
		$self->{"polarityCb"}->SetValue("+");
	}
	elsif ( $lInfo{"polarity"} eq "negative" ) {
		$self->{"polarityCb"}->SetValue("-");
	}

	$self->{"mirrorChb"}->SetValue( $lInfo{"mirror"} );
	$self->{"compTxt"}->SetValue( $lInfo{"comp"} );
	$self->{"stretchX"}->SetValue( $lInfo{"stretchX"} );
	$self->{"stretchY"}->SetValue( $lInfo{"stretchX"} );
}

sub GetLayerValues {
	my $self = shift;

	my %lInfo = ();

	$lInfo{"name"} = $self->GetRowText();

	$lInfo{"plot"} = $self->IsSelected();

	$lInfo{"polarity"} = $self->{"polarityCb"}->GetValue() eq "+" ? "positive" : "negative";

	if ( $self->{"mirrorChb"}->IsChecked() ) {
		$lInfo{"mirror"} = 1;
	}
	else {
		$lInfo{"mirror"} = 0;

	}
	$lInfo{"comp"} = $self->{"compTxt"}->GetValue();

	$lInfo{"stretchX"} = $self->{"shrinkXTxt"}->GetValue();

	$lInfo{"stretchY"} = $self->{"shrinkYTxt"}->GetValue();

	return %lInfo;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

