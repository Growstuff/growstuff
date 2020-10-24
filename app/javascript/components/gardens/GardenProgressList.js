import PlantingProgressBar from "../plantings/PlantingProgressBar";
import DataList from "../data/DataList";

class ProgressList extends DataList {
  state = { loading: false, hasError: false, data: [] };
  dataType = 'plantings';

  params() {
    return {
      'filter[garden_id]': this.props.garden.id,
      'filter[active]' : true,
      'filter[perennial]': false
    };
  }
  renderPlantings() {
    return this.state.data.map((planting, index) => {
      let url = `/plantings/${planting.attributes.slug}`;
      let crop_name = planting['crop-name'];

      return (
        <div key={index} className="row progress-row">
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
    });
  }

  render () {
    return (
      <section className="card garden-progress">
        <h2 className="card-title">Progress</h2>
        <div className="card-body">
          {this.state.loading &&
            <p className="mx-auto display-4 text-muted"><i className="fas fa-spinner fa-pulse"></i>Loading...</p>
          }
          {this.state.hasError &&
            <p className="alert alert-warning">Error</p>
          }
          {this.renderPlantings()}
        </div>
      </section>
    )
  }
}

export default ProgressList;
