import React from "react"
import PropTypes from "prop-types"
import axios from 'axios';
import PlantingProgressBar from "../plantings/PlantingProgressBar";

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
  state = { loading: false, hasError: false, crops: [], plantings: [] };

  componentDidMount() {
    let params = {
        'filter[garden_id]': this.props.garden.id,
        'filter[active]' : true,
        'filter[perennial]': false
      };

    this.setState({loading: true});
    axios.get('/api/v1/plantings', { params: params })
      .then((res) => this.setState({
          loading: false,
          plantings: flatten(res.data.data, 'plantings')
        }))
      .catch(() => this.setState({ loading: false, plantings: [] }));
  }

  componentDidCatch(error, info) {
    this.setState({ hasError: true });
  }

  render () {
    if (this.state.loading) {
      return (
        <p className="mx-auto display-4 text-muted"><i className="fas fa-spinner fa-pulse"></i>Loading...</p>
      );
    }
    if (this.state.hasError) {
      return (
        <p className="alert alert-warning">Error</p>
      );
    }

    return (
      <section className="garden-progress">
        <h2>Progress</h2>
        {this.state.plantings.map((planting, index) => {
          let url = `/plantings/${planting.slug}`;
          let crop_name = planting['crop-name'];

          return (
            <div key={index} className="row progress-row border-bottom">
              <div className="col-12 col-md-4 progress-row--crop">
                <a href={url}>
                  <span className="chip crop-chip">
                    {crop_name}
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

export default ProgressList;
