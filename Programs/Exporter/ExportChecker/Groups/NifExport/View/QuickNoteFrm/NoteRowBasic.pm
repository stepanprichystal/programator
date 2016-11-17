#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::NoteRowBasic;
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
	my $note        = shift;
	#my $filmRuleSet1 = shift;
	#my $filmRuleSet2 = shift;
	my $rowHeight    = 20;

	my $self = $class->SUPER::new( $parent, $note->{"title"}, $rowHeight );

	bless($self);

	 
	$self->{"rowHeight"} = $rowHeight;
	$self->{"note"} = $note;
 

	 

	$self->__SetLayout();

	# EVENTS
	 

	return $self;
}


sub GetNoteData{
	my $self = shift;
	
	
	my %info = ();
	
	$info{"selected"} = $self->IsSelected();
	$info{"id"} = $self->{"note"}->{"id"};
	$info{"text"} = $self->{"note"}->{"text"};
	
	# contain additional parameters, which are inseted to note text
	my @values = ();
	$info{"values"} = \@values;
 
 
 	return \%info;
	
}
 

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS
 
	# SET EVENTS
 

	# SET REFERENCES
 
}

 

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}


1;
