# Author: Mike

window.Blog = window.Blog || {}

_.sum = (seq) -> _.reduce(seq, ((memo, num) -> memo + num), 0)

String::toProperCase = ->
  @replace /\w\S*/g, (txt) -> txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

String::toCapitalCase = ->
  @charAt(0).toUpperCase() + @substr(1)

String::hashCode = ->
  hash = 0
  if @length is 0
    return hash
  i = 0
  while i < @length
    hash = ((hash << 5) - hash) + @charCodeAt(i)
    hash = hash & hash
    ++i
  hash

afterPjax = []
window.$$$ = (callback) ->
  afterPjax.push(callback)

Blog.pjax = (selector) ->
  $(selector).pjax
    fragment: ".main-subcontainer"
    container: ".outer-container"
    success: ->
      _.each afterPjax, (callback) -> callback()

Blog.$pjax = (url) ->
  $.pjax
    url: url
    fragment: ".main-subcontainer"
    container: ".outer-container"
    success: ->
      _.each afterPjax, (callback) -> callback()


Blog.isLive = _.include(["www.yaluandmike.com", "yaluandmike.com", "server.yaluandmike.com"], window.location.host)

Blog.url = (path) ->
  if Blog.isLive
    "//s3.amazonaws.com/yaluandmike/base#{path}"
  else
    "#{path}"

$ ->
  Blog.pjax(".navbar-inner a")
  $(document).on 'pjax:start', ->
    $(".outer-container").hide()
  $(document).on 'pjax:start', ->
    $(".outer-container").fadeIn(200)
  _.each afterPjax, (callback) -> callback()

$$$ ->
  Blog.pjax("a[data-pjax]")


if $.browser.mozilla
  popped = false
else
  popped = ('state' in window.history and window.history.state isnt null)

initialURL = window.location.href

$(window).bind 'popstate', (e) ->
  initialPop = !popped && location.href == initialURL
  popped = true
  return if (initialPop)

  _.each afterPjax, (callback) -> callback()

slugify = (text) ->
  text
    .replace(/[\W\s]+/g, '-')
    .toLowerCase()

$$$ ->
  Blog.pjax("a[data-pjax]")

$ ->
  _gaq.push ['_trackEvent', 'loadTime', location.href, undefined, parseInt(new Date() - window.startTime)]
  _gaq.push ['_trackEvent', 'renderTime', location.href, undefined, parseInt(window.renderTime - window.startTime)]


$$$ ->
  contentTmpl = $(".main-content").data("tmpl")
  $("ul.nav li").each () ->
    $li = $ @
    currentText = $("a", $li).text()

    if currentText is "Home"
      if contentTmpl is "/index.html"
        $li.addClass "active"
      else
        $li.removeClass "active"
      return
    if contentTmpl.indexOf($("a", $li).attr("href")) > -1
      $li.addClass "active"
    else
      $li.removeClass "active"
  $("body").attr "class", slugify($("ul.nav li.active").text())
  $("body").addClass slugify(location.pathname.replace(/\.html$/, '').replace(/(?:^\/|\/$)*/, ''))

$$$ ->
  Blog.loadDisqus() if $("#disqus_thread").length

Blog.loadDisqus = ->
  disqus_shortname = window.disqus_shortname = 'yaluandmike'
  return unless $("#disqus_thread").length
  dsq = document.createElement('script')
  dsq.type = 'text/javascript'
  dsq.async = true
  if location.protocol is 'https:'
    queryString = '?https'
  else
    queryString = ''
  dsq.src = "#{location.protocol}//#{disqus_shortname}.disqus.com/embed.js#{queryString}";
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq)
  $("hr.footer").removeClass("hide")

$$$ ->
  return unless $("body").hasClass "home"
  fixImageWidth = ->
    $(".front-image").width Math.max(
      $(".main-container").parent().width(),
      $(".main-container").outerWidth()
    )
  $(window).on "resize", _.debounce(fixImageWidth, 50)
  fixImageWidth()
  dateDiff = -moment().diff([2013, 04, 13], "days")
  $(".countdown").html "#{num2str(dateDiff).toCapitalCase()} days until <strong>5/12/13</strong>"


$$$ ->
  return unless $("body").hasClass "photos"

  $("#photo-nav-bar a").on "click", (e) ->
    e.preventDefault()
    target = @hash
    $.scrollTo target, 1000

  deferreds = []
  $(".album-container").each ->
    deferred = $.Deferred()
    deferreds.push deferred
    unless $("html").hasClass "lt-ie9"
      $container = $(@)
      $container.gpGallery(".picture-item")
    deferred.resolve()
  $.when(deferreds).then ->
    setTimeout((->
      $("body").scrollspy("refresh")
    ), 1000)
    setTimeout((->
      $("body").scrollspy("refresh")
    ), 600)
    setTimeout((->
      $("body").scrollspy("refresh")
    ), 1600)
    setTimeout((->
      $("body").scrollspy
        offset: 20
    ), 100)
