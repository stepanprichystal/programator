
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::HeliosConnector::Helper;

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;
 
use DBI;
#Win32::OLE => not allowed use this module!
# Module is used by perl ithreads and this Win32::OLE is not thread sa
 
#local library

use aliased 'Connectors::EnumsErrors';
use aliased 'Connectors::HeliosConnector::Enums';
use Connectors::Config;
use aliased 'Packages::Exceptions::HeliosException';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $__dbUserName     = $Connectors::Config::heliosDb{"dbUserName"};
my $__dbPassword     = $Connectors::Config::heliosDb{"dbPassword"};
my $__dbHost         = $Connectors::Config::heliosDb{"dbHost"};
my $__conTimeout     = $Connectors::Config::heliosDb{"connectionTimeout"};
my $__commandTimeout = $Connectors::Config::heliosDb{"commandTimeout"};

sub __OpenConnection {

	my $self = shift;
	my $con  = undef;

	 

	eval {

		my %att = ( "ConnectionTimeout" => $__conTimeout, "CommandTimeout" => $__commandTimeout );

		#ConnectionTimeout=$__conTimeout;
		#CommandTimeout=$__commandTimeout

		$con = DBI->connect(
			"dbi:ADO:$__dbHost;",
			$__dbUserName,
			$__dbPassword,
			{

				#'PrintError' => 0,
				'PrintError'            => 0,
				'RaiseError'            => 1,
				'ado_ConnectionTimeout' => $__conTimeout,
				'CommandTimeout'        => $__commandTimeout,
				'on_connect_do'         => [ "SET NAMES 'utf8'", "SET CHARACTER SET 'utf8'" ]
			}
		);

		 

	};
	if ($@) {

		die HeliosException->new( EnumsErrors->HELIOSDBCONN, $@ )

		  #ErrorHandler->HeliosDatabase();

	}
	return $con;

}

sub __PrepareCommand {
	my $self       = shift;
	my $cmd        = shift;
	my $cmdParTemp = shift;
	my @cmdPar     = undef;

	unless ( defined $cmdParTemp ) {
		@cmdPar = ();
	}
	else {
		@cmdPar = @{$cmdParTemp};
	}

	foreach my $param (@cmdPar) {

		my $name = quotemeta $param->{"name"};

		if ( $param->{"dbType"} == Enums->SqlDbType_VARCHAR ) {
			$cmd =~ s/$name/'$param->{"value"}'/;

		}
		elsif ( $param->{"dbType"} == Enums->SqlDbType_TEXT ) {
			$cmd =~ s/$name/$param->{"value"}/;

		}
		elsif (    $param->{"dbType"} == Enums->SqlDbType_DECIMAL
				|| $param->{"dbType"} == Enums->SqlDbType_INT
				|| $param->{"dbType"} == Enums->SqlDbType_FLOAT
				|| $param->{"dbType"} == Enums->SqlDbType_BIT )
		{
			$cmd =~ s/$name/$param->{"value"}/;

		}
		else {

			$cmd =~ s/$name/'$param->{"value"}')/;
		}

	}

	return $cmd;
}

sub __Execute {
	my $self        = shift;
	my $con         = shift;
	my $commands    = shift;
	my $isDataset   = shift;
	my $noDiacritic = shift;
	my @dataset     = ();

	#my $cmdTable = "use " . $__dbName;
	#$con->do($cmdTable);

	if ( defined $isDataset && $isDataset == 1 ) {
		my $sth = $con->prepare($commands);
		$sth->execute();
		while ( my $ref = $sth->fetchrow_hashref() ) {

			if ($noDiacritic) {
				foreach my $k ( keys %{$ref} ) {
					$ref->{$k} = $self->__ConvertFromCzech( $ref->{$k} );
				}
			}

			push( @dataset, $ref );
		}

		$sth->finish();

		return @dataset;

	}
	else {

		$con->do($commands);
	}

}

#Return array of hashes, for each row returned by select command
# - Each hash contain name of db column and value given row
sub ExecuteDataSet {
	my $self              = shift;
	my $commandText       = shift;
	my $commandParameters = shift;
	my $noDiacritic       = shift;

	if ( $commandText eq "" ) { die "$commandText is empty" }

	my $con = undef;
	my $cmd = Connectors::HeliosConnector::Helper->__PrepareCommand( $commandText, $commandParameters );

	my @dataset = ();

	$con = Connectors::HeliosConnector::Helper->__OpenConnection();
	if ($con) {

		try {
			@dataset = Connectors::HeliosConnector::Helper->__Execute( $con, $cmd, 1, $noDiacritic );
		}
		catch {

			#ErrorHandler->HeliosDatabase( EnumsErrors->LOGDBERROR . $_ );
			die HeliosException->new( EnumsErrors->HELIOSDBREADERROR, $_ )

		}
		finally {

			$con->disconnect();

		};
	}

	return @dataset;
}

# Retrun one scalar value, based on select commad
sub ExecuteScalar {
	my $self              = shift;
	my $commandText       = shift;
	my $commandParameters = shift;
	my $noDiacritic       = shift;

	if ( $commandText eq "" ) { die "$commandText is empty" }

	my $con = undef;
	my $cmd = Connectors::HeliosConnector::Helper->__PrepareCommand( $commandText, $commandParameters );

	my @dataset = ();

	$con = Connectors::HeliosConnector::Helper->__OpenConnection();
	if ($con) {

		try {
			@dataset = Connectors::HeliosConnector::Helper->__Execute( $con, $cmd, 1, $noDiacritic );
		}
		catch {

			#ErrorHandler->HeliosDatabase( EnumsErrors->LOGDBERROR . $_ );
			die HeliosException->new( EnumsErrors->HELIOSDBREADERROR, $_ )

		}
		finally {

			$con->disconnect();

		};
	}

	if ( scalar(@dataset) > 0 ) {

		my $k = ( keys %{ $dataset[0] } )[0];

		if ($k) {
			return $dataset[0]->{$k};
		}

	}

	return undef;

	#return @dataset;
}

sub __ConvertFromCzech {
	my $self          = shift;
	my $lineToConvert = shift;
	my $char;
	my $ret;
	my @str = split( //, $lineToConvert );

	foreach my $char (@str) {
		$char =~
tr/\x8A\xE1\xC1\xE8\xC8\xEF\xCF\xE9\xC9\xEC\xCC\xED\xCD\xF3\xD3\xF8\xD8\xB9\xA9\xBB\xAB\xFA\xDA\xF9\xD9\xFD\xDD\xBE\xAE\xF2\xD2/\x53\x61\x41\x63\x43\x64\x44\x65\x45\x65\x45\x69\x49\x6F\x4F\x72\x52\x73\x53\x74\x54\x75\x55\x75\x55\x79\x59\x7A\x5A\x6E\x4E/;
		$ret .= $char;
	}
	return ($ret);

}

1;

