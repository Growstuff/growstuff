//=require d3

/*
Width scale is used to map the value for the length of each bar
to the display size of the svg
 */

(function(){
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  function WidthScale (data){
    this._data = data;
  }

  WidthScale.prototype.render = function() {
    var data = this._data;
    var scaleType = data.width.scale;
    var axisSize = data.width.size;

    return d3.scale[scaleType]()
        .domain([0, this.getMaxValue()])
        .range([0, axisSize]);
  };

  WidthScale.prototype.getMaxValue = function(){
    return d3.max(this._data.bars.map(function(bar) { return bar.value; }));
  }

  growstuff.WidthScale = WidthScale;

}());
