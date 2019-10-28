import React from "react"
import PropTypes from "prop-types"

class PlantingProgressBar extends React.Component {
  render() {
    let planting = this.props.planting;
    let percent = planting['percentage-grown'];

    if(!planting['planted-at']) {
      return (<small>set "planted" date to allow predictions</small>);
    }
    if(!percent) {
      return (<small>not enough data on {planting['crop-name']} to predict</small>);
    }

    var style = { width: `${percent}%` };
    return (
      <React.Fragment>
        <div className="progress">
          <div className="progress-bar bg-success"
            aria-valuemax="100"
            aria-valuemin="0"
            aria-valuenow={percent}
            role="progressbar"
            style={style}>
          </div>
        </div>
        <small className="float-left">{percent}%</small>
        {planting['finish-predicted-at'] &&
          <small className="float-right">{planting['finish-predicted-at']}</small>
        }
      </React.Fragment>
    );
  }
}

export default PlantingProgressBar
