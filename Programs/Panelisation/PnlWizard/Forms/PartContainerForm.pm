#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Forms::PartContainerForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library
use aliased 'Programs::Panelisation::PnlWizard::Forms::PartWrapperForm';

#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	# Properties

	$self->{"partWrappers"} = [];

	#$self->SetBackgroundColour($Widgets::Style::clrBlack);

	return $self;
}

sub SetFinalProcessLayout {
	my $self = shift;
	my $val  = shift;    # start/end

	foreach my $partWrapper ( @{ $self->{"partWrappers"} } ) {

		$partWrapper->SetFinalProcessLayout($val);

	}

}

sub InitContainer {
	my $self     = shift;
	my $parts    = shift;
	my $messMngr = shift;
	my $inCAM = shift;
	
	$self->__SetLayout( $parts, $messMngr, $inCAM );

}

sub __SetLayout {

	my $self     = shift;
	my $parts    = shift;
	my $messMngr = shift;
	my $inCAM = shift;

	#$groupTable = $self->__DefineTableGroups();

	#my @rows = $groupTable->GetRows();
	$self->SetBackgroundColour( EnumsStyle->BACKGCLR_LIGHTGRAY );

	

	# ================= NEW ===========================

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	foreach my $part ( @{$parts} ) {

		# Get cell title
		my $title = EnumsStyle->GetPartTitle( $part->GetPartId() );

		# Create new group wrapper, parent is this panel
		my $partWrapper = PartWrapperForm->new( $self, $part->GetPartId(), $title, $messMngr );

		# Init unit form, where parent will by group wrapper
		$part->InitForm( $partWrapper, $inCAM );

		# Insert initialized group to group wrapper
		$partWrapper->Init( $part->{"form"} );

		#$groupWrapperPnl->{"pnlBody"}->Disable();
		#$cell->{"form"}->Disable();
		#$groupWrapperPnl->{"pnlBody"}->Disable();
		#$groupWrapperPnl->Disable();

		# Add this rappet to group table
		#my $w = $part->GetCellWidth();

		$szMain->Add( $partWrapper, 1, &Wx::wxEXPAND | &Wx::wxALL, 4 );
		push( @{ $self->{"partWrappers"} }, $partWrapper );
	}

	$self->SetSizer($szMain);

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

