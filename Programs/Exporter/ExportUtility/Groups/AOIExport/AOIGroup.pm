
#-------------------------------------------------------------------------------------------#
# Description: Export group for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::AOIExport::AOIGroup;
use base 'Programs::Exporter::ExportUtility::Groups::GroupBase';

use Class::Interface;
&implements('Programs::Exporter::ExportUtility::Groups::IGroup');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::AOIExport::AOIMngr';

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

	my $etMngr = AOIMngr->new($self->{"inCAM"}, $self->{"jobId"}, $exportData{"stepToTest"});
	$etMngr->{"onItemResult"}->Add(sub{ $self->_OnItemResultHandler(@_)});
	
	
	$etMngr->Run();
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

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETGroup';

	my $jobId    = "f13610";
	my $stepName = "panel";

	my $inCAM = InCAM->new();
	 

}

1;

