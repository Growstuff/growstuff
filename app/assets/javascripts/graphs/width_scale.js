//=require d3

(function(){
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  function WidthScale (data){
    this._data = data;
  };

  WidthScale.prototype.render = function() {
    var data = this._data;
    var scaleType = data.width.scale;
    var axisSize = data.width.size;


    return d3.scale[scaleType]()
        .domain([0, d3.max(this.getBarValues())])
        .range([0, axisSize]);


  };

  WidthScale.prototype.getBarValues = function(){
    var bars = this._data.bars;
    var barValues = [];
    var data = this._data;
    var i = 0;

    for (i; i < data.bars.length; i++){
      barValues.push(data.bars[i].value)
    };

    return barValues;
  }

  growstuff.WidthScale = WidthScale;

})();