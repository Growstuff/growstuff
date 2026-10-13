import React, {useState} from 'react';

import ChipToggle from './ChipToggle';

const SHOWN = 10;

// A dropdown of {id, name} choices with an "all" option on top, as a number
// (or null for all) in and out. Nothing is rendered when there is no choice to
// make.
function Filter({choices, allLabel, value, onChange}) {
  if (choices.length < 2) return null;

  return (
    <select
      className="form-select form-select-sm"
      aria-label={allLabel}
      value={value ?? ''}
      onChange={(event) => onChange(event.target.value === '' ? null : Number(event.target.value))}
    >
      <option value="">{allLabel}</option>
      {choices.map((choice) => <option key={choice.id} value={choice.id}>{choice.name}</option>)}
    </select>
  );
}

// What the member has growing, or just what is ready to pick, as a table. The
// chips and the filters narrow it without reloading. `rows` is everything
// growing, already worded by Rails, each with the `plant_id` of the crop it is
// a kind of (a tomato variety has its tomato's) and its `garden_id`; `plants`
// and `gardens` are what can be filtered on, and `gardens` is empty when
// there is only the one.
export default function GrowingTable({rows, plants, gardens, initial, labels}) {
  const [shown, setShown] = useState(initial);
  const [plantId, setPlantId] = useState(null);
  const [gardenId, setGardenId] = useState(null);

  const matching = rows.filter((row) => (
    (plantId === null || row.plant_id === plantId) && (gardenId === null || row.garden_id === gardenId)
  ));
  const readyRows = matching.filter((row) => row.ready);
  const options = [
    {key: 'growing', label: `${labels.chip_growing} (${matching.length})`, href: '/'},
    {key: 'ready', label: `${labels.chip_ready} (${readyRows.length})`, href: '/?show=ready'}
  ];
  const visible = (shown === 'ready' ? readyRows : matching).slice(0, SHOWN);

  return (
    <>
      <div className="home-filters">
        <ChipToggle options={options} value={shown} onChange={setShown} />
        <Filter choices={plants} allLabel={labels.all_plants} value={plantId} onChange={setPlantId} />
        <Filter choices={gardens} allLabel={labels.all_gardens} value={gardenId} onChange={setGardenId} />
      </div>
      <div className="home-table-scroll">
        <table className="home-table">
          <thead>
            <tr>
              <th>{labels.col_plant}</th>
              <th>{labels.col_bed}</th>
              <th>{labels.col_planted}</th>
              <th>{labels.col_maturity}</th>
              <th>{labels.col_progress}</th>
            </tr>
          </thead>
          <tbody>
            {visible.length === 0 && (
              <tr><td colSpan={5}>{labels.nothing_to_show}</td></tr>
            )}
            {visible.map((row) => (
              <tr key={row.id}>
                <td>
                  <img src={row.image_url} alt="" />
                  <a href={row.url}>{row.name}</a>
                </td>
                <td>{row.garden}</td>
                <td>{row.planted}</td>
                <td>{row.maturity}</td>
                <td>
                  <span className="home-bar"><i style={{width: `${row.progress}%`}} /></span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
