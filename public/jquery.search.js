(function($) {
  var Search = function(block) {
    this.callbacks = {};
    block(this);
  }

  Search.prototype.reset = function(fn) { this.callbacks.reset = fn; }
  Search.prototype.empty = function(fn) { this.callbacks.empty = fn; }
  Search.prototype.results = function(fn) { this.callbacks.results = fn; }

  function query(selector) {
    if (val = this.val()) {
      return $(selector + ':contains("' + val + '")');;
    } else {
      return false;
    }
  }

  $.fn.search = function search(selector, block) {
    var search = new Search(block);
    var callbacks = search.callbacks;

    function perform() {
      if (result = query.call($(this), selector)) {
        var method = result.size() > 0 ? 'results' : 'empty';
        return callbacks[method] && callbacks[method].call(this, result);
      } else {
        return callbacks.reset && callbacks.reset.call(this);
      };
    }

    $(this).live('keypress', perform);
    $(this).live('keyup', perform);
    $(this).live('keydown', perform);
    $(this).bind('blur', perform);
  }
})(jQuery);
