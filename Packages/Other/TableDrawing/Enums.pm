
package Packages::Other::TableDrawing::Enums;

use constant {
			   CoordSystem_LEFTTOP => "CoordSystem_LeftTop",    # Origin is located in left top corner of "canvas" (x raise right, y raise top)
			   CoordSystem_LEFTBOT => "CoordSystem_LeftBOT",    # Origin is located in left bot corner of "canvas" (x raise right, y raise bot)
};

use constant {
			   Units_MM => "units_mm",                          # i inch = 72points; 1mm = 1/25,4inch
			   Units_PT => "units_pt",                          # i inch = 72points; 1mm = 1/25,4inch
};

use constant {
			   EdgeStyle_NONE        => "Edge_none",            # none edge
			   EdgeStyle_SOLIDSTROKE => "Edge_solidstroke",     # stroke line
			   EdgeStyle_DASHED      => "Edge_dashedstroke",    # dashed line
};

use constant {
			   BackgStyle_NONE     => "BackgStyle_none",        # none color
			   BackgStyle_SOLIDCLR => "BackgStyle_solidclr",    # stroke line
};

use constant {
			   Font_NORMAL => "Font_normal",                    # none color
			   Font_BOLD   => "Font_bold",                      # none color
			   Font_ITALIC => "Font_italic",                    # none color
};

use constant {
			   FontFamily_ARIAL => "FontFamily_Arial",          # none color
			   FontFamily_TIMES => "FontFamily_Times",          # none color
};

use constant {
			   TextStyle_LINE      => "TextStyle_line",         # none color
			   TextStyle_MULTILINE => "TextStyle_multiline",    # none color
			   TextStyle_PARAGRAPH => "TextStyle_paragraph",    # none color
};

use constant {
	TextVAlign_TOP    => "TextVAlign_top",           # none color
	TextVAlign_CENTER => "TextVAlign_center",        # none color
	TextVAlign_BOT    => "TextVAlign_bot",           # none color

	TextHAlign_LEFT   => "TextHAlign_left",          # none color
	TextHAlign_CENTER => "TextHAlign_center",        # none color
	TextHAlign_RIGHT  => "TextHAlign_right",         # none color
};

use constant {
			   DrawPriority_TABBORDER  => "DrawPriority_TABBORDER",     # table frame
			   DrawPriority_COLLBACKG  => "DrawPriority_COLLBACKG",     # column background
			   DrawPriority_COLLBORDER => "DrawPriority_COLLBORDER",    # column border
			   DrawPriority_ROWBACKG   => "DrawPriority_ROWBACKG",      # row background
			   DrawPriority_ROWBORDER  => "DrawPriority_ROWBORDER",     # row border
			   DrawPriority_CELLBACKG  => "DrawPriority_CELLBACKG",     # cell background
			   DrawPriority_CELLBORDER => "DrawPriority_CELLBORDER",    # cell border
			   DrawPriority_CELLTEXT   => "DrawPriority_CELLTEXT",      # cell text
};

1;
