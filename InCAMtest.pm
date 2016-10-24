#!/usr/bin/perl -w
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Helpers::GeneralHelper';

my $portNumber = "2008";    #random number

my $serverPath = GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerExporter.pl";
@_ = ();
push( @_, $portNumber );    # port number, pass as argument

 $ARGV[0] = $portNumber;

require $serverPath;
