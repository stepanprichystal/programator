# Global coupon settings

stepName           = coupon      # default step name
  padClearance     = 80          #�m
  pad2GNDClearance = 120         #�m
  padTrackSize     = 1524        #�m
  padGNDSize       = 1524        #�m
  padTrackShape    = s    #�m
padGNDShape 	 = r     #�m
padGNDSymNeg = thr2000x1800x0x4x203    #�m
  padDrillSize      = 1050             #�m
  trackPad2GNDPad   = 2540             # �m
  trackPad2TrackPad = 2540             # �m
  trackPadIsolation = 100              # �m
  trackToCopper     = 400              # �m

  cpnSingleWidth = 130                 # mm

  marginSingle   = 2000                # �m
  marginCoupon   = 2000                # �m
  couponSpace    = 1000                # �m
  groupPadsDist  = 4000                # �m
  twoEndedDesign = 1

  # pool settings
  maxTrackCnt = 5                      # two track per measurement layer in group
  poolCnt = 2 maxStripsCntH = 3 shareGNDPads = 1 routeBetween = 1 routeBelow = 1 routeAbove = 1 routeStraight = 1

  # Info text settings

  infoTextWidth = 1 infoTextHeight = 1 infoTextWeight = 0.2 padsTopTextDist = 2    # mm
  infoTextRightCpnDist   = 1                                                       #mm
  infoText               = 1                                                       # 1/0
  infoTextPosition       = right                                                   # top/right
  infoTextNumber         = 1                                                       # 1/0 numberingo of strips
  infoTextTrackImpedance = 1                                                       # 1/0
  infoTextTrackWidth     = 1                                                       # 1/0
  infoTextTrackLayer     = 1                                                       # 1/0
  infoTextTrackSpace     = 1                                                       # 1/0
  infoTextHSpacing       = 1                                                       #
  infoTextVSpacing       = 1                                                       #

  # Track pad text settings

  padTextWidth = 0.8 padTextHeight = 0.7 padTextWeight = 0.2 padTextDist = 0.15    # mm
  padText = 1                                                                      # 1/0
  padTextUnmask = 1 padTextClearance = 100                                         #�m

  # Guard tracks settings

  guardTracks          = 1                                                         # 1/0
  guardTracksType      = single                                                    # single - single lines, full - fill whole area except pads area
  guardTrack2TrackDist = 0.25                                                      #mm
  guardTrack2PadDist   = 0.4                                                       #mm
  guardTrackWidth      = 200                                                       # �m

  # General shielding for signal layers
  shieldingType = symbol                                                           # symbol/solid

  shieldingSymbol   = r50                                                          # �m incam symbol
  shieldingSymbolDX = 250                                                          # �m
  shieldingSymbolDY = 250                                                          # �m
