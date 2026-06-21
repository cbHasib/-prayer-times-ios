// TabCalc.jsx — Calculation: Calculated vs Manual (fixed mosque jamaat times)
function TabCalculation({ s, up }) {
  const setJamaat = (key, t) => up("jamaat", { ...s.jamaat, [key]: t });
  const obligatory = window.PT.PRAYERS.filter(p => p.obligatory);

  return (
    <div className="content" style={{ flex: 1 }}>
      <Section title="Source"
        sub={s.calcMode === "calculated"
          ? "Times are computed astronomically from your location."
          : "Times are taken from the fixed schedule you enter below — ideal where the mosque announces set jamaat times (e.g. Bangladesh)."}>
        <Group>
          <Row label="Time source">
            <Segmented value={s.calcMode} onChange={(v) => up("calcMode", v)}
              options={[{ v: "calculated", l: "Calculated" }, { v: "manual", l: "Manual (fixed)" }]} />
          </Row>
        </Group>
      </Section>

      {s.calcMode === "calculated" ? (
        <>
          <Section title="Method">
            <Group>
              <Row label="Calculation method">
                <Popup value={s.method} onChange={(v) => up("method", v)} width={210}
                  options={["Diyanet İşleri (Türkiye)", "Muslim World League", "Umm al-Qura", "Egyptian General Authority", "Karachi (Hanafi)", "ISNA (North America)", "Moonsighting Committee"]} />
              </Row>
              <Row label="Asr (madhab)">
                <Popup value={s.asr} onChange={(v) => up("asr", v)}
                  options={["Standard (Shafiʿi)", "Hanafi"]} />
              </Row>
              <Row label="High-latitude rule" sub="Adjusts Fajr & Isha where the sun never fully sets.">
                <Popup value={s.highLat} onChange={(v) => up("highLat", v)} width={200}
                  options={["Automatic (recommended)", "Middle of the night", "One-seventh of night", "Angle-based"]} />
              </Row>
            </Group>
          </Section>

          <Section title="Automation"
            sub={s.autoDetect ? "Auto: Diyanet İşleri (Türkiye)" : "Method stays fixed regardless of location."}>
            <Group>
              <Row label="Auto-detect method from location">
                <Switch on={s.autoDetect} onChange={(v) => up("autoDetect", v)} />
              </Row>
            </Group>
          </Section>
        </>
      ) : (
        <>
          <Section title="Azan timing"
            sub="The azan reminder fires this many minutes before the jamaat time set below. Override individual prayers in the schedule.">
            <Group>
              <Row label="Azan before jamaat">
                <NumStepper value={s.azanBefore} set={(v) => up("azanBefore", v)} min={0} max={60}
                  fmt={(v) => v === 0 ? "At jamaat" : v + " min before"} />
              </Row>
              <Row label="Follow waqt for Sunrise & windows" sub="Keep astronomical times for non-jamaat events.">
                <Switch on={s.manualKeepWaqt} onChange={(v) => up("manualKeepWaqt", v)} />
              </Row>
            </Group>
          </Section>

          <Section title="Jamaat schedule" sub="Times as announced by your mosque. Updated weekly by many masjids.">
            <Group>
              {obligatory.map(p => (
                <Row key={p.key} label={p.name} lead={Icon[p.icon]({ width: 17, height: 17 })}>
                  <span className="chip gray" style={{ marginRight: 6 }}>{minusMin(s.jamaat[p.key], s.azanBefore)}</span>
                  <span className="val" style={{ marginRight: 2 }}>jamaat</span>
                  <TimeField value={s.jamaat[p.key]} onChange={(t) => setJamaat(p.key, t)} />
                </Row>
              ))}
            </Group>
          </Section>

          <Section title="">
            <Group>
              <Row label="Import weekly timetable" sub="Load a CSV / mosque schedule for the month.">
                <button className="btn" onClick={() => {}}>{Icon.calendar({ width: 14, height: 14 })} Import…</button>
              </Row>
            </Group>
          </Section>
        </>
      )}
    </div>
  );
}

// helper: jamaat time minus offset -> azan time label
function minusMin(t, off) {
  if (!t || !/^\d{1,2}:\d{2}$/.test(t)) return "—";
  let m = (+t.slice(0, t.indexOf(":"))) * 60 + (+t.slice(t.indexOf(":") + 1)) - off;
  m = ((m % 1440) + 1440) % 1440;
  return "azan " + String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
}
window.TabCalculation = TabCalculation;
