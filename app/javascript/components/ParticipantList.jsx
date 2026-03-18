import React from 'react';
import UserSearch from './UserSearch';

export default function ParticipantList({ users, currentUserId, readOnly, onAdd, onRemove }) {
  const excludeIds = users.map(u => u.id);

  const handleSelect = (user) => {
    onAdd(user.id);
  };

  return (
    <div style={{
      backgroundColor: '#fff',
      borderRadius: '8px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    }}>
      <div style={{
        padding: '12px 24px',
        backgroundColor: '#f9fafb',
        borderBottom: '1px solid #e5e7eb',
      }}>
        <h2 style={{ fontSize: '16px', fontWeight: '600', color: '#111827', margin: 0 }}>
          Participants
        </h2>
      </div>
      <div style={{ padding: '16px 24px' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: !readOnly ? '12px' : 0 }}>
          {users.map(u => (
            <span
              key={u.id}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '4px 12px',
                borderRadius: '9999px',
                backgroundColor: '#eef2ff',
                color: '#4338ca',
                fontSize: '14px',
              }}
            >
              {u.name}
              {!readOnly && u.id !== currentUserId && (
                <button
                  onClick={() => onRemove(u.id)}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: '#6366f1',
                    cursor: 'pointer',
                    padding: '0 2px',
                    fontSize: '14px',
                    lineHeight: 1,
                  }}
                >
                  x
                </button>
              )}
            </span>
          ))}
        </div>
        {!readOnly && (
          <UserSearch onSelect={handleSelect} excludeIds={excludeIds} />
        )}
      </div>
    </div>
  );
}
