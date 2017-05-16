
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::TpvConnector::Helper;

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;
use DBI;

#local library
use aliased 'Connectors::TpvConnector::Enums';
use aliased 'Connectors::EnumsErrors';
use aliased 'Packages::Handlers::ErrorHandler';
use aliased 'Packages::Exceptions::TpvDbException';
use Connectors::Config;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $__conTimeout = $Connectors::Config::tpvDb{"connectionTimeout"};
my $__commandTimeout = $Connectors::Config::tpvDb{"commandTimeout"};
my $__dbUserName     = $Connectors::Config::tpvDb{"dbUserName"};
my $__dbName         = $Connectors::Config::tpvDb{"dbName"};
my $__dbPassword     = $Connectors::Config::tpvDb{"dbPassword"};
my $__dbHost         = $Connectors::Config::tpvDb{"dbHost"};
my $__dbPort         = $Connectors::Config::tpvDb{"dbPort"};
my $__dbAllowed         = $Connectors::Config::tpvDb{"dbAllowed"};

sub __OpenConnection {

	my $self = shift;
	my $con  = undef;
	
	unless ($__dbAllowed){
		return;
	}


 #con = DBI->connect( "DBI:mysql:database=$__dbName;
	#	host=$__dbHost; 
	#	mysql_connect_timeout=$__conTimeout;
	#	mysql_write_timeout=$__commandTimeout;
	#	mysql_read_timeout=$__commandTimeout", $__dbUserName, $__dbPassword, { 'RaiseError' => 1 } );


	eval {
		$con = DBI->connect( "DBI:mysql:database=$__dbName;host=$__dbHost; 
		mysql_write_timeout=$__commandTimeout;
		mysql_read_timeout=$__conTimeout;
		mysql_connect_timeout=$__conTimeout", $__dbUserName, $__dbPassword, { 'RaiseError' => 1 } );
		
		$con->{'mysql_enable_utf8'} = 1;
		$con->do('set names utf8');
		 
		 
	};
	if ($@) {
		 
		die TpvDbException->new( EnumsErrors->TPVDBCONN, $@ )

	}
	

	#unless ( defined $con ) {
	#	print STDERR EnumsErrors->LOGDBCONN. $_."22222222";
	#}

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
			$cmd =~ s/$name/'$param->{"value"}'/g;

		}
		elsif ( $param->{"dbType"} == Enums->SqlDbType_TEXT ) {
			$cmd =~ s/$name/$param->{"value"}/g;

		}
		elsif (    $param->{"dbType"} == Enums->SqlDbType_DECIMAL
				|| $param->{"dbType"} == Enums->SqlDbType_INT
				|| $param->{"dbType"} == Enums->SqlDbType_FLOAT
				|| $param->{"dbType"} == Enums->SqlDbType_BIT )
		{
			$cmd =~ s/$name/$param->{"value"}/g;

		}
		else {

			$cmd =~ s/$name/'$param->{"value"}')/g;
		}

	}

	return $cmd;
}

sub __Execute {
	my $self      = shift;
	my $con       = shift;
	my $commands  = shift;
	my $isDataset = shift;
	my @dataset   = ();

	my $cmdTable = "use " . $__dbName;
	$con->do($cmdTable);

	if ( defined $isDataset && $isDataset == 1 ) {
		my $sth = $con->prepare($commands);
		$sth->execute();
		while ( my $ref = $sth->fetchrow_hashref() ) {

			push( @dataset, $ref );
		}

		$sth->finish();

		return @dataset;
	}
	else {

		$con->do($commands);
	}

}

sub ExecuteNonQuery {
	my $self              = shift;
	my $commandText       = shift;
	my $commandParameters = shift;

	if ( $commandText eq "" ) { die "$commandText is empty" }

	my $con = undef;
	my $cmd = Connectors::TpvConnector::Helper->__PrepareCommand( $commandText, $commandParameters );

 

	$con = Connectors::TpvConnector::Helper->__OpenConnection();
	unless ($con) {
		return 0;
	}

	try {
		Connectors::TpvConnector::Helper->__Execute( $con, $cmd, 0 );
	}
	catch {

			die TpvDbException->new( EnumsErrors->TPVDBERROR, $_ )

	}
	finally {

		$con->disconnect();

	};

}

sub ExecuteDataSet {
	my $self              = shift;
	my $commandText       = shift;
	my $commandParameters = shift;

	if ( $commandText eq "" ) { die "$commandText is empty" }

	my $con = undef;
	my $cmd = Connectors::TpvConnector::Helper->__PrepareCommand( $commandText, $commandParameters );
 
	my @dataset = ();

	$con = Connectors::TpvConnector::Helper->__OpenConnection();
	if ($con) {

		try {
			@dataset = Connectors::TpvConnector::Helper->__Execute( $con, $cmd, 1 );
		}
		catch {

			die TpvDbException->new( EnumsErrors->TPVDBERROR, $_ )

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
	my $cmd = Connectors::TpvConnector::Helper->__PrepareCommand( $commandText, $commandParameters );
 

	my @dataset = ();

	$con = Connectors::TpvConnector::Helper->__OpenConnection();
	if ($con) {

		try {
			@dataset = Connectors::TpvConnector::Helper->__Execute( $con, $cmd, 1, $noDiacritic );
		}
		catch {

			#ErrorHandler->HeliosDatabase( EnumsErrors->LOGDBERROR . $_ );
			die TpvDbException->new(  EnumsErrors->TPVDBERROR, $_ )

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

1;

