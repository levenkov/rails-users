import React from 'react';

export default function ApprovalPanel({ approvals, users, currentUserId, readOnly, dirty, onApprove, onRevoke }) {
  const approvedUserIds = new Set(approvals.map(a => a.user_id));
  const currentUserApproved = approvedUserIds.has(currentUserId);
  const allApproved = users.length > 0 && users.every(u => approvedUserIds.has(u.id));

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
          Approvals
          {allApproved && (
            <span style={{
              marginLeft: '8px',
              padding: '2px 8px',
              borderRadius: '9999px',
              backgroundColor: '#dcfce7',
              color: '#166534',
              fontSize: '12px',
              fontWeight: '600',
            }}>
              All approved
            </span>
          )}
        </h2>
      </div>
      <div style={{ padding: '16px 24px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
          {users.map(u => {
            const approved = approvedUserIds.has(u.id);
            const approval = approvals.find(a => a.user_id === u.id);
            return (
              <div key={u.id} style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                fontSize: '14px',
              }}>
                <span style={{
                  display: 'inline-block',
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  backgroundColor: approved ? '#22c55e' : '#d1d5db',
                }} />
                <span style={{ color: '#111827' }}>{u.name}</span>
                {approved && (
                  <span style={{ color: '#6b7280', fontSize: '12px' }}>
                    {new Date(approval.approved_at).toLocaleDateString()}
                  </span>
                )}
              </div>
            );
          })}
        </div>
        {!readOnly && (
          <div>
            {dirty && (
              <p style={{ fontSize: '13px', color: '#d97706', marginBottom: '8px' }}>
                Save your changes before approving.
              </p>
            )}
            {currentUserApproved ? (
              <button
                onClick={onRevoke}
                style={{
                  padding: '8px 20px',
                  borderRadius: '6px',
                  border: '1px solid #d1d5db',
                  backgroundColor: '#fff',
                  color: '#dc2626',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: '500',
                }}
              >
                Revoke Approval
              </button>
            ) : (
              <button
                onClick={onApprove}
                disabled={dirty}
                style={{
                  padding: '8px 20px',
                  borderRadius: '6px',
                  border: 'none',
                  backgroundColor: dirty ? '#9ca3af' : '#22c55e',
                  color: '#fff',
                  cursor: dirty ? 'not-allowed' : 'pointer',
                  fontSize: '14px',
                  fontWeight: '500',
                }}
              >
                Approve
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
