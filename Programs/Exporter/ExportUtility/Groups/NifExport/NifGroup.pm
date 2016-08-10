
#-------------------------------------------------------------------------------------------#
# Description: Export group for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup;
use base 'Programs::Exporter::ExportUtility::Groups::GroupBase';

use Class::Interface;
&implements('Programs::Exporter::ExportUtility::Groups::IGroup');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Export::NifExport::NifMngr';

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


	return $self;
}

 

sub Run {
	my $self = shift;
	
	my %exportData = %{$self->{"exportData"}};

	my $nifMngr = NifMngr->new($self->{"inCAM"}, $self->{"jobId"}, $exportData{"nifdata"});
	$nifMngr->{"onItemResult"}->Add(sub{ $self->_OnItemResultHandler(@_)});
	
	
	$nifMngr->Run();
}
 
 sub GetItemsCount {
	my $self = shift;

	#tems builder from dadta
	return -1;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

	my $jobId    = "f13610";
	my $stepName = "panel";

	my $inCAM = InCAM->new();
	 
	my %exportData = ();
	#dps
	$exportData{"nifdata"}{"zpracoval"} = "SPR";
	$exportData{"nifdata"}{"c_mask_colour"} = "zelena";
	$exportData{"nifdata"}{"s_mask_colour"} = "zelena";
	$exportData{"nifdata"}{"tenting"} = 0;
	
	#dimension
	$exportData{"nifdata"}{"single_x"} = "155.0";
	$exportData{"nifdata"}{"single_y"} = "162.0";
	$exportData{"nifdata"}{"panel_x"} = "";
	$exportData{"nifdata"}{"panel_y"} = "";
	$exportData{"nifdata"}{"nasobnost_panelu"} = "0";
	$exportData{"nifdata"}{"nasobnost"} = "2";

	#other
	$exportData{"nifdata"}{"poznamka"} = "Test poznamka";
	$exportData{"nifdata"}{"rel(22305,L"} = "Test poznamka";
	$exportData{"nifdata"}{"merit_presfitt"} = 0;


	my $group = Nif_Group->new( $inCAM, $jobId);
	$group->SetData( \%exportData );
	my $itemsCnt = $group->GetItemsCount();


	#my $builder = $group->GetResultBuilder();
	$group->{"onItemResult"}->Add( sub { Test(@_) } );

	$group->Run();

	

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

