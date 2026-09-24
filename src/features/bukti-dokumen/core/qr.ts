// QR helper murni JS (tanpa canvas / Node stream), aman untuk browser & worker.
// Digambar sebagai kotak vektor ke halaman pdf-lib, jadi tidak perlu encode PNG.
import qrcodeGenerator from "qrcode-generator";

export type QrMatrix = { size: number; isDark: (row: number, col: number) => boolean };

/** Bangun matriks modul QR untuk sebuah teks/URL. */
export function buildQrMatrix(text: string): QrMatrix {
  const qr = qrcodeGenerator(0, "M");
  qr.addData(text);
  qr.make();
  const size = qr.getModuleCount();
  return { size, isDark: (r, c) => qr.isDark(r, c) };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DrawRectFn = (opts?: any) => void;

/** Gambar QR sebagai kotak-kotak vektor pada page pdf-lib. */
export function drawQrOnPage(
  page: { drawRectangle: DrawRectFn },
  matrix: QrMatrix,
  opts: { x: number; y: number; size: number; color: unknown; margin?: number },
) {
  const marginModules = opts.margin ?? 2;
  const total = matrix.size + marginModules * 2;
  const cell = opts.size / total;
  for (let r = 0; r < matrix.size; r++) {
    for (let c = 0; c < matrix.size; c++) {
      if (!matrix.isDark(r, c)) continue;
      page.drawRectangle({
        x: opts.x + (c + marginModules) * cell,
        y: opts.y + opts.size - (r + marginModules + 1) * cell,
        width: cell + 0.2,
        height: cell + 0.2,
        color: opts.color,
      });
    }
  }
}
