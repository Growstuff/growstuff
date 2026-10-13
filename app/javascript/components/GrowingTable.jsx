import React, {useState} from 'react';

import ChipToggle from './ChipToggle';

// What the member has growing, or just what is ready to pick, as a table. The
// chips switch between the two without reloading. `growing` and `ready` are
// the rows to show, already worded by Rails; `chips` are the
// chip labels, with the full totals in them.
export default function GrowingTable({growing, ready, chips, initial, labels}) {
  const [shown, setShown] = useState(initial);
  const rows = shown === 'ready' ? ready : growing;
  const options = [
    {key: 'growing', label: chips.growing, href: '/'},
    {key: 'ready', label: chips.ready, href: '/?show=ready'}
  ];

  return (
    <>
      <ChipToggle options={options} value={shown} onChange={setShown} />
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
            {rows.length === 0 && (
              <tr><td colSpan={5}>{labels.nothing_ready}</td></tr>
            )}
            {rows.map((row) => (
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
