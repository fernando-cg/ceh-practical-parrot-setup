# CEH Practical — Parrot setup (sin SSH)

Preparación del Parrot de laboratorio:
- Importa y fusiona el historial curado `zsh_history_extra` en `~/.zsh_history`.
- Instala NetExec (`nxc`), Sherlock y Kerbrute.
- Kerbrute se descarga de [ropnop/kerbrute v1.0.3](https://github.com/ropnop/kerbrute/releases/tag/v1.0.3) en `~/.local/bin/kerbrute`, seleccionando Linux amd64 o 386. Comprueba `--help` antes de instalar y omite la descarga si ya está disponible. En otras arquitecturas avisa y continúa.
- Comprueba Kerbrute con `~/.local/bin/kerbrute --help`; si tu terminal actual aún no reconoce `kerbrute`, ejecuta `export PATH="$HOME/.local/bin:$PATH"` y, en Zsh, `rehash`.
- Cambia el teclado a español (X11) e intenta persistirlo.
- Descarga CO2 para cargarlo manualmente en Burp: Extensions → Installed → Add → Java.

## Uso

Desde el usuario normal de Parrot (`attacker`), sin ejecutar todo como root:

```bash
curl -fsSL https://raw.githubusercontent.com/fernando-cg/ceh-practical-parrot-setup/main/ceh_setup.sh -o ceh_setup.sh
bash ceh_setup.sh
```

Después, desde tu terminal Zsh:

```zsh
fc -R ~/.zsh_history
```

## Copiar y pegar

Usa el menú de Lab on Demand/Skillable: **Type Text → Type Clipboard Text**.
Es una función de la consola web para introducir texto de tu PC en la VM; no instala ni garantiza un portapapeles bidireccional.

Esta versión **no instala openssh-server, no arranca ni habilita SSH y no instala el helper `clip`**. Tampoco detiene o desinstala servicios que ya existan en la VM.

El historial conserva comandos SSH suministrados por el usuario como texto: importar el historial no ejecuta esos comandos.

## Límites de verificación

Se comprueba sintaxis Bash y el flujo con comandos externos simulados. Las instalaciones reales requieren repositorios y red disponibles en tu Parrot; no se garantiza una duración fija. Para el examen, comprueba previamente que estén autorizados los scripts y descargas externos.

Solo para entornos autorizados. No publiques secretos ni contenido del examen en este repositorio.
