
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NCExport::NCGroup;
use base 'Programs::Exporter::ExportUtility::Groups::GroupBase';

use Class::Interface;
&implements('Programs::Exporter::ExportUtility::Groups::IGroup');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Packages::Export::NCExport::ExportMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Export::NCExport::FileHelper::Parser';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $groupId = __PACKAGE__;
	my $self = $class->SUPER::new($groupId,@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepName"} = "panel";

	#$self->_SetResultBuilder($builder);

	return $self;
}

sub Run {
	my $self = shift;

	my %exportData = %{ $self->{"exportData"} };

	my $exportMngr = ExportMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"},
									  $exportData{"exportSingle"},
									  $exportData{"pltLayers"},
									  $exportData{"npltLayers"});


	$exportMngr->{"onItemResult"}->Add(sub{ $self->_OnItemResultHandler(@_)});

	$exportMngr->Run();

	my @info = $exportMngr->GetNCInfo();
	$self->__SaveNcInfo( \@info );

}

sub GetItemsCount {
	my $self = shift;

	#tems builder from dadta

	return -1;
}

sub __SaveNcInfo {
	my $self = shift;
	my @info = @{ shift(@_) };

	my $path = JobHelper->GetJobArchive( $self->{"jobId"} ) . "nc\\nc_info.txt";

	open( FILE, ">", $path );

	for ( my $i = 0 ; $i < scalar(@info) ; $i++ ) {

		my %item = %{ $info[$i] };

		my @data = @{ $item{"data"} };

		if ( $item{"group"} ) {
			print FILE "\nSkupina operaci:\n";
		}
		else {
			print FILE "\nSamostatna operace:\n";
		}

		foreach my $item (@data) {

			my $row = "[ " . $item->{"name"} . " ] - ";

			my $mach = join( ", ", @{ $item->{"machines"} } );

			$row .= uc($mach) . "\n";

			print FILE $row;
		}

	}

	close(FILE);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCGroup';

	my $jobId    = "f13610";
	my $stepName = "panel";

	my $inCAM = InCAM->new();

	my @pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );

	#my @pltLayers1 = ();
#	foreach (@pltLayers) {
#
#		push( @pltLayers1, $_->{"name"} );
#	}

	my @npltLayers = CamDrilling->GetNPltNCLayers( $inCAM, $jobId );
#	my @npltLayers1 = ();
#	foreach (@npltLayers) {
#
#		push( @npltLayers1, $_->{"name"} );
#	}

	#@pltLayers1  = ("s1c12");
	#@npltLayers1 = ();

	my %exportData = ();
	$exportData{"exportSingle"} = 0;
	$exportData{"pltLayers"}    = \@pltLayers;
	$exportData{"npltLayers"}   = \@npltLayers;

	my $ncgroup = NCGroup->new( $inCAM, $jobId, );
	$ncgroup->SetData( \%exportData );
	my $itemsCnt = $ncgroup->GetItemsCount();

	my $builder = $ncgroup->GetResultBuilder();

	#print "Pocet polozek pro exportovani: $itemsCnt\n\n";

	$builder->{"onItemResult"}->Add( sub { Test(@_) } );

	$ncgroup->Run();

	sub Test {
		my $itemResult = shift;

		print " \n=============== Export task result: ==============\n";
		print "Task: " . $itemResult->ItemId() . "\n";
		print "Task result: " . $itemResult->Result() . "\n";
		print "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
		print "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";

	}

}

1;

