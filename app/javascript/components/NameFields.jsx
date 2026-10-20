import React, {useRef, useState} from 'react';

// A list of text fields for a crop's names, numbered the way the controller
// reads them (`field`[1], `field`[2], ...), with a button to add another and
// one on each row to remove it. There is always at least one field, so emptying
// it and saving clears the crop's names.
//
// `renderInput({id, name, value, onChange})` draws a field, so a list can use
// a plain input or one that suggests names. `buttonClass` is the stem of the
// buttons' class names (`add-<stem>-row`, `remove-<stem>-row`).
export default function NameFields({names, field, noun, buttonClass, help, renderInput}) {
  const nextKey = useRef(0);
  const newRow = (value) => ({key: nextKey.current++, value: value ?? ''}); // a new crop's blank name is null
  const [rows, setRows] = useState(() => (names.length ? names : ['']).map(newRow));

  const change = (key, value) => setRows(rows.map((row) => (row.key === key ? {...row, value} : row)));
  const remove = (key) => setRows(rows.filter((row) => row.key !== key));

  return (
    <div className="mb-3">
      {rows.map((row, index) => {
        const number = index + 1;
        const id = `${field}[${number}]`;
        return (
          <div className="mb-2" key={row.key}>
            <label className="form-label" htmlFor={id}>{noun} {number}:</label>
            <div className="input-group">
              {renderInput({id, name: id, value: row.value, onChange: (value) => change(row.key, value)})}
              <button
                type="button"
                className={`btn btn-outline-secondary remove-${buttonClass}-row`}
                aria-label={`Remove ${noun.toLowerCase()} ${number}`}
                disabled={rows.length === 1}
                onClick={() => remove(row.key)}
              >
                &minus;
              </button>
            </div>
          </div>
        );
      })}
      <span className="form-text d-block mb-2">{help}</span>
      <button type="button" className={`btn btn-outline-secondary add-${buttonClass}-row`} onClick={() => setRows([...rows, newRow()])}>
        Add {noun.toLowerCase()}
      </button>
    </div>
  );
}
