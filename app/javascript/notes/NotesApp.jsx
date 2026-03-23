import React, { useState, useCallback } from 'react';
import NotesList from './NotesList';
import NoteModal from './NoteModal';
import { api } from './api';

const styles = {
  container: {
    maxWidth: 960,
    margin: '0 auto',
    padding: '0 16px',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  },
};

const NotesApp = () => {
  const [selectedNoteId, setSelectedNoteId] = useState(null);
  const [isNewNote, setIsNewNote] = useState(false);
  const [listKey, setListKey] = useState(0);

  const handleSelectNote = (noteId) => {
    setSelectedNoteId(noteId);
    setIsNewNote(false);
  };

  const handleCloseModal = () => {
    setSelectedNoteId(null);
    setIsNewNote(false);
    setListKey(k => k + 1);
  };

  const handleNewNote = async () => {
    const result = await api.post('/notes', {
      note: { title: '', body: '' }
    });
    setSelectedNoteId(result.id);
    setIsNewNote(true);
  };

  return (
    <div style={styles.container}>
      <NotesList
        key={listKey}
        onSelectNote={handleSelectNote}
        onNewNote={handleNewNote}
      />
      {selectedNoteId && (
        <NoteModal
          noteId={selectedNoteId}
          onClose={handleCloseModal}
          isNew={isNewNote}
        />
      )}
    </div>
  );
};

export default NotesApp;
