(function() {
  var afterPjax, initialURL, popped, slugify,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.Blog = window.Blog || {};

  afterPjax = [];

  window.$$$ = function(callback) {
    return afterPjax.push(callback);
  };

  Blog.pjax = function(selector) {
    return $(selector).pjax({
      fragment: ".main-subcontainer",
      container: ".outer-container",
      success: function() {
        return _.each(afterPjax, function(callback) {
          return callback();
        });
      }
    });
  };

  $(function() {
    Blog.pjax(".navbar-inner a");
    $(document).on('pjax:start', function() {
      return $(".outer-container").hide();
    });
    $(document).on('pjax:start', function() {
      return $(".outer-container").fadeIn(200);
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
    return Blog.pjax("a[data-pjax]");
  });

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
    if ($("#disqus_thread").length) return Blog.loadDisqus();
  });

  Blog.loadDisqus = function() {
    var disqus_shortname, dsq;
    disqus_shortname = 'yaluandmike';
    if (!$("#disqus_thread").length) return;
    dsq = document.createElement('script');
    dsq.type = 'text/javascript';
    dsq.async = true;
    dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    return $("hr.footer").removeClass("hide");
  };

  $$$(function() {
    var deferreds;
    if (!$("body").hasClass("photos")) return;
    $("#photo-nav-bar a").on("click", function(e) {
      var target;
      e.preventDefault();
      target = this.hash;
      return $.scrollTo(target, 1000);
    });
    deferreds = [];
    $(".album-container").each(function() {
      var $container, deferred;
      deferred = $.Deferred();
      deferreds.push(deferred);
      $container = $(this);
      $container.gpGallery(".picture-item");
      return deferred.resolve();
    });
    return $.when(deferreds).then(function() {
      setTimeout((function() {
        return $("body").scrollspy("refresh");
      }), 1000);
      setTimeout((function() {
        return $("body").scrollspy("refresh");
      }), 600);
      setTimeout((function() {
        return $("body").scrollspy("refresh");
      }), 1600);
      return setTimeout((function() {
        return $("body").scrollspy({
          offset: 20
        });
      }), 100);
    });
  });

}).call(this);
