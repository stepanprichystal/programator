#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
my @dwarfs = qw(Doc Grumpy Happy Sleepy Sneezy Dopey Bashful);
my $test = splice @dwarfs, 3, 1;
print "@dwarfs";    # Doc Grumpy Happy Dopey Bashful