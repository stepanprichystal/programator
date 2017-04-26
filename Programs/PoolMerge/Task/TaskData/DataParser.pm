
#-------------------------------------------------------------------------------------------#
# Description: Class which prepare task data from pool xml file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::Task::TaskData::DataParser;

#3th party library
use strict;
use warnings;
use XML::Simple;
use List::MoreUtils qw(uniq);
use File::Basename;
use Storable qw(dclone);
use Digest::MD5;

#local library
use aliased 'Programs::PoolMerge::Task::TaskData::GroupData';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Programs::PoolMerge::Task::TaskData::TaskData';
use aliased 'Managers::AsyncJobMngr::Enums' => "EnumsJobMngr";
use aliased 'Programs::PoolMerge::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless($self);

	return $self;
}

sub GetTaskDataByString{
	my $self = shift;
	my $xmlString = shift;
	my $xmlName = shift;
	
	$self->__GetTaskData($xmlString, $xmlName);
 	
}


sub GetTaskDataByPath{
	my $self = shift;
	my $path = shift;
 
	
	my $xmlString = FileHelper->ReadAsString($path);
	my $xmlName = basename($path);
	
	$self->__GetTaskData($xmlString, $xmlName);
 	
}


sub __GetTaskData {
	my $self = shift;
	my $xmlString = shift;
	my $xmlName = shift;
	 
 
	# 1) init gorup data
	my $groupData = $self->__GetGroupData($xmlString);

	# 2) task data
	my $taskData = TaskData->new();

	my ( $sec, $min, $hour ) = localtime();
	my $time = sprintf( "%02d:%02d", $hour, $min );

	$taskData->{"settings"}->{"time"} = $time;
	$taskData->{"settings"}->{"mode"} = EnumsJobMngr->TaskMode_ASYNC;    # synchronousTask/ asynchronousTask

	# parse file name and store info
 
	my ( $panelName, $type, $surface, $exportTime ) = $xmlName =~ /(pan\d+)_([\d-]+)-(\w+)_([\d-]+)/;

	$panelName =~ s/pan/panel /i;

	$taskData->{"settings"}->{"panelName"}    = $panelName;
	$taskData->{"settings"}->{"poolType"}     = $type;
	$taskData->{"settings"}->{"poolSurface"}  = $surface;
	$taskData->{"settings"}->{"poolExported"} = $exportTime;

	my @mandatory = (UnitEnums->UnitId_CHECK, UnitEnums->UnitId_MERGE, UnitEnums->UnitId_ROUT, UnitEnums->UnitId_OUTPUT);
	#my @mandatory = ( UnitEnums->UnitId_MERGE  );
	$taskData->{"settings"}->{"mandatoryUnits"} = \@mandatory;              # units, which has to be processed

	for ( my $i = 0 ; $i < scalar(@mandatory) ; $i++ ) {

		my $unit = $mandatory[$i];
			
		my $gData = dclone($groupData);

		$taskData->{"units"}->{$unit} = $gData;

		$taskData->{"units"}->{$unit}->{"data"}->{"__UNITORDER__"} = $i

	}
	
 	

	return $taskData;

}

sub __GetGroupData {
	my $self = shift;
	#my $path = shift;
	my $stringXml = shift;
 
	# 1) open file

	#my $xmlF = FileHelper->Open($string);

	my $xml = XMLin(
		$stringXml,

		#ForceArray => 1,
		# KeepRoot   => 1
	);

	# 2) parse and create GroupData structure
	my $groupData = GroupData->new();

	my %pnlDim = ( "width" => $xml->{"panel_width"}, "height" => $xml->{"panel_height"} );
	$groupData->SetPnlDim( \%pnlDim );

	my @order = @{ $xml->{"order"} };

	my @orderIds = map { $_->{"order_id"} } @order;
	@orderIds = uniq(@orderIds);

	my @orderInf = ();

	foreach my $orderId (@orderIds) {
	 

		my ($jobName) = $orderId =~ /^(\w\d+)/;
		$jobName = lc($jobName);

		my @all = grep { $_->{"order_id"} eq $orderId } @order;
		
		my $orderId = lc($orderId);

		my @pos = ();

		# get width and height from first order item
		my %order = (
					  "orderId" => $orderId,
					  "jobName" => $jobName,
					  "width"   => $all[0]->{"w"},
					  "height"  => $all[0]->{"h"},
					  "pos"     => \@pos
		);

		# store positions
		foreach my $orderPos (@all) {

			my %inf = ( "x" => $orderPos->{"x"}, "y" => $orderPos->{"y"}, "rotated" => $orderPos->{"rotated"} );
			push( @{ $order{"pos"} }, \%inf );

		}

		push( @orderInf, \%order );

	}

	$groupData->SetOrdersInfo( \@orderInf );
	
	
	
	# genereate file name, where helper info will be stored (like mother job name)
 	# this file is used across by all group managers fot their comunication
 	
 		
 	my $ctx = Digest::MD5->new;
 	
 	# generate name based on order names
 	my @names = $groupData->GetJobNames();
 	my $str = join( ";", @names);
 	
 	$ctx->add($str);
 
 
 	$groupData->{"infoFile"} = $ctx->hexdigest();

	return $groupData;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::PoolMerge::Task::TaskData::DataParser';

	my $parser = DataParser->new();
	$parser->GetTaskData("c:\\Export\\ExportFilesPool\\test.xml");

	print STDERR "rrr";

	#$app->Test();

	#$app->MainLoop;

}

1;

