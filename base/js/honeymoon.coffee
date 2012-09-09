
Blog = window.Blog ? {}

getItems = (callback) ->
  $.ajax
    url: "/api/items/"
    success: (response) ->
      callback(response.items)

Blog.formatCurrency = (number) ->
  "$#{parseFloat(number).toFixed(2)}".replace(/\d{1,3}(?=(\d{3})+(?!\d))/g, "$&,")


$$$ ->
  template = false
  mainTemplate = false
  return unless $("body").hasClass "other-gifts"

  if !window.development and location.protocol isnt 'https:'
    location.reload location.href.replace('http:', 'https:')

  if template is false
    template = _.template($("#tmpl-honeymoon").html())
    mainTemplate = _.template($("#tmpl-honeymoon-outer").html())

  getItems (data) ->
    tbody = _.map(data, (item) ->
      template(item: item)).join("")

    $("#gift-table").html(mainTemplate(tbody: tbody))

  $("#gift-table").on "change", "select", (e) ->
    e.preventDefault()
    total = _.sum(_.map($("#gift-table tr[data-id]"), (elem) ->
      price = $(elem).data('price')
      price * $("select", elem).val()
    ))
    console.log total
    $("#gift-table .total").text("Total: #{Blog.formatCurrency(total)}")