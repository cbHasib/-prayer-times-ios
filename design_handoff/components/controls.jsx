// controls.jsx — macOS UI primitives. Exposed on window.
const { useState, useRef, useEffect } = React;

function Switch({ on, onChange, sm }) {
  return (
    <div className={"sw" + (sm ? " sm" : "") + (on ? " on" : "")}
      role="switch" aria-checked={on} tabIndex={0}
      onClick={() => onChange(!on)}
      onKeyDown={(e) => { if (e.key === " " || e.key === "Enter") { e.preventDefault(); onChange(!on); } }}>
      <i />
    </div>
  );
}

// Pop-up button: cycles through options on click (prototype behaviour)
function Popup({ value, options, onChange, width }) {
  const idx = Math.max(0, options.indexOf(value));
  const cycle = () => onChange(options[(idx + 1) % options.length]);
  return (
    <button className="popup" style={width ? { minWidth: width } : null} onClick={cycle} title="Click to cycle options">
      <span className="pv">{value}</span>
      <span className="chev">{Icon.chevUD()}</span>
    </button>
  );
}

function Stepper({ onUp, onDown }) {
  return (
    <div className="stepper">
      <button onClick={onUp} aria-label="increase">{Icon.chevUp()}</button>
      <button onClick={onDown} aria-label="decrease">{Icon.chevDown()}</button>
    </div>
  );
}

// Stepper bound to a numeric/labelled value displayed to its left
function NumStepper({ value, set, min = 0, max = 999, step = 1, fmt }) {
  const up = () => set(Math.min(max, value + step));
  const down = () => set(Math.max(min, value - step));
  return (
    <>
      <span className="stepval">{fmt ? fmt(value) : value}</span>
      <Stepper onUp={up} onDown={down} />
    </>
  );
}

function Segmented({ value, options, onChange, neutral }) {
  return (
    <div className={"seg" + (neutral ? " neutral" : "")}>
      {options.map((o) => {
        const v = typeof o === "object" ? o.v : o;
        const l = typeof o === "object" ? o.l : o;
        return (
          <button key={v} className={value === v ? "on" : ""} onClick={() => onChange(v)}>{l}</button>
        );
      })}
    </div>
  );
}

function TimeField({ value, onChange }) {
  return (
    <input className="timefield" value={value} size={5}
      onChange={(e) => onChange(e.target.value)} />
  );
}

// Layout helpers
function Section({ title, sub, children }) {
  return (
    <>
      <div className="sect">{title}</div>
      {children}
      {sub && <div className="sect-sub">{sub}</div>}
    </>
  );
}

function Group({ children }) { return <div className="group">{children}</div>; }

function Row({ label, sub, lead, children, tall }) {
  return (
    <div className={"row" + (tall ? " tall" : "")}>
      {lead && <span className="lead-ic">{lead}</span>}
      <span className="rl">{label}{sub && <span className="sub">{sub}</span>}</span>
      <span className="rr">{children}</span>
    </div>
  );
}

function Note({ children, info }) {
  return (
    <div className={"note" + (info ? " info" : "")}>
      <span className="ni">{info ? Icon.warn({ width: 15, height: 15 }) : Icon.warn({ width: 15, height: 15 })}</span>
      <span>{children}</span>
    </div>
  );
}

Object.assign(window, { Switch, Popup, Stepper, NumStepper, Segmented, TimeField, Section, Group, Row, Note });
