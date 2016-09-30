
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::HeliosConnector::HelperWriter;

#3th party library
use strict;
use warnings;
use Switch;
use XML::Writer;
use Connectors::HeliosConnector::MyInterfaces::ServiceGate::ServiceGateSoap;

#local library
use Connectors::Config;
use aliased 'Connectors::EnumsErrors';
use aliased 'Packages::Exceptions::HeliosException';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $__dbProfile  = $Connectors::Config::heliosWriteDb{"dbProfile"};
my $__dbUserName = $Connectors::Config::heliosWriteDb{"dbUserName"};
my $__dbPassword = $Connectors::Config::heliosWriteDb{"dbPassword"};
my $__dbLanguage = $Connectors::Config::heliosWriteDb{"dbLanguage"};
my $__dbOptions  = $Connectors::Config::heliosWriteDb{"dbOptions"};

my $service = Connectors::HeliosConnector::MyInterfaces::ServiceGate::ServiceGateSoap->new();

sub OnlineWrite_order {
	my $self       = shift;
	my $reference  = shift;    #reference zakazky
	my $stavOnline = shift;    #hodnota, informace
	my $attribute  = shift;    #do jakeho pole v norisu
	$reference = uc $reference;

	my $result = UpdateRecord(
							   classid   => "22207",
							   folderid  => "22050",
							   refer     => $reference,
							   attribute => $attribute,
							   value     => $stavOnline
	);

	if ( $result =~ /FAIL/ ) {
		die HeliosException->new( EnumsErrors->HELIOSDBWRITEERROR , "No details");
	}

	return $result;
}

sub OnlineWrite_pcb {
	my $self       = shift;
	my $reference  = shift;    #reference zakazky
	my $stavOnline = shift;    #hodnota, informace
	my $attribute  = shift;    #do jakeho pole v norisu
	$reference = uc $reference;

	my $result = UpdateRecord(
							   classid   => "22201",
							   folderid  => "22041",
							   refer     => $reference,
							   attribute => $attribute,
							   value     => $stavOnline
	);

	if ( $result =~ /FAIL/ )
	{
		die HeliosException->new( EnumsErrors->HELIOSDBWRITEERROR, $result );
	}

	return $result;
}

sub LogOn {
	my $profile  = $__dbProfile;
	my $username = $__dbUserName;
	my $password = $__dbPassword;
	my $language = $__dbLanguage;
	my $options  = $__dbOptions;

	my $result = $service->LogOn(
		{
		  profile  => $profile,     # string
		  username => $username,    # string
		  password => $password,    # string
		  language => $language,    # string
		  options  => $options,     # string
		}
	);

	$result =~ m{\&lt;LogOnResult&gt;(.*?)\&lt;/LogOnResult&gt;};
	return $1;
}

sub LogOff {
	my %args = @_;
	my $result = $service->LogOff(
		{
		  sessionToken => $args{sessionToken},    # string
		}
	);

	$result =~ m{\&lt;LogOffResult&gt;(.*?)\&lt;/LogOffResult&gt;};
	return $1;
}

sub CreateXml {
	my %args      = @_;
	my $classid   = $args{classid};
	my $folderid  = $args{folderid};
	my $refer     = $args{refer};
	my $attribute = $args{attribute};
	my $value     = $args{value};

	my $writer = new XML::Writer( OUTPUT => 'self' );
	$writer->startTag( "INSERTUPDATE", "action" => "update" );
	$writer->startTag(
					   "RECORD",
					   "CLASSID"       => $classid,
					   "FOLDERID"      => $folderid,
					   "REFERENCE"     => $refer,
					   "keyAttributes" => "reference_subjektu"
	);
	$writer->startTag( "ATTRIBUTE", "name" => $attribute );
	$writer->characters($value);
	$writer->endTag("ATTRIBUTE");
	$writer->endTag("RECORD");
	$writer->endTag("INSERTUPDATE");
	$writer->end();
	return $writer->to_string();
}

sub ProcessXml {
	my %args         = @_;
	my $sessionToken = $args{sessionToken};
	my $xml          = $args{xml};

	my $result = $service->ProcessXml(
									   {
										 sessionToken => $sessionToken,
										 inputXml     => $xml,
									   }
	);

	$result =~ /STATE=(.*)START/;
	my $res = $1;
	$res =~ tr/&quot;//d;
	if ( $res =~ m/^FAIL/ ) {
		$res = $res . "\n";
		$result =~ /errorMessage=(.*)WHEN/;
		my $error = $1;
		if ( defined($error) ) {
			$error =~ s/&quot;//g;
			$res = $res . $error;
		}
	}
	return $res;
}

sub UpdateRecord {
	my %args      = @_;
	my $classid   = $args{classid};
	my $folderid  = $args{folderid};
	my $refer     = $args{refer};
	my $attribute = $args{attribute};
	my $value     = $args{value};

	my $sessionToken = LogOn();

	my $xml = CreateXml(
						 classid   => $classid,
						 folderid  => $folderid,
						 refer     => $refer,
						 attribute => $attribute,
						 value     => $value
	);

	my $processXmlResult = ProcessXml( sessionToken => $sessionToken,
									   xml          => $xml );

	my $logOffResult = LogOff( sessionToken => $sessionToken );

	return $processXmlResult;
}

1;

#test
