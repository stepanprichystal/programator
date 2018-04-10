#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use Win32::Service;
use Config;
use Win32::Process;
use Log::Log4perl qw(get_logger);

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Enums::EnumsDrill';

my $jobId = "d152457";

my $customerNote = CustomerNote->new( HegMethods->GetCustomerInfo($jobId)->{"reference_subjektu"} );

# Vraci jednu ze tri hodnot

# undef
# EnumsDrill->DTM_VRTANE
# EnumsDrill->DTM_VYSLEDNE
 
print $customerNote->PlatedHolesType();

