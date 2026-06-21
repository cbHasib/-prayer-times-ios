// TabNotif.jsx — Notifications, reorganized. Two layouts via `layout` prop.
const SOUNDS = ["Default (Takbir)", "Takbir", "Adhan (Makkah)", "Adhan (Madinah)", "Soft chime", "Silent"];
const REMINDERS = ["Off", "5 min before", "10 min before", "15 min before", "30 min before"];

function NotifTab({ s, up, layout, onSample }) {
  const N = s.notif;
  const setN = (patch) => up("notif", { ...N, ...patch });
  const setP = (key, patch) => setN({ per: { ...N.per, [key]: { ...N.per[key], ...patch } } });
  const list = window.PT.NOTIF_PRAYERS;

  return (
    <div className="content" style={{ flex: 1 }}>
      <Section title="">
        <Group>
          <Row label="Enable notifications" sub="Master switch for all prayer alerts.">
            <Switch on={N.enabled} onChange={(v) => setN({ enabled: v })} />
          </Row>
          <Row label="">
            <button className="btn" onClick={onSample}>{Icon.bell({ width: 14, height: 14 })} Send a sample notification</button>
          </Row>
        </Group>
      </Section>

      <Section title="Defaults"
        sub="Applied to every prayer. Set a prayer’s own values below to override.">
        <Group>
          <Row label="Default sound">
            <button className="iconbtn" onClick={() => onSample(N.defSound)} title="Preview">{Icon.play()}</button>
            <Popup value={N.defSound} onChange={(v) => setN({ defSound: v })} options={SOUNDS} />
          </Row>
          <Row label="Play full Adhan audio" sub="Use the complete call instead of a short tone.">
            <Switch on={N.defFullAdhan} onChange={(v) => setN({ defFullAdhan: v })} />
          </Row>
          <Row label="Early reminder">
            <Popup value={N.defReminder} onChange={(v) => setN({ defReminder: v })} options={REMINDERS} />
          </Row>
          <Row label="Iqamah / jamaat offset" sub="Second alert this long after the adhan.">
            <NumStepper value={N.defIqamah} set={(v) => setN({ defIqamah: v })} min={0} max={45}
              fmt={(v) => v === 0 ? "Off" : v + " min"} />
          </Row>
        </Group>
      </Section>

      <Section title="Per prayer">
        {layout === "matrix"
          ? <NotifMatrix list={list} N={N} setP={setP} onSample={onSample} />
          : <NotifStacked list={list} N={N} setP={setP} onSample={onSample} />}
      </Section>
    </div>
  );
}

const COLS = "1.5fr 60px 56px 70px 34px";

function NotifMatrix({ list, N, setP, onSample }) {
  return (
    <div className="matrix">
      <div className="matrix-head" style={{ gridTemplateColumns: COLS }}>
        <span></span>
        <span style={{ textAlign: "center" }}>Notify</span>
        <span style={{ textAlign: "center" }}>Adhan</span>
        <span style={{ textAlign: "center" }}>Remind</span>
        <span></span>
      </div>
      {list.map(p => {
        const pr = N.per[p.key];
        return (
          <React.Fragment key={p.key}>
            <div className={"matrix-row" + (p.minor ? " minor" : "")} style={{ gridTemplateColumns: COLS }}>
              <span className="mp"><span className="ic">{Icon[p.icon]({ width: 17, height: 17 })}</span>{p.name}</span>
              <span className="mcell"><Switch sm on={pr.notify} onChange={(v) => setP(p.key, { notify: v })} /></span>
              <span className="mcell">{p.minor ? <span style={{ color: "var(--text-3)" }}>—</span>
                : <Switch sm on={pr.adhan} onChange={(v) => setP(p.key, { adhan: v })} />}</span>
              <span className="mcell"><Switch sm on={pr.reminder} onChange={(v) => setP(p.key, { reminder: v })} /></span>
              <span className="mcell mgear">
                {!p.minor && <button className="iconbtn" title="Per-prayer overrides"
                  onClick={() => setP(p.key, { open: !pr.open })}
                  style={{ transform: pr.open ? "rotate(180deg)" : "none", transition: "transform .15s" }}>
                  {Icon.sliders()}</button>}
              </span>
            </div>
            {pr.open && !p.minor && (
              <PrayerOverrides p={p} pr={pr} setP={setP} onSample={onSample} />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
}

function NotifStacked({ list, N, setP, onSample }) {
  return (
    <Group>
      {list.map(p => {
        const pr = N.per[p.key];
        return (
          <React.Fragment key={p.key}>
            <Row label={p.name} lead={Icon[p.icon]({ width: 17, height: 17 })}
              sub={pr.notify ? notifSummary(p, pr, N) : "Off"}>
              {!p.minor && pr.notify && (
                <button className="iconbtn" title="Customize"
                  onClick={() => setP(p.key, { open: !pr.open })}
                  style={{ transform: pr.open ? "rotate(180deg)" : "none", transition: "transform .15s" }}>
                  {Icon.sliders()}</button>)}
              <Switch on={pr.notify} onChange={(v) => setP(p.key, { notify: v })} />
            </Row>
            {pr.open && !p.minor && pr.notify && (
              <div style={{ padding: "0 0 4px" }}>
                <PrayerOverrides p={p} pr={pr} setP={setP} onSample={onSample} inline />
              </div>
            )}
          </React.Fragment>
        );
      })}
    </Group>
  );
}

function notifSummary(p, pr, N) {
  const parts = [];
  parts.push(pr.sound === "Default" ? N.defSound.replace(/^Default \(|\)$/g, "") : pr.sound);
  if (!p.minor && pr.reminder) parts.push("reminder on");
  if (!p.minor && pr.iqamah !== "Default" && pr.iqamah !== 0) parts.push("iqamah +" + pr.iqamah);
  return parts.join(" · ");
}

function PrayerOverrides({ p, pr, setP, onSample }) {
  return (
    <div className="drawer">
      <div className="row">
        <span className="rl">Sound<span className="sub">Overrides the default for {p.name}.</span></span>
        <span className="rr">
          <button className="iconbtn" onClick={() => onSample(pr.sound)} title="Preview">{Icon.play()}</button>
          <Popup value={pr.sound} onChange={(v) => setP(p.key, { sound: v })} options={["Default", ...SOUNDS.slice(1)]} />
        </span>
      </div>
      <div className="row">
        <span className="rl">Play full Adhan audio</span>
        <span className="rr"><Switch on={pr.fullAdhan} onChange={(v) => setP(p.key, { fullAdhan: v })} /></span>
      </div>
      <div className="row">
        <span className="rl">Early reminder</span>
        <span className="rr"><Popup value={pr.reminderLead} onChange={(v) => setP(p.key, { reminderLead: v })} options={REMINDERS} /></span>
      </div>
      <div className="row">
        <span className="rl">Iqamah / jamaat offset</span>
        <span className="rr"><NumStepper value={pr.iqamah === "Default" ? 0 : pr.iqamah} set={(v) => setP(p.key, { iqamah: v })}
          min={0} max={45} fmt={(v) => v === 0 ? "Off" : v + " min"} /></span>
      </div>
    </div>
  );
}
window.NotifTab = NotifTab;
