
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading information about TaskStatus
# By TaskStatus file we can decide, if job is tasked ok and if could be send to produce
# TaskStatus is file which contain name of task groups, and values
# if group has been tasked succes or not
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Task::TaskStatus::TaskStatus;

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased "Enums::EnumsPaths";
use aliased "Enums::EnumsGeneral";
use aliased "Helpers::FileHelper";
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
 
	$self->{"filePath"} = shift;
	
	unless($self->{"filePath"}){
		$self->{"filePath"} =   EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
	}
 

	return $self;
}

sub IsTaskOk {
	my $self = shift;
	my $notTasked = shift;

	my %hashKeys = $self->__ReadTaskStatus();

	my $statusOk = 1;

	foreach my $k ( keys %hashKeys ) {

		if ( $hashKeys{$k} == 0 ) {
			
			push(@{$notTasked}, $k );
			
			$statusOk = 0;
			 
		}

	}

	return $statusOk;

}

sub DeleteStatusFile {
	my $self = shift;

	if ( -e $self->{"filePath"} ) {

		unlink( $self->{"filePath"} );
	}

}

sub CreateStatusFile {
	my $self = shift;
	my @keys = @{shift(@_)};

	# test if file already exist
	if ( -e $self->{"filePath"} ) {
		return 1;
	}

	#my $builder = TaskStatusBuilder->new();
	#my @keys    = $builder->GetStatusKeys($self);

	my %hashKeys = ();

	# create hash from keys
	foreach my $k (@keys) {

		$hashKeys{$k} = 0;
	}

	$self->__SaveTaskStatus( \%hashKeys );
}

sub UpdateStatusFile {
	my $self         = shift;
	my $unitKey      = shift;
	my $taskResult = shift;

	my $result = 0;

	if ( $taskResult eq EnumsGeneral->ResultType_OK ) {
		$result = 1;
	}
	elsif ( $taskResult eq EnumsGeneral->ResultType_FAIL ) {
		$result = 0;
	}

	my %hashKeys = $self->__ReadTaskStatus();

	$hashKeys{$unitKey} = $result;

	$self->__SaveTaskStatus( \%hashKeys );
}

sub __SaveTaskStatus {
	my $self     = shift;
	my %hashData = %{ shift(@_) };

	my $json = JSON->new();

	my $serialized = $json->pretty->encode( \%hashData );

	#delete old file
	unlink $self->{"filePath"};

	open( my $f, '>', $self->{"filePath"} );
	print $f $serialized;
	close $f;
}

sub __ReadTaskStatus {
	my $self = shift;

	# read from disc
	# Load data from file
	my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );

	my $json = JSON->new();

	my $hashData = $json->decode($serializeData);

	return %{$hashData};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::AbstractQueue::TaskChecker::TaskChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

