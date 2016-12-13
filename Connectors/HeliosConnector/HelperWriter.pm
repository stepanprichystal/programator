
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
		print STDERR "\n\n ============== Update record 2 =================== \n\n";
	my $result = $service->LogOn(
		{
		  profile  => $profile,     # string
		  username => $username,    # string
		  password => $password,    # string
		  language => $language,    # string
		  options  => $options,     # string
		}
	);
		print STDERR "\n\n ============== Update record 3 =================== \n\n";
	$result =~ m{\&lt;LogOnResult&gt;(.*?)\&lt;/LogOnResult&gt;};
	return $1;
}

sub LogOff {
	my %args = @_;
	
		print STDERR "\n\n ============== Update record 12 =================== \n\n";
	
	
	my $result = $service->LogOff(
		{
		  sessionToken => $args{sessionToken},    # string
		}
	);
	
		print STDERR "\n\n ============== Update record 13 =================== \n\n";

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


		print STDERR "\n\n ============== Update record 4 =================== \n\n";

	my $writer = new XML::Writer( OUTPUT => 'self' );
	
		print STDERR "\n\n ============== Update record 5 =================== \n\n";
	
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
	
		print STDERR "\n\n ============== Update record 6 =================== \n\n";
	
	$writer->end();
	
	
		print STDERR "\n\n ============== Update record 7 =================== \n\n";
	return $writer->to_string();
}

sub ProcessXml {
	my %args         = @_;
	my $sessionToken = $args{sessionToken};
	my $xml          = $args{xml};

		print STDERR "\n\n ============== Update record 9 =================== \n\n";

	my $result = $service->ProcessXml(
									   {
										 sessionToken => $sessionToken,
										 inputXml     => $xml,
									   }
	);

	print STDERR "\n\n ============== Update record 10 =================== \n\n";

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

	print STDERR "\n\n ============== Update record 1 =================== \n\n";

	my $sessionToken = LogOn();

	my $xml = CreateXml(
						 classid   => $classid,
						 folderid  => $folderid,
						 refer     => $refer,
						 attribute => $attribute,
						 value     => $value
	);

		print STDERR "\n\n ============== Update record 8 =================== \n\n";

	my $processXmlResult = ProcessXml( sessionToken => $sessionToken,
									   xml          => $xml );

		print STDERR "\n\n ============== Update record 11 =================== \n\n";

	my $logOffResult = LogOff( sessionToken => $sessionToken );

	return $processXmlResult;
}

1;

#test
