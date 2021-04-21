#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;
use XML::LibXML;

my $jobL = "c:\\Export\\test\\Final\\script\\joblayer.xml";

my $jobDoc  = XML::LibXML->load_xml( "location" => $jobL );
my $eleml   = ( $jobDoc->findnodes('/job_layer') )[0];
my $jobDoc2 = XML::LibXML->load_xml( "location" => $jobL );
my $eleml2  = ( $jobDoc2->findnodes('/job_layer') )[0];

my $stcFile = "c:\\Export\\test\\Final\\script\\d315805c_mdi.jobconfig.xml";

my $doc = XML::LibXML->load_xml( "location" => $stcFile );

#my $elem = ( $doc->findnodes('/jobconfig/data_type') )[0];
#
#$elem->removeChildNodes();
#$elem->appendText('VAL2');

my $jobconfig = ( $doc->findnodes('/jobconfig') )[-1];

$jobconfig->appendChild($eleml);
$jobconfig->appendChild($eleml2);



die;


# $jobconfig->insertAfter( $eleml );
#  my  $jobconfig2= ( $doc->findnodes('/jobconfig/job_layer') )[-1];
#   $jobconfig2->addSibling( $eleml2 );
#
#
#
#my $outPath =  "c:\\Export\\test\\Final\\script\\out.xml";
### save
#open my $out, '>', $outPath;
#binmode $out; # as above
#$doc->toFH($out, 2);
### or
##print {$out} $doc->toString();
#
##use XML::LibXML::PrettyPrint;
##
##my $document = XML::LibXML->new->parse_file($outPath);
##my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
###$pp->pretty_print($document); # modified in-place
###
###
##die;
