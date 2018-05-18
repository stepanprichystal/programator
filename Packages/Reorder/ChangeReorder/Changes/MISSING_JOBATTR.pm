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

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Connectors::HeliosConnector::HegMethods';

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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $nif = NifFile->new($jobId);

	# insert user name
	my $userName = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );

	if ( !defined $userName || $userName eq "" || $userName =~ /none/i ) {

		my $user = $nif->GetValue("zpracoval");

		if ( !defined $user || $user eq "" ) {
			die "User is not defined in nif";
		}

		CamAttributes->SetJobAttribute( $inCAM, $jobId, "user_name", $user );
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

		if ( !defined $class || $class < 3 ) {
			die "Pcb class is not defined in nif";
		}

		CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class", $class );
	}

	# insert mjissing pcb inner class
	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {
		
		my $pcbClassInner = CamJob->GetJobPcbClassInner( $inCAM, $jobId );

		if ( !defined $pcbClassInner || $pcbClassInner eq "" || $pcbClassInner < 3 ) {

			my $class = $pcbClass;

			if ( !defined $class || $class < 3 ) {
				die "Unable to set constructor inner class, because outer construction class is not known.";
			}

			CamAttributes->SetJobAttribute( $inCAM, $jobId, "pcb_class_inner", $class );
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

