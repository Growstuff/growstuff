import React, {useEffect, useState} from 'react';

import {getJson} from '../api';

// Fills in a translated template: "sown %{date}" with {date: '3 Oct'}.
function fill(template, values = {}) {
  return String(template).replace(/%\{(\w+)\}/g, (_, key) => (values[key] === undefined ? '' : values[key]));
}

function plural(forms, count) {
  return fill(count === 1 ? forms.one : forms.other, {count});
}

function Person({person, children}) {
  return (
    <>
      <span className="give-avatar" aria-hidden="true">{person.name.charAt(0).toUpperCase()}</span>
      <span className="give-person-text">
        <span className="give-strong">{person.name}</span>
        {person.place && <span className="give-muted">{person.place}</span>}
      </span>
      {children}
    </>
  );
}

// Who has the seedlings: a member picked from Growstuff, or someone who is not on it, by name and, if known, how
// they sign in. Picking a member sends them the seedlings to claim; the contact is only so they can be found later.
function WhoHasThem({labels, who, setWho, picked, setPicked, name, setName, kind, setKind, contact, setContact, suggestions, recipientsUrl}) {
  const [query, setQuery] = useState('');
  const [found, setFound] = useState(null); // null until a search has answered
  const term = query.trim();

  useEffect(() => {
    if (term.length < 2) {
      setFound(null);
      return undefined;
    }
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const {ok, data} = await getJson(`${recipientsUrl}?q=${encodeURIComponent(term)}`, {signal: controller.signal});
        if (ok) setFound(data);
      } catch (error) {
        // aborted, or the server is out of reach: keep what is shown
      }
    }, 250);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [term, recipientsUrl]);

  const people = term.length >= 2 ? (found || []) : suggestions;
  const kinds = [
    {key: 'email', label: labels.email, icon: '✉'},
    {key: 'mastodon', label: labels.fediverse, icon: '@'},
    {key: 'bluesky', label: labels.bluesky, icon: '☁'},
  ];

  if (who === 'guest') {
    return (
      <div className="give-stack">
        <div className="give-field">
          <label htmlFor="give-name" className="give-strong">
            {labels.their_name} <span className="give-normal give-muted">{labels.required}</span>
          </label>
          <input id="give-name" name="recipient_name" type="text" autoComplete="off" required maxLength={100}
                 className="form-control" value={name} onChange={(event) => setName(event.target.value)} />
          <span className="give-muted">{labels.name_hint}</span>
        </div>
        <div className="give-signin">
          <div>
            <h2 className="give-signin-title">{labels.signin_heading} <span className="give-badge">{labels.recommended}</span></h2>
            <p>{labels.signin_text}</p>
          </div>
          <fieldset className="give-field">
            <legend className="give-strong give-legend-small">{labels.how_signin}</legend>
            <div className="give-chips">
              {kinds.map(({key, label, icon}) => (
                <label key={key} className={`give-chip${kind === key ? ' give-chip-on' : ''}`}>
                  <input type="radio" name="recipient_kind" value={key} checked={kind === key} onChange={() => setKind(key)} />
                  <span aria-hidden="true">{icon}</span>
                  <span>{label}</span>
                </label>
              ))}
            </div>
          </fieldset>
          <div className="give-field">
            <label htmlFor="give-contact" className="give-strong">{labels[`${kind}_label`]}</label>
            <input id="give-contact" name="recipient" type="text" autoComplete="off" className="form-control"
                   placeholder={labels[`${kind}_placeholder`]} value={contact} onChange={(event) => setContact(event.target.value)} />
          </div>
          <p className="mb-0">{fill(labels.tell_them, {what: kind === 'email' ? labels.email_what : labels.handle_what})}</p>
        </div>
        <button type="button" className="give-link" onClick={() => setWho('member')}>{labels.on_growstuff_after_all}</button>
      </div>
    );
  }

  if (picked) {
    return (
      <div className="give-picked">
        <input type="hidden" name="recipient_member_id" value={picked.id} />
        <Person person={picked}>
          <button type="button" className="give-link" onClick={() => setPicked(null)}>{labels.change}</button>
        </Person>
      </div>
    );
  }

  return (
    <div className="give-stack">
      <div className="give-field">
        <label htmlFor="give-find" className="give-strong">{labels.who_has}</label>
        <input id="give-find" type="search" autoComplete="off" className="form-control" value={query}
               placeholder={labels.search_placeholder} onChange={(event) => setQuery(event.target.value)} />
        <span className="give-muted">{term.length >= 2 ? labels.matching_hint : labels.suggestions_hint}</span>
      </div>
      {people.map((person) => (
        <button key={person.id} type="button" className="give-person" onClick={() => setPicked(person)}>
          <Person person={person} />
        </button>
      ))}
      {term.length >= 2 && found && found.length === 0 && (
        <p className="give-note">{fill(labels.no_match, {query: term})}</p>
      )}
      <div>
        <button type="button" className="give-link" onClick={() => setWho('guest')}>{labels.not_on_growstuff}</button>
      </div>
    </div>
  );
}

function PathCard({id, value, current, setCurrent, title, hint, children}) {
  const on = current === value;
  return (
    <div className={`give-card${on ? ' give-card-on' : ''}`}>
      <label className="give-card-label">
        <input type="radio" name="path" value={value} id={id} checked={on} onChange={() => setCurrent(value)} />
        <span>
          <span className="give-block give-strong">{title}</span>
          {hint && <span className="give-block give-muted">{hint}</span>}
        </span>
      </label>
      {on && children && <div className="give-card-body">{children}</div>}
    </div>
  );
}

// Giving away seedlings from the nursery, or putting them on the stall. One question, "what's happened to them?", then
// only the fields that answer needs. It is an ordinary form: the server decides what is saved, and shows this again
// with what was typed if it can't.
export default function GiveAwayForm({
  action, csrf, cancelUrl, recipientsUrl, today, labels, seedlings, selected = {}, offeredIds = [], status = '',
  values = {}, suggestions = [], picked: initialPicked = null, errors = [],
}) {
  const [quantities, setQuantities] = useState(() => {
    const start = {};
    seedlings.forEach((seedling) => {
      if (seedling.id in selected) start[seedling.id] = selected[seedling.id] || seedling.total;
    });
    return start;
  });
  const [path, setPath] = useState(status);
  const [who, setWho] = useState(values.recipient_name ? 'guest' : 'member');
  const [picked, setPicked] = useState(initialPicked);
  const [name, setName] = useState(values.recipient_name || '');
  const [kind, setKind] = useState(values.recipient_kind || 'email');
  const [contact, setContact] = useState(values.recipient || '');
  const [givenOn, setGivenOn] = useState(values.given_on || today);

  const chosen = seedlings.filter((seedling) => seedling.id in quantities);
  const plants = chosen.reduce((sum, seedling) => sum + quantities[seedling.id], 0);
  const these = plants === 1 ? labels.it : labels.them;
  const ready = chosen.length > 0 && (path === 'offered' || (path === 'given' && (picked || (who === 'guest' && name.trim()))));

  function toggle(seedling) {
    setQuantities((current) => {
      const next = {...current};
      if (seedling.id in next) delete next[seedling.id];
      else next[seedling.id] = seedling.total;
      return next;
    });
  }

  function step(seedling, by) {
    setQuantities((current) => ({...current, [seedling.id]: Math.min(seedling.total, Math.max(1, current[seedling.id] + by))}));
  }

  return (
    <form method="post" action={action} className="stall-dialog give-form">
      <input type="hidden" name="authenticity_token" value={csrf} />
      <div className="stall-dialog-header">
        <h1 id="give-title">{labels.title}</h1>
        <a href={cancelUrl} className="stall-dialog-close" title={labels.close}>
          <svg aria-hidden="true" width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 3l12 12M15 3L3 15" /></svg>
          <span className="visually-hidden">{labels.close}</span>
        </a>
      </div>

      <div className="stall-dialog-body give-body">
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
          </div>
        )}

        <fieldset className="give-fieldset">
          <legend>{labels.which}</legend>
          {seedlings.length === 0 && <p className="text-muted">{labels.none_left}</p>}
          {seedlings.map((seedling) => {
            const on = seedling.id in quantities;
            const qty = quantities[seedling.id];
            const domId = `give-seedling-${seedling.id}`;
            return (
              <div key={seedling.id} className={`give-row${on ? ' give-row-on' : ''}`}>
                <label htmlFor={domId} className="give-row-label">
                  <input id={domId} type="checkbox" name="planting_ids[]" value={seedling.id} checked={on} onChange={() => toggle(seedling)} />
                  <span className="give-thumb" aria-hidden="true">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 21v-9" /><path d="M12 12C12 8 9 6 5 6c0 4 2 6 7 6z" /><path d="M12 14c0-3 2-5 6-5 0 3-2 5-6 5z" /></svg>
                  </span>
                  <span className="give-person-text">
                    <span className="give-strong">{seedling.label}</span>
                    <span className="give-muted">{seedling.detail}</span>
                    {offeredIds.includes(seedling.id) && <span className="give-muted">{labels.on_stall}</span>}
                  </span>
                </label>
                {on && seedling.total > 1 && (
                  <>
                    <div role="group" aria-label={fill(labels.quantity_group, {name: seedling.label})} className="give-stepper">
                      <button type="button" aria-label={labels.one_fewer} disabled={qty <= 1} onClick={() => step(seedling, -1)}>−</button>
                      <span className="give-qty">{qty}</span>
                      <button type="button" aria-label={labels.one_more} disabled={qty >= seedling.total} onClick={() => step(seedling, 1)}>+</button>
                      <span className="give-muted">{fill(labels.of_total, {total: seedling.total})}</span>
                    </div>
                    {qty < seedling.total && (
                      <div className="give-stay">{plural(labels.stay, seedling.total - qty)}</div>
                    )}
                  </>
                )}
                {on && <input type="hidden" name={`quantities[${seedling.id}]`} value={qty} />}
              </div>
            );
          })}
        </fieldset>

        <fieldset className="give-fieldset">
          <legend>{fill(labels.what_happened, {these})}</legend>

          <PathCard id="give-path-given" value="given" current={path} setCurrent={setPath} title={labels.given_title} hint={labels.given_hint}>
            <div className="give-stack give-stack-wide">
              <WhoHasThem labels={labels} who={who} setWho={setWho} picked={picked} setPicked={setPicked} name={name} setName={setName}
                          kind={kind} setKind={setKind} contact={contact} setContact={setContact} suggestions={suggestions} recipientsUrl={recipientsUrl} />
              <div className="give-field give-date">
                <label htmlFor="give-when" className="give-strong">{labels.given_on}</label>
                <input id="give-when" name="given_on" type="date" className="form-control" value={givenOn} max={today}
                       onChange={(event) => setGivenOn(event.target.value)} />
                <span className="give-muted">{labels.given_on_hint}</span>
              </div>
              <p className="give-note">
                {who === 'guest' ? labels.privacy_guest : (picked ? fill(labels.privacy_member, {name: picked.name}) : labels.privacy_member_unnamed)}
              </p>
            </div>
          </PathCard>

          <PathCard id="give-path-offered" value="offered" current={path} setCurrent={setPath} title={labels.offered_title} hint={labels.offered_hint}>
            <p className="mb-0">{labels.offered_detail}</p>
          </PathCard>

          <PathCard id="give-path-help" value="help" current={path} setCurrent={setPath} title={labels.help_title}>
            <p>{labels.help_leaving}</p>
            <p><strong>{labels.help_given_lead}</strong> {labels.help_given_rest} <strong>{labels.help_offered_lead}</strong> {labels.help_offered_rest}</p>
            <p className="mb-0">{labels.help_nothing_deleted}</p>
          </PathCard>
        </fieldset>
      </div>

      {(path === 'given' || path === 'offered') && <input type="hidden" name="status" value={path} />}
      <div className="stall-dialog-footer give-footer">
        <a href={cancelUrl} className="btn btn-secondary">{labels.cancel}</a>
        {(path === 'given' || path === 'offered') && (
          <button type="submit" className="btn btn-primary" disabled={!ready}>
            {path === 'given' ? labels.submit_given : labels.submit_offered}
          </button>
        )}
      </div>
    </form>
  );
}
