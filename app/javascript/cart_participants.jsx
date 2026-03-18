import React from 'react';
import { createRoot } from 'react-dom/client';
import CartParticipants from './components/CartParticipants';

export function mountCartParticipants(el) {
  const initialParticipants = JSON.parse(el.dataset.participants);
  const currentUserId = parseInt(el.dataset.currentUserId, 10);
  const currentUserName = el.dataset.currentUserName;
  const addParticipantPath = el.dataset.addParticipantPath;
  const removeParticipantPath = el.dataset.removeParticipantPath;
  const csrfToken = el.dataset.csrfToken;

  const root = createRoot(el);
  root.render(
    <CartParticipants
      initialParticipants={initialParticipants}
      currentUserId={currentUserId}
      currentUserName={currentUserName}
      addParticipantPath={addParticipantPath}
      removeParticipantPath={removeParticipantPath}
      csrfToken={csrfToken}
    />
  );
}
