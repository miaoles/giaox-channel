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
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages kerberos))

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
                (glibc (assoc-ref %build-inputs "glibc"))
                (nss (assoc-ref %build-inputs "nss"))
                (nspr (assoc-ref %build-inputs "nspr")))

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
\"~a/albion-online-setup\" \"$@\"

# After installation, create wrapper for the game executable
if [ -f \"$INSTALL_DIR/launcher/Albion-Online\" ]; then
  echo \"Creating launcher wrapper...\"
  # Backup original if not already done
  if [ ! -f \"$INSTALL_DIR/launcher/Albion-Online.original\" ]; then
    mv \"$INSTALL_DIR/launcher/Albion-Online\" \"$INSTALL_DIR/launcher/Albion-Online.original\"
  fi

  # Create wrapper script
  cat > \"$INSTALL_DIR/launcher/Albion-Online\" << 'WRAPPER_EOF'
#!/bin/sh
# Wrapper script for Albion Online
SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")\" && pwd)\"
export LD_LIBRARY_PATH=\"~a:$SCRIPT_DIR\"
exec ~a/lib/ld-linux-x86-64.so.2 \"$SCRIPT_DIR/Albion-Online.original\" \"$@\"
WRAPPER_EOF

  chmod +x \"$INSTALL_DIR/launcher/Albion-Online\"
  echo \"Wrapper created successfully.\"
fi
"
                       (assoc-ref %build-inputs "bash")
                       (string-join
                        (map (lambda (lib)
                               (string-append (assoc-ref %build-inputs lib) "/lib"))
                             '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                               "mesa" "gtk+" "pango" "freetype" "fontconfig"))
                        ":")
                       libexec
                       (string-append
                        (string-join
                         (map (lambda (lib)
                                (string-append (assoc-ref %build-inputs lib) "/lib"))
                              '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                                "libxtst" "libxi" "libxrandr" "libxcursor"
                                "libxcomposite" "libxdamage" "libxfixes"
                                "libxcb" "libxau" "libxdmcp"
                                "mesa" "pulseaudio" "gtk+" "glib"
                                "freetype" "fontconfig" "dbus"
                                "alsa-lib" "expat" "zlib"
                                "util-linux" "mit-krb5"))
                         ":")
                        ":"
                        nss "/lib/nss"
                        ":"
                        nspr "/lib/nspr")
                       glibc)))
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

# Copy NSPR and NSS libraries directly to the game directory
NSPR_LIBS=(\"libnspr4.so\" \"libplc4.so\" \"libplds4.so\")
for lib in \"${NSPR_LIBS[@]}\"; do
  if [ ! -f \"$GAME_DIR/launcher/$lib\" ]; then
    echo \"Copying $lib to game directory\"
    cp -f \"~a/lib/nspr/$lib\" \"$GAME_DIR/launcher/$lib\"
  fi
done

NSS_LIBS=(\"libsmime3.so\" \"libnss3.so\" \"libnssutil3.so\")
for lib in \"${NSS_LIBS[@]}\"; do
  if [ ! -f \"$GAME_DIR/launcher/$lib\" ]; then
    echo \"Copying $lib to game directory\"
    cp -f \"~a/lib/nss/$lib\" \"$GAME_DIR/launcher/$lib\"
  fi
done

# Copy GCC libraries
GCC_LIBS=(\"libstdc++.so.6\" \"libgcc_s.so.1\")
for lib in \"${GCC_LIBS[@]}\"; do
  if [ ! -f \"$GAME_DIR/launcher/$lib\" ]; then
    echo \"Copying $lib to game directory\"
    cp -f \"~a/lib/$lib\" \"$GAME_DIR/launcher/$lib\"
  fi
done

# Copy OpenGL library
if [ ! -f \"$GAME_DIR/launcher/libGL.so.1\" ]; then
  echo \"Copying libGL.so.1 to game directory\"
  cp -f \"~a/lib/libGL.so.1\" \"$GAME_DIR/launcher/libGL.so.1\"
fi

# Setup environment
export LD_LIBRARY_PATH=\"~a:$GAME_DIR:$GAME_DIR/launcher\"
export QT_QPA_PLATFORM_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/platforms\"
export QT_PLUGIN_PATH=\"$GAME_DIR/launcher/plugins/\"
export LIBGL_ALWAYS_SOFTWARE=1

# Additional environment variables
export FONTCONFIG_PATH=\"~a/etc/fonts\"
export FONTCONFIG_FILE=\"~a/etc/fonts/fonts.conf\"

# For debugging: print all the missing libraries
echo \"Checking for missing libraries...\"
ldd \"$GAME_DIR/launcher/Albion-Online.original\" | grep \"not found\" || true

# Run the game through the wrapper
cd \"$GAME_DIR\"
exec \"$GAME_DIR/launcher/Albion-Online\" \"--no-sandbox\" \"$@\"
"
                       (assoc-ref %build-inputs "bash")
                       nspr
                       nss
                       (assoc-ref %build-inputs "gcc:lib")
                       (assoc-ref %build-inputs "mesa")
                       (string-append
                        (string-join
                         (map (lambda (lib)
                                (string-append (assoc-ref %build-inputs lib) "/lib"))
                              '("glibc" "gcc:lib" "libx11" "libxext" "libxrender"
                                "libxtst" "libxi" "libxrandr" "libxcursor"
                                "libxcomposite" "libxdamage" "libxfixes"
                                "libxcb" "libxau" "libxdmcp"
                                "mesa" "pulseaudio" "gtk+" "glib"
                                "freetype" "fontconfig" "dbus"
                                "alsa-lib" "expat" "zlib"
                                "util-linux" "mit-krb5"))
                         ":")
                        ":"
                        nss "/lib/nss"
                        ":"
                        nspr "/lib/nspr")
                       (assoc-ref %build-inputs "fontconfig")
                       (assoc-ref %build-inputs "fontconfig"))))
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
       ("libxcomposite" ,libxcomposite)
       ("libxdamage" ,libxdamage)
       ("libxfixes" ,libxfixes)
       ("libxcb" ,libxcb)
       ("libxau" ,libxau)
       ("libxdmcp" ,libxdmcp)
       ("mesa" ,mesa)
       ("pulseaudio" ,pulseaudio)
       ("gtk+" ,gtk+)
       ("glib" ,glib)
       ("dbus" ,dbus)
       ("pango" ,pango)
       ("freetype" ,freetype)
       ("fontconfig" ,fontconfig)
       ("nss" ,nss)
       ("nspr" ,nspr)
       ("alsa-lib" ,alsa-lib)
       ("expat" ,expat)
       ("zlib" ,zlib)
       ("util-linux" ,util-linux)
       ("mit-krb5" ,mit-krb5)))
    (home-page "https://albiononline.com")
    (synopsis "Sandbox MMORPG set in an open medieval fantasy world")
    (description
     "Albion Online is a sandbox MMORPG set in an open medieval fantasy world.
It features a player-driven economy, classless combat system, and intense PvP battles.
This package provides both the game installer and a launcher for the installed game.")
    (license (license:non-copyleft "https://albiononline.com/en/terms_and_conditions"))))

albion-online
