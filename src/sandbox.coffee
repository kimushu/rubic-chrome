#  editor = ace.edit("editor")
#  editor.setTheme("ace/theme/github")
#  editor.getSession().setMode("ace/mode/ruby")
#  displayPath = (fileEntry) ->
#    chrome.fileSystem.getDisplayPath(fileEntry, (path) ->
#      console.log(path)
#    )
#  dnd = new DndFileController('#editor', (data) ->
#    fileEntry = data.items[0].webkitGetAsEntry()
#    console.log(fileEntry)
#    displayPath(fileEntry)
#  )
