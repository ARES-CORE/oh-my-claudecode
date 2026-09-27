// Preload (node --import) que registra en stderr cada fetch() del proceso.
const orig = globalThis.fetch;
globalThis.fetch = async (url, ...rest) => { process.stderr.write(`FETCH ${url}\n`); return orig(url, ...rest); };
