import React, {useState} from 'react';

// A first, deliberately small island to prove the pipeline: it takes props from
// the server and has client-side state.
export default function GardenSummary({owner, count}) {
  const [expanded, setExpanded] = useState(false);
  const who = owner ? `${owner}'s` : 'Everyone\'s';

  return (
    <div className="react-garden-summary mb-3">
      <span>{who} gardens: {count} in total. </span>
      <button
        type="button"
        className="btn btn-sm btn-outline-secondary"
        aria-expanded={expanded}
        onClick={() => setExpanded(!expanded)}
      >
        {expanded ? 'Hide' : 'Show'} details
      </button>
      {expanded && (
        <p className="text-muted mt-2">
          This summary is a React component, mounted into a server-rendered page.
        </p>
      )}
    </div>
  );
}
