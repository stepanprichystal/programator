#-------------------------------------------------------------------------------------------#
# Description:  Display constraints
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
	my @widths = ( 45		, 30  ,  40    , 250	      ,  100         , 150             ,  150          , 100        , 1000             );
	my @titles = ( "Include", "Id", "Group","Type + model",  "Test layer", "Top ref layer", "Bot ref layer", "Impedance"  );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, , Enums->Mode_CHECKBOX, $columnCnt, $columnWidths, $verticalLine, 2, 1 );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"inCAM"}  = $inCAM;
	$self->{"jobId"}  = $jobId;
	
	$self->{"constraintSet"} = 0;
	 
 
	$self->__SetLayout();

	# EVENTS

	$self->{"onGroupChanged"} = Event->new();

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
 
 
	
	#create rows for each constraint
 
	foreach my $c (@constraints) {

		my $row = ConstraintListRow->new( $self, $c );

		# zaregistrovat udalost
		#$self->{"onSelectedChanged"}->Add(sub{ $row->PlotSelectionChanged($self, @_) });
 
		$self->AddRow($row);
		
		$row->{"onGroupChanged"}->Add( sub { $self->{"onGroupChanged"}->Do($self, @_) } );
		

	}

	#$self->__OnSelectedChangeHandler();

	$self->{"szMain"}->Layout();
	
	$self->{"constraintSet"} = 1;
}

sub ConstraintsSet{
	my $self = shift;	
	
	return $self->{"constraintSet"};
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"},  Wx::Colour->new( 250, 250, 250 ));

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );
	
	$self->SetBodyBackgroundColor( Wx::Colour->new( 255, 255, 255 ) );
	$self->SetHeaderBackgroundColor( Wx::Colour->new( 127, 127, 127 ) );



	# REGISTER EVENTS

	#$self->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChangeHandler(@_) } );

	# BUILD LAYOUT STRUCTURE

}

#sub __OnSelectedChangeHandler {
#	my $self = shift;
#
#	my @selectedConstr = ();
#
#	foreach my $row ( $self->GetSelectedRows() ) {
#
#		push( @selectedConstr, $row->GetRowText() );
#	}
#
#	my @rows = $self->GetAllRows();
#
#	foreach my $r (@rows) {
#		$r->ConstrSelectionChanged( \@selectedConstr );
#	}
#
#	print STDERR "test";
#
#}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

