
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
  return Gifts.oldDetails if Gifts.oldDetails
  _.filter(_.map($("#gift-table tr[data-id]"), (elem) ->
    quantity = parseInt($("select", elem).val())
    price = $(elem).data('price')
    {id: $(elem).data('id'), price: price, quantity: quantity}), (item) -> item.quantity)

Gifts.makePayment = (token) ->
  request =
    payment:
      card: true
      token: token
      name: $("#name").val()
      email: $("#email").val()
    details: Gifts.getDetails()
  $.ajax
    url: "/api/payment/"
    type: "POST"
    dataType: "json"
    contentType: "application/json;charset=utf-8"
    data: JSON.stringify(request)
    success: (result) ->
      #
    error: (status) ->
      #

Gifts.showReceipt = ->
  $root = $(".gift-sub-page")
  Gifts.oldHtml = $root.html()
  paymentTmpl = _.template($("#tmpl-payment").html())
  receiptTmpl = _.template($("#tmpl-receipt").html())
  $root.html(paymentTmpl(receipt: receiptTmpl(lineitems: Gifts.getDetails())))

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

    $("#gift-table").html(mainTemplate(tbody: tbody))

  $("#gift-table").on "change", "select", (e) ->
    e.preventDefault()
    $("#gift-table .total").text("Total: #{Blog.formatCurrency(Gifts.getTotal())}")

  $("#honeymoon-continue").on "click", (e) ->
    e.preventDefault()
    return if $(@).hasClass "disabled"
    Gifts.oldDetails = Gifts.getDetails()
    Gifts.showReceipt()

  $(".gift-sub-page").on "change", "input[name='payment-type']", (e) ->
    $("form.credit-card-form").validate
      highlight: (label) ->
        $(label).closest(".control-group").addClass 'error'
      success: (label) ->
        label.addClass("valid")
        .closest(".control-group").removeClass("error").addClass("success")

    e.preventDefault()
    if $(this).val() is "credit"
      $(".cash-form").slideUp()
      $(".credit-card-form").slideDown()
    else
      $(".credit-card-form").slideUp()
      $(".cash-form").slideDown()

  $(".gift-sub-page").on 'click', '.submit-card-payment', (e) ->
    e.preventDefault()
    $btn = $(@)
    return if $btn.hasClass "disabled"
    $btn.addClass "disabled"
    $btn.attr "disabled", "disabled"
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
        $btn.removeAttr "disabled"
        $btn.removeClass "disabled"
      else
        Gifts.makePayment(response.id)

