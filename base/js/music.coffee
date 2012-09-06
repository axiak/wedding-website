metadata = {}

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
      results = data?.results?.trackmatches?.track ? []
      window.results = results
      callback _.map(results, (track) ->
        key = "#{track.name} - #{track.artist}"
        metadata[key] = track
        key)

getMusicListing = _.debounce getMusicListing, 100

highlighter = (item) ->
  query = @query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&")
  text = item.replace new RegExp("(#{query})", "ig"), ($1, match) ->
    "<strong>#{match}</strong>"
  image = metadata[item]?.image?[0]?['#text']

  if image
    """<div class='typeahead-result'><span>#{text}</span><img src="#{image}"></div>"""
  else
    text



$$$ ->
  return unless $("body").hasClass "other-info"
  Parse.initialize("7lC1sG3cg8cozBZ6eU3cPei6FlkUAItUZTbTtJ3j", "QtEmWSrzpopTuBVTM44aUAlDIsUFntQXDZagAj96")
  MusicRequest = Parse.Object.extend("MusicRequest")

  $form = $("#music-request")
  $("#song-name").typeahead
    source: getMusicListing
    minLength: 3
    highlighter: highlighter

  $form.on "submit", (e) ->
    e.preventDefault()
    title = $("#song-name").val()
    return unless title
    name = $("#submitter-name").val()
    lastFmUrl = metadata[title]?.url
    newRequest = new MusicRequest()
    newRequest.save {name, lastFmUrl, title}

    _gaq.push ['_trackEvent', 'musicRequest', name, title, undefined, true]

    $(".alert-success", $form).fadeIn()
    $("#song-name").val('')
