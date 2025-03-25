(define-module (giaox packages xdg-desktop-portal-lxqt)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages lxqt)
  #:use-module (gnu packages lxde)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages freedesktop))

(define-public xdg-desktop-portal-lxqt
  (package
    (name "xdg-desktop-portal-lxqt")
    (version "1.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/lxqt/xdg-desktop-portal-lxqt")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0pbbych38f5g9451injx0iha6gxia3plk3gf00zlfi78a9x3m0mq"))))
    (build-system cmake-build-system)
    (arguments
     '(#:tests? #f))
    (inputs
     (list kwindowsystem
           libexif
           libfm-qt
           lxqt-qtplugin
           menu-cache
           qtbase
           xdg-desktop-portal))
    (native-inputs
     (list pkg-config
           lxqt-build-tools))
    (home-page "https://github.com/lxqt/xdg-desktop-portal-lxqt")
    (synopsis "Backend implementation for xdg-desktop-portal using Qt/KF5/libfm-qt")
    (description "This package provides a backend implementation for
xdg-desktop-portal that is using Qt/KF5/libfm-qt.")
    (license lgpl2.1+)))

xdg-desktop-portal-lxqt
