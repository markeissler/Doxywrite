// hide Discussion title if there is no body.
$(function() {
  $("dl.discus").map(function(idx, ele) {
    if ($(ele).next().prop("tagName") != "P") {
      $(ele).hide();
    }
  })
});
