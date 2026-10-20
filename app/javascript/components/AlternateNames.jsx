import React, {useRef, useState} from 'react';

// The alternate names on the crop form: a text field for each, numbered the
// way the controller reads them (alt_name[1], alt_name[2], ...), with a button
// to add another and one on each row to remove it. There is always at least one
// field, so emptying it and saving clears the crop's names.
export default function AlternateNames({names}) {
  const nextKey = useRef(0);
  const newRow = (value = '') => ({key: nextKey.current++, value});
  const [rows, setRows] = useState(() => (names.length ? names : ['']).map(newRow));

  const change = (key, value) => setRows(rows.map((row) => (row.key === key ? {...row, value} : row)));
  const remove = (key) => setRows(rows.filter((row) => row.key !== key));

  return (
    <div className="mb-3">
      {rows.map((row, index) => {
        const number = index + 1;
        const id = `alt_name[${number}]`;
        return (
          <div className="mb-2" key={row.key}>
            <label className="form-label" htmlFor={id}>Alternate name {number}:</label>
            <div className="input-group">
              <input
                type="text"
                className="form-control"
                id={id}
                name={id}
                value={row.value}
                onChange={(event) => change(row.key, event.target.value)}
              />
              <button
                type="button"
                className="btn btn-outline-secondary remove-altname-row"
                aria-label={`Remove alternate name ${number}`}
                disabled={rows.length === 1}
                onClick={() => remove(row.key)}
              >
                &minus;
              </button>
            </div>
          </div>
        );
      })}
      <span className="form-text d-block mb-2">Alternate name of crop.</span>
      <button type="button" className="btn btn-outline-secondary add-altname-row" onClick={() => setRows([...rows, newRow()])}>
        Add alternate name
      </button>
    </div>
  );
}
