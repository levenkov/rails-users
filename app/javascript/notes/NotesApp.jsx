import React, { useState, useCallback } from 'react';
import NotesList from './NotesList';
import NoteModal from './NoteModal';
import { api } from './api';

const CONTENT_WIDTH = 1120;

const styles = {
  header: {
    display: 'flex',
    justifyContent: 'flex-end',
    marginBottom: 16,
  },
  newBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    fontSize: 14,
    fontWeight: 500,
    padding: '10px 20px',
    background: '#fbbc04',
    color: '#202124',
    border: 'none',
    borderRadius: 24,
    cursor: 'pointer',
    boxShadow: '0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)',
  },
};

const NotesApp = () => {
  const [selectedNoteId, setSelectedNoteId] = useState(null);
  const [isNewNote, setIsNewNote] = useState(false);
  const [listKey, setListKey] = useState(0);

  const handleNoteClicked = (noteId) => {
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
    <>
      <div style={styles.header}>
        <button style={styles.newBtn} onClick={handleNewNote}>+ New Note</button>
      </div>
      <NotesList
        key={listKey}
        width={CONTENT_WIDTH}
        onNoteClicked={handleNoteClicked}
      />
      {selectedNoteId && (
        <NoteModal
          noteId={selectedNoteId}
          onClose={handleCloseModal}
          isNew={isNewNote}
        />
      )}
    </>
  );
};

export default NotesApp;
