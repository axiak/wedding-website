getMusicListing = (query, callback) ->
  params =
    method: "track.search"
    api_key: "3fddc47b7d85b89c46603e3804674a9c"
    format: "json"
    track: query
  $.ajax
    url: "//ws.audioscrobbler.com/2.0/?#{$.param params}"
    type: "GET"
    success: (data) ->
      results = data?.results?.trackmatches ? []
      callback _.map(results, (track) -> "#{track.name} - #{track.artist}")


$$$ ->
  return unless $("body").hasClass "other-info"
  $form = $("#music-request")
  $("#song-name").typeahead
    source: getMusicListing
    minLength: 3
