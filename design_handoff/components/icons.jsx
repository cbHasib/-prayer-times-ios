// icons.jsx — SF-Symbols-style line icons. Exposed on window.Icon.*
const Icon = (() => {
  const s = (paths, props = {}) => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={props.w || 1.7}
      strokeLinecap="round" strokeLinejoin="round" {...props}>{paths}</svg>
  );
  return {
    gear: (p) => s(<>
      <circle cx="12" cy="12" r="3.2" />
      <path d="M12 2.6v2.2M12 19.2v2.2M21.4 12h-2.2M4.8 12H2.6M18.4 5.6l-1.6 1.6M7.2 16.8l-1.6 1.6M18.4 18.4l-1.6-1.6M7.2 7.2 5.6 5.6" />
    </>, p),
    location: (p) => s(<path d="M20.5 3.5 3.8 10.2c-.7.3-.7 1.3.1 1.5l6.7 1.9 1.9 6.7c.2.8 1.2.8 1.5.1z" />, p),
    moon: (p) => s(<path d="M20 13.4A8 8 0 1 1 10.6 4 6.4 6.4 0 0 0 20 13.4z" />, p),
    bell: (p) => s(<><path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6" /><path d="M13.7 19a2 2 0 0 1-3.4 0" /></>, p),
    eyeoff: (p) => s(<><path d="M2.5 12S6 5.5 12 5.5c1.7 0 3.2.5 4.5 1.2M21.5 12s-1.2 2.3-3.5 4M9.9 9.9a3 3 0 0 0 4.2 4.2" /><path d="M3 3l18 18" /></>, p),
    sun: (p) => s(<><circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M22 12h-2M4 12H2M19 5l-1.5 1.5M6.5 17.5 5 19M19 19l-1.5-1.5M6.5 6.5 5 5" /></>, p),
    sunrise: (p) => s(<><path d="M3 18h18M7.5 14a4.5 4.5 0 0 1 9 0" /><path d="M12 3v5M12 3 9.5 5.5M12 3l2.5 2.5M2 18.5h2M20 18.5h2" /></>, p),
    sunset: (p) => s(<><path d="M3 18h18M7.5 14a4.5 4.5 0 0 1 9 0" /><path d="M12 8V3M12 8 9.5 5.5M12 8l2.5-2.5M2 18.5h2M20 18.5h2" /></>, p),
    dawn: (p) => s(<><path d="M4 16.5h16M6.5 13a5.5 5.5 0 0 1 11 0" /><path d="M12 4.5v1.6M5.6 6.6l1.1 1.1M18.4 6.6l-1.1 1.1" /></>, p),
    chevUD: (p) => s(<path d="M8 10l4-4 4 4M8 14l4 4 4-4" />, { ...p, w: 1.8 }),
    chevUp: (p) => s(<path d="M6 14l6-6 6 6" />, { ...p, w: 2 }),
    chevDown: (p) => s(<path d="M6 10l6 6 6-6" />, { ...p, w: 2 }),
    play: (p) => s(<path d="M7 5.5v13l11-6.5z" fill="currentColor" stroke="none" />, p),
    sliders: (p) => s(<><path d="M5 8h6M15 8h4M5 16h2M11 16h8" /><circle cx="13" cy="8" r="2" fill="#fff" /><circle cx="9" cy="16" r="2" fill="#fff" /></>, p),
    speaker: (p) => s(<><path d="M4 9v6h4l5 4V5L8 9z" /><path d="M16.5 9.5a3.5 3.5 0 0 1 0 5M19 7a7 7 0 0 1 0 10" /></>, p),
    clock: (p) => s(<><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></>, p),
    pin: (p) => s(<><path d="M12 21s7-6.3 7-11a7 7 0 1 0-14 0c0 4.7 7 11 7 11z" /><circle cx="12" cy="10" r="2.4" /></>, p),
    globe: (p) => s(<><circle cx="12" cy="12" r="8.5" /><path d="M3.5 12h17M12 3.5c2.5 2.4 2.5 14.6 0 17M12 3.5c-2.5 2.4-2.5 14.6 0 17" /></>, p),
    calendar: (p) => s(<><rect x="4" y="5" width="16" height="15" rx="2.2" /><path d="M4 9.5h16M8 3.5v3M16 3.5v3" /></>, p),
    refresh: (p) => s(<><path d="M20 11a8 8 0 0 0-14-4.5L4 8M4 13a8 8 0 0 0 14 4.5L20 16" /><path d="M4 4v4h4M20 20v-4h-4" /></>, p),
    eye: (p) => s(<><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" /><circle cx="12" cy="12" r="2.8" /></>, p),
    warn: (p) => s(<><path d="M12 3.5 22 19.5H2z" /><path d="M12 10v4.5M12 17.2v.2" /></>, p),
    mosque: (p) => s(<><path d="M12 3c1.6 1.4 2.6 2.6 2.6 4 0 1.4-1.2 2-2.6 2s-2.6-.6-2.6-2c0-1.4 1-2.6 2.6-4z" /><path d="M4 20v-7c0-2 1.6-3 3-3M20 20v-7c0-2-1.6-3-3-3M4 20h16M9 20v-3a3 3 0 0 1 6 0v3" /></>, p),
    plus: (p) => s(<path d="M12 5v14M5 12h14" w="2" />, p),
    check: (p) => s(<path d="M5 12.5l4.5 4.5L19 7" w="2.2" />, p),
  };
})();
window.Icon = Icon;
