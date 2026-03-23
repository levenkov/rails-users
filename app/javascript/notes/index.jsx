import React from 'react';
import {createRoot} from 'react-dom/client';
import NotesApp from './NotesApp';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('notes-react-root');
  if (container) {
    const root = createRoot(container);
    root.render(<NotesApp />);
  }
});
