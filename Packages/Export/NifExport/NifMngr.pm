
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');


#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Export::NifExport::NifSection';
use aliased 'Packages::Export::NifExport::NifBuilders::V0Builder';
use aliased 'Packages::Export::NifExport::NifBuilders::V1Builder';
use aliased 'Packages::Export::NifExport::NifBuilders::V2Builder';
use aliased 'Packages::Export::NifExport::NifBuilders::VVBuilder';
use aliased 'Packages::Export::NifExport::NifBuilders::PoolBuilder';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"nifData"} = shift;
	
	 
	my @sections = ();
	$self->{"sections"} = \@sections;

	my @rowResults = ();
	$self->{"rowResults"} = \@rowResults;

	# get layer cnt
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	 
	return $self;
}

# Choose souitable nif builder, by tzpe of pcb
# Every builder create sligtly different NIF file
sub Run {
	my $self = shift;

	# TODO smayat
	my $test = $self->{"inCAM"}->COM("set_step", "name"=> "1");

	#information necessary for making decision which nif builder use
	my $typeCu   = CamHelper->GetPcbType( $self->{"inCAM"}, $self->{"jobId"} );
	my $isPool   = HegMethods->GetPcbIsPool( $self->{"jobId"} );
	my $pnlExist = CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "panel" );

	if ( $isPool && !$pnlExist ) {

		$self->{"nifBuilder"} = PoolBuilder->new();
	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_NOCOPPER ) {

		$self->{"nifBuilder"} = V0Builder->new();

	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_ONELAYER ) {

		$self->{"nifBuilder"} = V1Builder->new();
	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_TWOLAYER ) {

		$self->{"nifBuilder"} = V2Builder->new();

	}
	elsif ( $typeCu eq EnumsGeneral->PcbTyp_MULTILAYER ) {

		$self->{"nifBuilder"} = VVBuilder->new();

	}

	$self->{"nifBuilder"}->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"nifData"} );
	$self->{"nifBuilder"}->Build($self);

	$self->__Save();

}

# Add new  section in NIF file
sub AddSection {
	my $self       = shift;
	my $name       = shift;
	my $secBuilder = shift;

	#new section object
	my $sec = NifSection->new($name);

	#add handler for item result
	$sec->{"onRowResult"}->Add( sub { $self->__ResultAddRowError(@_) } );

	#save new section object
	push( @{ $self->{"sections"} }, $sec );

	$secBuilder->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"nifData"}, $self->{"layerCnt"} );

	#buil section
	$secBuilder->Build($sec);

	return $sec;
}

# Save built NIF to job archive
sub __Save {
	my $self = shift;

	my @sections = @{ $self->{"sections"} };

	my @nif      = ();
	my $saveSucc = 0;

	 
	#join all nif section and ther rows
	foreach my $sec (@sections) {

		my $titleLen = length($sec->GetName());
		my $fillCnt = int( ( 60 -  $titleLen) /2); #60 is requested total title len
		
		my $fill = "";
		
		for(my $i = 0; $i < $fillCnt; $i++){
			$fill .= "=";
		}
		

		push( @nif, "[$fill SEKCE " . $sec->GetName() . " $fill]\n" );

		foreach my $r ( $sec->GetRows() ) {

			push( @nif, $r . "\n" );
		}

		push( @nif, "\n" );
	}

	push( @nif, "complete=1\n" );

	my $path = JobHelper->GetJobArchive( $self->{"jobId"} );

	$path = $path . $self->{"jobId"} . ".nif";

	if ( -e $path ) {
		unlink($path);
	}

	my $nifFile;
	if ( open( $nifFile, "+>", $path ) ) {

		$saveSucc = 1;
		print $nifFile @nif;

	}
	else {
		$saveSucc = $_;

	}

	$self->__ResultNifCreation();
	$self->__ResultSaving($saveSucc);

}

sub __ResultSaving {
	my $self     = shift;
	my $saveSucc = shift;

	my $resultItem = $self->_GetNewItem("File save");

	unless ($saveSucc) {
		$resultItem->AddError( "Unable to save nif file. " . $saveSucc );
	}

	$self->_OnItemResult($resultItem);

}

sub __ResultAddRowError {
	my $self = shift;
	my $mess = shift;

	push( @{ $self->{"rowResults"} }, $mess );
}

sub __ResultNifCreation {
	my $self = shift;

	my $resultItem = $self->_GetNewItem("File build");

	foreach my $err ( @{ $self->{"rowResults"} } ) {

		$resultItem->AddError($err);
	}

	$self->_OnItemResult($resultItem);

}


sub ExportItemsCount{

		
				my $self = shift;
		
		my $totalCnt= 0;
		
		$totalCnt ++; #  nc merging
		
		
		
		$totalCnt ++; # variable cnt - nc exporting
		
		return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

