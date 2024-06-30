(define-module (giaox packages gamemode)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system meson)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux))

(define-public gamemode
  (package
    (name "gamemode")
    (version "1.8.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/FeralInteractive/gamemode")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0760brj8iy2ls6gycww7v7fc1f44nzanb6yiacvq1if6r7kipswj"))))
    (build-system meson-build-system)
    (arguments
     `(#:configure-flags
       (list
        "-Dwith-sd-bus-provider=no-daemon"
        "-Dwith-examples=false"
        "-Dwith-util=true"
        "-Dwith-systemd-user-unit=false")
       #:tests? #f)) ; https://github.com/FeralInteractive/gamemode/issues/468
    (native-inputs
     (list pkg-config))
    (inputs
     (list dbus libinih))
    (home-page "https://github.com/FeralInteractive/gamemode")
    (synopsis "Optimise Linux system performance on demand")
    (description
     "Gamemode is a daemon/lib combo for Linux that allows games to request
a set of optimisations be temporarily applied to the host OS. This package
is built without systemd support.")
    (license license:bsd-3)))

gamemode
