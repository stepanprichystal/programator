#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro automaticke vytvoreni standardniho slozeni
#  pro dps 4vv, 6vv, 8vv  9um + 18um + 35um
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::StackupDefault;

#loading of locale modules

#3th party library
use English;
use strict;
use warnings;
use XML::Simple;
use POSIX;
use File::Copy;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#Create xml and pdf stackup and  automatically
sub CreateStackup {
	my $self         = shift;
	my $inCAM        = shift;
	my $pcbId        = shift;
	my $lCount       = shift;
	my @innerCuUsage = @{ shift(@_) };
	my $outerCuThick = shift;
	my $pcbClass     = shift;

	#test input parameters
	if ( $lCount < 4 ) {
		print STDERR "Number of Cu has to be larger then 4";
		return 0;
	}

	unless ($pcbId) {
		print STDERR "No pcb Id";
		return 0;
	}

	unless (@innerCuUsage) {
		print STDERR "No inner Cu ussage in param innerCuUsage";
		return 0;
	}

	if ( $outerCuThick < 9 ) {
		print STDERR "Error, outher thick is less then 9";
		return 0;
	}

	if ( $lCount != scalar(@innerCuUsage) + 2 ) {
		print STDERR "Number of layer is diffrent from number of item in array innerCuUsage + 2";
		return 0;
	}

	#we need identify, which type of stackup use. It depends on inner layers Cu ussage
	#see Resources/DefaultStackup/Navod.txt
	my $stackType = "type1";

	if ( $lCount == 6 && $innerCuUsage[1] + $innerCuUsage[2] < 30 ) {
		$stackType = "type2";

	}
	elsif (
			$lCount == 8
			&& (    ( $innerCuUsage[1] + $innerCuUsage[2] < 60 )
				 || ( $innerCuUsage[3] + $innerCuUsage[4] < 60 ) )
	  )
	{
		$stackType = "type2";
	}

	my $defaultName = $lCount . "vv_" . $stackType . ".xml";

	#my @mess = ("Který typ standardního stackupu chceš vygenerovat? (IS400 pouze velký pøíøez)");
	#my @btn = ( "IS400", "FR4" );

	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, \@btn );

	#my $res = $messMngr->Result();
	my $mat = HegMethods->GetMaterialKind($pcbId);

	my $path;

	if ( $mat =~ /is400/i ) {

		$path = GeneralHelper->Root() . "\\Resources\\DefaultStackups_is400\\";
	}
	else {
		$path = GeneralHelper->Root() . "\\Resources\\DefaultStackups\\";

	}

	my $stcFile = $path . $defaultName;

	my $xml = $self->_LoadStandardStackup($stcFile);

	#if pcb is in 8 class, set outer Cu 9Âµm
	if ( $pcbClass >= 8 && $outerCuThick <= 18 ) {
		$self->_SetOuterCu( \$xml, 9 );
	}

	#create new xml stackup file

	$self->_SetCuUsage( \$xml, \@innerCuUsage );
	$self->_CreateNewStackup( \$xml, $pcbId, $pcbId );

	#get final thick of pcb and get info about stackup layers
	my $stackup = Stackup->new( $inCAM, $pcbId );
	my $pcbThick = $stackup->GetFinalThick();

	#generate name of stackup file eg.: d99991_4vv_1,578_Euro.xml
	my $stackupName = $self->GetStackupName( $stackup, $pcbId );

	$self->_CompleteNewStackup( $pcbId, $pcbThick, $stackupName );

	#Tidy up temp dir
	FileHelper->DeleteTempFiles();

	return 1;

}

# Generate standard stackup file name
sub GetStackupName {
	my $self    = shift;
	my $stackup = shift;
	my $pcbId   = shift;

	my $lCount   = $stackup->GetCuLayerCnt();
	my $pcbThick = $stackup->GetFinalThick();

	$pcbThick = sprintf( "%4.3f", ( $pcbThick / 1000 ) );
	$pcbThick =~ s/\./\,/g;

	my %customerInfo = %{ HegMethods->GetCustomerInfo($pcbId) };

	my $customer = $customerInfo{"customer"};

	if ($customer) {
		$customer =~ s/\s//g;
		$customer = substr( $customer, 0, 8 );
	}
	else {
		$customer = "";
	}

	if ( $customer =~ /safiral/i )    #exception for safiral
	{
		$customer = "";
	}

	return $pcbId . "_" . $lCount . "vv" . "_" . $pcbThick . "_" . $customer;
}

#Load xml stackup for pcb
sub _LoadStandardStackup {
	my $self    = shift;
	my $stcFile = shift;

	#load standard stackup by LayerCount
	my $fStackupXml = undef;

	#check validation of pcb's stackup xml file
	if ( FileHelper->IsXMLValid($stcFile) ) {

		my $fStackupXml = FileHelper->Open($stcFile);
	}
	else {

		my $fname = FileHelper->ChangeEncoding( $stcFile, "cp1252", "utf8" );

		$fStackupXml = FileHelper->Open( EnumsPaths->Client_INCAMTMPOTHER . $fname );
	}

	my @thickList = ();

	my $xml = XMLin(
					 $fStackupXml,
					 ForceArray => undef,
					 KeyAttr    => undef,
					 KeepRoot   => 1,
	);

	return $xml;
}

#set thick of Cu to stackup
sub _SetOuterCu {
	my $self         = shift;
	my $xml          = ${ shift(@_) };
	my $outerCuThick = shift;

	my $idOfCu   = $self->_GetCuIdByThick($outerCuThick);
	my @elements = @{ $xml->{ml}->{element} };

	my $copper = Enums->MaterialType_COPPER;

	if (    $elements[0]->{type} =~ /\Q$copper/i
		 && $elements[ scalar(@elements) - 1 ]->{type} =~ /\Q$copper/i )
	{
		@{ $xml->{ml}->{element} }[0]->{id} = $idOfCu;
		@{ $xml->{ml}->{element} }[ scalar(@elements) - 1 ]->{id} = $idOfCu;

		print STDERR "======================";
	}

}

#Return id of Cu material from ml.xml
sub _GetCuIdByThick {
	my $self  = shift;
	my $thick = shift;

	#read id from multicall.
	#temporary solution

	if ( $thick == 9 ) {
		return 2;
	}
	elsif ( $thick == 18 ) {
		return 4;
	}
	elsif ( $thick == 35 ) {
		return 5;
	}
}

#Set ussage of inner Cu layers to stackup
sub _SetCuUsage {
	my $self         = shift;
	my $xml          = ${ shift(@_) };
	my @innerCuUsage = @{ shift(@_) };

	#add TOP and BOTTOM usage 100%
	@innerCuUsage = ( 100, @innerCuUsage, 100 );

	my @elements = @{ $xml->{ml}->{element} };
	my $cuPos    = 0;

	for ( my $i = 0 ; $i < scalar(@elements) ; $i++ ) {

		my $type = Enums->MaterialType_COPPER;
		if ( $elements[$i]->{type} =~ /$type/i ) {
			@{ $xml->{ml}->{element} }[$i]->{p} = $innerCuUsage[$cuPos];
			$cuPos++;
		}
	}
}

#Create and save new xml stackup, without pcb thickness and correct file name yet
sub _CreateNewStackup {
	my $self        = shift;
	my $xml         = ${ shift(@_) };
	my $pcbId       = shift;
	my $stackupName = shift;

	$xml->{"ml"}{"soll"} = 0;
	my $xmlString = XMLout( $xml->{ml}, RootName => "ml" );

	my @oldStackups = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_STACKUPS, $pcbId );

	foreach my $f (@oldStackups) {
		unlink $f;
	}

	FileHelper->WriteString( EnumsPaths->Jobs_STACKUPS . $stackupName . "\.xml", $xmlString );
}

#Complete created stacup with right file name and thick of pcb
sub _CompleteNewStackup {
	my $self        = shift;
	my $pcbId       = shift;
	my $pcbThick    = shift;
	my $stackupName = shift;

	$pcbThick = sprintf( "%4.3f", ( $pcbThick / 1000 ) );
	$pcbThick =~ s/\./\,/g;

	my $newXml = $self->_LoadStandardStackup( EnumsPaths->Jobs_STACKUPS . $pcbId . ".xml" );
	$newXml->{"ml"}{"soll"} = $pcbThick;
	my $xmlString = XMLout( $newXml->{ml}, RootName => "ml" );

	#delete all files beginning with actual pcb id
	opendir( DIR, EnumsPaths->Jobs_STACKUPS );
	my @stackups = grep( m/$pcbId/i, readdir(DIR) );
	map { FileHelper->DeleteFile( EnumsPaths->Jobs_STACKUPS . $_ ) } @stackups;
	closedir(DIR);

	FileHelper->WriteString( EnumsPaths->Jobs_STACKUPS . $stackupName . "\.xml", $xmlString );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;

if ( $filename =~ /DEBUG_FILE.pl/ ) {

	my $pcbId        = "d152456";
	my $layerCnt     = 6;
	my @innerCuUsage = ( 58, 15, 12, 44 );
	my $outerCuThick = 9;
	my $pcbClass     = 7;

	use aliased 'Packages::CAMJob::Stackup::StackupDefault';

	StackupDefault->CreateStackup( $pcbId, $layerCnt, \@innerCuUsage, $outerCuThick, $pcbClass );
}

1;

