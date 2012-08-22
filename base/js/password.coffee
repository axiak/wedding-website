pwCookieName = "_IAMSEEN"
mainPw =
  '31538022dfb72e2a2a8e03f007217394adb4a9d1': 1

authorizeUser = ->
  $(".initial-backdrop").remove()
  $('html').css('overflow', '')
  $(".container").removeClass("blurred")
  $("#pw-modal").modal 'hide'

showModal = ->
  $("#pw-modal").modal
    backdrop: false
    keyboard: false
    show: true
  $("#pw-modal form").on 'submit', (e) ->
    e.preventDefault()
    password = $("#pw-modal .pw-answer").val().toLowerCase()
    if mainPw[hex_sha1(password)]
      $.cookie pwCookieName, password,
        expires: 7
        path: '/'
      authorizeUser()
    else
      $("#pw-modal .alert").show()
  $(".container").addClass("blurred")
  $('html').css('overflow', 'hidden')


val = $.cookie(pwCookieName)

if val and mainPw[hex_sha1(val.toLowerCase())]
  authorizeUser()
else
  showModal()

