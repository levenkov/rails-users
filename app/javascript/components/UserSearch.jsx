import React, { useState, useRef, useEffect, useCallback } from 'react';

function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : '';
}

export default function UserSearch({ onSelect, excludeIds = [] }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [highlightIndex, setHighlightIndex] = useState(-1);
  const containerRef = useRef(null);
  const debounceRef = useRef(null);

  const search = useCallback((q) => {
    if (!q.trim()) {
      setResults([]);
      setOpen(false);
      return;
    }

    setLoading(true);
    fetch(`/api/users/search?q=${encodeURIComponent(q)}`, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': getCsrfToken(),
      },
    })
      .then(res => res.ok ? res.json() : [])
      .then(data => {
        const filtered = data.filter(u => !excludeIds.includes(u.id));
        setResults(filtered);
        setOpen(filtered.length > 0);
        setHighlightIndex(-1);
      })
      .catch(() => {
        setResults([]);
        setOpen(false);
      })
      .finally(() => setLoading(false));
  }, [excludeIds]);

  const handleChange = (e) => {
    const value = e.target.value;
    setQuery(value);

    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => search(value), 300);
  };

  const handleSelect = (user) => {
    onSelect(user);
    setQuery('');
    setResults([]);
    setOpen(false);
  };

  const handleKeyDown = (e) => {
    if (!open) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlightIndex(i => Math.min(i + 1, results.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightIndex(i => Math.max(i - 1, 0));
    } else if (e.key === 'Enter' && highlightIndex >= 0) {
      e.preventDefault();
      handleSelect(results[highlightIndex]);
    } else if (e.key === 'Escape') {
      setOpen(false);
    }
  };

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  return (
    <div ref={containerRef} style={{ position: 'relative' }}>
      <input
        type="text"
        value={query}
        onChange={handleChange}
        onKeyDown={handleKeyDown}
        onFocus={() => { if (results.length > 0) setOpen(true); }}
        placeholder="Search users by name or email..."
        style={{
          width: '100%',
          padding: '6px 10px',
          borderRadius: '6px',
          border: '1px solid #d1d5db',
          fontSize: '14px',
          boxSizing: 'border-box',
        }}
      />
      {loading && (
        <span style={{
          position: 'absolute',
          right: '10px',
          top: '50%',
          transform: 'translateY(-50%)',
          fontSize: '12px',
          color: '#9ca3af',
        }}>
          ...
        </span>
      )}
      {open && (
        <ul style={{
          position: 'absolute',
          top: '100%',
          left: 0,
          right: 0,
          margin: '4px 0 0',
          padding: 0,
          listStyle: 'none',
          backgroundColor: '#fff',
          border: '1px solid #d1d5db',
          borderRadius: '6px',
          boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
          zIndex: 50,
          maxHeight: '240px',
          overflowY: 'auto',
        }}>
          {results.map((user, i) => (
            <li
              key={user.id}
              onClick={() => handleSelect(user)}
              onMouseEnter={() => setHighlightIndex(i)}
              style={{
                padding: '8px 12px',
                cursor: 'pointer',
                backgroundColor: i === highlightIndex ? '#eef2ff' : '#fff',
                borderBottom: i < results.length - 1 ? '1px solid #f3f4f6' : 'none',
              }}
            >
              <div style={{ fontSize: '14px', color: '#111827' }}>{user.name}</div>
              <div style={{ fontSize: '12px', color: '#6b7280' }}>{user.email}</div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
