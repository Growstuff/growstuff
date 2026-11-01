export function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

// What to tell someone when saving from a dialog failed. A 422 has the server's
// own reasons, by field ("Quantity must be…", or just the reason when it isn't
// about a field); anything else gets a general message.
export function errorMessages(status, data, {forbidden, signedOut, fallback = 'Something went wrong saving that. Please try again.'} = {}) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => (
      list.map((message) => (field === 'base' ? message : `${humanize(field)} ${message}`))
    ));
    if (messages.length > 0) return messages;
  }
  if (status === 403 && forbidden) return [forbidden];
  if (status === 401 && signedOut) return [signedOut];
  return [fallback];
}
