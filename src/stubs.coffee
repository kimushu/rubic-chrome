unless chrome.serial?
  console.warn("chrome.serial is provided as a stub")
  e = {addListener: (-> return), removeListener: (-> return)}
  chrome.serial = {onReceive: e, onReceiveError: e}
