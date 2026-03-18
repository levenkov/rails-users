import React, { useState } from 'react';
import UserSearch from './UserSearch';

export default function CartParticipants({
  initialParticipants,
  currentUserId,
  currentUserName,
  addParticipantPath,
  removeParticipantPath,
  csrfToken,
}) {
  const ensureSelf = (list) => {
    if (list.some(p => p.id === currentUserId)) return list;
    return [{ id: currentUserId, name: currentUserName }, ...list];
  };

  const [participants, setParticipants] = useState(
    ensureSelf(initialParticipants)
  );

  const handleAdd = (user) => {
    if (participants.some(p => p.id === user.id)) return;

    fetch(addParticipantPath, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
      },
      body: JSON.stringify({ user_id: user.id }),
    }).then(res => {
      if (res.ok) {
        setParticipants(prev => [...prev, user]);
      }
    });
  };

  const handleRemove = (userId) => {
    if (userId === currentUserId) return;

    fetch(removeParticipantPath + `?user_id=${userId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
      },
    }).then(res => {
      if (res.ok || res.status === 204) {
        setParticipants(prev => prev.filter(p => p.id !== userId));
      }
    });
  };

  const excludeIds = participants.map(p => p.id);

  return (
    <div className="bg-white shadow rounded-lg">
      <div className="px-6 py-4 bg-gray-50 border-b border-gray-200 rounded-t-lg">
        <h2 className="text-lg font-semibold text-gray-900">Participants</h2>
      </div>
      <div className="px-6 py-6">
        <p className="text-sm text-gray-500 mb-4">
          Add users who will participate in this order.
        </p>

        <div className="flex flex-wrap gap-2 mb-4">
          {participants.map(p => (
            <span
              key={p.id}
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-50 text-indigo-700 text-sm"
            >
              {p.name}
              {p.id !== currentUserId && (
                <button
                  type="button"
                  onClick={() => handleRemove(p.id)}
                  className="text-indigo-400 hover:text-indigo-600 cursor-pointer"
                >
                  &times;
                </button>
              )}
            </span>
          ))}
        </div>

        <UserSearch onSelect={handleAdd} excludeIds={excludeIds} />
      </div>
    </div>
  );
}
