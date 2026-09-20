// Same-origin calls to our own Rails controllers: the session cookie plus the
// CSRF token from the page's meta tag. (Not for the public /api/v1.)

export function csrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.content : '';
}

async function parse(response) {
  try {
    return await response.json();
  } catch (error) {
    return null; // no body, or not JSON
  }
}

export async function getJson(url, {signal} = {}) {
  const response = await fetch(url, {credentials: 'same-origin', headers: {Accept: 'application/json'}, signal});
  return {ok: response.ok, status: response.status, data: await parse(response)};
}

export async function postJson(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    credentials: 'same-origin',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: JSON.stringify(body),
  });
  return {ok: response.ok, status: response.status, data: await parse(response)};
}
