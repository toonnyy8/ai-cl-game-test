// worker.ts: renders the sound bank off the main thread (BANK_ORDER, ~1.3 s on a desktop, several on a phone) and posts
// each sound's samples as it is done (transferred, not copied).
import { BANK_ORDER, renderSound } from './sounds';

for (const key of BANK_ORDER) {
  const data = renderSound(key);
  (self as unknown as Worker).postMessage({ key, data }, [data.buffer]);
}
