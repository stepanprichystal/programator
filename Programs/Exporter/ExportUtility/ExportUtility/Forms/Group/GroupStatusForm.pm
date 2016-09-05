#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupStatusForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 100, 25 ] );

	bless($self);

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	$self->SetBackgroundColour( Wx::Colour->new( 204, 204, 204 ) );    #gray

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $statusTxt = Wx::StaticText->new( $self, -1, "Exporting", [ -1, -1 ], [ 100, 20 ] );

	my $groupErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15 );
	my $groupWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15 );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $statusTxt,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $groupErrInd, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $groupWarnInd, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"groupErrInd"}  = $groupErrInd;
	$self->{"groupWarnInd"} = $groupWarnInd;
	$self->{"statusTxt"}    = $statusTxt;
}

sub SetExporting {
	my $self  = shift;
	my $value = shift;

	$self->{"statusTxt"}->SetLabel("Exporting...");
}

sub SetErrorCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupErrInd"}->SetErrorCnt($cnt);

	if ( $cnt > 0 ) {
		$self->{"groupErrInd"}->Show(1);
	}

}

sub SetWarningCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupWarnInd"}->SetErrorCnt($cnt);

	if ( $cnt > 0 ) {
		$self->{"groupWarnInd"}->Show(1);
	}
}

sub SetResult {
	my $self   = shift;
	my $result = shift;

	if ( $result eq EnumsGeneral->ResultType_OK ) {

		$self->SetBackgroundColour( Wx::Colour->new( 152, 230, 152 ) );    #green

	}
	elsif ( $result eq EnumsGeneral->ResultType_FAIL ) {

		$self->SetBackgroundColour( Wx::Colour->new( 255, 102, 102 ) );    #green
	}
	
	$self->{"statusTxt"}->SetLabel("");
	$self->Refresh();

}

1;
