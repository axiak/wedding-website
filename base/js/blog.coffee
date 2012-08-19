
$$$ ->
  template = false
  return unless $("body").hasClass("notes")

  if template is false
    template = _.template($("#tmpl-post").html())

  notesUrl = 'http://api.tumblr.com/v2/blog/mcaxiak.tumblr.com/posts'

  params =
    api_key: '9T0k9Qsc5KUXwx69fDd6WtlyTEbUIxDshgBVHnOAFolcxBN5dw'
    limit: 3

  locationInfo = location.search ? location.hash
  matches = locationInfo?.match /\?(after|post)=(\d+)/

  showComments = false

  if matches and matches[1] is "after"
    params.offset = matches[2]
  else if matches
    params.id = matches[2]
    showComments = true

  $container = $("#post-container")
  $.ajax
    type: "GET"
    url: notesUrl
    dataType: "jsonp"
    data: params
    jsonp: "jsonp"
    success: (data) ->
      unless data?.response?.posts?.length
        $container.html("There are no notes to display.")
      _.each data?.response?.posts, (post) ->
        post.displayTime = moment(post.timestamp * 1000).format "dddd, MMMM Do YYYY, h:mm a"
        post.showComments = showComments
        $container.append(template(post: post))
      if $("#disqus_thread").length
        Blog.loadDisqus()

      start = ~~(params.offset || 0)
      currentMax = start + params.limit
      $btnContainer = $(".post-pagination")
      numShown = 0
      if start > 0
        if (start - params.limit) > 0
          href = "/notes/?after=#{start - params.limit}"
        else
          href = "/notes/"

        $(".previous", $btnContainer)
          .attr("href", href)
          .show()

        numShown += 1

      if currentMax < data.response?.total_posts
        $(".next", $btnContainer)
          .attr("href", "/notes/?after=#{currentMax}")
          .show()

        numShown += 1
      if numShown is 2
        $(".pipe", $btnContainer).show()




