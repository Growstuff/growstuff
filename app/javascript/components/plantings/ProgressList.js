import React from "react"
import PropTypes from "prop-types"
import axios from 'axios';

const flatten = (results, type) => {
  var data = []
  results.forEach(function (result) {
    if (type == result.type) {
      data[result.id] = result.attributes;
    }
  });
  return data;
};

class ProgressList extends React.Component {
  state = { loading: false, results: [], crops: [], plantings: [] };

  componentDidMount() {
    let params = {'filter[garden_id]': this.props.garden.id };

    this.setState({loading: true});
    axios.get('/api/v1/plantings', { params: params })
      .then((res) => this.setState({
          loading: false,
          plantings: flatten(res.data.data, 'plantings')
        }))
      .catch(() => this.setState({ loading: false, plantings: [] }));
  }

  render () {
    return (
      <section>
        {this.state.plantings.map((planting, index) => {
          let url = `/plantings/${planting.slug}`;
          return (
            <div key={index} className="row progress-row border-bottom">
              <div className="col-12 col-md-4 progress-row--crop">
                <a href={url}>
                  <span className="chip crop-chip">
                    {planting['crop-name']}
                  </span>
                </a>
              </div>
              <div className="col-12 col-md-6 progress-row--bar">
                <PlantingProgressBar planting={planting} />
              </div>
            </div>
            );
        })}
      </section>
    )
  }
}

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
      </React.Fragment>
    );
  }
}

export default ProgressList
