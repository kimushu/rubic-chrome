class Board
  @list: []
  @add: (subclass) -> @list.push(subclass)
  @load: (data) -> Marshal.load(data, @list)

  selected: ->
    # Display selected board name
    $('#dropdown-board').find('.ph-body').text(@constructor.boardname)

    # Refresh port list
    $('#dropdown-port-list')
      .empty()
      .append("""
      <li class="btn-xs">
        <a href="#" class="port-rescan">Rescan ports</a>
      </li>
      <li class="divider"></li>
      <li id="port-none" class="btn-xs disabled"><a>No available port</a></li>
      """
      )
    do (_this = this) ->
      $('a.port-rescan').click(->
        _this.selected()
      )
    $('#dropdown-port')
      .prop('disabled', true)
      .find('.ph-body').empty()
    c.enumerate((ports) ->
      $('#dropdown-port').prop('disabled', false)
      return if ports.length == 0
      $('li#port-none').remove()
      $('#dropdown-port-list').append("""
        <li class="btn-xs">
          <a href="#" title="#{p.path}" class="port-#{c.name}">#{p.name}</a>
        </li>
        """
      ) for p in ports
      $("a.port-#{c.name}").click(->
        $('#dropdown-port').find('.ph-body').text(this.text)
        # sketch.
      )
    ) for c in @constructor.comm

$(->
  # Display supported board list
  for b in Board.list
    do (b) ->
      $('#dropdown-board-list')
        .append("""
          <li class="btn-xs">
            <a href="#" id="board-#{b.name}" title="Author: #{b.author
            }&#10;Website: #{b.website}">#{b.boardname}</a>
          </li>
          """
        )
      $("a#board-#{b.name}").click(->
        console.log({"Board selected": b})
        App.sketch.board = new b
      )
)
