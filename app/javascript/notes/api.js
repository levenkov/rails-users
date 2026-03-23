const getCSRFToken = () => document.querySelector('meta[name="csrf-token"]')?.content;

const jsonHeaders = () => ({
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-CSRF-Token': getCSRFToken()
});

export const api = {
  get: (url) => fetch(url, { headers: { 'Accept': 'application/json' } }).then(r => r.json()),

  post: (url, data) => fetch(url, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify(data)
  }).then(r => r.json()),

  patch: (url, data) => fetch(url, {
    method: 'PATCH',
    headers: jsonHeaders(),
    body: JSON.stringify(data)
  }).then(r => r.json()),

  delete: (url) => fetch(url, {
    method: 'DELETE',
    headers: { 'Accept': 'application/json', 'X-CSRF-Token': getCSRFToken() }
  })
};
