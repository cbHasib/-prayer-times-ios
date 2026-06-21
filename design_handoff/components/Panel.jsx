// Panel.jsx — menu-bar dropdown popover
function Panel({ onOpenSettings, showIshraq, accentDemoFocus }) {
  const { PRAYERS, NOW_MIN, toMin, fmtCountdown, HIJRI, CITY } = window.PT;
  const list = PRAYERS.filter(p => showIshraq || p.key !== "ishraq");

  // next obligatory-or-major prayer after now
  const ordered = list.map(p => ({ ...p, m: toMin(p.time) }));
  const next = ordered.find(p => p.m > NOW_MIN) || ordered[0];
  const prev = [...ordered].reverse().find(p => p.m <= NOW_MIN) || ordered[ordered.length - 1];
  const toNext = next.m - NOW_MIN;
  const span = next.m - prev.m;
  const prog = Math.max(0, Math.min(1, (NOW_MIN - prev.m) / span)) * 100;

  return (
    <div className="panel" style={{ right: 12 }} onClick={(e) => e.stopPropagation()}>
      <div className="panel-head">
        <div className="panel-loc">{Icon.pin({ width: 13, height: 13 })}{CITY}</div>
        <div className="panel-hijri">{HIJRI}</div>
        <div className="panel-next">
          <div>
            <div className="lbl">Next · {next.name}</div>
            <div className="nm">{next.time}</div>
          </div>
          <div className="cd">in {fmtCountdown(toNext)}</div>
        </div>
        <div className="panel-prog"><i style={{ width: prog + "%" }} /></div>
      </div>
      <div className="panel-list">
        {list.map(p => {
          const m = toMin(p.time);
          const passed = m <= NOW_MIN && p.key !== next.key;
          const isNext = p.key === next.key;
          return (
            <div key={p.key} className={"prow" + (p.minor ? " minor" : "") + (passed ? " passed" : "") + (isNext ? " next" : "")}>
              <span className="ic">{Icon[p.icon]({ width: 16, height: 16 })}</span>
              <span className="pn">{p.name}</span>
              <span className="pt">{p.time}</span>
            </div>
          );
        })}
      </div>
      <div className="panel-foot">
        <button className="pbtn" onClick={accentDemoFocus}>{Icon.eyeoff({ width: 15, height: 15 })}Focus now</button>
        <span className="spacer" />
        <button className="pbtn accent" onClick={onOpenSettings}>{Icon.gear({ width: 15, height: 15 })}Settings…</button>
      </div>
    </div>
  );
}
window.Panel = Panel;
