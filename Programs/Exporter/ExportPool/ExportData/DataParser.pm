
#-------------------------------------------------------------------------------------------#
# Description: Class which prepare export data from pool xml file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::ExportData::DataParser;

#3th party library
use strict;
use warnings;
use XML::Simple;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Programs::Exporter::ExportPool::ExportData::GroupData';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::AbstractQueue::ExportData::ExportData';
use aliased 'Managers::AbstractQueue::ExportData::Enums' => "BaseEnums";
use aliased 'Programs::Exporter::ExportPool::UnitEnums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless($self);

	return $self;
}

sub GetExportData {
	my $self = shift;
	my $path = shift;
	
	# 1) init gorup data
	my $groupData = $self->__GetGroupData($path);
	
	# 2) export data
	my $exportData = ExportData->new();
	
	my ( $sec, $min, $hour ) = localtime();
	my $time = sprintf( "%02d:%02d", $hour, $min );
	
	
	$exportData->{"settings"}->{"time"}         = $time;
	$exportData->{"settings"}->{"mode"}         = BaseEnums->ExportMode_ASYNC;    # synchronousExport/ asynchronousExport
	
	my @mandatory = (UnitEnums->UnitId_MERGE, UnitEnums->UnitId_ROUT, UnitEnums->UnitId_EXPORT);
	$exportData->{"settings"}->{"mandatoryUnits"} = \@mandatory;    # units, which has to be exported
	
	foreach my $unit (@mandatory){
		
		$exportData->{"units"}->{$unit} = $groupData;
	}
	
	return $exportData;
 
}

sub __GetGroupData{
	my $self = shift;
	my $path = shift;
	
	# 1) open file

	my $xmlF = FileHelper->Open($path);

	my $xml = XMLin(
		$xmlF,

		#ForceArray => 1,
		# KeepRoot   => 1
	);

	# 2) parse and create GroupData structure
	my $groupData = GroupData->new();

	my %pnlDim = ( "width" => $xml->{"panel_width"}, "height" => $xml->{"panel_height"} );
	$groupData->SetPnlDim( \%pnlDim );

	my @order = @{ $xml->{"order"} };

	my @jobNames = map { $_->{"order_id"} } @order;
	@jobNames = uniq(@jobNames);

	my @jobInf = ();

	foreach my $job (@jobNames) {

		my ($jobName) = $job =~ /^(\w\d+)/;

		my @all = grep { $_->{"order_id"} eq $job } @order;

		my @pos = ();

		# get width and height from first order item
		my %order = (
					  "orderId" => $job,
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

		push( @jobInf, \%order );

	}

	$groupData->SetChildJobs( \@jobInf );
	
	
	
	return $groupData;		
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportPool::ExportData::DataParser';

	my $parser = DataParser->new();
	$parser->GetExportData("c:\\Export\\ExportFilesPool\\test.xml");

	print STDERR "rrr";

	#$app->Test();

	#$app->MainLoop;

}

1;

