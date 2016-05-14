###*
@class
GR-CITRUS board support
###
class GrCitrusBoard extends WakayamaRbBoard
  Board.addBoard(this)

  #----------------------------------------------------------------
  # Class attributes/methods

  @boardname: "GR-CITRUS"
  @author: "Wakarama.rb"
  @website: "https://github.com/wakayamarb/wrbb-v2lib-firm"

  @WRBB_POLL_BYTE: undefined
  @WRBB_SEND_BYTES: null
  @WRBB_SEND_INTERVAL: 50
  @WRBB_H_RETRY: 250

window.Rubic.GrCitrusBoard = GrCitrusBoard
