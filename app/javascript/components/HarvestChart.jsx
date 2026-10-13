import React, {useState} from 'react';

// Harvests in each month of this year and last, as paired bars. It shows how
// many harvests were recorded by default, since many have no weight, and the
// chips switch to kilograms without reloading. `months` has, for each month,
// its `label` and `harvests` and `kilograms` totals for `this_year` and
// `last_year`.
export default function HarvestChart({months, current_month: currentMonth, labels}) {
  const [measure, setMeasure] = useState('harvests');
  const unit = measure === 'harvests' ? labels.unit_count : labels.unit_weight;
  const peak = Math.max(1, ...months.flatMap((entry) => [entry[measure].this_year, entry[measure].last_year]));
  const height = (value) => `${Math.round((value / peak) * 100)}%`;
  const title = (value) => `${Math.round(value * 10) / 10} ${unit}`;

  return (
    <>
      <div className="home-chips home-chart-toggle" role="group" aria-label={labels.note_count}>
        {[['harvests', labels.count], ['kilograms', labels.weight]].map(([key, text]) => (
          <a
            key={key}
            href="#"
            className={measure === key ? 'on' : undefined}
            aria-pressed={measure === key}
            onClick={(event) => { event.preventDefault(); setMeasure(key); }}
          >
            {text}
          </a>
        ))}
      </div>
      <p className="home-section-note">{measure === 'harvests' ? labels.note_count : labels.note_weight}</p>
      <div className="home-chart">
        {months.map((entry) => (
          <div className="home-chart-month" key={entry.month}>
            <div className="home-chart-bars">
              <span className="this-year" style={{height: height(entry[measure].this_year)}} title={title(entry[measure].this_year)} />
              <span className="last-year" style={{height: height(entry[measure].last_year)}} title={title(entry[measure].last_year)} />
            </div>
            <span className={entry.month === currentMonth ? 'now' : undefined}>{entry.label}</span>
          </div>
        ))}
      </div>
    </>
  );
}
