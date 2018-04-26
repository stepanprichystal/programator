#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro porovnani vrstev ve dvou stepech
# Author:SPR
#-------------------------------------------------------------------------------------------#
#package LayerCompareScript;

#loading of locale modules
use LoadLibrary;

#3th party library
use English;
use strict;
use warnings;

#use Try::Tiny;
use Tk;
use Tk::Font;
use Tk::Photo;
use Tk::widgets qw/JPEG PNG/;
use Tk::BrowseEntry;
use File::Basename;
use Genesis;


#local library
use Enums;
use GeneralHelper;
use MessageForm;

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#GLOBAL variables


my $genesis = new Genesis;

my $job = "$ENV{JOB}";

#$genesis->COM( "open_job", job => $job );

$genesis->INFO(
	entity_type => 'matrix',
	entity_path => "$job/matrix",
	data_type   => 'ROW'
);

my @ROWsignal = @{ $genesis->{doinfo}{gROWlayer_type} };
my @ROWboard  = @{ $genesis->{doinfo}{gROWcontext} };
my @ROWname   = @{ $genesis->{doinfo}{gROWname} };
my @layers;

for ( my $i = 0 ; $i < scalar(@ROWsignal) ; $i++ ) {
	if (  $ROWboard[$i] eq "board" && $ROWname[$i] ne "" ) {
		push @layers, $ROWname[$i];
	}
}

$genesis->INFO(
	'entity_type' => 'job',
	'entity_path' => "$job",
	'data_type'   => 'STEPS_LIST'
);
my @steps = @{ $genesis->{doinfo}{gSTEPS_LIST} };


my $frm;    #GUI form

#data and options
my %layerToCheck;    #layer to compare
my $onlyCopyOpt = 0;
my $firstStep   = $steps[0];
my $secondStep  = $steps[1];

$frm = MainWindow->new();
__SetLayout( \@steps, \@layers );
 
#$frm->after(1,sub {$frm->stayOnTop()});

$frm->MainLoop;

sub __FillList {

	my $listName = shift;
	my @values   = @{ shift(@_) };

	my $list = $frm->Widget($listName);
	$list->delete( 0, 'end' );

	foreach my $item (@values) {
		$list->insert( 'end', "$item" );
	}
}

#Set dynamicly layout
sub __SetLayout {

	my @steps  = @{ shift(@_) };
	my @layers = @{ shift(@_) };

	my $fontLbl =
	  $frm->Font( -size => 11, -family => "Arial", -weight => "bold" );
	my $fontTxt = $frm->Font( -size => 13, -family => "Arial" );
	my $fontBtn = $frm->Font( -size => 12, -family => "Arial" );

	my $clrBackg       = "white";
	my $clrFooter      = "#E4E4E4";
	my $clrLightYellow = "#FFFD99";
	my $clrLightRed    = "#FFCCCC";
	my $clrLightBlue   = "#B8E4FF";

	$frm->optionAdd( '*font' => 'fixed' );
	$frm->configure( -bg => $clrBackg );

	my $bodyFrm =
	  $frm->Frame( -bg => $clrBackg )->pack( -fill => 'both', -expand => 1 );

	my $w = $bodyFrm->Label(
		-text => "Step 1:",
		-bg   => $clrBackg,
		-font => $fontLbl
	  )->grid(
		-row    => 0,
		-column => 0,
		-sticky => 'e',
		-ipadx  => 10,
		-pady   => 2,
	  );

	$w = $bodyFrm->BrowseEntry(
		-label => '',

		-variable => \$firstStep,
		-listcmd  => [ \&__FillList, '.frame.browseentry', \@steps ],
		-state    => "readonly",
		-width    => 10
	  )->grid(
		-row    => 0,
		-column => 1,
		-sticky => 'e',
		-ipadx  => 10,
		-pady   => 2,
	  );

	$w = $bodyFrm->Label(
		-text => "Step 2:",
		-bg   => $clrBackg,
		-font => $fontLbl
	  )->grid(
		-row    => 0,
		-column => 2,
		-sticky => 'e',
		-ipadx  => 10,
		-pady   => 2,
	  );

	$w = $bodyFrm->BrowseEntry(
		-label => '',

		-variable => \$secondStep,
		-listcmd  => [ \&__FillList, '.frame.browseentry1', \@steps ],
		-state    => "readonly",
		-width    => 10
	  )->grid(
		-row    => 0,
		-column => 3,
		-sticky => 'e',
		-ipadx  => 10,
		-pady   => 2,
	  );

	$w = $bodyFrm->Label(
		-text => 'Layers:',
		-bg   => $clrBackg,
		-font => $fontLbl
	  )->grid(
		-row    => 1,
		-column => 0,
		-sticky => 'w',
		-ipadx  => 10,
		-pady   => 2,
	  );

	my $chbFrm = $bodyFrm->Frame(

		-bg => $clrBackg,

	  )->grid(
		-row    => 1,
		-column => 1,
		-sticky => 'ew',
		-ipadx  => 10,
		-pady   => 2,
	  );

	  
	   foreach my $lIn (@layers)
			{
				$genesis -> COM ("display_layer",name=>$lIn,display=>"no",number=>1);
			}
	  
	my @values = ();

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		$values[$i] = 1;

		if ( $layers[$i] eq 'pc' ) {
			$values[$i] = 0;
		}

		$layerToCheck{ $layers[$i] } = $values[$i];

		$chbFrm->Checkbutton(
			-text     => $layers[$i],
			-variable => \$values[$i],
			-onvalue  => "1",
			-offvalue => "0",

			-command => [
				sub {
					my $lname = shift;
					my $value = shift;

					$layerToCheck{$lname} = ${$value};

				},
				$layers[$i],
				\$values[$i]
			],
			-bg   => $clrBackg,
			-font => $fontTxt
		)->pack( -side => 'top' );

	}

	$w = $bodyFrm->Label(
		-text => 'Options:',
		-bg   => $clrBackg,
		-font => $fontLbl
	  )->grid(
		-row    => 1,
		-column => 2,
		-sticky => 'w',
		-ipadx  => 10,
		-pady   => 2,
	  );

	$bodyFrm->Checkbutton(
		-text     => 'Only copy',
		-variable => \$onlyCopyOpt,
		-onvalue  => "1",
		-offvalue => "0",
		-font     => $fontTxt,
		-bg       => $clrBackg,
	  )->grid(
		-row    => 1,
		-column => 3,
		-sticky => 'w',
		-ipadx  => 10,
		-pady   => 2,
	  );

	my $footerFrm = $bodyFrm->Frame( -bg => $clrFooter )->grid(
		-row        => 3,
		-column     => 0,
		-columnspan => 3,
		-sticky     => 'we',
		-ipadx      => 10,
		-columnspan => 4,

	);

	$footerFrm->Button(
		-font    => $fontBtn,
		-text    => "Ok",
		-command => [
			sub {

				if ($onlyCopyOpt) {

					
					CopyLayer();
				}
				else {
				
				
					ShowLayer();
				}

				$frm->destroy();

			  }
		]
	  )->pack(
		-ipadx => 5,
		-ipady => 3,
		-padx  => 5,
		-pady  => 3,	
		-side  => 'right'
	  );
	  
	  
	 

}

sub ShowLayer {
	
	my $suffix = "_input_".$job;
	
	my @layerToComp = CopyLayer();
			

	#show layers
	foreach my $l (@layerToComp) {
	
			
			foreach my $lIn (@layers)
			{
				$genesis -> COM ("display_layer",name=>$lIn,display=>"no",number=>1);
			}
	
			$genesis -> COM ("display_layer",name=>$l.$suffix,display=>"yes",number=>1);
			$genesis -> COM ("display_layer",name=>$l,display=>"yes",number=>2);
			$genesis -> COM ("work_layer",name=>$l);
			
			$genesis -> COM ("zoom_home");
			$genesis -> PAUSE ('Compare layers - '.$l); 
			

	}

	#remove layer
	foreach my $l (@layerToComp) {
		$genesis->COM('delete_layer',layer=>$l.$suffix);
	}

}

sub CopyLayer {
 
	#$genesis -> COM ("editor_page_close");
	$genesis -> COM ("open_entity", job => $job, type => "step", name=>$secondStep,iconic=>"no");
	$genesis->AUX('set_group', group => $genesis->{COMANS});

	my $suffix = "_input_".$job;
	
	my @layerToComp = ();
			
	#copy layer to second step
	foreach my $l (@layers) {
		if ( $layerToCheck{$l} ) {
			push @layerToComp, $l;

			$genesis -> COM ("copy_layer",
			source_job=>$job,
			source_step=>$firstStep,
			source_layer=>$l,
			dest=>"layer_name",
			dest_layer=>$l.$suffix,
			mode=>"replace",
			invert=>"no",
			copy_notes=>"no"
			);
		}
	}
	
	return @layerToComp;

}

#1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
