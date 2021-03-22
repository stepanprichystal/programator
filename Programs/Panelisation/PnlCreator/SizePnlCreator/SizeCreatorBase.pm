
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::SizeCreatorBase;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

#3th party library
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpPrepareData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpExportData';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::View::ImpUnitForm';

#use aliased 'Programs::Panelisation::PnlWizard::Enums';

use aliased 'Packages::CAMJob::Panelization::SRStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = shift;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"width"}       = undef;
	$self->{"settings"}->{"height"}      = undef;
	$self->{"settings"}->{"borderLeft"}  = undef;
	$self->{"settings"}->{"borderRight"} = undef;
	$self->{"settings"}->{"borderTop"}   = undef;
	$self->{"settings"}->{"borderBot"}   = undef;

	return $self;    # Return the reference to the hash.
}

sub _Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $result = 1;

	$self->{"settings"}->{"step"} = $stepName;

	return $result;

}

sub _Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;

	my $result = 1;

	my $w  = $self->GetWidth();
	my $h  = $self->GetHeight();
	my $bL = $self->GetBorderLeft();
	my $bR = $self->GetBorderRight();
	my $bT = $self->GetBorderTop();
	my $bB = $self->GetBorderBot();

	if ( !defined $w || !looks_like_number($w) || $w <= 0 ) {

		$result = 0;
		$$errMess .= "Panel width is not set.\n";
	}

	if ( !defined $h || !looks_like_number($h) || $h <= 0 ) {

		$result = 0;
		$$errMess .= "Panel height is not set.\n";
	}

	if (    !defined $bL
		 || !defined $bR
		 || !defined $bT
		 || !defined $bB
		 || !looks_like_number($bL)
		 || !looks_like_number($bR)
		 || !looks_like_number($bT)
		 || !looks_like_number($bB) )
	{

		$result = 0;
		$$errMess .= "Not all panel borders are defined (border must be number  >= 0).\n";
	}

	return $result;

}

# Return 1 if succes 0 if fail
sub _Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};

	$self->_CreateStep($inCAM);

	my $step = SRStep->new( $inCAM, $jobId, $self->GetStep() );

	#	my %p = ("x"=> -10, "y" => -20);
	$step->Edit( $self->GetWidth(),     $self->GetHeight(),
				   $self->GetBorderTop(), $self->GetBorderBot(), $self->GetBorderLeft(), $self->GetBorderRight() );

	#	my $control = SRStep->new( $inCAM, $jobId, "test" );
	#	my %p = ("x"=> 10, "y" => +10);
	#	$control->Create( 300, 400, 10,10,10,10, \%p   );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"width"} = $val;
}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"width"};
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"height"} = $val;
}

sub GetHeight {
	my $self = shift;

	return $self->{"settings"}->{"height"};
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderLeft"} = $val;
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"settings"}->{"borderLeft"};
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderRight"} = $val;
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"settings"}->{"borderRight"};
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderTop"} = $val;
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"settings"}->{"borderTop"};
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderBot"} = $val;
}

sub GetBorderBot {
	my $self = shift;

	return $self->{"settings"}->{"borderBot"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

