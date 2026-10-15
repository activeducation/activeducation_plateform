"use client";

import { useCallback } from 'react';

const SOUNDS = {
  pop: 'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3', // click/pop
  success: 'https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3', // success chime
  error: 'https://assets.mixkit.co/active_storage/sfx/2955/2955-preview.mp3', // error buzz
  celebration: 'https://assets.mixkit.co/active_storage/sfx/2019/2019-preview.mp3' // big win
};

export function useSound() {
  const playSound = useCallback((type: keyof typeof SOUNDS) => {
    try {
      const audio = new Audio(SOUNDS[type]);
      audio.volume = 0.5; // Pas trop fort
      audio.play().catch(e => console.log("Audio play prevented by browser:", e));
    } catch (e) {
      console.error("Audio error:", e);
    }
  }, []);

  return playSound;
}
