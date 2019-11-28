#-------------------------------------------------------------------------------------------#
# Description: App which automatically export mdi files of missing job
# Second purpose is delete old files (pcb are not in produce) from MDI folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::MdiDataApp::MdiDataApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;
 
#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use POSIX qw(strftime);
use List::MoreUtils qw(uniq);

#local library
#use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::MdiDataApp::Enums';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Enums'  => 'MdiEnums';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Helper' => 'MdiHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportFiles';
use aliased 'Packages::ItemResult::Enums' => "ItemResEnums";
use aliased 'Packages::TifFile::TifFile::TifFile';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_MDIDATA;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"} = undef;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {



		# 2) Load jobs to export MDI files
		my @jobs = $self->__GetPcb2Export();

		if ( scalar(@jobs) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			foreach my $jobId (@jobs) {

				$self->{"logger"}->info("Process job: $jobId");

				$self->__RunJob($jobId);
			}
		}

	};
	if ($@) {

		my $err = "Aplication: " . $self->GetAppName() . " exited with error: \n$@";
		$self->{"logger"}->error($err);
		$self->{"loggerDB"}->Error( undef, $err );
	}
}

sub __RunJob {
	my $self  = shift;
	my $jobId = shift;

	# DEBUG DELETE
	#$self->__ProcessJob($orderId);
	#return 0;
	# DEBUG DELETE

	eval {

		# run only if tif file exist (old jobs has not tif file)
		my $tif = TifFile->new($jobId);
		unless ( $tif->TifFileExist() ) {
			print STDERR "TIF file doesn't exist\n";
			$self->{"logger"}->error("TIF file doesn't exist");
			return 0;
		}

		$self->__ProcessJob($jobId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process job id: \"$jobId\" exited with error: \n $eStr";

		$self->__ProcessError( $jobId, $err );
		
		# parameter "wholesite" has to by set, unless it noesn't work out in windows service
		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1 ) ) {
 
  			
  			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "uncheckout", "ent_type" => "job" );	
			#$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );		
			$self->{"inCAM"}->COM( "close_job", "job" => "$jobId" );
		}
	}
}

## -----------------------------------------------
## Private method
##------------------------------------------------

sub __ProcessJob {
	my $self  = shift;
	my $jobId = shift;

	$jobId = lc($jobId);

	my $inCAM = $self->{"inCAM"};

	# 1) Open Job

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {
		$self->{"logger"}->debug("Job doesn't exist: $jobId");
		return 0;
	}

	$self->_OpenJob( $jobId, 1 );
	$self->{"logger"}->debug("After open job: $jobId");

	

	# 2) Export mdi files
 

	# getr dfault layer types to export
	my %mdiInfo = MdiHelper->GetDefaultLayerTypes( $inCAM, $jobId );

	# remove all job files
	my @f = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI, $jobId );

	foreach (@f) {
		unless ( unlink($_) ) {
			die "Can not delete mdi file $_.\n";
		}
	}

	# export
	my $export = ExportFiles->new( $inCAM, $jobId, "panel" );
	$export->{"onItemResult"}->Add( sub { $self->__OnExportLayer(@_) } );

	my @result = ();
	$self->{"errResults"} = \@result;

	$export->Run( \%mdiInfo );
	$self->{"logger"}->debug("After export mdi files: $jobId");

	# 3) save job
	$self->_CloseJob($jobId);

	# If error during export, send err log to db
	if ( @{ $self->{"errResults"} } ) {

		my $errMess = join( "\n ", @{ $self->{"errResults"} } );

		$self->__ProcessError( $jobId, $errMess );
	}

}

# handler for mdi export results
sub __OnExportLayer {
	my $self = shift;
	my $item = shift;

	if ( $item->Result() eq ItemResEnums->ItemResult_Fail ) {

		push( @{ $self->{"errResults"} }, $item->GetErrorStr() );
	}
}

# Return pcb which not contain gerbers or xml in MDI folders
sub __GetPcb2Export {
	my $self = shift;

	my @pcb2Export = ();

	my @pcbInProduc = $self->__GetPcbsInProduc();

	# all files from MDI folder
	my @xmlAll = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI, '.xml' );
	my @gerAll = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI, '.ger' );

	foreach my $jobId (@pcbInProduc) {

		my @xml = grep { $_ =~ /($jobId)[\w\d]+_mdi/i } @xmlAll;
		my @ger = grep { $_ =~ /($jobId)[\w\d]+_mdi/i } @gerAll;

		if ( scalar(@xml) == 0 ) {

			push( @pcb2Export, $jobId );

		}
		elsif ( scalar(@xml) ) {

			# check every xml, if there is gerber file of same name (if xml is order than 15 minutes)
			foreach my $xmlFile (@xml) {

				my $created = ( stat($xmlFile) )[9];

				if ( $created + 15 * 60 < time() ) {

					# chek if exist relevant gerber file
					my $gerFile = $xmlFile;
					$gerFile =~ s/\.xml/\.ger/;

					unless ( -e $gerFile ) {
						push( @pcb2Export, $jobId );
						last;
					}
				}
			}
		}
	}

	# limit if more than 30jobs, in order don't block  another service apps
	if ( scalar(@pcb2Export) > 30 ) {
		@pcb2Export = @pcb2Export[ 0 .. 29 ];    # oricess max 30 jobs
	}

	return @pcb2Export;
}


sub __GetPcbsInProduc {
	my $self = shift;

	my @pcbInProduc = HegMethods->GetPcbsInProduceMDI();        # get pcb "Ve vyrobe"

	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	return @pcbInProduc;
}

# store err to logs
sub __ProcessError {
	my $self    = shift;
	my $jobId   = shift;
	my $errMess = shift;

	print STDERR $errMess;

	# log error to file
	$self->{"logger"}->error($errMess);

	# sent error to log db
	$self->{"loggerDB"}->Error( $jobId, $errMess );

}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
	#
	#	print "ee";
}

1;

