import React from 'react';
import { createRoot } from 'react-dom/client';
import SplitEditor from './components/SplitEditor';

export function mountSplitEditor(el) {
  const orderId = el.dataset.orderId;
  const currentUserId = parseInt(el.dataset.currentUserId, 10);
  const root = createRoot(el);
  root.render(<SplitEditor orderId={orderId} currentUserId={currentUserId} />);
}
