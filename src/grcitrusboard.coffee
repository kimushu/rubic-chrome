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
  @WRBB_SEND_BYTES: null
  @WRBB_SEND_INTERVAL: 50
  @WRBB_H_RETRY: 250

window.Rubic.GrCitrusBoard = GrCitrusBoard
