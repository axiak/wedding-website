window.Blog = window.Blog || {}

Blog.isPhone = -> $(window).width() < 480 or !!(/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent))

_gaq = _gaq || []

pwCookieName = "_IAMSEEN"
mainPw =
  '0ebe94f6218a33b9adf5d7bcffe06e71b10cce1b': 1 # shinichi
  'bb7ff8f13adabcc9505660f185214c5af8162ec9': 1 # mori
  'de2f0bf6779a3f842a3fc744413294ed19180343': 1 # kogoro
  'c45cd80a556f432a3607171a6818cd5a074b5cd4': 1 # jin
  '28c2def44d63e33804a47aaf04226f8f95ef6f91': 1 # vokka
  '272d162ce4173a0480e0834a48421bc5b0a26da8': 1 # edogawa
  'ecbd8af733a17803b66ee4321b23f87f103cc9ca': 1 # ayumi
  'ed011358f1b2c7bdf2c58a9d13d251e4ad2aac7c': 1 # mitsuhiko
  'e01721035c4856a59f5bcb368d87aef7de0529ae': 1 # genta
  'a480de7811283751e1558c5703081da73e4d3190': 1 # shiho
  '2cc5420872645ee927bbd68e9f0025b06ecb6793': 1 # megure
  '2f0431f0bfe30fcf1a1148ad4a3cd170d2237fbe': 1 # sato
  '517d88ca04f7cce2bb7c7d5b3d525a37f3d2b1de': 1 # takagi
  '37b19054cbc49172edd7fc3e762eb695cac832a1': 1 # ninzaburo
  '8b13d25aa3d2fb6c3db440e0263e1b8f06381b92': 1 # kiyonaga
  'fc5ce85d6ddc60da9b367fd86a6b3a89d426bd64': 1 # agasa
  '2d5cd350c7a48263c670a6374c5c55bca8d1a68a': 1 # suzuki
  '573bb4a6ef9c5426b6ff755d1dfcf605b12a27d6': 1 # yusaku
  '23ed30a594145905e5fb264400bdab1ee8bb5c1c': 1 # kaito
  'f5e53e6973451b0efebfcb7e399d0f41367a244c': 1 # yukiko

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
  answer = prompt("Please enter your password")
  checkPassword answer, authorizeUser, showPrompt

val = $.cookie(pwCookieName)

if val and mainPw[hex_sha1(val.toLowerCase())]
  authorizeUser()
else
  if Blog.isPhone()
    showPrompt()
  else
    showModal()

