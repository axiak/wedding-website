
if $.browser.safari or ($.browser.mozilla and parseInt($.browser.version) >= 11)
  if location.protocol is "http:" and window.location.host == "www.yaluandmike.com"
    window.location.replace("https#{window.location.href.substring(4)})")