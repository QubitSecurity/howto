웹에서는 Base64 / URL 사용, Audit 로그에서는 Hex 인·디코딩 사용  
기존 컴포넌트를 **Base64 / URL / Hex 인·디코딩** 지원으로 확장한 React + Tailwind 예시를 드립니다.

```jsx
import React, { useMemo, useState } from "react";

/* ===== UTF-8 Safe helpers ===== */
const enc = new TextEncoder();
const dec = new TextDecoder();

/* --- Base64 --- */
function b64Encode(str) {
  const bytes = enc.encode(str);
  let bin = "";
  bytes.forEach(b => (bin += String.fromCharCode(b)));
  return btoa(bin);
}
function b64Decode(b64) {
  const bin = atob(b64);
  const bytes = new Uint8Array([...bin].map(c => c.charCodeAt(0)));
  return dec.decode(bytes);
}

/* --- URL --- */
const urlEncode = s => encodeURIComponent(s);
const urlDecode = s => decodeURIComponent(s);

/* --- HEX (auditd comm=) --- */
// 입력이 "comm=616263" 혹은 "61 62 63" 또는 "\x61\x62\x63" 형태라도 인식
function sanitizeHex(input) {
  // \xHH, 0xHH, 공백/쉼표 등 제거 후 2글자씩만 취합
  const pairs = input.match(/[0-9A-Fa-f]{2}/g);
  return pairs ? pairs.join("") : "";
}
function hexEncode(str) {
  const bytes = enc.encode(str);
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}
function hexDecode(hexLike) {
  const hex = sanitizeHex(hexLike);
  if (!hex || hex.length % 2 !== 0) throw new Error("invalid hex");
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return dec.decode(bytes);
}

/* --- Heuristics --- */
const looksLikeB64 = s =>
  /^[A-Za-z0-9+/]+={0,2}$/.test(s.replace(/\s+/g, "")) && s.replace(/\s+/g, "").length >= 4;

const looksLikeHex = s => {
  const hex = sanitizeHex(s);
  return hex.length >= 2 && hex.length % 2 === 0;
};

export default function LogCodec() {
  const [source, setSource] = useState("");
  const [result, setResult] = useState("");
  const [codec, setCodec] = useState("hex");      // base64 | url | hex
  const [direction, setDirection] = useState("decode"); // encode | decode

  // 로그에서 드래그한 텍스트 자동 입력
  const onMouseUp = () => {
    const picked = window.getSelection()?.toString();
    if (picked) setSource(picked.trim());
  };

  const convert = () => {
    try {
      let out = "";
      if (codec === "base64") {
        out = direction === "encode" ? b64Encode(source) : b64Decode(source);
      } else if (codec === "url") {
        out = direction === "encode" ? urlEncode(source) : urlDecode(source);
      } else {
        out = direction === "encode" ? hexEncode(source) : hexDecode(source);
      }
      setResult(out);
    } catch (e) {
      setResult("❌ 변환 실패: 입력 형식을 확인해 주세요.");
    }
  };

  const hint = useMemo(() => {
    if (!source) return "";
    if (codec === "base64" && direction === "decode" && !looksLikeB64(source))
      return "⚠️ Base64가 아닐 수 있습니다.";
    if (codec === "hex" && direction === "decode" && !looksLikeHex(source))
      return "⚠️ Hex가 아닐 수 있습니다. (예: 616263 또는 \\x61\\x62\\x63)";
    return "";
  }, [codec, direction, source]);

  const copy = async (text) => {
    if (!text) return;
    try { await navigator.clipboard.writeText(text); alert("복사했습니다."); } catch {}
  };

  return (
    <div className="p-4 space-y-4">
      {/* 예시 로그 (감싼 영역 드래그해서 선택) */}
      <pre
        className="bg-gray-900 text-green-300 p-3 rounded leading-relaxed overflow-x-auto"
        onMouseUp={onMouseUp}
      >{`msg='... comm=617676168692D6461656D6F6E3A2063 exe="/run/lock/kdmtmpflush" ...'`}</pre>

      {/* 컨트롤 */}
      <div className="flex flex-wrap gap-2 items-center">
        <select
          value={codec}
          onChange={e => setCodec(e.target.value)}
          className="px-3 py-2 border rounded"
        >
          <option value="hex">Hex (auditd comm)</option>
          <option value="base64">Base64</option>
          <option value="url">URL</option>
        </select>

        <select
          value={direction}
          onChange={e => setDirection(e.target.value)}
          className="px-3 py-2 border rounded"
        >
          <option value="decode">Decode</option>
          <option value="encode">Encode</option>
        </select>

        <button
          onClick={convert}
          className="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
        >
          변환
        </button>
      </div>

      {/* 입력 */}
      <div>
        <label className="block text-sm font-semibold mb-1">
          입력(드래그 선택 또는 붙여넣기)
        </label>
        <textarea
          value={source}
          onChange={e => setSource(e.target.value)}
          className="w-full h-28 p-3 border rounded font-mono"
          placeholder={
            codec === "hex"
              ? '예) 636174 (=> "cat"), \\x63\\x61\\x74, 0x63 0x61 0x74 모두 허용'
              : codec === "base64"
              ? '예) "Y2F0" => "cat"'
              : "예) a/b?x=y => a%2Fb%3Fx%3Dy"
          }
        />
        {hint && <p className="mt-1 text-xs text-amber-600">{hint}</p>}
        <div className="mt-2 flex gap-2">
          <button onClick={() => copy(source)} className="px-3 py-1 border rounded">
            입력 복사
          </button>
          <button onClick={() => setSource("")} className="px-3 py-1 border rounded">
            입력 지우기
          </button>
        </div>
      </div>

      {/* 결과 */}
      <div>
        <label className="block text-sm font-semibold mb-1">결과</label>
        <textarea
          readOnly
          value={result}
          className="w-full h-28 p-3 border rounded font-mono bg-gray-50"
        />
        <div className="mt-2 flex gap-2">
          <button onClick={() => copy(result)} className="px-3 py-1 border rounded">
            결과 복사
          </button>
          <button onClick={() => setResult("")} className="px-3 py-1 border rounded">
            결과 지우기
          </button>
        </div>
      </div>
    </div>
  );
}
```

### 포인트

* **Hex 디코딩**: `sanitizeHex()` 로 `comm=...`, `\xHH`, `0xHH`, 공백/쉼표 등 불필요한 표기 제거 후 2자리씩 바이트로 복원합니다.
* **UTF-8 안전 처리**: `TextEncoder/TextDecoder` 사용.
* **드래그 → 자동 입력**: 로그에서 `comm=...` 부분을 드래그하면 바로 입력창으로 들어옵니다.
* 동일 UI에서 **Base64/URL/Hex** 전부 **Encode/Decode** 가능.

원하시면 선택한 영역 위에 **작은 팝오버(“Hex Decode”, “Base64 Decode” 등)** 를 띄워 바로 변환하는 UX도 추가해 드릴게요.
