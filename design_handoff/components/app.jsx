// app.jsx — composes the desktop scene, menu-bar panel, settings window, tweaks
const { useState: uState, useEffect: uEffect, useRef: uRef } = React;

const TABS = [
  { key: "general",  label: "General",         icon: "gear" },
  { key: "location", label: "Location & Time",  icon: "location" },
  { key: "calc",     label: "Calculation",      icon: "moon" },
  { key: "notif",    label: "Notifications",    icon: "bell" },
  { key: "focus",    label: "Focus Mode",       icon: "eyeoff" },
];

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "notifLayout": "matrix",
  "accent": "#0A84FF",
  "density": "regular",
  "wallpaper": "blue"
}/*EDITMODE-END*/;

const ACCENTS = { "#0A84FF": ["#0A84FF", "#0060df", "#E9F2FF"], "#1f8a5b": ["#1f8a5b", "#136b45", "#e6f4ec"], "#0a9bb5": ["#0a9bb5", "#077a8f", "#e3f4f7"] };
const WALLS = {
  blue: "radial-gradient(120% 90% at 18% 8%, #6f8fb8 0%, #5b79a6 28%, #46618c 55%, #33486e 80%, #25375a 100%)",
  dusk: "radial-gradient(120% 100% at 80% 0%, #e8a06b 0%, #c97a6d 26%, #8a5d80 52%, #4f4a7a 76%, #2c3360 100%)",
  slate: "linear-gradient(160deg, #3a4a5a 0%, #2b3845 50%, #1e2832 100%)",
};

function defaultSettings() {
  const per = {};
  window.PT.NOTIF_PRAYERS.forEach((p, i) => {
    per[p.key] = {
      notify: p.key === "fajr" || (!p.minor && i < 6),
      adhan: p.key === "fajr",
      reminder: false,
      open: false,
      sound: "Default",
      fullAdhan: false,
      reminderLead: "Off",
      iqamah: "Default",
    };
  });
  per.sunrise.notify = false;
  return {
    // general
    launchAtLogin: true, labelStyle: "Icon + name + countdown", countdownShows: "Next prayer",
    showIshraq: true, showHijri: true, language: "English", autoUpdate: true,
    // location
    locMode: "auto", located: true, lat: "41.0961", lon: "28.7733", elev: "0",
    tzMode: "system", tz: "Europe/Istanbul", hijriAdj: 0,
    // calc
    calcMode: "calculated", method: "Diyanet İşleri (Türkiye)", asr: "Standard (Shafiʿi)",
    highLat: "Automatic (recommended)", autoDetect: true,
    azanBefore: 15, manualKeepWaqt: true,
    jamaat: { fajr: "05:00", dhuhr: "13:30", asr: "17:30", maghrib: "20:45", isha: "22:45" },
    // notif
    notif: { enabled: true, defSound: "Takbir", defFullAdhan: false, defReminder: "Off", defIqamah: 0, per },
    // focus
    focusEnabled: true, focusDuration: 16, focusBlur: "Low", focusTrigger: "Obligatory prayers", focusEmergency: false,
  };
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [s, setS] = uState(defaultSettings);
  const up = (k, v) => setS(o => ({ ...o, [k]: v }));
  const [tab, setTab] = uState("notif");
  const [panel, setPanel] = uState(false);
  const [focusDemo, setFocusDemo] = uState(false);
  const [toast, setToast] = uState(null);

  // apply accent + density to :root
  uEffect(() => {
    const [a, ap, at] = ACCENTS[t.accent] || ACCENTS["#0A84FF"];
    const r = document.documentElement.style;
    r.setProperty("--accent", a); r.setProperty("--accent-press", ap); r.setProperty("--accent-tint", at);
    r.setProperty("--row-h", t.density === "compact" ? "32px" : "38px");
  }, [t.accent, t.density]);

  const fireToast = (sound) => {
    setToast({ id: Date.now(), sound: typeof sound === "string" ? sound : null });
    setTimeout(() => setToast(null), 3200);
  };
  const tryFocus = () => { setFocusDemo(true); };

  // menu-bar app label
  const { PRAYERS, NOW_MIN, toMin, fmtCountdown } = window.PT;
  const next = PRAYERS.map(p => ({ ...p, m: toMin(p.time) })).find(p => p.m > NOW_MIN && p.obligatory) || PRAYERS[0];
  const cd = fmtCountdown(next.m - NOW_MIN);
  const label = s.labelStyle === "Icon only" ? "" :
    s.labelStyle === "Icon + countdown" ? cd :
    s.labelStyle === "Name + time" ? `${next.name} ${next.time}` : `${next.name} ${cd}`;

  return (
    <div className="desktop" style={{ background: WALLS[t.wallpaper] }} onClick={() => setPanel(false)}>
      {/* menu bar */}
      <div className="menubar" onClick={(e) => e.stopPropagation()}>
        <span className="mb-logo">🕌</span>
        <span className="mb-menu" style={{ fontWeight: 600 }}>Prayer Time</span>
        <span className="mb-menu">File</span><span className="mb-menu">View</span><span className="mb-menu">Help</span>
        <div className="mb-right">
          <span className="mb-status">{Icon.globe({ width: 15, height: 15 })}</span>
          <div className={"mb-item app" + (panel ? " active" : "")} onClick={() => setPanel(p => !p)}>
            {Icon.mosque({ width: 15, height: 15 })}{label && <span>{label}</span>}
          </div>
          <span className="mb-status">100%</span>
          <span className="mb-clock">Tue 9 Jun&nbsp;&nbsp;14:39</span>
        </div>
      </div>

      {panel && <div onClick={(e) => e.stopPropagation()}>
        <Panel showIshraq={s.showIshraq} onOpenSettings={() => { setPanel(false); setTab("general"); }}
          accentDemoFocus={() => { setPanel(false); tryFocus(); }} />
      </div>}

      {/* settings window */}
      <div className="win" onClick={(e) => e.stopPropagation()}>
        <div className="titlebar">
          <div className="traffic"><i className="r" /><i className="y" /><i className="g" /></div>
          <span className="title">{TABS.find(x => x.key === tab).label}</span>
        </div>
        <div className="toolbar">
          {TABS.map(x => (
            <button key={x.key} className={"tab" + (tab === x.key ? " active" : "")} onClick={() => setTab(x.key)}>
              {Icon[x.icon]({ width: 22, height: 22 })}
              <span className="tl">{x.label}</span>
            </button>
          ))}
        </div>
        {tab === "general"  && <TabGeneral s={s} up={up} />}
        {tab === "location" && <TabLocation s={s} up={up} />}
        {tab === "calc"     && <TabCalculation s={s} up={up} />}
        {tab === "notif"    && <NotifTab s={s} up={up} layout={t.notifLayout} onSample={fireToast} />}
        {tab === "focus"    && <TabFocus s={s} up={up} onTry={tryFocus} />}
      </div>

      {/* notification banner */}
      {toast && <Toast next={next} sound={toast.sound} />}

      {/* focus demo */}
      {focusDemo && <FocusDemo blur={s.focusBlur} emergency={s.focusEmergency} onDone={() => setFocusDemo(false)} />}

      <div className="hint" onClick={(e) => e.stopPropagation()}>
        <span>Click the <b>🕌 menu-bar item</b> for the panel</span><span className="dot">•</span>
        <span>Switch tabs &amp; flip toggles</span><span className="dot">•</span>
        <span>Open <b>Tweaks</b> to compare layouts</span>
      </div>

      <TweaksPanel>
        <TweakSection label="Notifications" />
        <TweakRadio label="Per-prayer layout" value={t.notifLayout}
          options={[{ value: "matrix", label: "Matrix" }, { value: "stacked", label: "Stacked" }]}
          onChange={(v) => setTweak("notifLayout", v)} />
        <TweakSection label="Appearance" />
        <TweakColor label="Accent" value={t.accent}
          options={["#0A84FF", "#1f8a5b", "#0a9bb5"]} onChange={(v) => setTweak("accent", v)} />
        <TweakRadio label="Density" value={t.density}
          options={["compact", "regular"]} onChange={(v) => setTweak("density", v)} />
        <TweakSection label="Scene" />
        <TweakRadio label="Wallpaper" value={t.wallpaper}
          options={[{ value: "blue", label: "Day" }, { value: "dusk", label: "Dusk" }, { value: "slate", label: "Slate" }]}
          onChange={(v) => setTweak("wallpaper", v)} />
      </TweaksPanel>
    </div>
  );
}

function Toast({ next, sound }) {
  return (
    <div style={{
      position: "fixed", top: 34, right: 14, width: 344, zIndex: 90,
      background: "rgba(250,250,252,0.82)", backdropFilter: "saturate(180%) blur(30px)",
      WebkitBackdropFilter: "saturate(180%) blur(30px)", border: "0.5px solid rgba(0,0,0,0.12)",
      borderRadius: 16, boxShadow: "0 14px 44px rgba(0,0,0,0.30)", padding: "12px 14px",
      display: "flex", gap: 12, alignItems: "flex-start", animation: "pop .2s ease",
    }}>
      <div style={{ width: 38, height: 38, borderRadius: 9, background: "var(--accent)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", flex: "0 0 auto" }}>
        {Icon.mosque({ width: 22, height: 22 })}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600 }}>Prayer Time</div>
        <div style={{ fontSize: 13, marginTop: 1 }}>It’s time for <b>{next.name}</b> · {next.time}</div>
        <div style={{ fontSize: 12, color: "var(--text-3)", marginTop: 2 }}>
          {sound ? `Playing: ${sound}` : "Allāhu akbar — hayya ʿala-ṣ-ṣalāh"}
        </div>
      </div>
      <span style={{ fontSize: 11, color: "var(--text-3)" }}>now</span>
    </div>
  );
}

function FocusDemo({ blur, emergency, onDone }) {
  const [n, setN] = uState(10);
  uEffect(() => {
    if (n <= 0) { onDone(); return; }
    const id = setTimeout(() => setN(x => x - 1), 1000);
    return () => clearTimeout(id);
  }, [n]);
  uEffect(() => {
    const h = (e) => { if (e.key === "Escape") onDone(); };
    window.addEventListener("keydown", h); return () => window.removeEventListener("keydown", h);
  }, []);
  const blurPx = { Low: 14, Medium: 26, High: 44, Opaque: 60 }[blur] || 18;
  const next = window.PT.PRAYERS.find(p => p.key === "asr");
  return (
    <div className="focus-demo" style={{ backdropFilter: `blur(${blurPx}px)`, WebkitBackdropFilter: `blur(${blurPx}px)`, background: blur === "Opaque" ? "rgba(20,28,46,0.94)" : "rgba(20,28,46,0.5)" }}
      onClick={onDone}>
      <div className="fc">
        <div className="ft">Prayer in progress</div>
        <div className="fn">{next.name}</div>
        <div className="fr">{window.PT.CITY} · {next.time}</div>
        <div className="fcd">Resumes in 0:{String(n).padStart(2, "0")}</div>
        <div className="fx">Preview — click anywhere to dismiss{emergency ? " · ⌘⎋ enabled" : ""}</div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
