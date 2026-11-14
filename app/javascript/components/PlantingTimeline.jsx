import React from 'react';

import {formatDate} from '../dates';

// A planting's life as a line with its events on it, as plantings/_timeline draws it on the planting page: the same
// markup and styles, with the server's labels and icons. A solid badge has happened; a dashed, fainter one is
// expected. The line fills as far as today. `compact` is for a list, where the label sits on one line.
export default function PlantingTimeline({timeline, compact = false}) {
  const {events, fill, today, state, expected_label: expectedLabel, today_label: todayLabel} = timeline;

  return (
    <div className={`planting-timeline${compact ? ' planting-timeline--compact' : ''}`}>
      <div className="planting-timeline-line" aria-hidden="true">
        <div className={`planting-timeline-fill progress-bar--${state}`} style={{width: `${fill}%`}} />
        {today !== null && today !== undefined && (
          <span className="planting-timeline-today" style={{left: `${today}%`}} title={todayLabel} />
        )}
      </div>
      <ol className="planting-timeline-events">
        {events.map((event, index) => {
          const edge = event.percent < 12 ? 'start' : (event.percent > 88 ? 'end' : 'middle');
          const classes = [
            'planting-timeline-event',
            `planting-timeline-event--${index % 2 === 0 ? 'above' : 'below'}`,
            `planting-timeline-event--${edge}`,
            event.expected ? 'planting-timeline-event--expected' : null,
            event.kind === 'failed' ? 'planting-timeline-event--failed' : null,
          ].filter(Boolean).join(' ');
          const date = formatDate(event.date);

          return (
            <li key={`${event.kind}-${event.date}-${index}`} className={classes} style={{left: `${event.percent}%`}}
                title={`${event.label}, ${date}${event.expected ? ` (${expectedLabel})` : ''}`}>
              <span className="planting-timeline-marker" aria-hidden="true">
                <img className="img img-icon" src={event.icon_url} alt="" />
              </span>
              <span className="planting-timeline-label">
                <span className="planting-timeline-name">{event.label}</span>
                <span className="planting-timeline-date">
                  {date}
                  {event.expected && <em>{expectedLabel}</em>}
                </span>
              </span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
