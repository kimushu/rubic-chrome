###*
@class
Asynchronous utilities for CoffeeScript
###
class Async
  #----------------------------------------------------------------
  # Walker (with binding each object to callback)
  #
  # Script:
  #   Async.apply_each(
  #     [a, b, c]
  #     (next, abort) ->      # (callback next, callback abort)
  #       @save(next, abort)
  #     (done) =>             # (boolean done)
  #       console.log(done)
  #   )
  #
  # Behavior:
  #   a.save(
  #     -> b.save(
  #       -> c.save(
  #         -> console.log(true)
  #         -> console.log(false)
  #       )
  #       -> console.log(false)
  #     )
  #     -> console.log(false)
  #   )
  #
  @apply_each: (objects, callback, final) ->
    final or= -> null
    next = (index, next) ->
      return final(true) unless index < objects.length
      callback.call(
        objects[index],
        (-> next(index + 1, next)),
        (-> final(false))
      )
    return next(0, next)

  #----------------------------------------------------------------
  # Walker (with passing each object as an argument)
  #
  # Script:
  #   Async.each(
  #     [a, b, c]
  #     (item, next, abort) ->  # (object item,
  #                             #  callback next, callback abort)
  #       item.save(next, abort)
  #     (done) =>               # (boolean done)
  #       console.log(done)
  #   )
  #
  # Behavior:
  #   a.save(
  #     -> b.save(
  #       -> c.save(
  #         -> console.log(false)
  #         -> console.log(true)
  #       )
  #       -> console.log(true)
  #     )
  #     -> console.log(true)
  #   )
  @each: (objects, callback, final) ->
    final or= -> null
    next = (index, next) ->
      return final(true) unless index < objects.length
      callback(
        objects[index],
        (-> next(index + 1, next)),
        (-> final(false))
      )
    return next(0, next)

  #----------------------------------------------------------------
  # Sequencer
  #
  # Script:
  #   abort = -> console.log("aborted")
  #   Async.seq(                            # or "Async.sequence"
  #     (next) =>
  #       @send((=> next("foo")), abort)
  #     (next, text) =>
  #       console.log("text:#{text}")
  #       @recv((=> console.log("finished")), abort)
  #   )
  #
  # Behavior:
  #   abort = -> console.log("aborted")
  #   @send((=>
  #     console.log("text:#{text}")
  #     @recv(
  #       (=> console.log("finished")),
  #       abort
  #     )
  #   ), abort)
  #
  #  @seq: (jobs, done, first) ->
  #    next = (index, next, args) ->
  #      return null unless index < list.length
  #      args.unshift(-> next(index + 1, next, arguments))
  #      jobs[index].apply(this, args)
  #    return next(0, 

unless Function.Sequence
  ###*
  @private
  @class
    非同期関数を用いたシーケンス実行クラス
  ###
  class Function.Sequence
    ###*
    @property {function(Function.Sequence)[]}
      シーケンスで実行する要素の関数リスト
    @readonly
    ###
    @list: null

    ###*
    @property {function(Function.Sequence)}
      シーケンス終了時に成功失敗にかかわらず呼び出される関数。
      finalメソッドでも設定可能。
    ###
    onFinal: null

    ###*
    @property {null/number}
      現在実行中の要素番号(シーケンス開始前はnull)
    @readonly
    ###
    index: null

    ###*
    @property {boolean}
      異常終了したかどうか
    @readonly
    ###
    aborted: false

    ###*
    @property {boolean}
      正常終了したかどうか
    @readonly
    ###
    finished: false

    ###*
    @method constructor
      コンストラクタ
    @param {function(Function.Sequence)[]} list...
      初期状態で追加するシーケンス要素の関数リスト
    ###
    constructor: (@list...) ->

    ###*
    @method
      シーケンス要素を末尾に追加する
    @param {function(Function.Sequence)[]} f...
      追加するシーケンス要素の関数(複数可)
    @chainable
    @return {Function.Sequence} this
    ###
    add: (f...) ->
      @list.push(f...)
      return this

    ###*
    @method
      シーケンス終了時に成功失敗にかかわらず呼び出される関数を登録する
    @param {function(Function.Sequence)} f
      登録する関数
    @chainable
    @return {Function.Sequence} this
    ###
    final: (f) ->
      @onFinal = f
      return this

    ###*
    @method
      シーケンスを開始する
    @return {void}
    ###
    start: ->
      @index = -1
      @aborted = false
      @finished = false
      @next(true)
      return

    ###*
    @method
      シーケンスを一つ次へ進める(次が無ければ正常終了する)。または異常終了する。
    @param {boolean} [success]
      現在の要素が正常終了したかどうか(省略時true)。falseを指定するとシーケンスを異常終了する。
    @return {void}
    ###
    next: (success) ->
      return if @aborted or @finished or @index == null
      if success == false
        @aborted = true
        @onFinal?(this)
        return
      @index += 1
      if @index >= @list.length
        @finished = true
        @onFinal?(this)
        return
      @redo()
      return

    ###*
    @method
      シーケンスを次に進めずに、現在の要素をもう一度繰り返す。
    @return {void}
    ###
    redo: ->
      return if @aborted or @finished or @index == null
      @list[@index].call(this, this)
      return

    ###*
    @method
      シーケンスを異常終了させる。next(false)に同じ。
    @return {void}
    ###
    abort: ->
      @next(false)
      return

