import React from "react"
import DataList from "../data/DataList";

class Planting extends React.Component {
  render() {
    let planting = this.props.planting.attributes;
    let planted_from = planting['planted-from'];
    let crop_name = planting['crop-name'];
    let owner = planting['owner-login-name'];
    let planting_image = planting['thumbnail'];
    let planting_url = `/plantings/${planting['slug']}`;
    return (
      <a href={planting_url} className="list-group-item list-group-item-action flex-column align-items-start">
        <div className="d-flex w-100 justify-content-between homepage--list-item">
          <p className="mb-2">
            <img src={planting_image} width="75" className="rounded shadow" />
          </p>
          <div className="text-right">
            <h5>{crop_name}</h5>
            {planted_from &&
              <span className="badge badge-success">{planted_from}</span>
            }
            <p className="text-muted">planted by {owner}</p>
          </div>
        </div>
      </a>
    );
  }
}

class Plantings extends DataList {
  dataType = 'plantings';
  title = 'Recently planted'
  params() {
    return {
      'filter[interesting]' : true,
      'sort': '-planted-at',
      'page[limit]': 10
    };
  }

  renderData() {
    return this.state.data.map((planting, index) => {
      return (
        <Planting key={index} planting={planting} />
      );
    });
  }

  render() {
    return (
      <section className="plantings">
        <h2>{this.title}</h2>
          {this.state.loading &&
            this.renderLoading()
          }
          {this.state.hasError &&
            <p className="alert alert-warning">Error</p>
          }
        {this.renderData()}
      </section>
    );
  }
}

/*
%section.plantings
  = cute_icon
- Planting.has_photos.recent.includes(:crop, garden: :owner).limit(6).each do |planting|
  = link_to planting, class: 'list-group-item list-group-item-action flex-column align-items-start' do
    .d-flex.w-100.justify-content-between.homepage--list-item
      %p.mb-2
        = image_tag planting_image_path(planting), width: 75, class: 'rounded shadow'
      .text-right
        %h5= planting.crop.name
        - if planting.planted_from.present?
          %span.badge.badge-success= planting.planted_from.pluralize
        %small.text-muted planted by #{planting.owner}
  %p.text-right= link_to "#{t('home.plantings.view_all')} »", plantings_path, class: 'btn btn-block'
  */

export default Plantings
