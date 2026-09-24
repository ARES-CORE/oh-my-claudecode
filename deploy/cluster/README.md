# Despliegue offline en clúster

Instala oh-my-claudecode en los nodos/contenedores del clúster **sin acceso a
GitHub ni al registro npm**. `dist/` y `bridge/` ya vienen compilados; el paquete
solo añade las dependencias de ejecución (sin devDependencies).

## 1. Construir (máquina con internet, misma arquitectura/libc que el destino)

```bash
deploy/cluster/build-bundle.sh            # → oh-my-claudecode-<ver>-bundle.tar.gz + .sha256
```

## 2. Instalar (en cada destino, como el usuario de Claude Code)

Requisitos del destino: Node.js 20+ y Claude Code. Nada más.

```bash
sha256sum -c oh-my-claudecode-*-bundle.tar.gz.sha256
tar -xzf oh-my-claudecode-*-bundle.tar.gz
oh-my-claudecode/deploy-cluster/install-offline.sh
claude plugin list
```

`PREFIX` cambia la ruta del plugin (def. `~/.local/share/oh-my-claudecode`).

## Seguridad

- Ningún archivo de este directorio contiene credenciales, IPs ni hostnames reales.
- Configuraciones personales y skills privadas (manuales internos) **no** se
  versionan: se instalan con un kit aparte que vive solo en el clúster.
- Los secretos (API keys, tokens) se inyectan en el host por variables de entorno
  o gestor de secretos; nunca en este repositorio.
