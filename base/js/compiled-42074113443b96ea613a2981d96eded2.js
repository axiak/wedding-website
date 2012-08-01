(function() {
  var afterPjax, initialURL, popped, slugify,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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

  popped = __indexOf.call(window.history, 'state') >= 0 && window.history.state !== null;

  initialURL = location.href;

  $(window).bind('popstate', function(e) {
    var initialPop;
    initialPop = !popped && location.href === initialURL;
    popped = true;
    if (initialPop) return;
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

  $$$(function() {
    var disqus_shortname, dsq;
    disqus_shortname = 'yaluandmike';
    if (!$("#disqus_thread").length) return;
    dsq = document.createElement('script');
    dsq.type = 'text/javascript';
    dsq.async = true;
    dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
    return (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
  });

}).call(this);
