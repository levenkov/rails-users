import "@hotwired/turbo-rails"
import { marked } from "marked"
import "./tailwind.css"

window.marked = marked;

let currentAudio = null;
let currentPlayPromise = null;

window.playAudio = async function(audioUrl) {
  // Wait for any current play operation to complete
  if (currentPlayPromise) {
    try {
      await currentPlayPromise;
    } catch (e) {
      // Ignore errors from interrupted play
    }
  }

  if (currentAudio) {
    // If clicking the same audio, just pause it
    if (currentAudio.src === audioUrl) {
      currentAudio.pause();
      currentAudio = null;
      currentPlayPromise = null;
      return;
    }
    // Pause the current audio
    currentAudio.pause();
    currentAudio = null;
  }

  // Create and play new audio
  currentAudio = new Audio(audioUrl);
  currentPlayPromise = currentAudio.play().catch(error => {
    console.error('Error playing audio:', error);
  });
};

// Handle audio link clicks
document.addEventListener('click', function(e) {
  const audioLink = e.target.closest('a.audio-link');
  if (audioLink) {
    e.preventDefault();
    const audioUrl = audioLink.getAttribute('data-audio-url');
    if (audioUrl) {
      window.playAudio(audioUrl);
    }
  }
});

document.addEventListener('DOMContentLoaded', function() {
  const markdownElements = document.querySelectorAll('.markdown-content');
  markdownElements.forEach(function(element) {
    if (typeof marked !== 'undefined') {
      element.innerHTML = marked.parse(element.textContent || element.innerText);
    }
  });
});

