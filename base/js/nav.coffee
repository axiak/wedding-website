return unless Modernizr.svg


class NavVisualization
  @links = [
    source: "_root"
    target: "Home"
    thickness: 7
  ,
    source: "Home"
    target: "How we met"
    thickness: 4
  ,
    source: "How we met"
    target: "Photos"
    thickness: 2
  ,
    source: "Home"
    target: "Proposal"
    thickness: 4
  ,
    source: "Proposal"
    target: "Wedding Party"
    thickness: 2
  ,
    source: "Wedding Party"
    target: "Place & Time"
    thickness: 1
  ,
    source: "Wedding Party"
    target: "Updates"
    thickness: 1

  ]
  @hrefs =
    "Home": "/"
    "How we met": "/story/"
    "Proposal": "/engagement/"
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

    @activeLeaf = @activeFromUrl()
    @transitionLayout = false
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
    @force
      .nodes(d3.values(@nodes))
      .size([@width, @height])
      .links(@links)
      .start()

    @buildLinks()
    @buildNodes()


  activeFromUrl: ->
    active = "Home"
    _.each @hrefs, (v, k) ->
      if location.pathname.indexOf(v) isnt -1
        active = k
        return false
    active

  isNodeActive: (node) ->
    node.name is @activeLeaf

  isLinkActive: (d) ->
    @isNodeActive(d?.source?.name) or @isNodeActive(d?.target?.name)

  initializeNodes: ->
    @nodes = {}
    @links.forEach (link) =>
      link.source = @nodes[link.source] ? (@nodes[link.source] = {name: link.source})
      link.target = @nodes[link.target] ? (@nodes[link.target] = {name: link.target})

  setupForce: ->
    @force = d3.layout.force()
      .gravity(=>
        if @transitionLayout
          .9
        else
          0.001)
      .charge((d) =>
        if @transitionLayout
          -200
        else if @isNodeActive(d)
          -1200
        else
          -900)
      .linkStrength((d) =>
        if @isLinkActive(d)
          0.6
        else
          1)
      .theta(1)
      .linkDistance((d) =>
        if @isLinkActive(d)
          300
        else
          Math.round((@width - 100) / 6))
      .on("tick", @tick)

  buildLinks: ->
    @link = @svg.selectAll("line.link")
      .data(@force.links())

    @link.enter()
      .append("svg:path")
      .attr("d", "M0,-5L10,0L0,5")
      .attr("class", "link")
      .attr("stroke-width", (d) =>  d.thickness)
      #.attr("x1", (d) -> d.source.x)
      #.attr("y1", (d) -> d.source.y)
      #.attr("x2", (d) -> d.target.x)
      #.attr("y2", (d) -> d.target.y)
    @link.exit().remove()


  buildNodes: ->
    @node = @svg.append("svg:g").selectAll("circle")
      .data(@force.nodes())
    @node.exit().remove()

    @node.enter()
      .append("svg:image")
      .attr("class", (d) => if @isNodeActive(d) then "node active" else "node")
      .attr("xlink:href", "//s3.amazonaws.com/yaluandmike/base/img/wisteria.png")
      .attr("width", @defaultIfHidden(100, 0))
      .attr("height", @defaultIfHidden(80, 0))
      .call(@force.drag)
      .on("click", @click)

    @text = @svg.append("svg:g").selectAll("g")
      .filter(@hasHref).data(@force.nodes())

    @text.exit().remove()

    @textGroup = @text.enter()
      .append("svg:g")
      .attr("class", (d) => if @isNodeActive(d) then "node active" else "node")
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
      @transitionLayout = true
      @force.alpha(1)
      @force.start()
      setTimeout((=>
        @transitionLayout = false
        @force.alpha(0.1)
        @draw()), 500)



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
    @link.attr "d", (d) ->
      dx = d.target.x - d.source.x
      dy = d.target.y - d.source.y
      dr = Math.sqrt(dx * dx + dy * dy) * 5
      "M#{d.source.x},#{d.source.y}A#{dr},#{dr} 0 0,1 #{d.target.x},#{d.target.y}"

    @node.attr("transform", @transformFunc(-8, -64))
    @text.attr("transform", @transformFunc(15, -10))

  gaussian: (mu=0, sigma=1) ->
    std = (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1)
    std * sigma + mu

  transformFunc: (offsetX=0, offsetY=0) ->
    (d) =>
      targetPos = false
      damper = 0.1
      if d.index is 0
        targetPos = [-20, 0]
      else if d.index is 8
        targetPos = [Math.round(@width * 0.7), Math.round(@height * 0.4)]

      if targetPos isnt false
        d.x = d.x + (targetPos[0] - d.x) * (damper + 0.71) * @force.alpha() * 5
        d.y = d.y + (targetPos[1] - d.y) * (damper + 0.71) * @force.alpha() * 5
      else
        #if @isNodeActive(d)
        #  d.x = d.x + (0 - d.x) * (damper + 0.71) * @force.alpha() * 5
        #  d.y = d.y + (@height - 20 - d.y) * (damper + 0.71) * @force.alpha() * 5
        r = (d.name?.length ? 10) + 40
        d.x = Math.max(r, Math.min(@width - r, d.x))
        d.y = Math.max(r, Math.min(@height - r, d.y))

      "translate(#{d.x + offsetX}, #{d.y + offsetY})"

  collide: (node) ->
    nx1 = node.x - 50
    nx2 = node.x + 50
    ny1 = node.y - 40
    ny2 = node.y + 40
    (quad, x1, y1, x2, y2) ->
      if quad.point and (quad.point isnt node)
        x = node.x - quad.point.x
        y = node.y - quad.point.y
        l = Math.sqrt(x * x + y * y)
        r = node.radius + quad.point.radius
        if l < r
          l = (l - r) / l * .5
          node.x -= x *= l
          node.y -= y *= l
          quad.point.x += x
          quad.point.y += y
      x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1

$ ->
  nav = new NavVisualization($(window).width(), 150)

