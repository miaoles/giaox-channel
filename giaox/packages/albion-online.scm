(define-module (giaox packages albion-online)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages glib))

(define-public albion-online
  (package
    (name "albion-online")
    (version "1.0")  ; Update this to match the actual version
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
                (setup-bin (string-append libexec "/albion-online-setup"))
                (wrapper (string-append bin "/albion-online-setup"))
                (source (assoc-ref %build-inputs "source"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (glibc (assoc-ref %build-inputs "glibc")))

           ;; Create directories
           (mkdir-p bin)
           (mkdir-p libexec)

           ;; Copy the binary
           (copy-file source setup-bin)
           (chmod setup-bin #o755)

           ;; Patch the interpreter
           (invoke patchelf "--set-interpreter"
                   (string-append glibc "/lib/ld-linux-x86-64.so.2")
                   setup-bin)

           ;; Create wrapper script
           (call-with-output-file wrapper
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
                               "glib" "cups" "libxscrnsaver"))
                        ":")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts")
                       (string-append (assoc-ref %build-inputs "fontconfig") "/etc/fonts/fonts.conf")
                       setup-bin)))
           (chmod wrapper #o755)

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
       ("zlib" ,zlib)))
    (home-page "https://albiononline.com")
    (synopsis "Sandbox MMORPG set in an open medieval fantasy world")
    (description
     "Albion Online is a sandbox MMORPG set in an open medieval fantasy world.
It features a player-driven economy, classless combat system, and intense PvP battles.
This package provides the game launcher and installer.")
    (license (license:non-copyleft "https://albiononline.com/en/terms_and_conditions"))))

;; This allows building with "guix build -f"
albion-online
