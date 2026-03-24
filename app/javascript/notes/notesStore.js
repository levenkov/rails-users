import {useState, useEffect} from 'react';
import {api} from './api';

const computeOrderBetween = (prevNote, nextNote) => {
  if (!prevNote && nextNote) return Math.max(1, Math.floor(nextNote.order / 2));
  if (prevNote && !nextNote) return prevNote.order + 1000;
  if (prevNote && nextNote) return Math.floor((prevNote.order + nextNote.order) / 2);
  return 1000;
};

const sortByOrder = (notes) =>
  [...notes].sort((a, b) => a.order - b.order || new Date(b.updated_at) - new Date(a.updated_at));

export const useNotesStore = () => {
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api.get('/notes.json').then(data => {
      setNotes(data);
      setLoading(false);
    });
  }, []);

  const moveNoteBefore = (noteId, targetId) => {
    setNotes(prev => {
      const others = prev.filter(n => n.id !== noteId);
      const insertAt = others.findIndex(n => n.id === targetId);
      if (insertAt === -1) return prev;

      const newOrder = computeOrderBetween(
        insertAt > 0 ? others[insertAt - 1] : null,
        others[insertAt]
      );

      return sortByOrder(prev.map(n =>
        n.id === noteId ? {...n, order: newOrder} : n
      ));
    });
  };

  const saveNoteOrder = (noteId) => {
    const note = notes.find(n => n.id === noteId);
    if (note) api.patch(`/notes/${note.id}`, {note: {order: note.order}});
  };

  return {notes, loading, moveNoteBefore, saveNoteOrder};
};
