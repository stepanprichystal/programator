
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifMngr;
use base('Packages::ItemResult::ItemResultMngr');

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
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';

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

	my $tmp = EnumsPaths->Client_INCAMTMPOTHER.$self->{"jobId"}."nif";

	if ( -e $tmp ) {
		unlink($tmp);
	}

	my $nifFile;
	if ( open( $nifFile, "+>", $tmp ) ) {

		$saveSucc = 1;
		
		#use Encode;
		
#		my @nif2 = ();
#		
#		foreach my $str (@nif){
#			print STDERR "before$str\n";
#			my $str2 = encode("cp1250", $str );
#			print STDERR "after$str2\n";
#			
#			print STDERR "before$str\n";
#			my $str3 = encode("cp1251", $str );
#			print STDERR "after$str3\n";
#			
#			
#			$str2 = $str;
#			
#			push(@nif2, $str2);
#			
#		}
		
		#$str = encode("cp1250", $str );
		
		
		print $nifFile @nif;
		
		close($nifFile);
		
		open my $IN, "<:encoding(utf8)", $tmp or die $!;
		open my $OUT, ">:encoding(cp1250)",$path or die $!;
		print $OUT $_ while <$IN>;
		close $IN;
		close $OUT;
		
		#my $f = FileHelper->ChangeEncoding( $path, "utf8", "cp1250" ); #change encoding because of diacritics and helios
		#unlink($path);
		
		#FileHelper->Copy($f, $path);
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

