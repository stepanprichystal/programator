#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotListRow;
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
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::FilmForm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class        = shift;
	my $parent       = shift;
	my $layer        = shift;
	my $filmRuleSet1 = shift;
	my $filmRuleSet2 = shift;
	my $rowHeight    = 21;

	my $self = $class->SUPER::new( $parent, $layer->{"gROWname"}, $rowHeight );

	bless($self);

	$self->{"layer"}     = $layer;
	$self->{"rowHeight"} = $rowHeight;

	$self->{"filmRuleSet1"} = $filmRuleSet1;
	$self->{"filmRuleSet2"} = $filmRuleSet2;

	$self->__SetLayout();

	# EVENTS
	#$self->{"onSelectedChanged"}->Add(sub {$self->__PlotSelectionChanged(@_)});

	return $self;
}

sub SetPolarity {
	my $self = shift;
	my $val  = shift;

	$self->{"polarityCb"}->SetValue($val);

}

sub SetMirror {
	my $self = shift;
	my $val  = shift;

	$self->{"mirrorChb"}->SetValue($val);

}

sub SetComp {
	my $self = shift;
	my $val  = shift;

	$self->{"compTxt"}->SetValue($val);
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS

	my $layerColor = LayerColorPnl->new( $self->{"parent"}, $self->{"layer"}->{"gROWname"}, $self->{"rowHeight"} );

	my @polar = ( "+", "-" );
	my $polarityCb =
	  Wx::ComboBox->new( $self->{"parent"}, -1, $polar[0], &Wx::wxDefaultPosition, [ 10, $self->{"rowHeight"} ], \@polar, &Wx::wxCB_READONLY );
	
	my $fontPolar =
	  Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT  , &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_MAX   );
	
	#$polarityCb->SetFont($fontPolar);
	my $mirrorChb = Wx::CheckBox->new( $self->{"parent"}, -1, "", [ -1, -1 ], [ 10, $self->{"rowHeight"} ] );

	my $compTxt = Wx::TextCtrl->new( $self->{"parent"}, -1, "", &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );

	my $arrowTxt = Wx::StaticText->new( $self->{"parent"}, -1, "       ==>", &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	#$arrowTxt->SetFont($Widgets::Style::fontLblBold);

	my $film1Frm = FilmForm->new( $self->{"parent"}, $self->{"filmRuleSet1"}, $self->{"rowHeight"});
	my $film2Frm = FilmForm->new( $self->{"parent"}, $self->{"filmRuleSet2"}, $self->{"rowHeight"} );

	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $mainChb, -1, sub { $self->__OnSelectedChange(@_) } );

	$self->_AddCell($layerColor);
	$self->_AddCell($polarityCb);
	$self->_AddCell($mirrorChb);
	$self->_AddCell($compTxt);
	$self->_AddCell($arrowTxt);
	$self->_AddCell($film1Frm);
	$self->_AddCell($film2Frm);

	# SET REFERENCES

	$self->{"film1Frm"}   = $film1Frm;
	$self->{"film2Frm"}   = $film2Frm;
	$self->{"polarityCb"} = $polarityCb;
	$self->{"mirrorChb"}  = $mirrorChb;
	$self->{"compTxt"}    = $compTxt;

}

sub PlotSelectionChanged {
	my $self = shift;

	#my $plotList = shift;
	#my $row = shift;

	my @selectedLayers = ();

	foreach my $row ( $self->{"parent"}->GetSelectedRows() ) {

		push( @selectedLayers, $row->GetRowText() );

	}

	$self->{"film1Frm"}->PlotSelectChanged( \@selectedLayers );
	$self->{"film2Frm"}->PlotSelectChanged( \@selectedLayers );
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# layers
sub SetLayerValues {
	my $self  = shift;
	my %lInfo = %{ shift(@_) };

	$self->SetSelected( $lInfo{"plot"} );
	
	if($lInfo{"polarity"} eq "positive"){
		$self->{"polarityCb"}->SetValue("+" );
	}elsif($lInfo{"polarity"} eq "negative"){
		$self->{"polarityCb"}->SetValue( "-" );
	}
	
	
	$self->{"mirrorChb"}->SetValue( $lInfo{"mirror"} );
	$self->{"compTxt"}->SetValue( $lInfo{"comp"} );

}

sub GetLayerValues {
	my $self = shift;

	my %lInfo = ();
	
	$lInfo{"name"} = $self->GetRowText();
	
	$lInfo{"plot"} = $self->IsSelected();
	
	$lInfo{"polarity"} = $self->{"polarityCb"}->GetValue();

	if ( $self->{"mirrorChb"}->IsChecked() ) {
		$lInfo{"mirror"} = 1;
	}
	else {
		$lInfo{"mirror"} = 0;

	}
	$lInfo{"comp"} = $self->{"compTxt"}->GetValue();

	

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

