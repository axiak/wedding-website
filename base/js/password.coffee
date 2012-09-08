window.Blog = window.Blog || {}

Blog.isPhone = -> $(window).width() < 480 or !!(/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent))

_gaq = _gaq || []

pwCookieName = "_IAMSEEN"
mainPw =
  '31538022dfb72e2a2a8e03f007217394adb4a9d1': 1

authorizeUser = ->
  $(".initial-backdrop").remove()
  $('html').css('overflow', '')
  $(".container").removeClass("blurred")
  $("#pw-modal").modal 'hide'

checkPassword = (password, success, error) ->
  if mainPw[hex_sha1(password.toLowerCase())]
    _gaq.push ['_trackEvent', 'passwordSuccess', location.href, password, undefined]
    $.cookie pwCookieName, password,
      expires: 7
      path: "/"
    success()
  else
    error()

showModal = ->
  $("#pw-modal").modal
    backdrop: false
    keyboard: false
    show: true

  $("#pw-modal form").on 'submit', (e) ->
    e.preventDefault()
    checkPassword $("#pw-modal .pw-answer").val(), (->
      authorizeUser()), (->
      $("#pw-modal .alert").show()
    )

  $(".container").addClass("blurred")
  if $(window).width() >= 480
    $('html').css('overflow', 'hidden')

showPrompt = ->
  answer = prompt("Who isn't the worlds best detective?")
  checkPassword answer, authorizeUser, showPrompt

val = $.cookie(pwCookieName)

if val and mainPw[hex_sha1(val.toLowerCase())]
  authorizeUser()
else
  if Blog.isPhone()
    showPrompt()
  else
    showModal()

