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
use aliased 'Widgets::Forms::MyWxScrollPanel';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $parent, $pnlType ) = @_;

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	# Properties

	$self->{"partWrappers"} = [];
	$self->{"pnlType"}      = $pnlType;

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
	my $inCAM    = shift;

	$self->__SetLayout( $parts, $messMngr, $inCAM );

}

sub __SetLayout {

	my $self     = shift;
	my $parts    = shift;
	my $messMngr = shift;
	my $inCAM    = shift;

	#$groupTable = $self->__DefineTableGroups();

	#my @rows = $groupTable->GetRows();
	$self->SetBackgroundColour( EnumsStyle->BACKGCLR_LIGHTGRAY );

	# ================= NEW ===========================

	my $rowHeight    = 10;
	my $scrollPnl    = MyWxScrollPanel->new( $self, $rowHeight, );
	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );

	my $szMain      = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	$self->Freeze();

	for ( my $i = 0 ; $i < scalar( @{$parts} ) ; $i++ ) {

		my $part = $parts->[$i];

		# Get cell title
		my $title = EnumsStyle->GetPartTitle( $part->GetPartId() );

		# Create new group wrapper, parent is this panel
		my $partWrapper = PartWrapperForm->new( $containerPnl, $part->GetPartId(), $title, $messMngr );

		# Init unit form, where parent will by group wrapper
		$part->InitForm( $partWrapper, $inCAM, $self->{"pnlType"} );

		# Insert initialized group to group wrapper
		$partWrapper->Init( $part->{"form"} );

		#$groupWrapperPnl->{"pnlBody"}->Disable();
		#$cell->{"form"}->Disable();
		#$groupWrapperPnl->{"pnlBody"}->Disable();
		#$groupWrapperPnl->Disable();
		# Add this rappet to group table
		#my $w = $part->GetCellWidth();
		my $expand = ( $i < ( scalar( @{$parts} ) - 1 ) ? 1 : 0 );
		$containerSz->Add( $partWrapper, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

		push( @{ $self->{"partWrappers"} }, $partWrapper );


	}

	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );

	$containerPnl->SetSizer($containerSz);
	$scrollSizer->Add( $containerPnl, 1, &Wx::wxEXPAND );
	$scrollPnl->SetSizer($scrollSizer);
	$szMain->Add( $scrollPnl, 0, &Wx::wxEXPAND );
	
 

	$self->SetSizer($szMain);

	# get height of group table, for init scrollbar panel

	#$containerPnl->Layout();

	#	$containerPnl->InvalidateBestSize();
	#	$self->InvalidateBestSize();
	#	$scrollPnl->InvalidateBestSize();
	#	$containerPnl->InvalidateBestSize();
	#	$self->InvalidateBestSize();
	#	$scrollPnl->InvalidateBestSize();
	#	$scrollPnl->FitInside();

	#$self->{"mainFrm"}->Layout();
	$scrollPnl->Layout();
	$self->InvalidateBestSize();
	$scrollPnl->FitInside();
	$scrollPnl->Layout();
	
	
	my ( $width, $height ) = $containerPnl->GetSizeWH();

	#compute number of rows. One row has height 10 px
	$scrollPnl->SetRowCount( ($height) / 10 );

	$self->{"scrollPnl"}    = $scrollPnl;
	$self->{"containerPnl"} = $containerPnl;
	$self->{"szMain"}      = $szMain;

	$self->Thaw();

}

sub __OnScrollPaint {
	my $self = shift;

	my $scrollPnl = shift;
	my $event     = shift;
	#$self->{"containerPnl"}->Layout();
	#$self->Refresh();
 

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

