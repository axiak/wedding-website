return unless Modernizr.svg
return if Blog.isPhone()


class NavVisualization
  @links = [
    source: "_root"
    target: "_s11"
    thickness: 7
  ,
    source: "_s11"
    target: "Home"
    thickness: 7
  ,
    source: "Home"
    target: "_s21"
    thickness: 4
  ,
    source: "_s21"
    target: "_s22"
    thickness: 4
  ,
    source: "_s22"
    target: "_s23"
    thickness: 4
  ,
    source: "_s23"
    target: "How we met"
    thickness: 4
  ,
    source: "How we met"
    target: "_s31"
    thickness: 2
  ,
    source: "_s31"
    target: "_s32"
    thickness: 2
  ,
    source: "_s32"
    target: "_s33"
    thickness: 2
  ,
    source: "_s33"
    target: "_s34"
    thickness: 2
  ,
    source: "_s34"
    target: "_s35"
    thickness: 2
  ,
    source: "_s35"
    target: "Photos"
    thickness: 2
  ,
    source: "Home"
    target: "_s41"
    thickness: 4
  ,
    source: "_s41"
    target: "_s42"
    thickness: 4
  ,
    source: "_s42"
    target: "_s43"
    thickness: 4
  ,
    source: "_s43"
    target: "_s44"
    thickness: 4
  ,
    source: "_s44"
    target: "_s45"
    thickness: 4
  ,
    source: "_s45"
    target: "Proposal"
    thickness: 4
  ,
    source: "Proposal"
    target: "_s51"
    thickness: 2
  ,
    source: "_s51"
    target: "_s52"
    thickness: 2
  ,
    source: "_s52"
    target: "_s53"
    thickness: 2
  ,
    source: "_s53"
    target: "_s54"
    thickness: 2
  ,
    source: "_s54"
    target: "_s55"
    thickness: 2
  ,
    source: "_s55"
    target: "Wedding Party"
    thickness: 2
  ,
    source: "Wedding Party"
    target: "_s61"
    thickness: 1
  ,
    source: "_s61"
    target: "_s62"
    thickness: 1
  ,
    source: "_s62"
    target: "_s63"
    thickness: 1
  ,
    source: "_s63"
    target: "Place & Time"
    thickness: 1
  ,
    source: "Wedding Party"
    target: "_s71"
    thickness: 1
  ,
    source: "_s71"
    target: "_s72"
    thickness: 1
  ,
    source: "_s72"
    target: "_s73"
    thickness: 1
  ,
    source: "_s73"
    target: "_s74"
    thickness: 1
  ,
    source: "_s74"
    target: "Updates"
    thickness: 1
  ,
    source: "Photos"
    target: "_s81"
    thickness: 1
  ,
    source: "_s81"
    target: "_s82"
    thickness: 1
  ,
    source: "_s81"
    target: "_s82"
    thickness: 1
  ,
    source: "_s82"
    target: "Other Info"
    thickness: 1
  ,
    source: "Other Info"
    target: "_s91"
    thickness: 1
  ,
    source: "_s91"
    target: "_s92"
    thickness: 1
  ,
    source: "_s92"
    target: "Wedding Party"
    thickness: 1
  ]

  @linksSimplified = [
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
  ,
    source: "Photos"
    target: "Other Info"
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

  @pins = ->
    "_root": [-30, -10, 1]
    "Wedding Party": [0.8 * @width, 0.3 * @height]
    "Home": [0.05 * @width, 0.3 * @height]
    #"Updates": [0.8 * @width, 0.5 * @height]
    "How we met": [0.3 * @width, 0.7 * @height]
    #"Place & Time": [0.9 * @width, 0.3 * @height]
    "Other Info": [0.65 * @width, 0.7 * @height]
    #"Home": [0.01 * @width, 0.3 * @height]

  constructor: (width, height) ->
    $(".main-container").css 'margin-top', '100px'
    @links = if @showDetailed() then NavVisualization.links else NavVisualization.linksSimplified
    @hrefs = NavVisualization.hrefs
    @pins = NavVisualization.pins
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

    @linkRoot = @svg.append("svg:g")
    @stemRoot = @svg.append("svg:g")
    @nodeRoot = @svg.append("svg:g")
    @textRoot = @svg.append("svg:g")


    @setupForce()
    @draw()

  getValue: (prop) ->
    if _.isFunction(@[prop])
      @[prop]()
    else
      @[prop]

  draw: ->
    @svg.attr("width", @width)

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

  isLinkStem: (d) ->
    @isNodeStem(d?.source) or @isNodeStem(d?.target)

  isNodeStem: (node) ->
    !!node.name.match(/^_s/)

  isLinkActive: (d) ->
    @isNodeActive(d?.source?.name) or @isNodeActive(d?.target?.name)

  initializeNodes: ->
    @nodes = {}
    @links.forEach (link) =>
      link.source = @nodes[link.source] ? (@nodes[link.source] = {name: link.source})
      link.target = @nodes[link.target] ? (@nodes[link.target] = {name: link.target})

  showDetailed: ->
    not $.browser.mozilla

  setupForce: ->
    @force = d3.layout.force()
      .gravity(=> .001)
      .charge((d) => -900)
      .linkStrength((d) =>
        if @isLinkStem(d)
          6
        else if @isLinkActive(d)
          0.6
        else
          1)
      .theta(1)
      .linkDistance((d) =>
        if @isLinkStem(d)
          1
        else if @isLinkActive(d)
          300
        else
          Math.round((@width - 100) / 6))
      .on("tick", @tick)


  buildLinks: ->
    @link = @linkRoot.selectAll("path")
      .data(@force.links(), (d) => "#{d.source.name}#{d.target.name}")

    @link.enter()
      .append("path")
      .attr("d", "M0,-5L10,0L0,5")
      .attr("class", "link")
      .attr("stroke-width", (d) =>  d.thickness)

    @link.exit().remove()


  buildNodes: ->
    @node = @nodeRoot.selectAll("a")
      .data(_.filter(@force.nodes(), (d) => not @isNodeStem(d)), (d) -> d.name)

    @node.enter()
      .append("a")
      .attr("xlink:href", (d) => @hrefs[d.name] ? "#")
      .attr("class", @activeDefaultHidden("node active", "node", "node"))
      .call(@force.drag)
      .on("click", @click)
      .append("svg:image")
      .attr("xlink:href", @activeDefaultHidden(Blog.url("/img/wisteria.png"), Blog.url("/img/wisteria.png"), ""))
      .attr("width", @activeDefaultHidden(27, 27, 0))
      .attr("height", @activeDefaultHidden(72, 72, 0))

    @node.selectAll("image").transition()
      .attr("xlink:href", @activeDefaultHidden(
        Blog.url("/img/wisteria-active.png"),
        Blog.url("/img/wisteria.png"),
        ""))


    @stem = @stemRoot.selectAll("image")
      .data(_.filter(@force.nodes(), @isNodeStem), (d) -> d.name)

    @stem.enter()
      .append("svg:image")
      .attr("xlink:href", Blog.url("/img/stem.png"))
      .attr("width", 28)
      .attr("height", 14)

    @text = @textRoot.selectAll("a")
        .data(_.filter(@force.nodes(), @hasHref), (d) -> d.name)

    @textGroup = @text.enter()
      .append("a")
      .attr("xlink:href", (d) => @hrefs[d.name] ? "#")
      .attr("class", (d) => @activeDefaultHidden("node active", "node", "node"))
      .call(@force.drag)
      .on("click", @click)

    @textGroup.append("svg:text")
      .attr("x", 8)
      .attr("y", ".3em")
      .attr("class", "shadow")
      .text(@defaultIfHidden(((d) -> d.name), ''))

    @textGroup.append("svg:text")
      .attr("x", 8)
      .attr("y", ".3em")
      .text(@defaultIfHidden(((d) -> d.name), ''))

    @text.transition()
      .attr("class", @activeDefaultHidden("node active", "node", "node"))

    @text.exit()
      .remove()

    @node.exit().remove()
    @stem.exit().remove()


  click: (d, i, e) ->
    href = @hrefs[d.name]
    if href
      @navigate(href, d.name)
      @transitionLayout = true
      @force.start()
      @draw()
      setTimeout((=>
        @transitionLayout = false
        @force.alpha(0.1)), 500)



  navigate: (href, name) ->
    e = d3.event
    return if href == location.href
    if @usePjax(e, href)
      e.preventDefault()
      Blog.$pjax href
      @activeLeaf = name


  usePjax: (e, href) ->
    return false unless $.support.pjax
    return false if e.which > 1 or e.metaKey or e.ctrlKey
    link = $("<a/>")
    link = link.attr("href", href)[0]
    return false if location.protocol isnt link.protocol or location.host isnt link.host
    true

  hasHref: (d) ->
    !!(@hrefs[d.name])

  isHidden: (d) ->
    !@hrefs[d.name]

  defaultIfHidden: (n, def=0) ->
    (d) =>
      if @isHidden(d)
        def
      else
        if _.isFunction(n)
          n(d)
        else
          n

  activeDefaultHidden: (active, def, hidden, stem) ->
    (d) =>
      if @isHidden(d)
        hidden
      else if @isNodeActive(d)
        active
      else
        def

  tick: ->
    @link.attr "d", (d) =>
      @bbox(d.source)
      @bbox(d.target)
      dx = d.target.x - d.source.x
      dy = d.target.y - d.source.y
      dr = Math.sqrt(dx * dx + dy * dy) * 5
      "M#{d.source.x},#{d.source.y}A#{dr},#{dr} 0 0,1 #{d.target.x},#{d.target.y}"

    @node.attr("transform", @transformFunc(-6, -10, true))
    @text.attr("transform", @transformFunc(0, 0))
    @stem.attr("transform", @transformFunc(-6, -4, true))

  gaussian: (mu=0, sigma=1) ->
    std = (Math.random() * 2 - 1) + (Math.random() * 2 - 1) + (Math.random() * 2 - 1)
    std * sigma + mu

  transformFunc: (offsetX=0, offsetY=0, isNode=false) ->
    (d) =>
      currentOffsetY = offsetY

      pins = @getValue('pins')
      targetPos = pins[d.name]


      if targetPos
        targetPos[0] = Math.round(targetPos[0])
        targetPos[1] = Math.round(targetPos[1])
        damper = targetPos[2] ? 0.3
        d.x = (1 - damper) * d.x + damper * targetPos[0]
        d.y = (1 - damper) * d.y + damper * targetPos[1]
      else
        @bbox(d)

      "translate(#{d.x + offsetX}, #{d.y + currentOffsetY})"

  bbox: (node) ->
    r = (node.name?.length ? 10) * 10
    node.x = Math.max(0, Math.min(@width - r, node.x))
    node.y = Math.max(15, Math.min(@height - 72, node.y))


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
  $window = $(window)
  $(".navbar-inner").hide()
  windowWidth = $window.width()
  $navChart = $("#nav-chart")
  $navChart.width(windowWidth)
  nav = new NavVisualization(windowWidth, 150)


  $window.on 'resize', _.debounce((->
    return if $window.width() is windowWidth
    nav.width = windowWidth = $window.width()
    $navChart.width(windowWidth)
    nav.draw()
    ), 100)

  window.nav = nav
