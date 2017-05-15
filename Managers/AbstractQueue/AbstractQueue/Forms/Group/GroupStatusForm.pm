#-------------------------------------------------------------------------------------------#
# Description: Form which is placed in header of GroupWrapperForm
# Display actual state of group, like "Exporting", ...And display errors during tasking
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Managers::AbstractQueue::AbstractQueue::Forms::Group::GroupStatusForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Managers::AsyncJobMngr::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 100, 25 ] );

	$self->{"jobId"}           = shift;
	$self->{"resultItemMngr"}  = shift;
	$self->{"resultGroupMngr"} = shift;

	bless($self);

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	$self->SetBackgroundColour( AppConf->GetColor("clrGroupStatus") );    #gray

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $statusTxt = Wx::StaticText->new( $self, -1, "", [ -1, -1 ], [ 100, 20 ] );
	$statusTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # light gray

	my $groupErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"} );
	my $groupWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"} );
	$groupErrInd->Hide();
	$groupWarnInd->Hide();

	$groupErrInd->AddMenu();
	$groupErrInd->AddMenuItem( "Group", $self->{"resultGroupMngr"} );
	$groupErrInd->AddMenuItem( "Items", $self->{"resultItemMngr"} );

	$groupWarnInd->AddMenu();
	$groupWarnInd->AddMenuItem( "Group", $self->{"resultGroupMngr"} );
	$groupWarnInd->AddMenuItem( "Items", $self->{"resultItemMngr"} );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $statusTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $groupErrInd,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $groupWarnInd, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"groupErrInd"}  = $groupErrInd;
	$self->{"groupWarnInd"} = $groupWarnInd;
	$self->{"statusTxt"}    = $statusTxt;
	$self->{"szMain"}       = $szMain;
}

sub SetStatus {
	my $self  = shift;
	my $value = shift;

	$self->{"statusTxt"}->SetLabel($value);
}

sub SetErrorCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupErrInd"}->SetErrorCnt($cnt);

	if ( $cnt > 0 ) {
		$self->{"groupErrInd"}->Show(1);
		$self->__SetColor("red");

	}
	else {
		$self->{"groupErrInd"}->Show(0);
	}

	#$self->{"szMain"}->Layout();

}

sub SetWarningCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupWarnInd"}->SetErrorCnt($cnt);

	if ( $cnt > 0 ) {
		$self->{"groupWarnInd"}->Show(1);

		if ( $self->{"resultItemMngr"}->GetErrorsCnt() == 0 && $self->{"resultGroupMngr"}->GetErrorsCnt() == 0 ) {
			$self->__SetColor("yellow");
		}
		else {
			$self->__SetColor("red");
		}

	}
	else {
		$self->{"groupWarnInd"}->Show(0);
	}

	#$self->{"szMain"}->Layout();
}

sub SetResult {
	my $self   = shift;
	my $result = shift;

	if ( $result eq EnumsGeneral->ResultType_OK ) {

		$self->__SetColor("green");

	}
	elsif ( $result eq EnumsGeneral->ResultType_FAIL ) {

		if ( $self->{"resultItemMngr"}->GetErrorsCnt() == 0 && $self->{"resultGroupMngr"}->GetErrorsCnt() == 0 ) {
			
			$self->__SetColor("yellow");
		}
		else {
			
			$self->__SetColor("red");
		}
	}

	$self->{"statusTxt"}->SetLabel("");

}

sub Clear {
	my $self = shift;

	$self->__SetColor("default");

	$self->SetErrorCnt(0);
	$self->SetWarningCnt(0);

}

sub __SetColor {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "green" ) {

		$self->SetBackgroundColour( Wx::Colour->new( 193, 240, 193 ) );    #green

	}
	elsif ( $color eq "red" ) {

		$self->SetBackgroundColour( Wx::Colour->new( 255, 204, 204 ) );    #red
	}
	elsif ( $color eq "yellow" ) {

		$self->SetBackgroundColour( Wx::Colour->new( 255, 242, 155 ) );    #red
	}
	elsif ( $color eq "default" ) {

		$self->SetBackgroundColour( AppConf->GetColor("clrGroupStatus") );    # light gray
	}

	$self->Refresh();
}

1;
