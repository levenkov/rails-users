import React from 'react';
import { createRoot } from 'react-dom/client';
import CheckoutForm from './components/CheckoutForm';

export function mountCheckout(el) {
  const cartItems = JSON.parse(el.dataset.cartItems);
  const total = el.dataset.total;
  const currentUserId = parseInt(el.dataset.currentUserId, 10);
  const currentUserName = el.dataset.currentUserName;
  const cartPath = el.dataset.cartPath;
  const ordersPath = el.dataset.ordersPath;
  const initialParticipants = el.dataset.participants ? JSON.parse(el.dataset.participants) : [];
  const csrfToken = el.dataset.csrfToken;

  const root = createRoot(el);
  root.render(
    <CheckoutForm
      cartItems={cartItems}
      total={total}
      currentUserId={currentUserId}
      currentUserName={currentUserName}
      initialParticipants={initialParticipants}
      cartPath={cartPath}
      ordersPath={ordersPath}
      csrfToken={csrfToken}
    />
  );
}
