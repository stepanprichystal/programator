#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

#my $test = 1/0;
#$inCam->COM_test()

#$inCAM->COM( "clipb_open_job", job => "d99991", update_clipboard => "view_job" );

#sleep(4);

$inCAM->COM( "clipb_open_job", job => "F17116", update_clipboard => "view_job" );
for ( my $i = 0 ; $i < 30 ; $i++ ) {

	$inCAM->COM(
				 'output_layer_set',
				 layer        => "top",
				 angle        => '0',
				 x_scale      => '1',
				 y_scale      => '1',
				 comp         => '0',
				 polarity     => 'positive',
				 setupfile    => '',
				 setupfiletmp => '',
				 line_units   => 'mm',
				 gscl_file    => ''
	);
	$inCAM->COM(
				 'output',
				 job                  => "F17116",
				 step                 => 'input',
				 format               => 'Gerber274x',
				 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
				 prefix               => "incam1_$i",
				 suffix               => "",
				 break_sr             => 'no',
				 break_symbols        => 'no',
				 break_arc            => 'no',
				 scale_mode           => 'all',
				 surface_mode         => 'contour',
				 min_brush            => '25.4',
				 units                => 'inch',
				 coordinates          => 'absolute',
				 zeroes               => 'Leading',
				 nf1                  => '6',
				 nf2                  => '6',
				 x_anchor             => '0',
				 y_anchor             => '0',
				 wheel                => '',
				 x_offset             => '0',
				 y_offset             => '0',
				 line_units           => 'mm',
				 override_online      => 'yes',
				 film_size_cross_scan => '0',
				 film_size_along_scan => '0',
				 ds_model             => 'RG6500'
	);

}

#$inCAM->COM ('disp_on');
#$inCAM->COM ('origin_on');

sleep(5);
