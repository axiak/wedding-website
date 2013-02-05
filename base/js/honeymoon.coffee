
Blog = window.Blog = window.Blog ? {}
Gifts = window.Gifts = window.Gifts ? {}


Blog.formatCurrency = (number) ->
  "$#{parseFloat(number).toFixed(2)}".replace(/\d{1,3}(?=(\d{3})+(?!\d))/g, "$&,")

Gifts.getItems = (callback) ->
  $.ajax
    url: "/api/items/"
    success: (response) ->
      Gifts.itemDetails = {}
      _.each response.items, (item) ->
        Gifts.itemDetails[item.id] = item
      callback(response.items)

Gifts.getTotal = ->
  _.sum(_.map(Gifts.getDetails(), (lineitem) ->
    lineitem.quantity * lineitem.price
  ))

Gifts.getDetails = ->
  return Gifts.details unless $(".gift-table tr[data-id]").length
  Gifts.details = _.filter(_.map($(".gift-table tr[data-id]"), (elem) ->
    quantity = parseInt($("select", elem).val())
    price = $(elem).data('price')
    {id: $(elem).data('id'), price: price, quantity: quantity}), (item) -> item.quantity)

  Gifts.details

Gifts.makePayment = (token) ->
  request =
    payment:
      card: true
      token: token
      name: $("#name").val()
      notes: $("#notes").val()
      email: $("#email").val()
    details: Gifts.getDetails()
  $.ajax
    url: "/api/payment/"
    type: "POST"
    dataType: "json"
    contentType: "application/json;charset=utf-8"
    data: JSON.stringify(request)
    success: (result) ->
      Gifts.showHtml($("#tmpl-confirm-card").html())
    error: (status) ->
      Gifts.enableSubmit()

Gifts.payWithCard = ->
  Stripe.setPublishableKey(window.STRIPE_KEY)

  Stripe.createToken {
    number: $("#card-number").val()
    cvc: $("#cvc").val()
    name: $("#name").val()
    exp_month: $("#card-expiry-month").val()
    exp_year: $("#card-expiry-year").val()
  }, (status, response) ->
    if (response.error)
      $(".payment-errors").text(response.error.message)
      Gifts.enableSubmit()
    else
      Gifts.makePayment(response.id)

Gifts.payWithCash = ->
  request =
    payment:
      card: false
      name: $("#name").val()
      notes: $("#notes").val()
      email: $("#email").val()
    details: Gifts.getDetails()
  $.ajax
    url: "/api/payment/"
    type: "POST"
    dataType: "json"
    contentType: "application/json;charset=utf-8"
    data: JSON.stringify(request)
    success: (result) ->
      Gifts.showHtml($("#tmpl-confirm-paper").html())
    error: (status) ->
      Gifts.enableSubmit()


Gifts.enableSubmit = ->
  $btn = $(".gift-sub-page .submit-card-payment")
  $btn.removeAttr "disabled"
  $btn.removeClass "disabled"

Gifts.oldHtml = []

Gifts.showReceipt = ->
  paymentTmpl = _.template($("#tmpl-payment").html())
  receiptTmpl = _.template($("#tmpl-receipt").html())
  Gifts.showHtml(paymentTmpl(receipt: receiptTmpl(lineitems: Gifts.getDetails())))


Gifts.showHtml = (html) ->
  $root = $(".gift-sub-page")
  Gifts.oldHtml.push $root.html()
  $root.html(html)


Gifts.goBack = ->
  $root = $(".gift-sub-page")
  html = Gifts.oldHtml.pop()
  $root.html(html) if html?


$$$ ->
  template = false
  mainTemplate = false
  return unless $("body").hasClass "other-gifts"

  if !window.development and location.protocol isnt 'https:'
    location.reload location.href.replace('http:', 'https:')

  if template is false
    template = _.template($("#tmpl-honeymoon").html())
    mainTemplate = _.template($("#tmpl-honeymoon-outer").html())

  Gifts.getItems (data) ->
    tbody = _.map(data, (item) ->
      template(item: item)).join("")

    $(".gift-table").html(mainTemplate(tbody: tbody))

  $(".gift-sub-page").on "change", "select.item-quantity", (e) ->
    e.preventDefault()
    total = Gifts.getTotal()
    $(".gift-table .total").text("Total: #{Blog.formatCurrency(total)}")
    $button = $(".honeymoon-continue")
    if total
      $button.removeClass "disabled"
    else
      $button.addClass "disabled"

  $(".gift-sub-page").on "click", ".honeymoon-continue", (e) ->
    e.preventDefault()
    return if $(@).hasClass "disabled"
    Gifts.oldDetails = Gifts.getDetails()
    Gifts.showReceipt()

  $(".gift-sub-page").on "click", ".back-to-gifts", (e) ->
    e.preventDefault()
    Gifts.goBack()

  $(".gift-sub-page").on "change", "input[name='payment-type']", (e) ->
    $("form.credit-card-form").validate
      highlight: (label) ->
        $(label).closest(".control-group").addClass 'error'
      success: (label) ->
        label.addClass("valid")
        .closest(".control-group").removeClass("error").addClass("success")

    e.preventDefault()
    unless $(".credit-card-form").is(":visible")
      $(".credit-card-form").slideDown()
    if $(this).val() is "credit"
      $(".extra-credit-card").slideDown()
    else
      $(".extra-credit-card").slideUp()

  $(".gift-sub-page").on 'click', '.submit-card-payment', (e) ->
    e.preventDefault()
    $btn = $(@)
    return if $btn.hasClass "disabled"
    $btn.addClass "disabled"
    $btn.attr "disabled", "disabled"

    if $("#pay-with-card").is(":checked")
      Gifts.payWithCard()
    else
      Gifts.payWithCash()

$$$ ->
  return unless $("body").hasClass "other-confirm"

  m = window.location.hash.match /^\#(.+)/
  guid = m[1]
  confirmTmpl = _.template($("#tmpl-confirmation").html())

  $.ajax
    url: "/api/payment/confirm/"
    type: "POST"
    dataType: "json"
    contentType: "application/json;charset=utf-8"
    data: JSON.stringify({guid})
    success: (response) ->
      $(".content").html(confirmTmpl(response))
