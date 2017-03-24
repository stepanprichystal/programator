
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::RoutingMngr;
use base('Packages::ItemResult::ItemEventMngr');
 


#3th party library
use strict;
use warnings;
 

#local library

#use aliased 'Packages::Export::NifExport::NifSection';
#use aliased 'Packages::Export::NifExport::NifBuilders::V0Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V1Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V2Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::VVBuilder';
#use aliased 'Packages::Export::NifExport::NifBuilders::PoolBuilder';
#use aliased 'Helpers::JobHelper';
#use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::FileHelper';
use aliased 'Packages::ExportPool::Routing::StepList::StepList';
use aliased 'Packages::ExportPool::Routing::StepCheck::StepCheck';
use aliased 'Packages::ExportPool::Routing::RoutStart::RoutStart';
use aliased 'Packages::ItemResult::Enums' => "ResEnums";
use aliased 'Packages::ExportPool::Routing::ToolsOrder::ToolsOrder';

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
	 
	$self->{"stepList"} = StepList->new($self->{"inCAM"}, $self->{"jobId"}, "panel", "f"); 
	
	$self->{"stepCheck"} = StepCheck->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"stepList"}); 
	$self->{"routStart"} = RoutStart->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"stepList"}); 
	$self->{"toolsOrder"} = ToolsOrder->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"stepList"}); 
 
	return $self;
}

 
sub Run {
	my $self = shift;
	
	$self->{"stepList"}->Init();
	
 
	$self->__ProcessResult($self->{"stepCheck"}->OnlyBridges());
	
	$self->__ProcessResult($self->{"stepCheck"}->OutsideChains());
	
	$self->__ProcessResult($self->{"stepCheck"}->LeftRoutChecks());
	
	$self->__ProcessResult($self->{"stepCheck"}->OutlineToolIsLast());
	
	$self->__ProcessResult($self->{"routStart"}->FindStart());
	
	my %convTable1 = ();
	my %convTable2 = ();
	
	$self->__ProcessResult($self->{"routStart"}->CreateFsch(\%convTable1, \%convTable2));
 
 	$self->__ProcessResult($self->{"toolsOrder"}->SetInnerOrder(\%convTable1, \%convTable2));
 
  	$self->__ProcessResult($self->{"toolsOrder"}->SetOutlineOrder(\%convTable1, \%convTable2));
 
 
 	#$self->{"stepList"}->Clean();
 
}

sub Continue{
	my $self = shift;
	
	
}


sub __ProcessResult{
	my $self = shift;
	my $res = shift;
	
	
	unless( $res eq ResEnums->ItemResult_Fail ){
		
		if($res->GetWarningCount() > 0){
			
			print STDERR "Warning:\n\n".$res->GetWarningStr();
		}
		
		if($res->GetErrorCount() > 0){
			
			print STDERR "Errors:\n\n".$res->GetErrorStr();
		}
		  
	}
	
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ExportPool::Routing::RoutingMngr';
	use aliased 'Packages::InCAM::InCAM';
 

	my $inCAM = InCAM->new();

	my $jobId = "f52456";
	 
	
	my $routMngr = RoutingMngr->new($inCAM, $jobId);
	$routMngr->Run();

}

1;

