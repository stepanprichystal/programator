#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;

my $pcbName = "abcdefg";

$pcbName = substr($pcbName, 0, length($pcbName) -1 );

print $pcbName;