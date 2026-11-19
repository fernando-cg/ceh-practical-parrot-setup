#!/bin/bash
# ============================================================================
#  ceh_setup.sh — Despliegue rápido del Parrot del CEH Practical (iLabs)
#  Uso:  bash ceh_setup.sh          (o: curl -sL <URL_RAW_DE_TU_REPO> | bash)
#  Idempotente: se puede relanzar sin romper nada. Timeouts cortos.
# ============================================================================
set -u
export DEBIAN_FRONTEND=noninteractive

# ── CONFIGURA ANTES DE SUBIRLO A GITHUB ─────────────────────────────────────
HIST_RAW_URL="https://raw.githubusercontent.com/fernando-cg/ceh-practical-parrot-setup/main/zsh_history_extra"
CO2_URL="https://portswigger.net/bappstore/bapps/download/c5071c7a7e004f72ae485e8a72911afc/12"
# ────────────────────────────────────────────────────────────────────────────

ok(){ echo -e "\e[32m[+] $1\e[0m"; }
warn(){ echo -e "\e[33m[!] $1\e[0m"; }
fail(){ echo -e "\e[31m[-] $1\e[0m"; }

echo "== CEH Practical — setup del Parrot =="

# 0) Conectividad (5 s) — si no hay red, no instalamos nada a ciegas
if timeout 8 curl -sI https://github.com -o /dev/null; then ok "Conectividad OK"; else
  warn "Sin salida a internet (o lenta). Las descargas van a fallar — usa el método manual de pegar comandos por Type Clipboard Text."; fi

# 1) DEPENDENCIAS. El pegado PC -> VM lo proporciona Lab on Demand/Skillable.
# Commands -> Type Text -> Type Clipboard Text (no es bidireccional).
# No instalar ni arrancar servidores de acceso remoto.
ok "1/7 · Dependencias básicas (versión sin SSH)"
sudo apt-get update -qq 2>/dev/null
sudo apt-get install -y -qq git curl pipx zsh >/dev/null 2>&1
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
echo "   Pegado: Lab on Demand → Type Text → Type Clipboard Text"

# 2) HISTORIAL DE ZSH (tus comandos del lab, ya disponibles con flecha arriba)
ok "2/7 · Importando historial zsh"
mkdir -p ~/.cache/zsh 2>/dev/null
if timeout 20 curl -fsSL "$HIST_RAW_URL" -o /tmp/hist_import 2>/dev/null && [ -s /tmp/hist_import ]; then
  touch ~/.zsh_history
  # deduplicado simple: solo líneas nuevas
  cat ~/.zsh_history /tmp/hist_import | awk '!seen[$0]++' > ~/.zsh_history.new && mv ~/.zsh_history.new ~/.zsh_history
  rm -f /tmp/hist_import
  ok "Historial importado ($(wc -l < ~/.zsh_history) líneas totales). Abre una zsh nueva y usa ↑"
else
  warn "No pude bajar el historial (¿URL raw correcta?). Pégalo a mano: cat >> ~/.zsh_history"
fi
# formato extended_history para lo que grabs hoy
grep -q 'HISTFILE' ~/.zshrc 2>/dev/null || echo 'HISTFILE=~/.zsh_history; HISTSIZE=50000; SAVEHIST=50000; setopt share_history' >> ~/.zshrc

# 3) NETEXEC
ok "3/7 · NetExec (nxc)"
if command -v nxc >/dev/null 2>&1; then ok "nxc ya instalado: $(nxc --version 2>/dev/null | head -1)"
else
  (sudo apt-get install -y -qq netexec >/dev/null 2>&1 && ok "nxc vía apt") || \
  (timeout 240 pipx install git+https://github.com/Pennyw0rth/NetExec >/dev/null 2>&1 && ok "nxc vía pipx") || \
  warn "NetExec falló — relanza: pipx install git+https://github.com/Pennyw0rth/NetExec"
  pipx ensurepath >/dev/null 2>&1
fi

# 4) SHERLOCK
ok "4/7 · Sherlock (sherlock-project)"
if command -v sherlock >/dev/null 2>&1; then ok "sherlock ya instalado"
else
  timeout 120 pipx install sherlock-project >/dev/null 2>&1 && ok "sherlock instalado (pipx)" || \
  warn "Sherlock falló — relanza: pipx install sherlock-project  (NO uses setup.py: da AttributeError install_layout)"
  pipx ensurepath >/dev/null 2>&1
fi

# 5) KERBRUTE — binario oficial versionado, sin instalar Go ni compilar.
ok "5/7 · Kerbrute"
if command -v kerbrute >/dev/null 2>&1; then
  ok "kerbrute ya instalado: $(command -v kerbrute)"
else
  kerbrute_arch=""
  case "$(uname -m)" in
    x86_64|amd64) kerbrute_arch="amd64" ;;
    i386|i486|i586|i686) kerbrute_arch="386" ;;
    *) warn "Arquitectura sin binario oficial Kerbrute v1.0.3; no se instalará." ;;
  esac
  if [ -n "$kerbrute_arch" ]; then
    kerbrute_tmp=$(mktemp "$HOME/.local/bin/.kerbrute.XXXXXX") || kerbrute_tmp=""
    if [ -n "$kerbrute_tmp" ]; then
      if timeout 90 curl -fSL --connect-timeout 10 --max-time 80 \
        "https://github.com/ropnop/kerbrute/releases/download/v1.0.3/kerbrute_linux_${kerbrute_arch}" \
        -o "$kerbrute_tmp" && \
        chmod 755 "$kerbrute_tmp" && \
        timeout 10 "$kerbrute_tmp" --help >/dev/null 2>&1 && \
        mv -f "$kerbrute_tmp" "$HOME/.local/bin/kerbrute"; then
        ok "kerbrute instalado y --help comprobado: ~/.local/bin/kerbrute"
      else
        rm -f "$kerbrute_tmp"
        warn "Kerbrute no se pudo descargar o ejecutar; no se ha instalado. Puedes relanzar el setup."
      fi
    else
      warn "No se pudo crear el archivo temporal de Kerbrute."
    fi
  fi
fi

# 6) TECLADO ESPAÑOL
ok "6/7 · Teclado español"
setxkbmap es 2>/dev/null && ok "setxkbmap es (sesión X)" || warn "sin X (¿consola?): sudo loadkeys es"
sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="es"/' /etc/default/keyboard 2>/dev/null && ok "persistente en /etc/default/keyboard"

# 7) EXTENSIÓN CO2 DE BURP
ok "7/7 · Extensión CO2 para Burp (SQLMapper, User Generator...)"
mkdir -p ~/burp-exts
if timeout 30 curl -fsSL "$CO2_URL" -o ~/burp-exts/co2.jar 2>/dev/null && [ -s ~/burp-exts/co2.jar ]; then
  ok "CO2 descargado en ~/burp-exts/co2.jar"
  echo "    En Burp: Extensions → Installed → Add → Java → selecciona ~/burp-exts/co2.jar"
else
  warn "Descarga de CO2 falló. Alternativa EN Burp: Extensions → BApp Store → busca 'CO2' → Install"
fi

# No se crean puentes externos de texto ni se cambia el estado de servicios existentes.

echo
ok "LISTO. Resumen:"
echo "   Pegado PC → Parrot: menú Type Clipboard Text de Lab on Demand"
echo "   nxc --version; sherlock --help; kerbrute --help"
echo "   En tu zsh actual: fc -R ~/.zsh_history"
echo "   Burp: carga ~/burp-exts/co2.jar"
ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | while read i; do echo "   IP: $i"; done
