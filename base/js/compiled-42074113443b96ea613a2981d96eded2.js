(function() {
  var afterPjax, slugify;

  afterPjax = [];

  window.$$$ = function(callback) {
    return afterPjax.push(callback);
  };

  $(function() {
    $("a").pjax({
      fragment: ".main-subcontainer",
      container: ".main-container",
      success: function() {
        return _.each(afterPjax, function(callback) {
          return callback();
        });
      }
    });
    return _.each(afterPjax, function(callback) {
      return callback();
    });
  });

  slugify = function(text) {
    return text.replace(/[\W\s]+/g, '-').toLowerCase();
  };

  $$$(function() {
    var contentTmpl;
    contentTmpl = $(".main-content").data("tmpl");
    $("ul.nav li").each(function() {
      var $li, currentText;
      $li = $(this);
      currentText = $("a", $li).text();
      if (currentText === "Home") {
        if (contentTmpl === "/index.html") {
          $li.addClass("active");
        } else {
          $li.removeClass("active");
        }
        return;
      }
      if (contentTmpl.indexOf($("a", $li).attr("href")) > -1) {
        return $li.addClass("active");
      } else {
        return $li.removeClass("active");
      }
    });
    return $("body").attr("class", slugify($("ul.nav li.active").text()));
  });

}).call(this);
