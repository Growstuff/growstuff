import React from 'react';

// A row of pill buttons that pick one of several options without reloading.
// `options` are {key, label, href}; the href is where the link goes without
// JavaScript. `value` is the chosen key.
export default function ChipToggle({options, value, onChange, className = ''}) {
  return (
    <div className={`home-chips ${className}`.trim()} role="group">
      {options.map(({key, label, href = '#'}) => (
        <a
          key={key}
          href={href}
          className={value === key ? 'on' : undefined}
          aria-pressed={value === key}
          onClick={(event) => { event.preventDefault(); onChange(key); }}
        >
          {label}
        </a>
      ))}
    </div>
  );
}
