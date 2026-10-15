import React, {useEffect, useRef, useState} from 'react';

// How long the packets take to fold back into the pile, in ms. Matches the
// seed-group-close animation in _seeds.scss.
const CLOSE_MS = 260;

const pill = (heirloom) => heirloom && (
  <span className={`seed-pill seed-pill-${heirloom}`}>
    {heirloom.charAt(0).toUpperCase() + heirloom.slice(1)}
  </span>
);

// The owner's avatar, small, beside a pile on a page of other people's seeds.
const Owner = ({owner}) => owner && (
  <a className="seed-owner" href={owner.path} title={owner.label} aria-label={owner.label}>
    <img src={owner.avatar_url} alt="" width="32" height="32" />
  </a>
);

// Several packets of one variety. Closed, they are a pile with a count on top;
// opened, the pile spreads out where it stood, one packet each, to pick from.
// Rails renders the top packet first (see seeds/_stack), so there is something
// to see before this loads and without JavaScript.
export default function SeedStack({crop, count, image_url: imageUrl, heirloom, rule, packets, owner}) {
  const [state, setState] = useState('closed');
  const toggle = useRef(null);
  const closeTimer = useRef(null);

  useEffect(() => () => clearTimeout(closeTimer.current), []);

  const open = () => setState('open');
  const close = () => {
    setState('closing');
    closeTimer.current = setTimeout(() => {
      setState('closed');
      toggle.current?.focus();
    }, CLOSE_MS);
  };

  if (state === 'closed') {
    return (
      <div className="seed-stack seed-stack-island">
        <div className="seed-stack-pile">
          <span className="seed-stack-count" aria-hidden="true">×{count}</span>
          <button
            type="button"
            ref={toggle}
            className="seed-packet seed-stack-toggle"
            aria-expanded="false"
            aria-label={`${crop.name}, ${count} packets. Open to see each packet`}
            onClick={open}
          >
            <span className="seed-packet-tear" aria-hidden="true" />
            <img className="seed-packet-window" src={imageUrl} alt="" />
            <span className="seed-packet-name">{crop.name}</span>
            <span className="seed-packet-line seed-stack-hint">{count} packets <i aria-hidden="true">▸</i> open</span>
            {heirloom && <span className="seed-packet-line">{pill(heirloom)}</span>}
            {owner && <span className={`seed-packet-line seed-packet-owner${owner.yours ? ' seed-packet-yours' : ''}`}>{owner.tag}</span>}
            <span className="seed-packet-rule">{rule}</span>
          </button>
        </div>
        <Owner owner={owner} />
      </div>
    );
  }

  return (
    <div
      className={`seed-group${state === 'closing' ? ' is-closing' : ''}`}
      role="group"
      aria-label={`${crop.name}, ${count} packets`}
      onKeyDown={(event) => { if (event.key === 'Escape' && state === 'open') close(); }}
    >
      <div className="seed-group-head">
        <b>{crop.name} · {count} packets</b>
        {owner && (
          <a className="seed-group-owner" href={owner.path} title={owner.label}>
            <img src={owner.avatar_url} alt="" width="24" height="24" />
            {owner.tag}
          </a>
        )}
        <button type="button" className="seed-group-close" aria-expanded="true" onClick={close} disabled={state === 'closing'}>
          Close ▴
        </button>
      </div>
      <div className="seed-group-row">
        {packets.map((packet, index) => (
          <article key={packet.id} className="seed-packet seed-group-packet" style={{'--i': index, '--n': packets.length}}>
            <div className="seed-packet-tear" aria-hidden="true" />
            <a href={packet.path}><img className="seed-packet-window" src={packet.image_url} alt="" /></a>
            <h4 className="seed-packet-name"><a href={packet.path}>{packet.name}</a></h4>
            <p>{packet.when}</p>
            {packet.heirloom && <p>{pill(packet.heirloom)}</p>}
            <p className="seed-packet-detail">{packet.detail}</p>
            {packet.past && <span className="seed-packet-stamp">Past sow-by</span>}
            <div className="seed-packet-rule">{packet.rule}</div>
          </article>
        ))}
      </div>
      <div className="seed-group-foot">
        <a href={crop.path}>Open the {crop.name} page →</a>
        <span className="text-muted"> history, finished packets, plantings these seeds grew</span>
      </div>
    </div>
  );
}
