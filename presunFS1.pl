
use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Managers::MessageMngr::MessageMngr';
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use aliased 'Enums::EnumsGeneral';
use File::Basename;
use aliased 'Helpers::FileHelper';
use File::Copy;
use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';

my $jobIdStr = 0;

my $frm = SimpleInputFrm->new( -1, "kopirovani dat jobu mezi deiskem FS1 <=> R", "job id", \$jobIdStr );

$frm->ShowModal();

$jobIdStr =~ s/\s//g;

my @jobIds = split(";", $jobIdStr);

foreach my $jobId (@jobIds) {

	if ( !defined $jobId || $jobId eq "" || $jobId !~ /\w\d/i ) {

		die "wrong  format of job id";
	}
}

my $messMngr = MessageMngr->new("test");

my @mess1 = ("Vyber odkud kam kopirovat data jobu.");

my @btn = ( "\"R\" docasne =>  \"fs1.gatema.cz\"", "  \"fs1.gatema.cz\" => \"R\" docasne" );
$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess1, \@btn );

my $res = $messMngr->Result();

foreach my $jobId (@jobIds) {

	Copy( $jobId, $res );
}

sub Copy {
	my $jobId = shift;
	my $res   = shift;

	use constant {

		Jobs_ARCHIV     => "\\\\gatema.cz\\fs\\r\\Archiv\\",
		Jobs_STACKUPS   => "\\\\gatema.cz\\fs\\r\\PCB\\pcb\\VV_slozeni\\",
		Jobs_PCBMDI     => "\\\\gatema.cz\\fs\\r\\pcb\\mdi\\",
		Jobs_MDI        => "\\\\gatema.cz\\fs\\r\\mdi\\",
		Jobs_JETPRINT   => "\\\\gatema.cz\\fs\\r\\potisk\\",
		Jobs_ELTESTS    => "\\\\gatema.cz\\fs\\EL_DATA\\",
		Jobs_ELTESTSIPC => "\\\\gatema.cz\\fs\\r\\El_tests\\"

	};

	use constant {

		# docana zmena
		cache_Jobs_ARCHIV     => "\\\\fs1.gatema.cz\\ps_data\\r\\Archiv\\",
		cache_Jobs_STACKUPS   => "\\\\fs1.gatema.cz\\ps_data\\r\\PCB\\pcb\\VV_slozeni\\",
		cache_Jobs_PCBMDI     => "\\\\fs1.gatema.cz\\ps_data\\r\\pcb\\mdi\\",
		cache_Jobs_MDI        => "\\\\fs1.gatema.cz\\ps_data\\r\\mdi\\",
		cache_Jobs_JETPRINT   => "\\\\fs1.gatema.cz\\ps_data\\r\\potisk\\",
		cache_Jobs_ELTESTS    => "\\\\fs1.gatema.cz\\EL_DATA\\",
		cache_Jobs_ELTESTSIPC => "\\\\fs1.gatema.cz\\ps_data\\r\\El_tests\\"
	};

	# R na W
	if ( $res == 0 ) {

		my $cacheArchiv = GetJobArchive( $jobId, cache_Jobs_ARCHIV );
		my $archiv      = GetJobArchive( $jobId, Jobs_ARCHIV );

		# copy archive data
		my $copyCnt = dircopy( $archiv, $cacheArchiv );

		# copy mdi

		my @mdi = FileHelper->GetFilesNameByPattern( Jobs_MDI, "$jobId" );

		foreach my $f (@mdi) {

			my $fileName = basename($f);

			copy( $f, cache_Jobs_MDI . $fileName );
		}

		# copy  jetprint
		my @jetPrint = FileHelper->GetFilesNameByPattern( Jobs_JETPRINT, "$jobId" );

		foreach my $f (@jetPrint) {

			my $fileName = basename($f);

			copy( $f, cache_Jobs_JETPRINT . $fileName );
		}

		# copy  stackup
		my @stackup = FileHelper->GetFilesNameByPattern( Jobs_STACKUPS, "$jobId" );

		foreach my $f (@stackup) {

			my $fileName = basename($f);

			copy( $f, cache_Jobs_STACKUPS . $fileName );
		}

	}
	else {

		my $cacheArchiv = GetJobArchive( $jobId, cache_Jobs_ARCHIV );
		my $archiv      = GetJobArchive( $jobId, Jobs_ARCHIV );

		my $aRoot = GetJobArchiveRoot( $jobId, Jobs_ARCHIV );
		unless ( -e $aRoot ) {
			mkdir($aRoot) or die "Can't create dir: " . $aRoot . $_;
		}

		# copy archive data
		my $copyCnt = dircopy( $cacheArchiv, $archiv );

		# copy  stackup
		my @stackup = FileHelper->GetFilesNameByPattern( cache_Jobs_STACKUPS, "$jobId" );

		foreach my $f (@stackup) {

			my $fileName = basename($f);

			copy( $f, Jobs_STACKUPS . $fileName );
		}
	}

}

sub GetJobArchive {
	my $jobId = shift;
	my $path  = shift;
	
	$jobId = uc($jobId);

	return $path . substr( $jobId, 0, 3 ) . "\\" . $jobId . "\\";

}

sub GetJobArchiveRoot {
	my $jobId = shift;
	my $path  = shift;
	
	$jobId = uc($jobId);

	return $path . substr( $jobId, 0, 3 ) . "\\";

}

