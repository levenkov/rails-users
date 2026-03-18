import React from 'react';

const SHARING_TYPES = [
  { value: 'share', label: 'Share (ratio)' },
  { value: 'percent', label: 'Percent' },
  { value: 'amount', label: 'Amount' },
];

export default function SharingTypeSelector({ value, onChange, readOnly }) {
  return (
    <div style={{
      backgroundColor: '#fff',
      borderRadius: '8px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      overflow: 'hidden',
    }}>
      <div style={{
        padding: '12px 24px',
        backgroundColor: '#f9fafb',
        borderBottom: '1px solid #e5e7eb',
      }}>
        <h2 style={{ fontSize: '16px', fontWeight: '600', color: '#111827', margin: 0 }}>
          Sharing Type
        </h2>
      </div>
      <div style={{ padding: '16px 24px' }}>
        <select
          value={value || ''}
          onChange={(e) => onChange(e.target.value || null)}
          disabled={readOnly}
          style={{
            width: '100%',
            maxWidth: '320px',
            padding: '8px 12px',
            borderRadius: '6px',
            border: '1px solid #d1d5db',
            fontSize: '14px',
            color: '#111827',
            backgroundColor: readOnly ? '#f3f4f6' : '#fff',
          }}
        >
          <option value="">Select sharing type</option>
          {SHARING_TYPES.map(t => (
            <option key={t.value} value={t.value}>{t.label}</option>
          ))}
        </select>
      </div>
    </div>
  );
}
