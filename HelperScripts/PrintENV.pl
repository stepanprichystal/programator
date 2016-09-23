#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( c:\Perl\site\lib\TpvScripts\Scripts);

 

use aliased 'Packages::InCAM::InCAM';
 



print "\nEnvironment vars:\n";
foreach my $key (keys %ENV)
{
  # do whatever you want with $key and $value here ...
  my $value = $ENV{$key};
  print "  $key = $value\n";
}

print 1;
