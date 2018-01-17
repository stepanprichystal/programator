
use Win32;
use Win32::GUI;    #added
use Win32::API;

use constant AW_HOR_POSITIVE => 0x00000001;
use constant AW_HOR_NEGATIVE => 0x00000002;
use constant AW_VER_POSITIVE => 0x00000004;
use constant AW_VER_NEGATIVE => 0x00000008;
use constant AW_CENTER       => 0x00000010;
use constant AW_HIDE         => 0x00010000;
use constant AW_ACTIVATE     => 0x00020000;
use constant AW_SLIDE        => 0x00040000;
use constant AW_BLEND        => 0x00080000;

# BOOL AnimateWindow(
# HWND hwnd,
# DWORD dwTime,
# DWORD dwFlags
# );
my $AnimateWindow = new Win32::API( "user32", "AnimateWindow", [ 'N', 'N', 'N' ], 'N' ) or $reg{'UI'}{'Fading'} = 0;

# ... here create your window object ($winObj) as ususal...
#my $winObj = new GUI::Window(-title=>"Test", -left=>10, -top=>10,
#-width=>640, -height=>480, -name=>"Window",); #added
#

# set animation duration in ms (usually 200ms)
my $msec = 200;

use Win32::GuiTest qw(:ALL);

my @windows = FindWindowLike( 0, "test" );

for (@windows) {

	# FADE IN
	# use this command in place of $objWin->Show()
	$AnimateWindow->Call( $_, $msec, AW_ACTIVATE | AW_BLEND );
}

# FADE OUT
# use this command in place of $objWin->Hide() for example in
#winObj_Terminate()
#    $AnimateWindow->Call($winObj->{-handle}, $msec, AW_HIDE | AW_BLEND );
#
#
## Some alternatives follows...
#
## APPEAR from LEFT-TOP
## use this command in place of $objWin->Show()
#$AnimateWindow->Call($winObj->{-handle}, $msec, AW_ACTIVATE | AW_SLIDE |
#AW_HOR_POSITIVE | AW_VER_POSITIVE );
#
## DISAPPEAR from RIGHT-BOTTOM
## use this command in place of $objWin->Hide() for example in
#winObj_Terminate()
#$AnimateWindow->Call($winObj->{-handle}, $msec, AW_HIDE | AW_SLIDE |
#AW_HOR_NEGATIVE | AW_VER_NEGATIVE );
#
## GROW from CENTER
## use this command in place of $objWin->Show()
#$AnimateWindow->Call($winObj->{-handle}, $msec, AW_ACTIVATE | AW_CENTER );
#
## SHRINK to CENTER
## use this command in place of $objWin->Hide() for example in
#winObj_Terminate()
#$AnimateWindow->Call($winObj->{-handle}, $msec, AW_HIDE | AW_CENTER );
