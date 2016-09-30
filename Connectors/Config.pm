
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::Config;

#3th party library
use warnings;

#local library

#define connection parameters for log DB
%logDb = ();

$logDb{"connectionTimeout"} = 1;
$logDb{"commandTimeout"} = 30;
$logDb{"dbUserName"}     = "tpv_user";
$logDb{"dbName"}         = "tpv_log";
$logDb{"dbPassword"}     = "1234";
$logDb{"dbHost"}         = "192.168.2.98"; #tpv-server
$logDb{"dbPort"}         = "3306";
$logDb{"dbAllowed"}         = 1; #say if database is allowed


#define connection parameters for Helios DB
%heliosDb = ();

$heliosDb{"connectionTimeout"} = 3;
$heliosDb{"commandTimeout"} = 30;
$heliosDb{"dbUserName"}     = "genesis";
#$heliosDb{"dbName"}         = "lcs";
$heliosDb{"dbPassword"}     = "genesis";
$heliosDb{"dbHost"}         = "dps";

#define connection parameters for Helios DB write operation
%heliosWriteDb = ();

$heliosWriteDb{"dbProfile"} = "Gatema";
$heliosWriteDb{"dbUserName"} = "replikator";
$heliosWriteDb{"dbPassword"}     = "oqobgqvq";
$heliosWriteDb{"dbLanguage"}         = "CZ";
$heliosWriteDb{"dbOptions"}     = "";



1;
