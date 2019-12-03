#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::MISSING_JOBATTR;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use strict;
use warnings;
use DateTime;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Reorder::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $orderId     = $self->{"orderId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	my $nif = NifFile->new($jobId);

	# insert user name
	my $userName = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );

	if ( !defined $userName || $userName eq "" || $userName =~ /none/i ) {

		my $user = $nif->GetValue("zpracoval");

		if ( defined $user && $user ne "" ) {

			CamAttributes->SetJobAttribute( $inCAM, $jobId, "user_name", $user );
		}

	}

	# Check if tpv user is still in IS
	# (some user is necessary, because are listed in control pdf etc)
	if ( defined $userName && $userName ne "" ) {

		unless ( defined HegMethods->GetEmployyInfo($userName) ) {

			my @tpvUsers = HegMethods->GetTPVEmployee();

			my $randomLogin = $tpvUsers[ int( rand( scalar(@tpvUsers) ) ) ]->{"login_id"};

			CamAttributes->SetJobAttribute( $inCAM, $jobId, "user_name", $randomLogin );
		}
	}

	# insert pcb class

	my $pcbClass = CamJob->GetJobPcbClass( $inCAM, $jobId );

	if ( !defined $pcbClass || $pcbClass eq "" || $pcbClass < 3 ) {

		my $class = $nif->GetValue("kons_trida");

		if ( defined $class && $class >= 3 ) {

			CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class", $class );
		}
	}

	# insert mjissing pcb inner class
	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {

		my $pcbClassInner = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

		if ( !defined $pcbClassInner || $pcbClassInner eq "" || $pcbClassInner < 3 ) {

			my $class = CamJob->GetJobPcbClass( $inCAM, $jobId );

			if ( defined $class && $class >= 3 ) {

				CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class_inner", $class );
			}
		}
	}

	# Add gold holder attribut when galvanic gold
	if ( HegMethods->GetPcbSurface( $self->{"jobId"} ) =~ /g/i ) {

		my $goldHolder = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "goldholder" );    # zakaznicky panel

		# set attribute gold holder
		if ( !defined $goldHolder || $goldHolder ne "yes" ) {

			CamAttributes->SetJobAttribute( $inCAM, $jobId, "goldholder", "yes" );
		}
	}

	# Add customer panel for POOL jobs, if nasobnost_panelu exist in HEG
	my $multiplHeg   = HegMethods->GetInfoDimensions($jobId)->{"nasobnost_panelu"};
	my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );  # zakaznicky panel

	if ( HegMethods->GetOrderIsPool($orderId) && defined $multiplHeg && $multiplHeg ne "" && $multiplHeg != 0 && $custPnlExist ne "yes" ) {

		# get single dimension from
		die "Unable read single piece dimension from step o+1_single, because step doesn't exist."
		  unless ( CamHelper->StepExists( $inCAM, $jobId, "o+1_single" ) );

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "o+1_single" );

		CamJob->SetJobAttribute( $inCAM, 'customer_panel',   'yes',                              $jobId );
		CamJob->SetJobAttribute( $inCAM, 'cust_pnl_singlex', abs( $lim{"xMax"} - $lim{"xMin"} ), $jobId );
		CamJob->SetJobAttribute( $inCAM, 'cust_pnl_singley', abs( $lim{"yMax"} - $lim{"yMin"} ), $jobId );
		CamJob->SetJobAttribute( $inCAM, 'cust_pnl_multipl', $multiplHeg,                        $jobId );
	}

	# Update attribut "custom year" if exist "SICURIT customer"
	my %allAttr = CamAttributes->GetJobAttr( $inCAM, $jobId );

	if ( defined $allAttr{"custom_year"} ) {

		my $d = ( DateTime->now( "time_zone" => 'Europe/Prague' )->year() + 1 ) % 100;
		CamAttributes->SetJobAttribute( $inCAM, $jobId, "custom_year", $d );
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::MISSING_JOBATTR' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

