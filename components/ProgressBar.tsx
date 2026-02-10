"use client";

type Props = {
  label: string;
  percent: number; // 0..100
};

export default function ProgressBar({ label, percent }: Props) {
  const p = Math.max(0, Math.min(100, percent));

  return (
    <div style={{ width: "100%", maxWidth: 520, marginTop: 12 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
        <span style={{ fontSize: 13, opacity: 0.9 }}>{label}</span>
        <span style={{ fontSize: 13, opacity: 0.9 }}>{p.toFixed(0)}%</span>
      </div>
      <div style={{ width: "100%", height: 10, borderRadius: 999, background: "rgba(255,255,255,0.12)" }}>
        <div
          style={{
            width: `${p}%`,
            height: "100%",
            borderRadius: 999,
            background: "rgba(255,255,255,0.8)",
            transition: "width 120ms linear"
          }}
        />
      </div>
    </div>
  );
}