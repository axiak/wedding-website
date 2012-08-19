width = 960
height = 500
node = false
root = false
vis = d3.select("#nav-chart").append("svg").attr("width", width).attr("height", height)
link = false

tick = ->
  link
  .attr("x1", (d) ->
    d.source.x
  ).attr("y1", (d) ->
    d.source.y
  ).attr("x2", (d) ->
    d.target.x
  ).attr "y2", (d) ->
    d.target.y

  node
  .attr("cx", (d) ->
    d.x
  ).attr "cy", (d) ->
    d.y

force = d3.layout.force()
  .on("tick", tick)
  .charge((d) ->
    if d._children then -d.size / 100 else -30
  ).linkDistance((d) ->
    if d.target._children then 80 else 30
  ).size([width, height])

d3.json "/flare.json", (json) ->
  root = json
  root.fixed = true
  root.x = width / 2
  root.y = height / 2
  update()


update = ->
  nodes = flatten(root)
  links = d3.layout.tree().links(nodes)
  console.log links
  # Restart the force layout.
  force.nodes(nodes).links(links).start()

  # Update the links…
  link = vis.selectAll("line.link").data(links, (d) ->
    d.target.id
  )

  # Enter any new links.
  link.enter()
    .insert("line", ".node")
    .attr("class", "link")
    .attr("x1", (d) ->
      d.source.x
    ).attr("y1", (d) ->
      d.source.y
    ).attr("x2", (d) ->
      d.target.x
    ).attr "y2", (d) ->
      d.target.y

  # Exit any old links.
  link.exit().remove()

  # Update the nodes…
  node = vis
    .selectAll("circle.node")
    .data(nodes, (d) ->
      d.id
  ).style("fill", color)

  node.transition().attr "r", (d) ->
    if d.children
      10
    else
      Math.sqrt(d.size) /20


  # Enter any new nodes.
  node.enter()
    .append("circle")
      .attr("class", "node")
      .attr("cx", (d) ->
        d.x
      ).attr("cy", (d) ->
        d.y
      ).attr("r", (d) ->
        if d.children
          10
        else
          Math.sqrt(d.size) / 20
      ).style("fill", color)
      .on("click", click)
      .call force.drag

  # Exit any old nodes.
  node.exit().remove()




# Color leaf nodes orange, and packages white or blue.
color = (d) ->
  if d._children
    "#3182bd"
  else
    if d.children
      "#c6dbef"
    else
      "#fd8d3c"


# Toggle children on click.
click = (d) ->
  if d.children
    d._children = d.children
    d.children = null
  else
    d.children = d._children
    d._children = null
  update()

# Returns a list of all nodes under the root.
flatten = (root) ->
  recurse = (node) ->
    if node.children
      node.size = node.children.reduce((p, v) ->
        p + recurse(v)
      , 0)
    node.id = ++i  unless node.id
    nodes.push node
    node.size
  nodes = []
  i = 0
  root.size = recurse(root)
  nodes


console.log d3.select("#nav-chart")
console.log vis

