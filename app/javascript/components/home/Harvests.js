import React from "react"
import DataList from "../data/DataList";

class Harvest extends React.Component {
  render() {
    let harvest = this.props.harvest.attributes;
    let harvest_url = `/harvests/${harvest.slug}`;
    let harvest_image = harvest['thumbnail'];
    return (
      <a href={harvest_url} className="list-group-item list-group-item-action flex-column align-items-start">
        <div className="d-flex w-100 justify-content-between homepage--list-item">
          <div>
            <h5>{harvest['crop-name']}</h5>
            <span className="badge badge-success">{harvest['plant_part']}</span>
            <small className="text-muted">harvested by {harvest['owner-login-name']}</small>
          </div>
          <p className="mb-2">
            <img src={harvest_image} width="75" className="rounded shadow" />
          </p>
        </div>
      </a>
    );
  }
}

class Harvests extends DataList {
  dataType = 'harvests';
  title = 'Recently Harvested';
  params() {
    return {
      'filter[interesting]' : true,
      'sort': '-harvested-at',
      'page[limit]': 10
    };
  }
  renderData() {
    return this.state.data.map((harvest, index) => {
      return (
        <Harvest key={index} harvest={harvest} />
      );
    });
  }
}

export default Harvests;


