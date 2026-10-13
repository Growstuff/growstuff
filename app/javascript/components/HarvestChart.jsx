import React, {useState} from 'react';

import ChipToggle from './ChipToggle';

// Harvests in each month of this year and last, as paired bars. The first
// measure is shown to start with and the chips switch to another without
// reloading. `months` has, for each month, its `label` and the `this_year` and
// `last_year` totals under each measure's key; each of `measures` has a
// `key`, `label`, `note` and `unit`.
export default function HarvestChart({months, current_month: currentMonth, measures}) {
  const [key, setKey] = useState(measures[0].key);
  const {note, unit} = measures.find((measure) => measure.key === key);
  const peak = Math.max(1, ...months.flatMap((entry) => [entry[key].this_year, entry[key].last_year]));
  const height = (value) => `${Math.round((value / peak) * 100)}%`;
  const title = (value) => `${Math.round(value * 10) / 10} ${unit}`;

  return (
    <>
      <ChipToggle className="home-chart-toggle" options={measures} value={key} onChange={setKey} />
      <p className="home-section-note">{note}</p>
      <div className="home-chart">
        {months.map((entry) => (
          <div className="home-chart-month" key={entry.month}>
            <div className="home-chart-bars">
              <span className="this-year" style={{height: height(entry[key].this_year)}} title={title(entry[key].this_year)} />
              <span className="last-year" style={{height: height(entry[key].last_year)}} title={title(entry[key].last_year)} />
            </div>
            <span className={entry.month === currentMonth ? 'now' : undefined}>{entry.label}</span>
          </div>
        ))}
      </div>
    </>
  );
}
