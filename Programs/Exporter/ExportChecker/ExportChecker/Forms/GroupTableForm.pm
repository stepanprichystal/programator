#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupTableForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	#$self->SetBackgroundColour($Widgets::Style::clrBlack);

	return $self;
}

sub InitGroupTable {
	my $self       = shift;
	my $groupTable = shift;
	my $inCAM      = shift;

	$self->__SetLayout( $groupTable, $inCAM );

}

sub __SetLayout {

	my $self       = shift;
	my $groupTable = shift;

	#$groupTable = $self->__DefineTableGroups();

	#my @rows = $groupTable->GetRows();

	my $inCAM = shift;

	# ================= NEW ===========================

	my @rows = $groupTable->GetRows();

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	foreach my $row (@rows) {

		my $szRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

		my @cells = $row->GetCells();

		my $totalWidth = 0;    # width of all cells in row

		for ( my $i = 0 ; $i < scalar(@cells) ; $i++ ) {

			my $cell = $cells[$i];

			#foreach my $cell (@cells) {

			#	my $cell = NifUnit->new("f121212");

			# Get cell title
			my $title = UnitEnums->GetTitle( $cell->GetUnitId() );

			# Create new group wrapper, parent is this panel
			my $groupWrapperPnl;

			unless ( $cell->IsFormLess() ) {
				
				$groupWrapperPnl = GroupWrapperForm->new( $self, $title );

				# Init unit form, where parent will by group wrapper
				$cell->InitForm( $groupWrapperPnl, $inCAM );
				$cell->GetForm()->DisableControls(); # after disabling controls, dimension of from can be changed	
			}
			else{
				
				# Init unit form, where parent will by group wrapper
				$cell->InitForm( undef, $inCAM );
			}

			unless ( $cell->IsFormLess() ) {

				# Insert initialized group to group wrapper
				$groupWrapperPnl->Init( $cell->{"form"} );

				#$groupWrapperPnl->{"pnlBody"}->Disable();
				#$cell->{"form"}->Disable();
				#$groupWrapperPnl->{"pnlBody"}->Disable();
				#$groupWrapperPnl->Disable();

				# Add this rappet to group table
				my $w = $cell->GetCellWidth();
				$totalWidth += $w;

				$szRow->Add( $groupWrapperPnl, $w, &Wx::wxEXPAND | &Wx::wxALL, 4 );
			}

		}

		# Add expander, which do space, if there are missing cells in row
		if ( $totalWidth < 100 ) {
			$szRow->Add( 1, 1, 100 - $totalWidth, &Wx::wxEXPAND | &Wx::wxALL, 0 );
		}

		$szMain->Add( $szRow, 0, &Wx::wxEXPAND | &Wx::wxALL );
	}

	$self->SetSizer($szMain);

}

sub __DefineTableGroups {
	my $self = shift;

	use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTable';
	use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
	use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';

	#my $scrollPnl = $self->{"exporterForm"}->{"scrollPnl"};
	#my $scrollSizer =  Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $tab1 = $self->{"form"}->GetTab(0);
	#my $tab2 = $self->{"form"}->GetTab(1);

	$self->{"groupTables"} = GroupTables->new();

	my $tableTab1 = GroupTable->new();

	# nif unit
	my $nifUnit1 = NifUnit->new( $self->{"jobId"}, "Nif 1" );
	my $nifUnit2 = NifUnit->new( $self->{"jobId"}, "Nif 2" );
	my $nifUnit3 = NifUnit->new( $self->{"jobId"}, "Nif 3" );
	my $nifUnit4 = NifUnit->new( $self->{"jobId"}, "Nif 4" );

	my $row1Tab1 = $tableTab1->AddRow();
	$row1Tab1->AddCell($nifUnit1);

	$row1Tab1->AddCell($nifUnit2);

	#$row1->AddCell($nifUnit3);

	my $row2Tab1 = $tableTab1->AddRow();
	$row2Tab1->AddCell($nifUnit3);
	$row2Tab1->AddCell($nifUnit4);

	#$row2Tab1->AddCell($nifUnit6);

	#	my $tab2 = $self->{"form"}->GetTab(1);
	#
	#my $tableTab2 = GroupTable->new($tab2);
	#
	#	# nif unit
	#	my $nifUnit21 = NifUnit->new($tab2);
	#	my $nifUnit22 = NifUnit->new($tab2);
	#
	#	my $row21Tab2 = $tableTab2->AddRow();
	#	$row21Tab2->AddCell($nifUnit21);
	#	$row21Tab2->AddCell($nifUnit22);

	#$self->{"groupTables"}->AddTable($tableTab1);

	#return $self->{"groupTables"};

	return $tableTab1;
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

