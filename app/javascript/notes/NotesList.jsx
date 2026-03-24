import React, {useState, useCallback} from 'react';
import NoteCard from './NoteCard';
import MasonryLayout from './MasonryLayout';
import {useNotesStore} from './notesStore';
import {styles} from './NotesList.styles';
import {useNoteDragController} from './useNoteDragController';

const NotesList = ({width, onNoteClicked}) => {
  const {notes, loading} = useNotesStore();
  const {onDragStart} = useNoteDragController(notes);
  const [heightsMap, setHeightsMap] = useState({});

  const handleHeightMeasured = useCallback((noteId, height) => {
    setHeightsMap(prev => {
      if (prev[noteId] === height) return prev;
      return {...prev, [noteId]: height};
    });
  }, []);

  if (loading) {
    return <div style={styles.loading}>Loading notes...</div>;
  }

  if (notes.length === 0) {
    return <div style={styles.empty}>No notes yet. Create your first note!</div>;
  }

  return (
    <MasonryLayout data={notes} heightsMap={heightsMap} width={width} renderItem={({item}) => (
      <NoteCard
        id={item.id}
        title={item.title}
        body={item.body}
        unchecked_points={item.unchecked_points}
        tags={item.tags}
        onClick={() => onNoteClicked(item.id)}
        onDragStart={(e) => onDragStart(e, item.id)}
        onHeightMeasured={handleHeightMeasured}
      />
    )} />
  );
};

export default NotesList;
