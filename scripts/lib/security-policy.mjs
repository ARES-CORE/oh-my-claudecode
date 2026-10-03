// Lee la política de seguridad de OMC (dist/lib/security-config.js) desde los hooks.
// OMC_SECURITY=strict activa todo sin depender de dist/ (puede faltar o ser una build vieja
// que aún no conoce el flag).
import { dirname, join } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const here = dirname(fileURLToPath(import.meta.url));

export async function isPolicyEnabled(flag) {
  if (process.env.OMC_SECURITY === 'strict') return true;
  try {
    const mod = await import(pathToFileURL(join(here, '..', '..', 'dist', 'lib', 'security-config.js')).href);
    return mod.getSecurityConfig()[flag] === true;
  } catch {
    return false;
  }
}
