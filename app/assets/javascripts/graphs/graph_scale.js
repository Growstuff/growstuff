(function(){
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  function GraphScale (data, scaleType){
    this._data = data;
    this._scaleType = scaleType;
  };

  GraphScale.prototype.render = function() {
    var data = this._data;
    var scaleType = this._scaleType;

    return d3.scale[scaleType]()
    .domain([0, d3.max(this.getBarValues())])
      .range([0, data.width]);

  };

  GraphScale.prototype.getBarValues = function(){
    var barValues = [];
    var bars = this._data.bars;
    var i = 0;
    var data = this._data;

    for (i; i < data.bars.length; i++){
      barValues.push(data.bars[i].value)
    };

    return barValues;
  }

  growstuff.GraphScale = GraphScale;

})();