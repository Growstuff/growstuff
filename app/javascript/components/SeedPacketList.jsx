import React, {useState} from 'react';

// A list of your seed packets to search and choose from, each with its photo
// (what tells two packets of the same crop apart), what kind it is, and how many
// seeds it has. `sownOn` is the day being sown, for saying a packet had expired.
export default function SeedPacketList({packets, search, onSearch, selected, onChoose, sownOn}) {
  const expired = (packet) => Boolean(packet.plant_before) && packet.plant_before < sownOn;
  // Expired packets are left out unless asked for, or one of them is already chosen.
  const [includeExpired, setIncludeExpired] = useState(Boolean(selected && expired(selected)));
  const named = packets.filter((packet) => packet.name.toLowerCase().includes(search.trim().toLowerCase()));
  const matching = includeExpired ? named : named.filter((packet) => !expired(packet));
  const hidden = named.length - matching.length;

  return (
    <div className="crop-picker crop-picker-compact">
      <label className="crop-picker-label seed-search-label" htmlFor="sow-seed-search">Search your seeds</label>
      <div className="seed-search">
        <div className="crop-picker-field seed-search-field">
          <i className="fas fa-search crop-picker-icon" aria-hidden="true" />
          <input
            id="sow-seed-search"
            type="text"
            className="crop-picker-input"
            autoFocus
            autoComplete="off"
            placeholder="Start typing a crop name, like tomato"
            value={search}
            onChange={(event) => onSearch(event.target.value)}
          />
        </div>
        <div className="form-check seed-search-expired">
          <input
            id="sow-include-expired"
            type="checkbox"
            className="form-check-input"
            checked={includeExpired}
            onChange={(event) => setIncludeExpired(event.target.checked)}
          />
          <label className="form-check-label" htmlFor="sow-include-expired">Include expired seeds</label>
        </div>
      </div>
      <p className="seed-search-hint" role="status">
        {search.trim()
          ? `${matching.length} of ${packets.length} packets match. Choose one.`
          : `${matching.length} packets. Type a crop name to narrow them down, or choose one.`}
        {hidden > 0 && ` ${hidden} expired ${hidden === 1 ? 'packet is' : 'packets are'} hidden.`}
      </p>
      <div className="seed-packets">
        {matching.map((packet) => (
          <button
            key={packet.id}
            type="button"
            className={`seed-packet-card${selected && selected.id === packet.id ? ' selected' : ''}`}
            aria-pressed={Boolean(selected && selected.id === packet.id)}
            onClick={() => onChoose(packet)}
          >
            {packet.photo_url && <img className="seed-packet-photo" src={packet.photo_url} alt={`Photo of the ${packet.name} packet`} />}
            <span className="seed-packet-text">
              <strong>{packet.name}</strong>
              <span className="seed-packet-badges">
                {packet.heirloom === 'heirloom' && <span className="badge text-bg-success">Heirloom</span>}
                {packet.heirloom === 'hybrid' && <span className="badge text-bg-warning">Hybrid</span>}
                {expired(packet) && <span className="badge text-bg-warning">Expired {packet.plant_before.slice(0, 4)}</span>}
              </span>
              <small>Saved {packet.saved}{packet.quantity != null ? ` · ${packet.quantity} seeds` : ''}</small>
            </span>
          </button>
        ))}
      </div>
      {matching.length === 0 && <p className="text-muted mb-0">No seed packets match. Choose &ldquo;New seeds&rdquo; to add one.</p>}
    </div>
  );
}
