
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Style;
 


#3th party library

use warnings;

use Wx;
use Wx qw( :font);
 
#local library


 

#define default colours
	 $clrDefaultFrm    = Wx::Colour->new( 215, 220, 238 );
	 $clrStatusBar     = Wx::Colour->new( 135, 157, 182 );
	 $clrDefaultTxtBox = Wx::Colour->new( 248, 248, 248 );
	
	$clrError = Wx::Colour->new( 255, 164, 164 );
	$clrSystemError = Wx::Colour->new(50, 50, 50  );
	$clrWarning = Wx::Colour->new(255, 255, 128  );
	$clrInfoQuestion = Wx::Colour->new(248, 248, 248  );
	
	$clrErrorLight = Wx::Colour->new( 255, 210, 210 );
	$clrWarningLight = Wx::Colour->new(255, 255, 154  );
	
	$clrWhite = Wx::Colour->new(255, 255, 255  );
	$clrLightGray = Wx::Colour->new(230, 230, 230 );
	$clrLightRed = Wx::Colour->new( 255, 164, 164 );
	$clrLightGreen = Wx::Colour->new( 200, 233, 171 );
	$clrBlack = Wx::Colour->new(0, 0, 0  );
	
	
	$clrDarkGray = Wx::Colour->new(127, 127, 127 );

	#define default fonts
	$fontLbl =
	  Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_NORMAL );
	$fontLblBold =
	  Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_BOLD );
	$fontBtn =
	  Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_NORMAL );
	$fontSmallLbl =
	  Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_NORMAL );
	$fontSmallLblBold =
	  Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_BOLD );



1;