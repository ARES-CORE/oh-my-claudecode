// Lee la política de seguridad de OMC (dist/lib/security-config.js) desde los hooks.
// Si dist/ no está disponible, cae a OMC_SECURITY=strict.
import { dirname, join } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const here = dirname(fileURLToPath(import.meta.url));

export async function isPolicyEnabled(flag) {
  try {
    const mod = await import(pathToFileURL(join(here, '..', '..', 'dist', 'lib', 'security-config.js')).href);
    return Boolean(mod.getSecurityConfig()[flag]);
  } catch {
    return process.env.OMC_SECURITY === 'strict';
  }
}
