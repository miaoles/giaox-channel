(define-module (giaox packages albion-online)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages audio)
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
                (libexec (string-append out "/libexec"))
                (source (assoc-ref %build-inputs "source"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (glibc (assoc-ref %build-inputs "glibc")))

           ;; Create directories
           (mkdir-p bin)
           (mkdir-p libexec)

           ;; Copy the installer binary
           (copy-file source (string-append libexec "/albion-online-setup"))
           (chmod (string-append libexec "/albion-online-setup") #o755)

           ;; Patch the installer
           (invoke patchelf "--set-interpreter"
                   (string-append glibc "/lib/ld-linux-x86-64.so.2")
                   (string-append libexec "/albion-online-setup"))

           ;; Create installer script
           (call-with-output-file (string-append bin "/albion-online-setup")
             (lambda (port)
               (format port "#!~a/bin/sh
# Set default installation directory
INSTALL_DIR=\"$HOME/Sandbox/Games/AlbionOnline\"
mkdir -p \"$INSTALL_DIR\"

# Set environment variables
export LD_LIBRARY_PATH=\"~a\"

# Run the installer
echo \"Installing Albion Online to $INSTALL_DIR\"
echo \"If prompted, please select this directory: $INSTALL_DIR\"
exec \"~a/albion-online-setup\" \"$@\"
"
                       (assoc-ref %build-inputs "bash")
                       (string-join
                        (map (lambda (lib)
                               (string-append (assoc-ref %build-inputs lib) "/lib"))
                             '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                               "mesa" "gtk+" "pango" "freetype" "fontconfig"))
                        ":")
                       libexec)))
           (chmod (string-append bin "/albion-online-setup") #o755)

           ;; Create game launcher script
           (call-with-output-file (string-append bin "/albion-online")
             (lambda (port)
               (format port "#!~a/bin/sh
# Game installation directory
GAME_DIR=\"$HOME/Sandbox/Games/AlbionOnline\"

# Check if the game is installed
if [ ! -d \"$GAME_DIR\" ]; then
  echo \"Albion Online is not installed. Please run albion-online-setup first.\"
  exit 1
fi

# Setup environment
export LD_LIBRARY_PATH=\"$GAME_DIR:$GAME_DIR/launcher:~a\"
export QT_QPA_PLATFORM_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/platforms\"
export QT_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/\"
export LIBGL_ALWAYS_SOFTWARE=1

# Run the game
cd \"$GAME_DIR\"
exec \"$GAME_DIR/launcher/Albion-Online\" \"--no-sandbox\" \"$@\"
"
                       (assoc-ref %build-inputs "bash")
                       (string-join
                        (map (lambda (lib)
                               (string-append (assoc-ref %build-inputs lib) "/lib"))
                             '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                               "libxtst" "libxi" "libxrandr" "libxcursor"
                               "mesa" "pulseaudio" "gtk+" "freetype" "fontconfig"
                               "nss" "alsa-lib" "expat"))
                        ":"))))
           (chmod (string-append bin "/albion-online") #o755)

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
       ("mesa" ,mesa)
       ("pulseaudio" ,pulseaudio)
       ("gtk+" ,gtk+)
       ("pango" ,pango)
       ("freetype" ,freetype)
       ("fontconfig" ,fontconfig)
       ("nss" ,nss)
       ("alsa-lib" ,alsa-lib)
       ("expat" ,expat)))
    (home-page "https://albiononline.com")
    (synopsis "Sandbox MMORPG set in an open medieval fantasy world")
    (description
     "Albion Online is a sandbox MMORPG set in an open medieval fantasy world.
It features a player-driven economy, classless combat system, and intense PvP battles.
This package provides both the game installer and a launcher for the installed game.")
    (license (license:non-copyleft "https://albiononline.com/en/terms_and_conditions"))))

albion-online
