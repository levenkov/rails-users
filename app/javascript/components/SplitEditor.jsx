import React, { useState, useEffect, useCallback } from 'react';
import SharingTypeSelector from './SharingTypeSelector';
import SplitTable from './SplitTable';
import ParticipantList from './ParticipantList';
import ApprovalPanel from './ApprovalPanel';

function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : '';
}

function apiFetch(url, options = {}) {
  return fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrfToken(),
      ...options.headers,
    },
  }).then(res => {
    if (!res.ok) return res.json().then(data => Promise.reject(data));
    return res.json();
  });
}

export default function SplitEditor({ orderId, currentUserId }) {
  const [order, setOrder] = useState(null);
  const [sharingType, setSharingType] = useState(null);
  const [splits, setSplits] = useState({});
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const basePath = `/api/orders/${orderId}/splitting`;

  const loadOrder = useCallback(() => {
    setLoading(true);
    apiFetch(basePath)
      .then(data => {
        setOrder(data);
        setSharingType(data.sharing_type);
        const splitMap = {};
        data.order_items.forEach(item => {
          splitMap[item.id] = item.order_item_splits.map(s => ({
            user_id: s.user_id,
            share: s.share,
          }));
        });
        if (data.suggested_splits && Object.values(splitMap).every(s => s.length === 0)) {
          Object.entries(data.suggested_splits).forEach(([itemId, suggestions]) => {
            splitMap[itemId] = suggestions;
          });
          setSplits(splitMap);
          if (!data.sharing_type) {
            setSharingType('share');
          }
          setDirty(true);
        } else {
          setSplits(splitMap);
          setDirty(false);
        }
        setError(null);
      })
      .catch(err => setError(err.error || 'Failed to load'))
      .finally(() => setLoading(false));
  }, [basePath]);

  useEffect(() => { loadOrder(); }, [loadOrder]);

  const readOnly = false;

  const handleSharingTypeChange = (type) => {
    setSharingType(type);
    setDirty(true);
  };

  const handleSplitChange = (itemId, newSplits) => {
    setSplits(prev => ({ ...prev, [itemId]: newSplits }));
    setDirty(true);
  };

  const handleSave = () => {
    setSaving(true);
    setError(null);

    const payload = {
      sharing_type: sharingType,
      splits: {},
    };
    Object.entries(splits).forEach(([itemId, userSplits]) => {
      payload.splits[itemId] = userSplits.filter(s => s.user_id && s.share > 0);
    });

    apiFetch(basePath, { method: 'PUT', body: JSON.stringify(payload) })
      .then(data => {
        setOrder(data);
        setSharingType(data.sharing_type);
        const splitMap = {};
        data.order_items.forEach(item => {
          splitMap[item.id] = item.order_item_splits.map(s => ({
            user_id: s.user_id,
            share: s.share,
          }));
        });
        setSplits(splitMap);
        setDirty(false);
      })
      .catch(err => setError(err.errors ? err.errors.join(', ') : 'Failed to save'))
      .finally(() => setSaving(false));
  };

  const handleApprove = () => {
    apiFetch(`${basePath}/approval`, { method: 'POST' })
      .then(data => { setOrder(data); setError(null); })
      .catch(err => setError(err.errors ? err.errors.join(', ') : 'Failed to approve'));
  };

  const handleRevoke = () => {
    apiFetch(`${basePath}/approval`, { method: 'DELETE' })
      .then(data => { setOrder(data); setError(null); })
      .catch(err => setError(err.errors ? err.errors.join(', ') : 'Failed to revoke'));
  };

  const handleAddParticipant = (userId) => {
    apiFetch(`${basePath}/participants`, {
      method: 'POST',
      body: JSON.stringify({ user_id: userId }),
    })
      .then(data => { setOrder(data); setError(null); })
      .catch(err => setError(err.errors ? err.errors.join(', ') : 'Failed to add participant'));
  };

  const handleRemoveParticipant = (userId) => {
    apiFetch(`${basePath}/participants/${userId}`, { method: 'DELETE' })
      .then(data => { setOrder(data); setError(null); })
      .catch(err => setError(err.errors ? err.errors.join(', ') : 'Failed to remove participant'));
  };

  if (loading) {
    return <div style={{ padding: '24px', color: '#6b7280' }}>Loading...</div>;
  }

  if (!order) {
    return <div style={{ padding: '24px', color: '#ef4444' }}>Failed to load order data.</div>;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {error && (
        <div style={{
          padding: '12px 16px',
          backgroundColor: '#fef2f2',
          border: '1px solid #fecaca',
          borderRadius: '8px',
          color: '#dc2626',
          fontSize: '14px',
        }}>
          {error}
        </div>
      )}

      <ParticipantList
        users={order.users}
        currentUserId={currentUserId}
        readOnly={readOnly}
        onAdd={handleAddParticipant}
        onRemove={handleRemoveParticipant}
      />

      <SharingTypeSelector
        value={sharingType}
        onChange={handleSharingTypeChange}
        readOnly={readOnly}
      />

      <SplitTable
        orderItems={order.order_items}
        users={order.users}
        splits={splits}
        sharingType={sharingType}
        onChange={handleSplitChange}
        readOnly={readOnly}
      />

      {!readOnly && (
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <button
            onClick={handleSave}
            disabled={!dirty || saving}
            style={{
              padding: '8px 20px',
              borderRadius: '6px',
              fontSize: '14px',
              fontWeight: '500',
              color: '#fff',
              backgroundColor: dirty && !saving ? '#4f46e5' : '#9ca3af',
              border: 'none',
              cursor: dirty && !saving ? 'pointer' : 'not-allowed',
            }}
          >
            {saving ? 'Saving...' : 'Save Splits'}
          </button>
        </div>
      )}

      <ApprovalPanel
        approvals={order.split_approvals}
        users={order.users}
        currentUserId={currentUserId}
        readOnly={readOnly}
        dirty={dirty}
        onApprove={handleApprove}
        onRevoke={handleRevoke}
      />
    </div>
  );
}
