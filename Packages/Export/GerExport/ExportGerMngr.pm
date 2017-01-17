
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportGerMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"exportLayers"} = shift;
	$self->{"layers"}       = shift;

	return $self;
}

sub Run {
	my $self = shift;

	unless($self->{"exportLayers"}){
		return 0;
	}

	$self->__Export();
}

sub __Export {
	my $self = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step = "panel";
	
	# remove layers, which has plot= 0;
	@{$self->{"layers"}} = grep {$_->{"plot"}} @{$self->{"layers"}};
	 

	my $archive     = JobHelper->GetJobArchive($jobId);
	my $output      = JobHelper->GetJobOutput($jobId);
	my $archivePath = $archive . "zdroje";

	#delete old ger form archive
	my @filesToDel = FileHelper->GetFilesNameByPattern( $archivePath, ".ger" );

	foreach my $f (@filesToDel) {
		unlink $f;
	}

	# function, which build output layer name, based on layer info
	my $suffixFunc = sub {

		my $l = shift;

		my $suffix = "_komp" . abs($l->{"comp"}) . "um-.ger"; # if negative comp, remove minus

		if ( $l->{"polarity"} eq "negative" ) {
			$suffix = "n" . $suffix;
		}

		return $suffix;
	};

	my $resultItemGer = $self->_GetNewItem("Single layers");
	
	Helper->ExportLayers( $resultItemGer, $inCAM,  $step, $self->{"layers"}, $archivePath, $jobId, $suffixFunc );

	$self->_OnItemResult($resultItemGer);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

