import React from 'react';

export default function SplitTable({ orderItems, users, splits, sharingType, onChange, readOnly }) {
  const handleShareChange = (itemId, userIndex, field, value) => {
    const current = splits[itemId] || [];
    const updated = [...current];
    if (!updated[userIndex]) {
      updated[userIndex] = { user_id: '', share: 0 };
    }
    updated[userIndex] = { ...updated[userIndex], [field]: field === 'share' ? parseFloat(value) || 0 : value };
    onChange(itemId, updated);
  };

  const addSplitRow = (itemId) => {
    const current = splits[itemId] || [];
    onChange(itemId, [...current, { user_id: '', share: 0 }]);
  };

  const removeSplitRow = (itemId, index) => {
    const current = splits[itemId] || [];
    onChange(itemId, current.filter((_, i) => i !== index));
  };

  const shareLabel = sharingType === 'percent' ? '%' : sharingType === 'amount' ? 'RSD' : 'parts';

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
          Splits per Item
        </h2>
      </div>
      <div style={{ padding: '16px 24px', display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {orderItems.map(item => (
          <div key={item.id} style={{
            border: '1px solid #e5e7eb',
            borderRadius: '8px',
            padding: '16px',
          }}>
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '12px',
            }}>
              <h3 style={{ fontSize: '14px', fontWeight: '600', color: '#111827', margin: 0 }}>
                {item.article_title}
                <span style={{ fontWeight: '400', color: '#6b7280', marginLeft: '8px' }}>
                  qtyasdf: {item.quantity} @ {item.price} RSD
                </span>
              </h3>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {(splits[item.id] || []).map((split, idx) => (
                <div key={idx} style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <select
                    value={split.user_id || ''}
                    onChange={(e) => handleShareChange(item.id, idx, 'user_id', parseInt(e.target.value, 10))}
                    disabled={readOnly}
                    style={{
                      flex: 1,
                      padding: '6px 10px',
                      borderRadius: '6px',
                      border: '1px solid #d1d5db',
                      fontSize: '14px',
                    }}
                  >
                    <option value="">Select user</option>
                    {users.map(u => (
                      <option key={u.id} value={u.id}>{u.name}</option>
                    ))}
                  </select>
                  <input
                    type="number"
                    min="0"
                    step="any"
                    value={split.share || ''}
                    onChange={(e) => handleShareChange(item.id, idx, 'share', e.target.value)}
                    disabled={readOnly}
                    placeholder={shareLabel}
                    style={{
                      width: '100px',
                      padding: '6px 10px',
                      borderRadius: '6px',
                      border: '1px solid #d1d5db',
                      fontSize: '14px',
                    }}
                  />
                  {!readOnly && (
                    <button
                      onClick={() => removeSplitRow(item.id, idx)}
                      style={{
                        padding: '6px 10px',
                        borderRadius: '6px',
                        border: '1px solid #d1d5db',
                        backgroundColor: '#fff',
                        color: '#dc2626',
                        cursor: 'pointer',
                        fontSize: '14px',
                      }}
                    >
                      x
                    </button>
                  )}
                </div>
              ))}
              {!readOnly && (
                <button
                  onClick={() => addSplitRow(item.id)}
                  style={{
                    alignSelf: 'flex-start',
                    padding: '4px 12px',
                    borderRadius: '6px',
                    border: '1px solid #d1d5db',
                    backgroundColor: '#fff',
                    color: '#4f46e5',
                    cursor: 'pointer',
                    fontSize: '13px',
                  }}
                >
                  + Add split
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
