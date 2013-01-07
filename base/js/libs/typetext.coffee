
expoVariate = (lambda, lower, upper) ->
  Math.min(Math.max(-Math.log(Math.random()) / lambda, lower), upper)

jQuery.fn.typeOut = (text, lambda=3) ->
  $target = @
  writeCharacter = (index) ->
    return if index > text.length
    $target.val(text[..index])
    timeToWait = expoVariate(lambda, 0, 1)
    setTimeout((-> writeCharacter(index + 1)),
      Math.floor(timeToWait * 1000))
  writeCharacter(0)
