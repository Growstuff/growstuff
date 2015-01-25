//=require d3

(function(){
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  function GraphScale (data, axisName){
    this._data = data;
    this._axisName = axisName;
  };

  GraphScale.prototype.render = function() {
    var data = this._data;
    var axisName = this._axisName;
    var scaleType = data[axisName].scale;
    var axisSize = data[axisName].size;
    return d3.scale[scaleType]()
    .domain([0, d3.max(this.getBarValues())])
      .range([0, axisSize]);

  };

  GraphScale.prototype.getBarValues = function(){
    var bars = this._data.bars;
    var barValues = [];
    var data = this._data;
    var i = 0;

    for (i; i < data.bars.length; i++){
      barValues.push(data.bars[i].value)
    };

    return barValues;
  }

  growstuff.GraphScale = GraphScale;

})();