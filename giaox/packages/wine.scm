;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>

(define-module (nongnu packages wine)
  #:use-module (ice-9 match)
  #:use-module ((guix licenses) :prefix license:)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages wine)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages image)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mingw)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages scanner)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

;; This minimal build of Wine is needed to prevent a circular dependency with
;; vkd3d.
(define-public wine-minimal
  (package
    (name "wine-minimal")
    (version "9.13")
    (source
     (origin
       (method url-fetch)
       (uri (let ((dir (string-append
                        (version-major version)
                        (if (string-suffix? ".0" (version-major+minor version))
                            ".0/"
                            ".x/"))))
              (string-append "https://dl.winehq.org/wine/source/" dir
                             "wine-" version ".tar.xz")))
       (sha256
        (base32 "0j3kpxx4hv9x42zrxqkrb49gqby007q4bqyrrf2gxpiqzv8535np"))))
    (properties '((upstream-name . "wine")))
    (build-system gnu-build-system)
    (native-inputs (list bison flex))
    (inputs `())
    (arguments
     (list
      ;; Force a 32-bit build targeting a similar architecture, i.e.:
      ;; armhf for armhf/aarch64, i686 for i686/x86_64.
      #:system (match (%current-system)
                 ((or "armhf-linux" "aarch64-linux") "armhf-linux")
                 (_ "i686-linux"))

       ;; XXX: There's a test suite, but it's unclear whether it's supposed to
       ;; pass.
       #:tests? #f

       #:make-flags
       #~(list "SHELL=bash"
               (string-append "libdir=" #$output "/lib/wine32"))

       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'patch-SHELL
             (lambda _
               (substitute* "configure"
                 ;; configure first respects CONFIG_SHELL, clobbers SHELL later.
                 (("/bin/sh")
                  (which "bash")))))
           (add-after 'configure 'patch-dlopen-paths
             ;; Hardcode dlopened sonames to absolute paths.
             (lambda _
               (let* ((library-path (search-path-as-string->list
                                     (getenv "LIBRARY_PATH")))
                      (find-so (lambda (soname)
                                 (search-path library-path soname))))
                 (substitute* "include/config.h"
                   (("(#define SONAME_.* )\"(.*)\"" _ defso soname)
                    (format #f "~a\"~a\"" defso (find-so soname)))))))
           (add-after 'patch-generated-file-shebangs 'patch-makedep
             (lambda* (#:key outputs #:allow-other-keys)
               (substitute* "tools/makedep.c"
                 (("output_filenames\\( unix_libs \\);" all)
                  (string-append all
                   "output ( \" -Wl,-rpath=%s \", arch_install_dirs[arch] );")))))
           (add-before 'build 'set-widl-time-override
             ;; Set WIDL_TIME_OVERRIDE to avoid embedding the current date in
             ;; files generated by WIDL.
             (lambda _
               (setenv "WIDL_TIME_OVERRIDE" "315532800"))))
       #:configure-flags
       #~(list "--without-freetype"
               "--without-x")))
    (home-page "https://www.winehq.org/")
    (synopsis "Implementation of the Windows API (32-bit only)")
    (description
     "Wine (originally an acronym for \"Wine Is Not an Emulator\") is a
compatibility layer capable of running Windows applications.  Instead of
simulating internal Windows logic like a virtual machine or emulator, Wine
translates Windows API calls into POSIX calls on-the-fly, eliminating the
performance and memory penalties of other methods and allowing you to cleanly
integrate Windows applications into your desktop.")
    ;; Any platform should be able to build wine, but based on '#:system' these
    ;; are the ones we currently support.
    (supported-systems '("i686-linux" "x86_64-linux" "armhf-linux"))
    (license license:lgpl2.1+)))

(define-public wine
  (package
    (inherit wine-minimal)
    (name "wine")
    (native-inputs
     (modify-inputs (package-native-inputs wine-minimal)
       (prepend gettext-minimal perl pkg-config)))
    (inputs
     ;; Some libraries like libjpeg are now compiled into native PE objects.
     ;; The ELF objects provided by Guix packages are of no use.  Whilst this
     ;; is technically bundling, it's quite defensible.  It might be possible
     ;; to build some of these from Guix PACKAGE-SOURCE but attempts were not
     ;; fruitful so far.  See <https://www.winehq.org/announce/7.0>.
     (list alsa-lib
           bash-minimal
           cups
           dbus
           eudev
           fontconfig
           freetype
           gnutls
           gst-plugins-base
           libgphoto2
           openldap
           samba
           sane-backends
           libpcap
           libusb
           libice
           libx11
           libxi
           libxext
           libxcursor
           libxkbcommon
           libxrender
           libxrandr
           libxinerama
           libxxf86vm
           libxcomposite
           mesa
           mit-krb5
           openal
           pulseaudio
           sdl2
           unixodbc
           v4l-utils
           vkd3d
           vulkan-loader
           wayland
           wayland-protocols))
    (arguments
     (substitute-keyword-arguments (package-arguments wine-minimal)
       ((#:phases phases)
        #~(modify-phases #$phases
           ;; Explicitly set the 32-bit version of vulkan-loader when installing
           ;; to i686-linux or x86_64-linux.
           ;; TODO: Add more JSON files as they become available in Mesa.
           #$@(match (%current-system)
                ((or "i686-linux" "x86_64-linux")
                 `((add-after 'install 'wrap-executable
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                       (let* ((out (assoc-ref outputs "out"))
                              (icd (string-append out "/share/vulkan/icd.d")))
                         (mkdir-p icd)
                         (copy-file (search-input-file
                                     inputs
                                     "/share/vulkan/icd.d/radeon_icd.i686.json")
                                    (string-append icd "/radeon_icd.i686.json"))
                         (copy-file (search-input-file
                                     inputs
                                     "/share/vulkan/icd.d/intel_icd.i686.json")
                                    (string-append icd "/intel_icd.i686.json"))
                         (wrap-program (string-append out "/bin/wine-preloader")
                           `("VK_ICD_FILENAMES" ":" =
                             (,(string-append icd
                                              "/radeon_icd.i686.json" ":"
                                              icd "/intel_icd.i686.json")))))))))
                (_
                 `()))))
       ((#:configure-flags _ '()) #~'())))))

(define-public wine64
  (package
    (inherit wine)
    (name "wine64")
    (inputs (modify-inputs (package-inputs wine)
              (prepend wine)))
    (arguments
     (substitute-keyword-arguments
         (strip-keyword-arguments '(#:system) (package-arguments wine))
       ((#:make-flags _)
        #~(list "SHELL=bash"
                (string-append "libdir=" #$output "/lib/wine64"))
        )
       ((#:phases phases)
        #~(modify-phases #$phases
            ;; Explicitly set both the 64-bit and 32-bit versions of vulkan-loader
            ;; when installing to x86_64-linux so both are available.
            ;; TODO: Add more JSON files as they become available in Mesa.
            #$@(match (%current-system)
                 ((or "x86_64-linux")
                  `((delete 'wrap-executable)
                    (add-after 'copy-wine32-binaries 'wrap-executable
                      (lambda* (#:key inputs outputs #:allow-other-keys)
                        (let* ((out (assoc-ref outputs "out"))
                               (icd-files (map
                                           (lambda (basename)
                                             (search-input-file
                                              inputs
                                              (string-append "/share/vulkan/icd.d/"
                                                             basename)))
                                           '("radeon_icd.x86_64.json"
                                             "intel_icd.x86_64.json"
                                             "radeon_icd.i686.json"
                                             "intel_icd.i686.json"))))
                          (wrap-program (string-append out "/bin/wine-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files))
                          (wrap-program (string-append out "/bin/wine64-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files)))))))
                 (_
                  `()))
            (add-after 'install 'copy-wine32-binaries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let ((out (assoc-ref %outputs "out")))
                  ;; Copy the 32-bit binaries needed for WoW64.
                  (copy-file (search-input-file inputs "/bin/wine")
                             (string-append out "/bin/wine"))
                  ;; Copy the real 32-bit wine-preloader instead of the wrapped
                  ;; version.
                  (copy-file (search-input-file inputs "/bin/.wine-preloader-real")
                             (string-append out "/bin/wine-preloader")))))
            (add-after 'install 'copy-wine32-libraries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  (copy-recursively (search-input-directory inputs "/lib/wine32")
                                    (string-append out "/lib/wine32")))))
            (add-after 'compress-documentation 'copy-wine32-manpage
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  ;; Copy the missing man file for the wine binary from wine.
                  (copy-file (search-input-file inputs "/share/man/man1/wine.1.gz")
                             (string-append out "/share/man/man1/wine.1.gz")))))))
       ((#:configure-flags configure-flags '())
        #~(cons "--enable-win64" #$configure-flags))))
    (synopsis "Implementation of the Windows API (WoW64 version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))

(define-public wine-staging-patchset-data
  (package
    (name "wine-staging-patchset-data")
    (version "9.13")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/wine-staging/wine-staging")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0p3nqas9qvh5fz2cwykhvr56n3z5vvbn0yssjjqhvx80sk9q7mgn"))))
    (build-system trivial-build-system)
    (native-inputs
     (list coreutils))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((build-directory ,(string-append name "-" version))
                (source (assoc-ref %build-inputs "source"))
                (coreutils (assoc-ref %build-inputs "coreutils"))
                (out (assoc-ref %outputs "out"))
                (wine-staging (string-append out "/share/wine-staging")))
           (copy-recursively source build-directory)
           (with-directory-excursion build-directory
             (substitute* '("patches/gitapply.sh" "staging/patchinstall.py")
               (("/usr/bin/env")
                (string-append coreutils "/bin/env"))))
           (copy-recursively build-directory wine-staging)
           #t))))
    (home-page "https://github.com/wine-staging")
    (synopsis "Patchset for Wine")
    (description
     "wine-staging-patchset-data contains the patchset to build Wine-Staging.")
    (license license:lgpl2.1+)))

(define-public wine-staging
  (package
    (inherit wine)
    (name "wine-staging")
    (version (package-version wine-staging-patchset-data))
    (source
     (let* ((wine-version (version-major+minor version))
            (subdirectory (string-append
                           (version-major version)
                           (if (string-suffix? ".0" wine-version)
                               ".0"
                               ".x"))))
       (origin
         (method url-fetch)
         (uri (string-append "https://dl.winehq.org/wine/source/"
                             subdirectory "/"
                             "wine-" wine-version ".tar.xz"))
         (file-name (string-append name "-" wine-version ".tar.xz"))
         (sha256
          (base32 "0j3kpxx4hv9x42zrxqkrb49gqby007q4bqyrrf2gxpiqzv8535np")))))
    (inputs (modify-inputs (package-inputs wine)
              (prepend autoconf ; for autoreconf
                       ffmpeg
                       gtk+
                       libva
                       mesa
                       python
                       util-linux ; for hexdump
                       wine-staging-patchset-data)))
    (native-inputs
     (modify-inputs (package-native-inputs wine)
       (prepend python-3)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, 32-bit only)")
    (description "Wine-Staging is the testing area of Wine.  It
contains bug fixes and features, which have not been integrated into
the development branch yet.  The idea of Wine-Staging is to provide
experimental features faster to end users and to give developers the
possibility to discuss and improve their patches before they are
integrated into the main branch.")
    (home-page "https://github.com/wine-staging")
    ;; In addition to the regular Wine license (lgpl2.1+), Wine-Staging
    ;; provides Liberation and WenQuanYi Micro Hei fonts.  Those use
    ;; different licenses.  In particular, the latter is licensed under
    ;; both GPL3+ and Apache 2 License.
    (license
     (list license:lgpl2.1+ license:silofl1.1 license:gpl3+ license:asl2.0))))

(define-public wine64-staging
  (package
    (inherit wine-staging)
    (name "wine64-staging")
    (inputs (modify-inputs (package-inputs wine-staging)
              (prepend wine-staging)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine64)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, WoW64
version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))

(define-public winetricks
  (package
    (name "winetricks")
    (version "20240105")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/Winetricks/winetricks")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "15glm6ws0zihcks93l39mli8wf5b5vkijb0vaid9cqra6x0zppd5"))))
    (build-system gnu-build-system)
    (inputs
     `(("cabextract" ,cabextract)
       ("p7zip" ,p7zip)
       ("perl" ,perl)
       ;; ("unrar" ,unrar) ; TODO: Include unrar?  It is referenced in the source.
       ("unzip" ,unzip)
       ("wget" ,wget)
       ("zenity" ,zenity)))
    (arguments
     `(#:tests? #f
       ;; TODO: Checks need bashate, shellcheck (in Guix), and checkbashisms.
       #:make-flags (list (string-append "DESTDIR=" (assoc-ref %outputs "out"))
                          "PREFIX=")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'install 'wrap-program
           ;; The script relies on WINETRICKS_GUI being exactly "zenity", so
           ;; we can't patch the path directly.  Probably same for other dependencies.
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((zenity-bin (string-append (assoc-ref inputs "zenity") "/bin/"))
                    (perl-bin (string-append (assoc-ref inputs "perl") "/bin/"))
                    (winetricks (string-append (assoc-ref outputs "out")
                                               "/bin/winetricks")))
               (wrap-program winetricks
                 `("PATH" prefix (,@(map (lambda (in)
                                           (string-append (assoc-ref inputs in) "/bin/"))
                                         '("cabextract"
                                           "p7zip"
                                           "perl"
                                           "unzip"
                                           "wget"
                                           "zenity"))))))))
         (add-after 'install 'patch-perl-path
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((perl (string-append (assoc-ref inputs "perl") "/bin/perl"))
                    (winetricks (string-append (assoc-ref outputs "out")
                                               "/bin/winetricks")))
               (substitute* winetricks
                 (("#!/usr/bin/env perl") (string-append "#!" perl)))))))))
    (home-page "https://github.com/Winetricks/winetricks")
    (synopsis "Easy way to work around problems in Wine")
    (description "Winetricks is an easy way to work around problems in Wine.
It has a menu of supported games/apps for which it can do all the workarounds
automatically.  It also allows the installation of missing nonfree DLLs and
tweaking of various Wine settings.")
    (license license:lgpl2.1)))

;; Upstream Guix dxvk does not build anymore because of missing mingw compiler.
(define-public dxvk-1.7 ; TODO: Can we remove this in favour of `dxvk' without breaking `guix pull'?
  (package
    (name "dxvk")
    (version "1.7.3")
    (home-page "https://github.com/doitsujin/dxvk/")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/doitsujin/dxvk/releases/download/v"
                    version "/dxvk-" version ".tar.gz") )
              (sha256
               (base32
                "185b80h7l62nv8k9rp32fkn00aglwcw9ccm6bx2n7bdpar149hp4"))))
    (build-system copy-build-system)
    (arguments
     `(#:install-plan
       `(,@,(if (string=? (or (%current-target-system) (%current-system))
                          "x86_64-linux")
                '(list '("x64" "share/dxvk/lib"))
                ''())
         ("x32" ,,(if (string=? (or (%current-target-system) (%current-system))
                                "i686-linux")
                       "share/dxvk/lib"
                       "share/dxvk/lib32"))
         ("setup_dxvk.sh" "bin/setup_dxvk"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'fix-setup
           (lambda* (#:key inputs outputs system #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (libs "../share/dxvk")
                    (wine (assoc-ref inputs "wine")))
               (substitute* (string-append out "/bin/setup_dxvk")
                 (("wine=\"wine\"")
                  (string-append "wine=" wine "/bin/wine"))
                 (("wine64=\"wine64\"")
                  (string-append "wine64=" wine "/bin/wine64"))
                 (("wineboot=\"wineboot\"")
                  (string-append "wineboot=" wine "/bin/wineboot"))
                 (("\"\\$wine_path/\\$wine\"")
                  "\"$wine_path/wine\"")
                 (("x32") (if (string=? system "x86_64-linux")
                              (string-append libs "/lib32")
                              (string-append libs "/lib")))
                 (("x64") (string-append libs "/lib")))))))))
    (inputs
     `(("wine" ,(match (or (%current-target-system)
                           (%current-system))
                  ("x86_64-linux" wine64-staging)
                  (_ wine-staging)))))
    (synopsis "Vulkan-based D3D9, D3D10 and D3D11 implementation for Wine")
    (description "A Vulkan-based translation layer for Direct3D 9/10/11 which
allows running complex 3D applications with high performance using Wine.

Use @command{setup_dxvk} to install the required libraries to a Wine prefix.")
    (supported-systems '("i686-linux" "x86_64-linux"))
    (license license:zlib)))

(define-public dxvk-next
  (package
    (name "dxvk")
    (version "2.4")
    (home-page "https://github.com/doitsujin/dxvk/")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/doitsujin/dxvk/releases/download/v"
                    version "/dxvk-" version ".tar.gz") )
              (sha256
               (base32
                "0xr4lq4zdmqwxh5x19am2y4lvy6q6s6bl1nfr4ixfgy2l2sghliq"))))
    (build-system copy-build-system)
    (arguments
     `(#:install-plan
       `(,@,(if (string=? (or (%current-target-system) (%current-system))
                          "x86_64-linux")
                '(list '("x64" "share/dxvk/lib"))
                ''())
         ("x32" ,,(if (string=? (or (%current-target-system) (%current-system))
                                "i686-linux")
                       "share/dxvk/lib"
                       "share/dxvk/lib32"))
         ("setup_dxvk.sh" "bin/setup_dxvk"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'fix-setup
           (lambda* (#:key inputs outputs system #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (libs "../share/dxvk")
                    (wine (assoc-ref inputs "wine")))
               (substitute* (string-append out "/bin/setup_dxvk")
                 (("wine=\"wine\"")
                  (string-append "wine=" wine "/bin/wine"))
                 (("wine64=\"wine64\"")
                  (string-append "wine64=" wine "/bin/wine64"))
                 (("wineboot=\"wineboot\"")
                  (string-append "wineboot=" wine "/bin/wineboot"))
                 (("\"\\$wine_path/\\$wine\"")
                  "\"$wine_path/wine\"")
                 (("x32") (if (string=? system "x86_64-linux")
                              (string-append libs "/lib32")
                              (string-append libs "/lib")))
                 (("x64") (string-append libs "/lib")))))))))
    (inputs
     `(("wine" ,(match (or (%current-target-system)
                           (%current-system))
                  ("x86_64-linux" wine64-staging)
                  (_ wine-staging)))))
    (synopsis "Vulkan-based D3D9, D3D10 and D3D11 implementation for Wine")
    (description "A Vulkan-based translation layer for Direct3D 9/10/11 which
allows running complex 3D applications with high performance using Wine.

Use @command{setup_dxvk} to install the required libraries to a Wine prefix.")
    (supported-systems '("i686-linux" "x86_64-linux"))
    (license license:zlib)))

;; Keep 1.10 since it's backward-compatible with older hardware unlike 2.*
;; See https://github.com/doitsujin/dxvk/releases/tag/v2.0
(define-public dxvk-1.10
  (package
    (inherit dxvk-1.7)
    (version "1.10.3")
    (home-page "https://github.com/doitsujin/dxvk/")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/doitsujin/dxvk/releases/download/v"
                    version "/dxvk-" version ".tar.gz"))
              (sha256
               (base32
                "1ijkznb8asqg18blhs6f82g67xpncjp7i17rg7451d314y8kq6ld"))))))

wine64
