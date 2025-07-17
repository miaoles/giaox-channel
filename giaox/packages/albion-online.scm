(define-module (giaox packages albion-online)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages xml))

(define-public albion-online
  (package
    (name "albion-online")
    (version "1.0")
    (source (origin
              (method url-fetch)
              (uri "https://live.albiononline.com/clients/20250712102808/albion-online-setup")
              (file-name (string-append name "-" version "-setup"))
              (sha256
               (base32
                "0znr639zdpy0iwf97h33pyxv462kjyd8p5n55q4s080482qznpbh"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (bin (string-append out "/bin"))
                (share (string-append out "/share"))
                (applications (string-append share "/applications"))
                (icons (string-append share "/icons/hicolor/128x128/apps"))
                (doc (string-append share "/doc/albion-online"))
                (libexec (string-append out "/libexec"))
                (setup-bin (string-append libexec "/albion-online-setup"))
                (launcher-script (string-append bin "/albion-online-setup"))
                (game-launcher-script (string-append bin "/albion-online"))
                (source (assoc-ref %build-inputs "source"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (glibc (assoc-ref %build-inputs "glibc")))

           ;; Create directories
           (mkdir-p bin)
           (mkdir-p libexec)
           (mkdir-p applications)
           (mkdir-p icons)
           (mkdir-p doc)

           ;; Copy the binary
           (copy-file source setup-bin)
           (chmod setup-bin #o755)

           ;; Patch the interpreter
           (invoke patchelf "--set-interpreter"
                   (string-append glibc "/lib/ld-linux-x86-64.so.2")
                   setup-bin)

           ;; Create installer wrapper script
           (call-with-output-file launcher-script
             (lambda (port)
               (format port "#!~a/bin/sh
export LD_LIBRARY_PATH=\"~a\"
export FONTCONFIG_PATH=\"~a\"
export FONTCONFIG_FILE=\"~a\"
exec \"~a\" \"$@\"
"
                       (assoc-ref %build-inputs "bash")
                       (string-join
                        (map (lambda (lib)
                               (string-append (assoc-ref %build-inputs lib) "/lib"))
                             '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                               "libxtst" "libxi" "libxrandr" "libxcursor"
                               "libxcomposite" "libxdamage" "libxfixes"
                               "mesa" "pulseaudio" "gtk+" "gdk-pixbuf"
                               "cairo" "pango" "freetype" "fontconfig"
                               "nspr" "nss" "atk" "at-spi2-core" "dbus"
                               "glib" "cups" "libxscrnsaver"
                               "libxcb" "libxau" "libxdmcp" "alsa-lib" "expat"))
                        ":")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts/fonts.conf")
                       setup-bin)))
           (chmod launcher-script #o755)

           ;; Create game launcher script
           (call-with-output-file game-launcher-script
             (lambda (port)
               (format port "#!~a/bin/sh
# Check if the game is installed
GAME_DIR=\"$HOME/Sandbox/Games/AlbionOnline\"
if [ ! -d \"$GAME_DIR\" ]; then
  echo \"Albion Online is not installed. Please run albion-online-setup first.\"
  exit 1
fi

# Add required libraries from Guix packages
export LD_LIBRARY_PATH=\"$GAME_DIR/launcher:~a:$LD_LIBRARY_PATH\"

# Set font configuration
export FONTCONFIG_PATH=\"~a\"
export FONTCONFIG_FILE=\"~a\"

# Set Qt environment variables
export QT_QPA_PLATFORM_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/platforms\"
export QT_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/\"
export QT_SCALE_FACTOR=1
export QT_QPA_PLATFORM=\"xcb\"

# Graphics settings
export LIBGL_ALWAYS_SOFTWARE=1
export QSG_INFO=1

# Run the game
cd \"$GAME_DIR\"
exec \"$GAME_DIR/launcher/Albion-Online\" \"--no-sandbox\" \"-loglevel 0\" \"$@\"
"
                       (assoc-ref %build-inputs "bash")
                       (string-join
                        (map (lambda (lib)
                               (string-append (assoc-ref %build-inputs lib) "/lib"))
                             '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                               "libxtst" "libxi" "libxrandr" "libxcursor"
                               "libxcomposite" "libxdamage" "libxfixes"
                               "mesa" "pulseaudio" "gtk+" "gdk-pixbuf"
                               "cairo" "pango" "freetype" "fontconfig"
                               "nspr" "nss" "atk" "at-spi2-core" "dbus"
                               "glib" "cups" "libxscrnsaver"
                               "libxcb" "libxau" "libxdmcp" "alsa-lib" "expat"))
                        ":")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts/fonts.conf"))))
           (chmod game-launcher-script #o755)

           ;; Create desktop file
           (call-with-output-file (string-append applications "/albion-online.desktop")
             (lambda (port)
               (format port "[Desktop Entry]
Name=Albion Online
Comment=Sandbox MMORPG set in an open medieval fantasy world
Exec=albion-online
Terminal=false
Type=Application
Categories=Game;RolePlaying;
Keywords=game;mmorpg;rpg;
Icon=albion-online
")))

           ;; Create a placeholder icon (will be replaced by the installer)
           (call-with-output-file (string-append icons "/albion-online.png")
             (lambda (port)
               (display "This is a placeholder. The actual icon will be installed by the game installer." port)))

           ;; Create README file
           (call-with-output-file (string-append doc "/README")
             (lambda (port)
               (display "Albion Online for Guix

Installation:
1. Run 'albion-online-setup' to install the game
2. Choose ~/Sandbox/Games/AlbionOnline as the installation directory
3. Complete the installation process

Playing:
1. Run 'albion-online' to start the game

Troubleshooting:
If you encounter issues, try running the game from a terminal to see error messages.
" port)))

           #t))))
    (native-inputs
     (list patchelf))
    (inputs
     `(("bash" ,bash-minimal)
       ("glibc" ,glibc)
       ("gcc:lib" ,gcc "lib")
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxrender" ,libxrender)
       ("libxtst" ,libxtst)
       ("libxi" ,libxi)
       ("libxrandr" ,libxrandr)
       ("libxcursor" ,libxcursor)
       ("libxcomposite" ,libxcomposite)
       ("libxdamage" ,libxdamage)
       ("libxfixes" ,libxfixes)
       ("libxscrnsaver" ,libxscrnsaver)
       ("libxcb" ,libxcb)
       ("libxau" ,libxau)
       ("libxdmcp" ,libxdmcp)
       ("mesa" ,mesa)
       ("pulseaudio" ,pulseaudio)
       ("gtk+" ,gtk+)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("cairo" ,cairo)
       ("pango" ,pango)
       ("freetype" ,freetype)
       ("fontconfig" ,fontconfig)
       ("nspr" ,nspr)
       ("nss" ,nss)
       ("atk" ,atk)
       ("at-spi2-core" ,at-spi2-core)
       ("dbus" ,dbus)
       ("glib" ,glib)
       ("cups" ,cups)
       ("alsa-lib" ,alsa-lib)
       ("expat" ,expat)
       ("zlib" ,zlib)))
    (home-page "https://albiononline.com")
    (synopsis "Sandbox MMORPG set in an open medieval fantasy world")
    (description
     "Albion Online is a sandbox MMORPG set in an open medieval fantasy world.
It features a player-driven economy, classless combat system, and intense PvP battles.
This package provides both the game installer and a launcher for the installed game.")
    (license (license:non-copyleft "https://albiononline.com/en/terms_and_conditions"))))

;; This allows building with "guix build -f"
albion-online
