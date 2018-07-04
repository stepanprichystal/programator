#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::ConstraintList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::ConstraintList::ConstraintListRow';
use aliased 'Packages::Events::Event';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::CustomControlList::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	 

	# Name, Color, Polarity, Mirror, Comp
	my @widths = ( 50		, 20  ,  50    , 250	      ,  100    , 90          ,  90            , 90             );
	my @titles = ( "Include", "Id", "Group","Type + model",  "Test layer", "Top ref layer", "Bot ref layer" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, , Enums->Mode_CHECKBOX, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"inCAM"}  = $inCAM;
	$self->{"jobId"}  = $jobId;
	 
 
	$self->__SetLayout();

	# EVENTS

	$self->{"onRowChanged"} = Event->new();

	return $self;
}
#
#sub SetPolarity {
#	my $self = shift;
#	my $val  = shift;
#
#	my @rows = $self->GetAllRows();
#
#	foreach my $r (@rows) {
#
#		$r->SetPolarity($val);
#	}
#}
#
#sub SetMirror {
#	my $self = shift;
#	my $val  = shift;
#
#	my @rows = $self->GetAllRows();
#
#	foreach my $r (@rows) {
#
#		$r->SetMirror($val);
#	}
#}
#
#sub SetComp {
#	my $self = shift;
#	my $val  = shift;
#
#	my @rows = $self->GetAllRows();
#
#	foreach my $r (@rows) {
#
#		$r->SetComp($val);
#	}
#}
#

sub SetConstraints {
	my $self   = shift;
	my @constraints = @{shift(@_)};
	my $constrGroup = shift;
	
	
	#create rows for each constraint
 
	foreach my $c (@constraints) {

		my $row = ConstraintListRow->new( $self, $c, $constrGroup->{$c->GetId()} );

		# zaregistrovat udalost
		#$self->{"onSelectedChanged"}->Add(sub{ $row->PlotSelectionChanged($self, @_) });
		
	 

		$row->{"onRowChanged"}->Add( sub { $self->{"onRowChanged"}->Do(@_) } );

		$self->AddRow($row);

	}
	
 

	$self->__OnSelectedChangeHandler();

	$self->{"szMain"}->Layout();
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );
	
	$self->SetBodyBackgroundColor( Wx::Colour->new( 255, 255, 255 ) );
	$self->SetHeaderBackgroundColor( Wx::Colour->new( 200, 200, 200 ) );



	# REGISTER EVENTS

	$self->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChangeHandler(@_) } );

	# BUILD LAYOUT STRUCTURE

}

sub __OnSelectedChangeHandler {
	my $self = shift;

	my @selectedConstr = ();

	foreach my $row ( $self->GetSelectedRows() ) {

		push( @selectedConstr, $row->GetRowText() );
	}

	my @rows = $self->GetAllRows();

	foreach my $r (@rows) {
		$r->ConstrSelectionChanged( \@selectedConstr );
	}

	print STDERR "test";

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

