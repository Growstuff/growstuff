//=require d3

(function(){
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  function HeightScale(data){
    this._data = data;
  };

  HeightScale.prototype.render = function(){
    var data = this._data;
    var scaleType = data.height.scale;
    var axisSize = data.height.size;

    return d3.scale[scaleType]()
        .domain(d3.range(data.bars.length))
        .rangeRoundBands([0, data.height.size], 0.05, 0);
  };

  growstuff.HeightScale = HeightScale;

})();