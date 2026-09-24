// Renderer HTML → PDF (A4) dengan placeholder QR inline.
// Diadaptasi dari `src/lib/bukti-permohonan.functions.ts` supaya bisa dipakai
// bersama untuk 3 jenis bukti: permohonan, aset, izin_asn.
export const QR_MARKER = "[[QR_CODE_PLACEHOLDER]]";

type InlineRun = { text: string; bold: boolean; italic: boolean };
type StyledBlock = {
  runs: InlineRun[];
  align: "left" | "right" | "center" | "justify";
  marginLeft: number;
  marginRight: number;
  textIndent: number;
  fontSize: number;
  bold: boolean;
  spaceAfter: number;
  isListItem: boolean;
  listMarker?: string;
  kind?: "qr";
};

function decodeEntities(s: string): string {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(parseInt(d, 10)));
}
function pxFromStyle(style: string, prop: string): number | null {
  const m = new RegExp(`${prop}\\s*:\\s*(-?\\d+(?:\\.\\d+)?)px`, "i").exec(style);
  return m ? parseFloat(m[1]) : null;
}
function alignFromStyle(style: string): StyledBlock["align"] | null {
  const m = /text-align\s*:\s*(left|right|center|justify)/i.exec(style);
  return m ? (m[1].toLowerCase() as StyledBlock["align"]) : null;
}

function extractRuns(html: string): InlineRun[] {
  const src = html.replace(/<br\s*\/?>/gi, "\u0001");
  const runs: InlineRun[] = [];
  let bold = 0;
  let italic = 0;
  let i = 0;
  let buf = "";
  const flush = () => {
    if (!buf) return;
    const text = decodeEntities(buf).replace(/\s+/g, " ");
    if (text) runs.push({ text, bold: bold > 0, italic: italic > 0 });
    buf = "";
  };
  while (i < src.length) {
    const c = src[i];
    if (c === "<") {
      const end = src.indexOf(">", i);
      if (end === -1) break;
      const lower = src.slice(i + 1, end).trim().toLowerCase();
      flush();
      if (lower === "b" || lower === "strong" || lower.startsWith("b ") || lower.startsWith("strong ")) bold++;
      else if (lower === "/b" || lower === "/strong") bold = Math.max(0, bold - 1);
      else if (lower === "i" || lower === "em" || lower.startsWith("i ") || lower.startsWith("em ")) italic++;
      else if (lower === "/i" || lower === "/em") italic = Math.max(0, italic - 1);
      i = end + 1;
    } else if (c === "\u0001") {
      flush();
      runs.push({ text: "\n", bold: false, italic: false });
      i++;
    } else {
      buf += c;
      i++;
    }
  }
  flush();
  return runs;
}

function parseHtmlToBlocks(html: string): StyledBlock[] {
  const cleaned = html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/\r\n?/g, "\n");
  const blocks: StyledBlock[] = [];
  const blockRe = /<(p|div|h[1-6]|li)\b([^>]*)>([\s\S]*?)<\/\1>/gi;
  let m: RegExpExecArray | null;
  let olCounter = 0;
  let inOl = false;
  const olSegments: Array<[number, number]> = [];
  const olRe = /<ol\b[^>]*>([\s\S]*?)<\/ol>/gi;
  let om: RegExpExecArray | null;
  while ((om = olRe.exec(cleaned)) !== null) {
    olSegments.push([om.index, om.index + om[0].length]);
  }
  while ((m = blockRe.exec(cleaned)) !== null) {
    const tag = m[1].toLowerCase();
    const attrs = m[2] || "";
    const inner = m[3] || "";
    const styleMatch = /style\s*=\s*"([^"]*)"/i.exec(attrs);
    const style = styleMatch ? styleMatch[1] : "";
    const isHeading = /^h[1-6]$/.test(tag);
    const headingLevel = isHeading ? parseInt(tag.slice(1), 10) : 0;
    const idx = m.index;
    const insideOl = olSegments.some(([a, b]) => idx > a && idx < b);
    if (tag === "li" && insideOl) {
      if (!inOl) { inOl = true; olCounter = 0; }
      olCounter++;
    } else if (tag !== "li") { inOl = false; }

    const runs = extractRuns(inner);
    const marginLeft = pxFromStyle(style, "margin-left") ?? 0;
    const marginRight = pxFromStyle(style, "margin-right") ?? 0;
    const textIndent = pxFromStyle(style, "text-indent") ?? 0;
    const fontSize = isHeading ? [18, 15, 13, 12, 11, 11][headingLevel - 1] || 11 : 11;
    const spaceAfter = isHeading ? 8 : 4;
    const align = alignFromStyle(style) ?? "left";

    const joinedText = runs.map((r) => r.text).join("");
    if (joinedText.includes(QR_MARKER)) {
      blocks.push({ runs: [], align, marginLeft, marginRight, textIndent, fontSize, bold: false, spaceAfter: 8, isListItem: false, kind: "qr" });
      continue;
    }
    if (!runs.length) {
      if (isHeading) continue;
      blocks.push({ runs: [{ text: " ", bold: false, italic: false }], align, marginLeft, marginRight, textIndent, fontSize, bold: false, spaceAfter, isListItem: false });
      continue;
    }
    blocks.push({
      runs, align, marginLeft, marginRight, textIndent, fontSize,
      bold: isHeading, spaceAfter,
      isListItem: tag === "li",
      listMarker: tag === "li" ? (insideOl ? `${olCounter}.` : "•") : undefined,
    });
  }
  return blocks;
}

/** Render HTML + verifyUrl → PDF bytes (A4). */
export async function renderBuktiPdf(html: string, verifyUrl: string): Promise<Uint8Array> {
  const { PDFDocument, StandardFonts, rgb } = await import("pdf-lib");
  const { buildQrMatrix, drawQrOnPage } = await import("./qr");
  const pdf = await PDFDocument.create();
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  const fontB = await pdf.embedFont(StandardFonts.HelveticaBold);
  const fontI = await pdf.embedFont(StandardFonts.HelveticaOblique);
  const fontBI = await pdf.embedFont(StandardFonts.HelveticaBoldOblique);
  const pickFont = (b: boolean, i: boolean) => (b && i ? fontBI : b ? fontB : i ? fontI : font);
  const A4: [number, number] = [595.28, 841.89];

  const qrMatrix = buildQrMatrix(verifyUrl);


  const blocks = parseHtmlToBlocks(html);
  let page = pdf.addPage(A4);
  let { width, height } = page.getSize();
  const margin = 56;
  let y = height - margin;

  type Seg = { text: string; bold: boolean; italic: boolean };
  const wrapRuns = (runs: InlineRun[], size: number, maxW: number, indent: number) => {
    const lines: Seg[][] = [];
    let cur: Seg[] = [];
    let curW = indent;
    const pushLine = () => { lines.push(cur); cur = []; curW = 0; };
    for (const r of runs) {
      if (r.text === "\n") { pushLine(); continue; }
      const words = r.text.split(/(\s+)/);
      for (const w of words) {
        if (!w) continue;
        const f = pickFont(r.bold, r.italic);
        const wW = f.widthOfTextAtSize(w, size);
        if (curW + wW > maxW && cur.length && w.trim()) {
          pushLine();
          if (!w.trim()) continue;
        }
        cur.push({ text: w, bold: r.bold, italic: r.italic });
        curW += wW;
      }
    }
    if (cur.length) lines.push(cur);
    return lines;
  };
  const ensureSpace = (needed: number) => {
    if (y - needed < margin) {
      page = pdf.addPage(A4);
      ({ width, height } = page.getSize());
      y = height - margin;
    }
  };

  for (const block of blocks) {
    if (block.kind === "qr") {
      const qrSize = 120;
      ensureSpace(qrSize + block.spaceAfter);
      const availW = width - margin * 2 - block.marginLeft - block.marginRight;
      let x = margin + block.marginLeft;
      if (block.align === "center") x = margin + block.marginLeft + (availW - qrSize) / 2;
      else if (block.align === "right") x = margin + block.marginLeft + availW - qrSize;
      drawQrOnPage(page, qrMatrix, { x, y: y - qrSize, size: qrSize, color: rgb(0, 0, 0) });
      y -= qrSize + block.spaceAfter;
      continue;
    }
    const size = block.fontSize;
    const lineHeight = size * 1.35;
    const leftPad = block.marginLeft + (block.isListItem ? 18 : 0);
    const rightPad = block.marginRight;
    const availW = width - margin * 2 - leftPad - rightPad;
    const runs: InlineRun[] = block.bold
      ? block.runs.map((r) => ({ ...r, bold: true }))
      : block.runs;
    const lines = wrapRuns(runs, size, availW, block.textIndent);
    for (let li = 0; li < lines.length; li++) {
      ensureSpace(lineHeight);
      const segs = lines[li];
      const lineW = segs.reduce((acc, s) => acc + pickFont(s.bold, s.italic).widthOfTextAtSize(s.text, size), 0);
      let x = margin + leftPad + (li === 0 ? block.textIndent : 0);
      if (block.align === "right") x = margin + leftPad + availW - lineW;
      else if (block.align === "center") x = margin + leftPad + (availW - lineW) / 2;
      if (block.isListItem && li === 0 && block.listMarker) {
        page.drawText(block.listMarker, { x: margin + block.marginLeft, y, size, font, color: rgb(0, 0, 0) });
      }
      for (const s of segs) {
        const f = pickFont(s.bold, s.italic);
        page.drawText(s.text, { x, y, size, font: f, color: rgb(0, 0, 0) });
        x += f.widthOfTextAtSize(s.text, size);
      }
      y -= lineHeight;
    }
    y -= block.spaceAfter;
  }

  return await pdf.save();
}

export async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", bytes as BufferSource);
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");
}

export function makeToken(len = 24): string {
  const b = new Uint8Array(len);
  crypto.getRandomValues(b);
  return Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
}