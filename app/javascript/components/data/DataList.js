import React from "react"
import PropTypes from "prop-types"
import axios from 'axios';


const flatten = (results, type) => {
  var data = {};
  results.forEach(function (result) {
    if (type == result.type) {
      data[`${result.id}`] = result.attributes;
      data[`${result.id}`]['id'] = result.id;
    }
  });
  return data;
};

class DataList extends React.Component {
  state = { loading: false, hasError: false, errors: [], data: [] };
  params() {
    return {};
  }

  componentDidCatch(error, info) {
    this.setState({ hasError: true });
  }

  componentDidMount() {
    this.setState({loading: true});
    axios.get(`/api/v1/${this.dataType}`, {params: this.params()})
      .then((res) => this.setState({
          loading: false,
          hasError: false,
          data: res.data.data,
          errors: []
        })
      )
      .catch((res) => this.setState({
          loading: false, data: [], hasError: true, errors: res.response.data.errors
        })
      );
  }
  renderData() {
    return this.state.data.map((item, index) => {
      return (
        <div key={index} className="card">
          {index} {this.dataType}
         </div>
      );
    });
  }
  shouldRender() {
    return !(this.state.loading || this.state.hasError)
  }
  renderLoading() {
    return (
      <p className="mx-auto text-muted">
        <i className="fas fa-spinner fa-pulse"></i>
        Loading {this.dataType}</p>
    );
  }
  renderError() {
    return (
      <div className="errors">
        <h4>Errors</h4>
        {this.renderErrorMessages()}
      </div>
    );
  }

  renderErrorMessages() {
    return this.state.errors.map((error, index) => {
      return (
          <div className="alert alert-danger">
            <strong>{error.title}</strong>
            <p>{error.detail}</p>
          </div>
      );
    });
  }
  render () {
    return (
      <section className={this.dataType}>
        <h2>{this.title}</h2>
          {this.state.loading &&
            this.renderLoading()
          }
          {this.state.hasError &&
            this.renderError()
          }
          {this.shouldRender() &&
            <div className="index-cards">
              {this.renderData()}
            </div>
          }
      </section>
    );
  }
}

export default DataList
