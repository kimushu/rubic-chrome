class Board
  @list: [] # List of all supported boards

  @load: (data) ->
    Marshal.load(data, @list)

  selected: ->
    $('#dropdown-board')
      .html("#{@constructor.boardname} <span class=\"caret\"/>")
    $('#dropdown-port-list')
      .empty()
      .append("""
      <li id="port-none" class="btn-xs disabled">
        No available port
      </li>
      """
      )
    $('#dropdown-port')
      .html("Select port <span class=\"caret\"></span>")
      .prop("disabled", true)
    i.enumerate((ports) ->
      $('#dropdown-port').prop("disabled", false)
      return if ports.length == 0
      $('li#port-none').remove()
      $('#dropdown-port-list').append("""
        <li class="btn-xs">
          <a href="#" title="#{p.path}" class="port-#{i.name}">#{p.name}</a>
        </li>
        """
      ) for p in ports
      $("a.port-#{i.name}").click(->
        $("#dropdown-port")
          .html("#{this.text} <span class=\"caret\"></span>")
        #sketch.board.port
      )
    ) for i in @constructor.interface

$ ->
  for b in Board.list
    $('#dropdown-board-list')
      .append("""
        <li class="btn-xs">
          <a href="#" id="board-#{b.name}" title="Author: #{b.author
          }&#10;Website: #{b.website}">#{b.boardname}</a>
        </li>
        """
      )
    $("a#board-#{b.name}").click(->
      sketch.board = new b
    )

  #$('#dropdown-board-list li a').click(->
  #  $(this).parents('.btn-group')
  #         .find('.dropdown-toggle')
  #         .html("#{$(this).text()} <span class=\"caret\"></span>")
  #)

