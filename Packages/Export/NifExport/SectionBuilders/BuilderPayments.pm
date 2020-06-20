
#-------------------------------------------------------------------------------------------#
# Description: Build section about general pcb information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderPayments;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;
use File::Find;
use Archive::Any;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my %nifData = %{ $self->{"nifData"} };

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	# 4007223 - panelizace

	if ( $self->_IsRequire("4007223") ) {

		$section->AddComment("Panelizace");

		my $panelizace = "4007223";

		my $exist = CamHelper->StepExists( $inCAM, $jobId, "o+1_single" );

		unless ($exist) {

			$panelizace = "-" . $panelizace;
		}

		$section->AddRow( "rel(22305,L)", $panelizace );
	}

	# 4007223 - frezovani pred prokovem

	if ( $self->_IsRequire("4010802") ) {

		$section->AddComment("Frezovani pred prokovem");

		my $platedMill = "4010802";

		my $exists = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		unless ($exists) {

			$platedMill = "-" . $platedMill;
		}

		$section->AddRow( "rel(22305,L)", $platedMill );
	}

	# 4115894 - drazkovani

	if ( $self->_IsRequire("4115894") ) {

		$section->AddComment("Drazkovani");

		my $scoring = "4115894";

		my $exists = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_score );

		unless ($exists) {

			$scoring = "-" . $scoring;
		}

		$section->AddRow( "rel(22305,L)", $scoring );
	}

	# check inner layers
	my $unitRTM   = UniRTM->new( $inCAM, $jobId, "o+1", "f" );
	my @out       = $unitRTM->GetOutlineChainSeqs();
	my $extraMill = 0;

	if ( scalar(@out) == 1 ) {

		# check if there is inner rout
		my @inside = grep { $_->GetIsInside() } $unitRTM->GetChainSequences();
		$extraMill = 1 if ( scalar(@inside) );
	}
	elsif ( scalar(@out) > 1 ) {

		# more than one outline => it means extra milling
		$extraMill = 1;
	}

	# 4141429 - vnitrni freza 2vv

	if ( $self->_IsRequire("4141429") ) {

		$section->AddComment("Vnitrni frezovani 2VV");

		my $inLayer = "4141429";

		my $exists = 0;

		if ( !( $layerCnt == 2 && $extraMill ) ) {

			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer );
	}

	# 8364285 - vnitrni freza 4vv

	if ( $self->_IsRequire("8364285") ) {

		$section->AddComment("Vnitrni frezovani 4VV");

		my $inLayer = "8364285";
		my $exists  = 0;

		if ( !( $layerCnt == 4 && $extraMill ) ) {

			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer );
	}

	# 8364286 - vnitrni freza 6vv, 8vv

	if ( $self->_IsRequire("8364286") ) {

		$section->AddComment("Vnitrni frezovani 6VV, 8VV");

		my $inLayer = "8364286";
		my $exists  = 0;

		if ( !( $layerCnt > 4 && $extraMill ) ) {

			$inLayer = "-" . $inLayer;
		}

		$section->AddRow( "rel(22305,L)", $inLayer );
	}

	# 4007227 - jiny format dat
	 

	if ( $self->_IsRequire("4007227") ) {

		$section->AddComment("Jiny format dat");

		my $wrongFormat = "4007227";

 
		if (!defined $nifData{"wrongFormat"} || $nifData{"wrongFormat"} == 0) {
			$wrongFormat = "-" . $wrongFormat;
		}

		$section->AddRow( "rel(22305,L)", $wrongFormat );
	}

	# 4007224 - jine nazvy souboru

	if ( $self->_IsRequire("4007224") ) {

		$section->AddComment("Jine nazvy souboru");

		my $wrongNames = "4007224";

		my @gerbers = $self->__GetCustomerGer($jobId);    # get all cutomer gerbers, whic are not exported in lat 15 minutes (by tpv)

		# if exist gerber files, check right format
		# there must be at least top or bot file (some 2v POOL are created from 1v source data)

		my $gerbersOk = 1;

		# Do check on proper gerbers only if data format is ok
		if ( (!defined $nifData{"wrongFormat"} || $nifData{"wrongFormat"} == 0) && scalar(@gerbers) ) {

			my $topExist = scalar( grep { $_ =~ /\.top$|top\.[(gbr)(ger)]/si } @gerbers );
			my $botExist = scalar( grep { $_ =~ /\.bot$|bot\.[(gbr)(ger)]/si } @gerbers );

			if ( !$topExist && !$botExist ) {
				$gerbersOk = 0;
			}
		}

		if ($gerbersOk) {
			$wrongNames = "-" . $wrongNames;
		}

		$section->AddRow( "rel(22305,L)", $wrongNames );
	}
}

sub __GetCustomerGer {
	my $self  = shift;
	my $jobId = shift;

	my @gerbers = ();

	my $location = EnumsPaths->Client_PCBLOCAL . "\\$jobId";

	unless ( -e $location ) {
		
		my $prevLoc = $location;
		$location =   JobHelper->GetJobArchive($jobId) . "zdroje\\data";
		
		unless (-e $location){
			
			print STDERR "Job customer data doesn't exist neither at $location nor at $prevLoc";
			return @gerbers;
			
		}
	}

	sub __Find {
		my $fPath = $File::Find::name;
		my $fname = $_;

		my $gerbers = ${ $_[0] }{"gerbers"};

		#get file attributes
		my @stats = stat($fPath);

		# if gerbers are younger than 15 minutes, it means TPV created this gerbers
		# Not customer data
#		if ( ( time() - $stats[9] ) < 900 ) {
#
#			return 0;
#		}

		if ( open( my $f, "<", $fPath ) ) {

			while ( my $l = <$f> ) {

				if ( $l =~ /%add|%lpd|%moin|g75\*/i ) {

					push( @{$gerbers}, $fname );
					last;
				}

			}
			close($f);
		}
	}

	find( sub { __Find( { "gerbers" => \@gerbers } ); }, $location );

	return @gerbers;
}

#sub __GetAllCustomerFiles {
#	my $self  = shift;
#	my $jobId = shift;
#
#	my @files = ();
#
#	my $location = EnumsPaths->Client_PCBLOCAL . "\\$jobId";
#
#	unless ( -e $location ) {
#		die "Job customer doesn't exist at $location";
#	}
#
#	sub __Find2 {
#		my $fPath = $File::Find::name;
#		my $files = ${ $_[0] }{"files"};
#
#		#get file attributes
#		my @stats = stat($fPath);
#
#		# if gerbers are younger than 15 minutes, it means TPV created this gerbers
#		# Not customer data
#		if ( ( time() - $stats[9] ) < 900 ) {
#			return 0;
#		}
#
#		push( @{$files}, $fPath );
#	}
#
#	find( sub { __Find2( { "files" => \@files } ); }, $location );
#
#	return @files;
#}
#
#sub __ODBExist {
#	my $self  = shift;
#	my $jobId = shift;
#
#	my $tgzExist = 0;
#
#	my @allFiles = $self->__GetAllCustomerFiles($jobId);
#
#	# test if exist TGZ files
#
#	if ( scalar( grep { $_ =~ /\.tgz/i } @allFiles ) ) {
#
#		$tgzExist = 1;
#	}
#
#	# test if exist extraced tgz file
#	elsif ( scalar( grep { $_ =~ /steps\/?$/i } @allFiles ) ) {
#
#		$tgzExist = 1;
#	}
#
#	# if there is no standard tgz, find tgz in all zip or already extracted tgz
#	else {
#
#		foreach my $file (@allFiles) {
#
#			#  test if it is archive and find dir "steps" inside
#			my $archive = Archive::Any->new($file);
#
#			unless ( defined $archive ) {
#				next;
#			}
#
#			my @files = $archive->files();
#
#			my $stepsDir = scalar( grep { $_ =~ /steps\/?$/i } @files );
#
#			if ($stepsDir) {
#				$tgzExist = 1;
#				last;
#			}
#		}
#
#	}
#
#	return $tgzExist;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

