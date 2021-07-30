
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::PreviewSize;
use base('Programs::Panelisation::PnlCreator::SizePnlCreator::SizeCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::Enums' => 'HegEnums';
use aliased 'Connectors::SqlParameter';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->SizePnlCreator_PREVIEW;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"srcJobId"}         = undef;
	$self->{"settings"}->{"srcJobByOffer"}    = undef;
	$self->{"settings"}->{"srcJobListByName"} = [];
	$self->{"settings"}->{"srcJobListByNote"} = [];
	$self->{"settings"}->{"panelJSON"}        = undef;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;
	my $srcJobId = shift;

	my $result = 1;

	$self->_Init( $inCAM, $stepName );

	# Try to get list of former orders
	my $jobId = $self->{"jobId"};

	# Check PCB offer
	my $info = ( HegMethods->GetAllByPcbId($jobId) )[0];
	if ( defined $info->{"dn_reference_subjektu"} && $info->{"dn_reference_subjektu"} =~ /^\w\d{6}/i ) {
		
			$self->SetSrcJobByOffer( $info->{"dn_reference_subjektu"} );
	}

	# Check TPV note if there is reference job id

	my @params = ( SqlParameter->new( "_PcbId", HegEnums->SqlDbType_VARCHAR, $jobId ) );

	my $cmd = "select top 1
				 	d.poznamka_tpv
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050";

	my $tpvNote = HegMethods->CustomSQLExecuteScalar( $cmd, \@params );

	if ( defined $tpvNote ) {

		if (    $tpvNote =~ /minul.*\s*verz/i
			 || $tpvNote =~ /nov.*verz/i
			 || $tpvNote =~ /p.*ede.*l.*verz/i
			 || $tpvNote =~ /p.*edcho.*verz/i )
		{

			if ( $tpvNote =~ m/(\w\d{5,6})/i ) {

				my $noteJobId = $1;
				$noteJobId = lc($noteJobId);

				my $noteInfo = HegMethods->GetBasePcbInfo($noteJobId);
				my $info = { "jobId" => uc($noteJobId), "jobName" => $noteInfo->{"nazev_subjektu"} };

				$self->SetSrcJobListByNote( [$info] );

			}
		}
	}

	# Check if exist jobs with similar name if not job in TPV note
	unless ( scalar( @{ $self->GetSrcJobListByNote() } ) ) {

		my $customerInfo = HegMethods->GetCustomerInfo($jobId);

		if ( defined $customerInfo->{"reference_subjektu"} ) {

			my $pcbInfo = HegMethods->GetBasePcbInfo($jobId);
			my $pcbName = $pcbInfo->{"nazev_subjektu"};

			my @jobsByNote = ();

			my $nameCnt = length($pcbName);

			while ( length($pcbName) > $nameCnt / 2 ) {

				my @params = ();
				push( @params, SqlParameter->new( "__CustReference", HegEnums->SqlDbType_VARCHAR, $customerInfo->{"reference_subjektu"} ) );
				push( @params, SqlParameter->new( "__Name",          HegEnums->SqlDbType_TEXT,    $pcbName ) );
				push( @params, SqlParameter->new( "__JobId",         HegEnums->SqlDbType_VARCHAR, uc($jobId) ) );

				my $cmd = "select distinct 
						d.reference_subjektu AS jobId,
						d.nazev_subjektu AS jobName
				   from lcs.desky_22 d with (nolock)
				 		left outer join lcs.subjekty c with (nolock) on c.cislo_subjektu=d.zakaznik
				 		left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
					WHERE
						z.cislo_poradace = 22050  AND
					    c.reference_subjektu = __CustReference AND
						d.reference_subjektu <> __JobId AND
				 		d.nazev_subjektu LIKE '__Name%'  
				 	 ";

				my @jobs = HegMethods->CustomSQLExecuteDataset( $cmd, \@params );

				if ( scalar(@jobs) ) {

					push( @jobsByNote, @jobs );
				}

				if ( scalar(@jobsByNote) > 5 ) {
					last;
				}

				$pcbName = substr( $pcbName, 0, length($pcbName) - 1 );
			}

			# remove original jobId
			@jobsByNote = grep { $_->{"jobId"} ne $jobId } @jobsByNote;

			my %seen;
			my @uniqueJobs = grep { !$seen{ $_->{"jobId"} }++ } @jobsByNote;

			# sort
			@uniqueJobs = sort { $b->{"jobName"} <=> $a->{"jobName"} } @uniqueJobs;

			if ( scalar(@uniqueJobs) ) {

				$self->SetSrcJobListByName( \@uniqueJobs );
			}
		}
	}

	# Get dimension and borders if source job is known
	if ( defined $srcJobId && $srcJobId =~ /^\w\d{6}$/i ) {

		$self->SetSrcJobId($srcJobId);

		$srcJobId = lc($srcJobId);

		# Unarchive job
		my $acquireErr = "";
		my $jobExist = AcquireJob->Acquire( $inCAM, $srcJobId, \$acquireErr );

		if ($jobExist) {

			# open job
			CamHelper->OpenJob( $inCAM, $srcJobId, 1 );
			CamJob->CheckOutJob( $inCAM, $srcJobId );

			my $errCopyStep    = 0;
			my $errCopyStepTxt = "";

			if ( CamHelper->StepExists( $inCAM, $srcJobId, $stepName ) ) {

				# Set dimensions for GUI
				my %profLim = CamJob->GetProfileLimits2( $inCAM, $srcJobId, $stepName );
				my %areaLim = CamStep->GetActiveAreaLim( $inCAM, $srcJobId, $stepName );

				my $bL = abs( $profLim{"xMin"} - $areaLim{"xMin"} );
				my $bR = abs( $profLim{"xMax"} - $areaLim{"xMax"} );
				my $bT = abs( $profLim{"yMax"} - $areaLim{"yMax"} );
				my $bB = abs( $profLim{"yMin"} - $areaLim{"yMin"} );

				my $w = abs( $profLim{"xMax"} - $profLim{"xMin"} );
				my $h = abs( $profLim{"yMax"} - $profLim{"yMin"} );

				$self->SetWidth($w);
				$self->SetHeight($h);

				$self->SetBorderLeft($bL);
				$self->SetBorderRight($bR);
				$self->SetBorderTop($bT);
				$self->SetBorderBot($bB);

				# Set parsed profile data for crating panel

				my $pnlToJSON = PnlToJSON->new( $inCAM, $srcJobId, $stepName );

				my $errMessJSON = "";

				if ( $pnlToJSON->CheckBeforeParse( \$errMessJSON ) ) {

					my $JSON = $pnlToJSON->ParsePnlToJSON( 1, 1, 1, 1 );
					$self->SetPanelJSON($JSON);

				}
				else {

					$errCopyStep    = 1;
					$errCopyStepTxt = "Unable parse step: $stepName from source job: ${srcJobId}. Error during parsing step.";
					 
					$result = 0;
				}

			}
			else {
				$errCopyStep    = 1;
				$errCopyStepTxt = "Unable parse step: $stepName from source job: ${srcJobId}. Job doesn't contain this step.";
				 
				$result = 0;
			}

			# Close job
			CamJob->CheckInJob( $inCAM, $srcJobId );
			CamJob->CloseJob( $inCAM, $srcJobId );
			CamJob->CheckInJob( $inCAM, $jobId, 0 );    # Reopen jon

			if ($errCopyStep) {

				die $errCopyStepTxt;
			}

		}
		else {
			die "Unable parse step: $stepName from source job: ${srcJobId}. Job doesn't exist in InCAM database.";
			$result = 0;
		}
	}

	return $result;
}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	# Check if source job exist
	my $srcJob = $self->GetSrcJobId();

	if ( !defined $srcJob || $srcJob eq "" ) {

		$result = 0;
		$$errMess .= "Source job, which panel should be coppied from is not defined.\n";
	}
	elsif ( !CamJob->JobExist( $inCAM, $srcJob ) ) {

		$result = 0;
		$$errMess .= "Source job: $srcJob, doesn't exist in InCAM database.\n";

	}
	else {

		# Check if JSON exist
		my $JSON = $self->GetPanelJSON();

		if ( !defined $JSON || $JSON eq "" ) {

			$result = 0;
			$$errMess .= "Source job panel dimension was not properly parsed.\n";
		}

	}

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	# Process base class

	# Process specific
	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
	$pnlToJSON->CreatePnlByJSON( $self->GetPanelJSON(), 1, 1 );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobId"} = $val;
}

sub GetSrcJobId {
	my $self = shift;

	return $self->{"settings"}->{"srcJobId"};
}

sub SetSrcJobByOffer {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobByOffer"} = $val;
}

sub GetSrcJobByOffer {
	my $self = shift;

	return $self->{"settings"}->{"srcJobByOffer"};
}

sub SetSrcJobListByName {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobListByName"} = $val;
}

sub GetSrcJobListByName {
	my $self = shift;

	return $self->{"settings"}->{"srcJobListByName"};
}

sub SetSrcJobListByNote {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobListByNote"} = $val;
}

sub GetSrcJobListByNote {
	my $self = shift;

	return $self->{"settings"}->{"srcJobListByNote"};
}

sub SetPanelJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"panelJSON"} = $val;

}

sub GetPanelJSON {
	my $self = shift;

	return $self->{"settings"}->{"panelJSON"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

