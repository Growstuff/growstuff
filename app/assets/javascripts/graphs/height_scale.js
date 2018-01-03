// =require d3

/*
Height Scale is used to map the number of bars to the display size of
the svg
 */

(function() {
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});

  /**
   * new height scale object
   * @param {Object} data Graph configuration
   */
  function HeightScale(data) {
    this._data = data;
  }

  HeightScale.prototype.render = function() {
    var data = this._data;
    var scaleType = data.height.scale;

    return d3.scale[scaleType]()
        .domain(d3.range(data.bars.length))
        .rangeRoundBands([0, data.height.size], 0.05, 0);
  };

  growstuff.HeightScale = HeightScale;
}());
