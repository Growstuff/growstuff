(function() {
  'use strict';



  var growstuff = (window.growtuff = window.growstuff || {});

  function BarLabelGroup(bars) {
    this._bars = bars;
  }

  BarLabelGroup.prototype.render = function(d3){
  };

  growstuff.BarLabelGroup = BarLabelGroup;

})();