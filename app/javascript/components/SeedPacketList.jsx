import React from 'react';

// A searchable list of your seed packets to choose from, each with its photo
// (what tells two packets of the same crop apart), what kind it is, and how many
// seeds it has. `sownOn` is the day being sown, for saying a packet had expired.
export default function SeedPacketList({packets, search, onSearch, selected, onChoose, sownOn}) {
  const matching = packets.filter((packet) => packet.name.toLowerCase().includes(search.trim().toLowerCase()));

  return (
    <>
      <label className="form-label" htmlFor="sow-seed-search">Which seeds?</label>
      <input id="sow-seed-search" className="form-control" type="search" value={search} onChange={(event) => onSearch(event.target.value)} />
      <div className="seed-packets mt-2">
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
                {packet.plant_before && packet.plant_before < sownOn && (
                  <span className="badge text-bg-warning">Expired {packet.plant_before.slice(0, 4)}</span>
                )}
              </span>
              <small>Saved {packet.saved}{packet.quantity != null ? ` · ${packet.quantity} seeds` : ''}</small>
            </span>
          </button>
        ))}
      </div>
      {matching.length === 0 && <p className="text-muted mb-0">No seed packets match. Choose &ldquo;New seeds&rdquo; to add one.</p>}
    </>
  );
}
