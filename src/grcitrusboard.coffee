###*
@class
GR-CITRUS board support
###
class GrCitrusBoard extends WakayamaRbBoard
  Board.addBoard(this)

  #----------------------------------------------------------------
  # Class attributes/methods

  @boardname: "GR-CITRUS"
  @author: "FIXME"
  @website: "FIXME"

  @WRBB_POLL_BYTE: undefined
  @WRBB_SEND_BYTES: 16
  @WRBB_SEND_INTERVAL: 50

window.Rubic.GrCitrusBoard = GrCitrusBoard
