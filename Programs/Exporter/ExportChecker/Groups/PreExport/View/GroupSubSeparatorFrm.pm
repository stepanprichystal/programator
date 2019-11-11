
#-------------------------------------------------------------------------------------------#
# Description: Base item class, wchich is managed by container MyWxCustomQueue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupSubSeparatorFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $parent     = shift;
 

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES

	$self->__SetLayout();

	#EVENTS
 

	return $self;

}

sub __SetLayout {
	my $self      = shift;
	my $groupType = shift;

	# DEFINE SIZERS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	
	$groupSepPnl->SetBackgroundColour( Wx::Colour->new( 100, 100, 100 ) );

	# BUILD LAYOUT STRUCTURE
	$groupSepPnl->SetSizer($szMain);

	$szMain->Add( $groupSepPnl, 1, &Wx::wxALL, 4 );

	$self->SetSizer($szMain);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
