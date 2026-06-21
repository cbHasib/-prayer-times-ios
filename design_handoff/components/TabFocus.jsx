// TabFocus.jsx
function TabFocus({ s, up, onTry }) {
  return (
    <div className="content" style={{ flex: 1 }}>
      <Section title="">
        <Group>
          <Row label="Enable Focus Mode" sub="Covers the entire screen during prayer time.">
            <Switch on={s.focusEnabled} onChange={(v) => up("focusEnabled", v)} />
          </Row>
        </Group>
      </Section>

      <Section title="Behaviour">
        <Group>
          <Row label="Prayer duration" sub="How long the screen stays covered at each prayer.">
            <NumStepper value={s.focusDuration} set={(v) => up("focusDuration", v)} min={2} max={45}
              fmt={(v) => v + " minutes"} />
          </Row>
          <Row label="Blur intensity">
            <Popup value={s.focusBlur} onChange={(v) => up("focusBlur", v)} options={["Low", "Medium", "High", "Opaque"]} />
          </Row>
          <Row label="Trigger on">
            <Popup value={s.focusTrigger} onChange={(v) => up("focusTrigger", v)} width={180}
              options={["Obligatory prayers", "All prayer times", "Fajr & Isha only"]} />
          </Row>
          <Row label="Emergency exit" sub="Allow ⌘⎋ to exit early.">
            <Switch on={s.focusEmergency} onChange={(v) => up("focusEmergency", v)} />
          </Row>
        </Group>
      </Section>

      <Section title="">
        <Group>
          <Row label="">
            <button className="btn full" onClick={onTry}>{Icon.eye({ width: 15, height: 15 })} Try it for 10 seconds</button>
          </Row>
        </Group>
        <Note>
          Focus Mode covers your whole screen at each obligatory prayer. It’s a discipline aid, not a lock —
          Force Quit always works, and it won’t engage while a fullscreen app (a call or presentation) is frontmost.
        </Note>
      </Section>
    </div>
  );
}
window.TabFocus = TabFocus;
