class Async
  #----------------------------------------------------------------
  # Walker (with binding each object to callback)
  #
  # Script:
  #   Async.apply_each(
  #     [a, b, c],
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
  #         -> console.log(false),
  #         -> console.log(true),
  #       ),
  #       -> console.log(true),
  #     ),
  #     ->console.log(true)
  #   )
  #
  @apply_each: (objects, callback, final) ->
    final or= -> null
    next = (index, next) ->
      return final(true) unless index < objects.length
      each.call(
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
  #     [a, b, c],
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
  #         -> console.log(false),
  #         -> console.log(true),
  #       ),
  #       -> console.log(true),
  #     ),
  #     ->console.log(true)
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

