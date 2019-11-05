import React from "react"
import DataList from "../data/DataList";

class RecentCrops extends DataList {
  dataType = 'crops';
  params() {
    return {
      'page[limit]': 20,
      'sort': '-created-at'
    };
  }
  renderCrops() {
    return this.state.data.map((crop, index) => {
      let url = `/crops/${crop.attributes.slug}`
      return (
        <a key={index} href={url}>{crop.attributes.name}, </a>
      );
    });
  }
  render () {
    return (
      <section className="recent-crops">
      <h2>Recently added</h2>
      {this.state.loading && this.renderLoading() }
      <p>{this.renderCrops()}</p>
      </section>
    );
  }
}

export default RecentCrops;
