return unless Modernizr.svg


class NavVisualization
  @links = [
    source: "_root"
    target: "Home"
  ,
    source: "Home"
    target: "How we met"
  ,
    source: "How we met"
    target: "Engagement Story"
  ,
    source: "Home"
    target: "Engagement Story"
  ,
    source: "Engagement Story"
    target: "Photos"
  ,
    source: "Photos"
    target: "Wedding Party"
  ,
    source: "Wedding Party"
    target: "Place & Time"
  ,
    source: "Place & Time"
    target: "Updates"
  ,
    source: "Updates"
    target: "Other Info"
  ,
    source: "Other Info"
    target: "Engagement Story"
  ]

  @hrefs =
    "Home": "/"
    "How we met": "/story/"
    "Engagement Story": "/engagement/"
    "Photos": "/pictures/"
    "Wedding Party": "/party/"
    "Place & Time": "/venue/"
    "Updates": "/updates/"
    "Other Info": "/other/"

  constructor: (width, height) ->
    $(".main-container").css 'margin-top', '100px'
    @links = NavVisualization.links
    @hrefs = NavVisualization.hrefs
    _.bindAll @, "click", "transformFunc", "tick", "defaultIfHidden", "hasHref"

    @width = width
    @height = height
    @initializeNodes()

    @svg = d3.select("#nav-chart")
      .append("svg:svg")
      .attr("width", width)
      .attr("height", height)

    @setupForce()
    @draw()

  draw: ->
    @buildLinks()
    @buildNodes()

  initializeNodes: ->
    @nodes = {}
    @links.forEach (link) =>
      link.source = @nodes[link.source] ? (@nodes[link.source] = {name: link.source})
      link.target = @nodes[link.target] ? (@nodes[link.target] = {name: link.target})

  setupForce: ->
    @force = d3.layout.force()
      .nodes(d3.values(@nodes))
      .size([@width, @height])
      .links(@links)
      .charge(-600)
      .linkDistance(100)
      .on("tick", @tick)
      .start()

  buildLinks: ->
    @link = @svg.selectAll("line.link")
      .data(@force.links())

    @link.enter()
      .insert("line", ".node")
      .attr("class", "link")
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
    @link.exit().remove()


  buildNodes: ->
    @node = @svg.append("svg:g").selectAll("circle")
      .data(@force.nodes())
    @node.exit().remove()

    @node.enter()
      .append("svg:rect")
      .attr("class", "node")
      .attr("rx", @defaultIfHidden(6, 0))
      .attr("ry", @defaultIfHidden(6, 0))
      .attr("width", @defaultIfHidden(150, 0))
      .attr("height", @defaultIfHidden(20, 0))
      .call(@force.drag)
      .on("click", @click)

    @text = @svg.append("svg:g").selectAll("g")
      .filter(@hasHref).data(@force.nodes())

    @text.exit().remove()

    @textGroup = @text.enter()
      .append("svg:g")
      .attr("class", "node")
      .on("click", @click)
      .call(@force.drag)

    @textGroup.append("svg:text")
      .attr("x", 8)
      .attr("y", ".3em")
      .attr("class", "shadow")
      .text(@defaultIfHidden(((d) -> d.name), ''))

    @textGroup.append("svg:text")
      .attr("x", 8)
      .attr("y", ".3em")
      .text(@defaultIfHidden(((d) -> d.name), ''))

  click: (d, i, e) ->
    href = @hrefs[d.name]
    if href
      @navigate(href)
    else if d.children
      d._children = d.children
      d.children = null
    else
      d.children = d._children
      d._children = null

  navigate: (href) ->
    e = d3.event
    return if href == location.href
    if @usePjax(e, href)
      Blog.$pjax href
    else
      window.location.href = href

  usePjax: (e, href) ->
    return false unless $.support.pjax
    return false if e.which > 1 or e.metaKey or e.ctrlKey
    link = $("<a/>")
    link = link.attr("href", href)[0]
    return false if location.protocol isnt link.protocol or location.host isnt link.host
    true

  hasHref: (d) ->
    !!(@hrefs[d.name])

  defaultIfHidden: (n, def=0) ->
    (d) =>
      if @hrefs[d.name]
        if _.isFunction(n)
          n(d)
        else
          n
      else
        def

  tick: ->
    @link
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    @node.attr("transform", @transformFunc(10))
    @text.attr("transform", @transformFunc())

  transformFunc: (offsetY=0) ->
    (d) =>
      if d.index is 0
        damper = 0.1
        d.x = d.x + (-20 - d.x) * (damper + 0.71) * 0.5
        d.y = d.y + (@height / 2 - d.y) * (damper + 0.71) * 0.5

      r = d.name.length
      d.x = Math.max(-10, Math.min(@width - r, d.x))
      d.y = Math.max(r, Math.min(@height - r, d.y))

      "translate(#{d.x}, #{d.y - offsetY})"

$ ->
  nav = new NavVisualization($(window).width(), 150)

