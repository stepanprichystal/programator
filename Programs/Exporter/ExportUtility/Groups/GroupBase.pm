
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::GroupBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{'groupId'} = shift;
 	$self->__ParseGroupId($self->{'groupId'});
 	
	$self->{'onItemResult'} = Event->new();

	return $self;    # Return the reference to the hash.
}


# Take last name from whole package name
sub __ParseGroupId{
	my $self = shift;
	my $groupId = shift;
	
	unless($groupId){
		die "Child's 'GroupId' was not pass to base class constructor."
	}
	
	my @splitted = split("::", $groupId);
	
	$self->{'groupId'} = $splitted[scalar(@splitted)-1];

}

# Return gorup id. Id is package name of class which inherit from this class
sub GetGroupId{
	my $self = shift;
	
	return $self->{"groupId"};
}

sub SetData {
	my $self = shift;
	$self->{"exportData"} = shift;
}

#sub GetResultBuilder {
#	my $self = shift;
#
#	return $self->{"resBuilder"};
#
#}

#sub _SetResultBuilder{
#	my $self = shift;
#	my $builder = shift;
#
#	$self->{"resBuilder"}  = $builder;
#	$self->{"resBuilder"}->{"onItemResult"}->Add(sub { $self->__ItemResult(@_)});
#}

#
sub _OnItemResultHandler {
	my $self       = shift;
	my $itemResult = shift;
	
	
	#add group Id to item
	
	my $newId = $self->{'groupId'}."/".$itemResult->ItemId();
	$itemResult->SetItemId($newId);

	#raise onJobStarRun event
	my $onItemResult = $self->{'onItemResult'};
	if ( $onItemResult->Handlers() ) {
		$onItemResult->Do($itemResult);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

