// TabBasic.jsx — General and Location & Time tabs
function TabGeneral({ s, up }) {
  return (
    <div className="content" style={{ flex: 1 }}>
      <Section title="Startup">
        <Group>
          <Row label="Launch at login" sub="Open Prayer Time automatically when you sign in.">
            <Switch on={s.launchAtLogin} onChange={(v) => up("launchAtLogin", v)} />
          </Row>
        </Group>
      </Section>

      <Section title="Menu bar">
        <Group>
          <Row label="Label style">
            <Popup value={s.labelStyle} onChange={(v) => up("labelStyle", v)}
              options={["Icon only", "Icon + countdown", "Icon + name + countdown", "Name + time"]} />
          </Row>
          <Row label="Countdown shows">
            <Popup value={s.countdownShows} onChange={(v) => up("countdownShows", v)}
              options={["Next prayer", "Next obligatory prayer", "Time remaining only"]} />
          </Row>
        </Group>
      </Section>

      <Section title="Panel">
        <Group>
          <Row label="Show Ishraq time" sub="Display the Ishraq window in the dropdown panel.">
            <Switch on={s.showIshraq} onChange={(v) => up("showIshraq", v)} />
          </Row>
          <Row label="Show Hijri date">
            <Switch on={s.showHijri} onChange={(v) => up("showHijri", v)} />
          </Row>
        </Group>
      </Section>

      <Section title="Language" sub="Changing the language relaunches the app.">
        <Group>
          <Row label="Language">
            <Popup value={s.language} onChange={(v) => up("language", v)}
              options={["English", "Türkçe", "العربية", "Bahasa", "বাংলা", "Français"]} />
          </Row>
        </Group>
      </Section>

      <Section title="Updates">
        <Group>
          <Row label="Check for updates automatically">
            <Switch on={s.autoUpdate} onChange={(v) => up("autoUpdate", v)} />
          </Row>
        </Group>
      </Section>
    </div>
  );
}

function TabLocation({ s, up }) {
  return (
    <div className="content" style={{ flex: 1 }}>
      <Section title="Location">
        <Group>
          <Row label="Mode">
            <Segmented value={s.locMode} onChange={(v) => up("locMode", v)}
              options={[{ v: "auto", l: "Automatic" }, { v: "manual", l: "Manual" }]} />
          </Row>
          {s.locMode === "auto" && (
            <Row label="">
              <button className="btn" onClick={() => up("located", true)}>
                {Icon.location({ width: 14, height: 14 })} Detect my location
              </button>
            </Row>
          )}
          <Row label="Latitude">
            {s.locMode === "manual"
              ? <TimeField value={s.lat} onChange={(v) => up("lat", v)} />
              : <span className="val">41.0961</span>}
          </Row>
          <Row label="Longitude">
            {s.locMode === "manual"
              ? <TimeField value={s.lon} onChange={(v) => up("lon", v)} />
              : <span className="val">28.7733</span>}
          </Row>
          <Row label="Elevation" sub="Metres above sea level.">
            {s.locMode === "manual"
              ? <TimeField value={s.elev} onChange={(v) => up("elev", v)} />
              : <span className="val">0 m</span>}
          </Row>
        </Group>
      </Section>

      <Section title="Time zone">
        <Group>
          <Row label="Time zone">
            <Segmented value={s.tzMode} onChange={(v) => up("tzMode", v)}
              options={[{ v: "system", l: "Follow system" }, { v: "explicit", l: "Pick explicitly" }]} />
          </Row>
          {s.tzMode === "explicit" && (
            <Row label="Zone">
              <Popup value={s.tz} onChange={(v) => up("tz", v)}
                options={["Europe/Istanbul", "Asia/Dhaka", "Asia/Riyadh", "Europe/London", "America/New_York"]} />
            </Row>
          )}
        </Group>
      </Section>

      <Section title="Hijri date"
        sub="Based on the calculated Umm al-Qura calendar. Adjust if your country's date differs — it depends on local moon-sighting.">
        <Group>
          <Row label="Day adjustment">
            <NumStepper value={s.hijriAdj} set={(v) => up("hijriAdj", v)} min={-2} max={2}
              fmt={(v) => (v > 0 ? "+" + v : v) + " day" + (Math.abs(v) === 1 ? "" : "s")} />
          </Row>
          <Row label="Today">
            <span className="val">{window.PT.HIJRI}</span>
          </Row>
        </Group>
      </Section>
    </div>
  );
}
window.TabGeneral = TabGeneral;
window.TabLocation = TabLocation;
