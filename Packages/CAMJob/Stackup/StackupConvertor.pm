
#-------------------------------------------------------------------------------------------#
# Description: Create standard Multicall xml from stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::StackupConvertor;

#3th party library
use strict;
use warnings;
use JSON;
use XML::Generator;
use Tie::IxHash;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::Stackup::StackupDefault';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

# Create stackup xml file and store to default stackup location
sub DoConvert {
	my $self       = shift;
	my $outputPath = shift; # default is standard stackup location if not specified

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# load stackup
	my $stackup = Stackup->new($inCAM, $jobId);

	my $thick = sprintf( "%.3f", $stackup->GetFinalThick() / 1000 );
	 
	my $name = StackupDefault->GetStackupName($stackup,$jobId).".xml";

	# store to standard stackup folder
	unless ($outputPath) {
		$outputPath = EnumsPaths->Jobs_STACKUPS . $name;
	}

	my $xmlGen = XML::Generator->new(':pretty');

	tie my %attr, 'Tie::IxHash';

	$attr{"path"}      = $outputPath;
	$attr{"name"}      = $name;
	$attr{"dbVersion"} = 9;
	$attr{"soll"}      = $thick;

	my @elements = ();

	my $lPos = 1;

	foreach my $l ( $stackup->GetAllLayers() ) {

		tie my %attrEl, 'Tie::IxHash';

		if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {

			$attrEl{"id"}   = $l->GetId();
			$attrEl{"pos"}  = $lPos;
			$attrEl{"p"}    = int( $l->GetUssage() * 100 );
			$attrEl{"type"} = "Copper";
			$lPos++;

			push( @elements, $xmlGen->element( \%attrEl ) );

		}
		elsif ( $l->GetType() eq StackEnums->MaterialType_CORE ) {

			$attrEl{"id"}   = $l->GetId();
			$attrEl{"pos"}  = $lPos;
			$attrEl{"qId"}  = $l->GetQId();
			$attrEl{"type"} = "Core";
			$lPos++;

			push( @elements, $xmlGen->element( \%attrEl ) );

		}
		elsif ( $l->GetType() eq StackEnums->MaterialType_PREPREG ) {

			foreach my $lPrepreg ( $l->GetAllPrepregs() ) {

				$attrEl{"id"}   = $lPrepreg->GetId();
				$attrEl{"pos"}  = $lPos;
				$attrEl{"qId"}  = $lPrepreg->GetQId();
				$attrEl{"type"} = "Prepreg";

				$lPos++;

				push( @elements, $xmlGen->element( \%attrEl ) );
			}

		}

	}

	my $str = $xmlGen->ml( \%attr, @elements );

	FileHelper->WriteString( $outputPath, $str );

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Stackup::StackupConvertor';

	my $convertor = StackupConvertor->new("d113609");
	$convertor->DoConvert();

}

1;

