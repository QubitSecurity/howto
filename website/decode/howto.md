**단순 Base64 / URL 인코딩·디코딩**으로 확장한 React + Tailwind 컴포넌트 정리본입니다.
드래그로 선택한 텍스트를 잡아오거나, 입력 박스에 직접 붙여넣어 변환할 수 있어요.

```jsx
import React, { useMemo, useState } from "react";

/* ===== UTF-8 안전 인/디코딩 유틸 ===== */
const encoder = new TextEncoder();
const decoder = new TextDecoder();

/** Base64 Encode (UTF-8 Safe) */
function b64Encode(str) {
  const bytes = encoder.encode(str);
  let bin = "";
  bytes.forEach((b) => (bin += String.fromCharCode(b)));
  return btoa(bin);
}

/** Base64 Decode (UTF-8 Safe) */
function b64Decode(b64) {
  const bin = atob(b64);
  const bytes = new Uint8Array([...bin].map((c) => c.charCodeAt(0)));
  return decoder.decode(bytes);
}

/** URL Encode/Decode */
const urlEncode = (s) => encodeURIComponent(s);
const urlDecode = (s) => decodeURIComponent(s);

/** heuristic: looks like base64 token */
const looksLikeB64 = (s) =>
  /^[A-Za-z0-9+/]+={0,2}$/.test(s.replace(/\s+/g, "")) && s.length >= 4;

export default function LogCodec() {
  const [source, setSource] = useState("");
  const [result, setResult] = useState("");
  const [codec, setCodec] = useState("base64"); // "base64" | "url"
  const [direction, setDirection] = useState("decode"); // "encode" | "decode"

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
      } else {
        out = direction === "encode" ? urlEncode(source) : urlDecode(source);
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
    return "";
  }, [codec, direction, source]);

  const copy = async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      alert("복사했습니다.");
    } catch {}
  };

  return (
    <div className="p-4 space-y-4">
      {/* 가상 로그 영역 (예시) */}
      <pre
        className="bg-gray-900 text-green-300 p-3 rounded leading-relaxed overflow-x-auto"
        onMouseUp={onMouseUp}
      >{`Post-body: <?php shell_exec(base64_decode("V29ybGQh")); ?>`}</pre>

      {/* 컨트롤 바 */}
      <div className="flex flex-wrap gap-2 items-center">
        <select
          value={codec}
          onChange={(e) => setCodec(e.target.value)}
          className="px-3 py-2 border rounded"
        >
          <option value="base64">Base64</option>
          <option value="url">URL</option>
        </select>

        <select
          value={direction}
          onChange={(e) => setDirection(e.target.value)}
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
          onChange={(e) => setSource(e.target.value)}
          className="w-full h-28 p-3 border rounded font-mono"
          placeholder={
            codec === "base64"
              ? '예) "V29ybGQh" → decode = "World!"'
              : "예) decodeURIComponent 대상 또는 평문"
          }
        />
        {hint && <p className="mt-1 text-xs text-amber-600">{hint}</p>}
        <div className="mt-2 flex gap-2">
          <button
            onClick={() => copy(source)}
            className="px-3 py-1 border rounded"
          >
            입력 복사
          </button>
          <button
            onClick={() => setSource("")}
            className="px-3 py-1 border rounded"
          >
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
          <button
            onClick={() => copy(result)}
            className="px-3 py-1 border rounded"
          >
            결과 복사
          </button>
          <button
            onClick={() => setResult("")}
            className="px-3 py-1 border rounded"
          >
            결과 지우기
          </button>
        </div>
      </div>
    </div>
  );
}
```

### 사용 포인트

* **드래그 선택 → 자동 입력**: 로그 영역에서 텍스트 드래그 후 마우스 업.
* 셀렉트 박스로 **코덱(Base64/URL)**, **방향(Encode/Decode)** 선택.
* UTF-8 안전한 Base64 인/디코딩 적용.
* URL은 `encodeURIComponent` / `decodeURIComponent` 사용.
* 간단한 **유효성 힌트**(Base64 의심)와 **복사 버튼** 포함.
