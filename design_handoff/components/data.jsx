// data.jsx — shared prayer data
const PRAYERS = [
  { key: "fajr",    name: "Fajr",    time: "03:33", icon: "dawn",    obligatory: true },
  { key: "sunrise", name: "Sunrise", time: "05:27", icon: "sunrise", obligatory: false, minor: true },
  { key: "ishraq",  name: "Ishraq",  time: "05:47", icon: "sun",     obligatory: false, minor: true },
  { key: "dhuhr",   name: "Dhuhr",   time: "13:14", icon: "sun",     obligatory: true },
  { key: "asr",     name: "Asr",     time: "17:13", icon: "sun",     obligatory: true },
  { key: "maghrib", name: "Maghrib", time: "20:42", icon: "sunset",  obligatory: true },
  { key: "isha",    name: "Isha",    time: "22:27", icon: "moon",    obligatory: true },
];
const NOTIF_PRAYERS = PRAYERS.filter(p => p.key !== "ishraq");
const NOW_MIN = 14 * 60 + 39;      // 14:39 — "now" for the scene
const toMin = (t) => (+t.slice(0, 2)) * 60 + (+t.slice(3));
const fmtCountdown = (m) => `${Math.floor(m / 60)}:${String(m % 60).padStart(2, "0")}`;
const HIJRI = "23 Dhu'l-Hijjah 1447 AH";
const CITY = "Istanbul, Türkiye";
window.PT = { PRAYERS, NOTIF_PRAYERS, NOW_MIN, toMin, fmtCountdown, HIJRI, CITY };
