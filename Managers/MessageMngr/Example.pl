
#-------------------------------------------------------------------------------------------#
# Description: Example HOW to use Message manager
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';

# Mesage window types:
# -----------------------
# MessageType_ERROR
# MessageType_SYSTEMERROR
# MessageType_WARNING
# MessageType_QUESTION
# MessageType_INFORMATION

# Mesage text definition:
# -----------------------
my $str = "Druha <r>FAIL</r> TEST <g>GREEN</g> konec \n";

my @mess1 = ( "Prvni zprava\n", $str );
push( @mess1, "<img1>" );
push( @mess1, "dalsi t<img1>ext" );

# Buttons definition:
# -----------------------
my @btn = ( "tl1", "tl2", "tl2" );

# Image collection:
# -----------------------
# Each image is defined by array ref:
# - 0 index = cislo obrazku (umisteni pomoci tagu <img<cislo orazku>>)
# - 1 index = cesta
# - 2 index = typ obrazku
my @imgs = ();
my $p    = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\small_coplanar_diff_coated_embedded_without_gnd.bmp";
push( @imgs, [ 1, $p, &Wx::wxBITMAP_TYPE_BMP ] );

my $messMngr = MessageMngr->new("D3333");

# --------------------------------------------
# Display message window: ShowModal()
# --------------------------------------------

$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn, \@imgs );    #  Script is stopped

my $btnNumber = $messMngr->Result();    # return button order of pressed button (start number is 0, counted from left)

# --------------------------------------------
# Display message window: Show()
# --------------------------------------------
#$messMngr->Show( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );    #  Script do not stop and continue

1;
