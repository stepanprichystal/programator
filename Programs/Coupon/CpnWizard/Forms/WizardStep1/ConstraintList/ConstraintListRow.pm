#-------------------------------------------------------------------------------------------#
# Description: 
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::ConstraintListRow;
use base qw(Widgets::Forms::CustomControlList::ControlListRow);

#3th party library
use strict;
use warnings;
use utf8;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);


#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';

use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::IconPnl';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class           = shift;
	my $parent          = shift;
	my $constraint      = shift;
	 

	#my $filmRuleSet1 = shift;
	#my $filmRuleSet2 = shift;
	my $rowHeight = 25;

	my $self = $class->SUPER::new( $constraint->GetId(), $parent, "", $rowHeight );

	bless($self);

	$self->{"constraint"}      = $constraint;
 
	$self->{"rowHeight"}       = $rowHeight;

	$self->__SetLayout();

	# EVENTS
	$self->{"onGroupChanged"} = Event->new(); 

	return $self;
}

sub GetGroup{
	my $self = shift;
	
	return $self->{"groupTxt"}->GetValue();
}

sub SetGroup{
	my $self = shift;
	my $val = shift;
	
	$self->{"groupTxt"}->SetValue($val);
	
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS
	my $constr = $self->{"constraint"};
 

	my $idTxt      = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetId(), &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
		my $groupTxt =
	  Wx::TextCtrl->new( $self->{"parent"}, -1, -1, &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	#my $typeTxt    = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetType(),        &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	#my $modelTxt   = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetModel(),       &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	my $typePnl = IconPnl->new( $self->{"parent"}, $constr->GetType(), $constr->GetModel(), $self->{"rowHeight"});
	
	my $trackLTxt  = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetTrackLayer(),  &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	my $topRefLTxt = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetTopRefLayer(), &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	my $botRefLTxt = Wx::StaticText->new( $self->{"parent"}, -1, $constr->GetBotRefLayer(), &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
 
	my $impedanceLTxt = Wx::StaticText->new( $self->{"parent"}, -1, sprintf("%.2f Ω", $constr->GetOption("CALCULATION_REQUIRED_IMPEDANCE")), &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );

	
	$self->_AddCell($idTxt);
	$self->_AddCell($groupTxt);
	$self->_AddCell($typePnl);
	#$self->_AddCell($modelTxt);
	$self->_AddCell($trackLTxt);
	$self->_AddCell($topRefLTxt);
	$self->_AddCell($botRefLTxt);
	$self->_AddCell($impedanceLTxt);
	
	# SET EVENTS

	Wx::Event::EVT_TEXT( $groupTxt, -1, sub { $self->__OnGroupChanged(@_) } );

	# SET REFERENCES

	$self->{"groupTxt"} = $groupTxt;

}

#sub ConstrSelectionChanged {
#	my $self           = shift;
#	my @selectedLayers = @{ shift(@_) };
#
#	#
#	#	$self->{"film1Frm"}->PlotSelectChanged( \@selectedLayers );
#	#	$self->{"film2Frm"}->PlotSelectChanged( \@selectedLayers );
#}

sub __OnGroupChanged {
	my $self = shift;

	$self->{"onGroupChanged"}->Do($self);
}
#
## =====================================================================
## SET/GET CONTROLS VALUES
## =====================================================================
#
## layers
#sub SetLayerValues {
#	my $self  = shift;
#	my %lInfo = %{ shift(@_) };
#
#	$self->SetSelected( $lInfo{"plot"} );
#
#	if($lInfo{"polarity"} eq "positive"){
#		$self->{"polarityCb"}->SetValue("+" );
#	}elsif($lInfo{"polarity"} eq "negative"){
#		$self->{"polarityCb"}->SetValue( "-" );
#	}
#
#
#	$self->{"mirrorChb"}->SetValue( $lInfo{"mirror"} );
#	$self->{"compTxt"}->SetValue( $lInfo{"comp"} );
#
#}
#
#sub GetLayerValues {
#	my $self = shift;
#
#	my %lInfo = ();
#
#	$lInfo{"name"} = $self->GetRowText();
#
#	$lInfo{"plot"} = $self->IsSelected();
#
#
#	$lInfo{"polarity"} = $self->{"polarityCb"}->GetValue() eq "+" ? "positive" : "negative";
#
#	if ( $self->{"mirrorChb"}->IsChecked() ) {
#		$lInfo{"mirror"} = 1;
#	}
#	else {
#		$lInfo{"mirror"} = 0;
#
#	}
#	$lInfo{"comp"} = $self->{"compTxt"}->GetValue();
#
#	return %lInfo;
#}
#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

