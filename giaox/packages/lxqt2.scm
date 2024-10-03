;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015, 2022 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2016 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2016, 2023 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2017 Nikita <nikita@n0.is>
;;; Copyright © 2018, 2019 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018, 2019 Meiyo Peng <meiyo@riseup.net>
;;; Copyright © 2018 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2019, 2020 Reza Alizadeh Majd <r.majd@pantherx.org>
;;; Copyright © 2020 Fakhri Sajadi <f.sajadi@pantherx.org>
;;; Copyright © 2020 André Batista <nandre@riseup.net>
;;; Copyright © 2021, 2022 Brendan Tildesley <mail@brendan.scot>
;;; Copyright © 2024 Zheng Junjie <873216071@qq.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (giaox packages lxqt2)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages compton)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages kde-plasma)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages lxde)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages openbox)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))


;; Third party libraries

(define-public libstatgrab
  (package
    (name "libstatgrab")
    (version "0.92.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://ftp.i-scream.org/pub/i-scream/libstatgrab/"
                           name "-" version ".tar.gz"))
       (sha256
        (base32 "04bcbln3qlilxsyh5hrwdrv7x4pfv2lkwdwa98bxfismd15am22n"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("--enable-tests"
                           "--disable-static")))
    (native-inputs
     ;; For testing.
     (list perl))
    (home-page "https://www.i-scream.org/libstatgrab/")
    (synopsis "Provides access to statistics about the system")
    (description "libstatgrab is a library that provides cross platform access
to statistics about the system on which it's run.")
    ;; Libraries are under LGPL2.1+, and programs under GPLv2+.
    (license license:gpl2+)))


;; Base

(define-public lxqt2-build-tools
  (package
    (name "lxqt2-build-tools")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/lxqt-build-tools/releases"
                           "/download/" version
                           "/lxqt-build-tools-" version ".tar.xz"))
       (sha256
        (base32 "01vz9vsmc0cvb6aapz6snhgyrckyzgip5dk23swhnpmk3myw96a5"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f  ; No test suite
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'install-custom-vars
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (lxqt-cmake-modules (string-append out "/share/cmake/lxqt2-build-tools/modules"))
                    (vars-file (string-append lxqt-cmake-modules "/LXQtConfigVars.cmake")))
               (mkdir-p lxqt-cmake-modules)
               (call-with-output-file vars-file
                 (lambda (port)
                   (format port "~
set(LXQT_SHARE_DIR \"${CMAKE_INSTALL_PREFIX}/share/lxqt\")
set(LXQT_TRANSLATIONS_DIR \"${CMAKE_INSTALL_PREFIX}/share/lxqt/translations\")
set(LXQT_ETC_XDG_DIR \"${CMAKE_INSTALL_PREFIX}/etc/xdg\")
set(LXQT_DATA_DIR \"${CMAKE_INSTALL_PREFIX}/share\")
set(POLKITQT-1_POLICY_FILES_INSTALL_DIR \"${CMAKE_INSTALL_PREFIX}/share/polkit-1/actions\")

# Ensure no absolute paths in the build system
string(REGEX REPLACE \"^${CMAKE_INSTALL_PREFIX}/\" \"\" LXQT_RELATIVE_SHARE_DIR \"${LXQT_SHARE_DIR}\")
string(REGEX REPLACE \"^${CMAKE_INSTALL_PREFIX}/\" \"\" LXQT_RELATIVE_TRANSLATIONS_DIR \"${LXQT_TRANSLATIONS_DIR}\")

# Add definitions
add_definitions(\"-DLXQT_SHARE_DIR=\\\"${LXQT_SHARE_DIR}\\\"\")
add_definitions(\"-DLXQT_TRANSLATIONS_DIR=\\\"${LXQT_TRANSLATIONS_DIR}\\\"\")
add_definitions(\"-DLXQT_ETC_XDG_DIR=\\\"${LXQT_ETC_XDG_DIR}\\\"\")
")))))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list qtbase glib))
    (propagated-inputs
     (list perl))
    (home-page "https://lxqt-project.org")
    (synopsis "LXQt build tools")
    (description "Lxqt-build-tools is providing several tools needed to build LXQt
itself as well as other components maintained by the LXQt project.")
    (license license:lgpl2.1+)))

(define-public libqtxdg
  (package
    (name "libqtxdg")
    (version "4.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/lxqt/libqtxdg/releases/download/"
             version "/libqtxdg-" version ".tar.xz"))
       (sha256
        (base32 "0qkblr3mlqbmzn1k5b45kirbbds9ybk3w88w8pxy3chlx46ja6wc"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f                    ; No test target
       #:configure-flags
       (list
        "-DBUILD_TESTS=OFF"
        "-DCMAKE_INSTALL_INCLUDEDIR=include"
        "-DCMAKE_INSTALL_LIBDIR=lib"
        (string-append "-DQTXDGX_ICONENGINEPLUGIN_INSTALL_PATH="
                       %output "/lib/qt6/plugins/iconengines")
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules"))))
    (inputs
     (list qtbase qtsvg glib))
    (native-inputs
     (list pkg-config lxqt2-build-tools))
    (home-page "https://github.com/lxqt/libqtxdg")
    (synopsis "Qt implementation of freedesktop.org xdg specifications")
    (description "Libqtxdg implements the freedesktop.org xdg specifications
in Qt.")
    (license license:lgpl2.1+)))

(define-public qtxdg-tools
  (package
    (name "qtxdg-tools")
    (version "4.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/lxqt/qtxdg-tools/releases/download/"
             version "/qtxdg-tools-" version ".tar.xz"))
       (sha256
        (base32 "0fkvw8f8gvxcwkajwryck3amxzhgkzdhbxj2fafxk402g3i8bm2c"))))
    (build-system cmake-build-system)
    (arguments '(#:tests? #f))          ; no tests
    (inputs (list qtbase qtsvg))
    (propagated-inputs (list libqtxdg))
    (native-inputs (list lxqt2-build-tools))
    (home-page "https://github.com/lxqt/qtxdg-tools")
    (synopsis "User tools for libqtxdg")
    (description "This package contains a CLI MIME tool, @command{qtxdg-mat},
for handling file associations and opening files with their default
applications.")
    (license license:lgpl2.1+)))

(define-public liblxqt
  (package
    (name "liblxqt")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/lxqt/" name "/releases/download/"
             version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "1r5k0zdw07xn5l2ixbh93a562zhm7w7maa5kpb4rsxkb2ib2a2b1"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f  ; No tests available
       #:configure-flags
       (list
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules")
        (string-append "-DQt6_DIR="
                       (assoc-ref %build-inputs "qtbase")
                       "/lib/cmake/Qt6")
        "-DLXQT_LIBRARY_NAME=lxqt")  ; Ensure the correct library name is set
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda _
             (substitute* "CMakeLists.txt"
               ;; Ensure KF6WindowSystem is found correctly
               (("find_package\\(KF6WindowSystem.*\\)")
                "find_package(KF6WindowSystem ${KF6_MINIMUM_VERSION} REQUIRED COMPONENTS WindowSystem)")
               ;; Update target_link_libraries to use the LXQT_LIBRARY_NAME variable
               (("target_link_libraries\\(\\$\\{LXQT_LIBRARY_NAME\\}")
                "target_link_libraries(${LXQT_LIBRARY_NAME}"))
             #t)))))
    (inputs
     (list kwindowsystem
           libqtxdg
           libxscrnsaver
           polkit-qt6
           qtbase
           qtsvg))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (home-page "https://lxqt-project.org")
    (synopsis "Core utility library for all LXQt components")
    (description "liblxqt provides the basic libraries shared by the
components of the LXQt desktop environment.")
    (license license:lgpl2.1+)))

(define-public libsysstat
  (package
    (name "libsysstat")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0d848v6w9d1cf60h2rlmk550xx55nw8ryqxmz9c2p9br5qz5x6zp"))))
    (build-system cmake-build-system)
    (arguments '(#:tests? #f))          ; no tests
    (inputs
     (list qtbase))
    (native-inputs
     (list lxqt2-build-tools))
    (home-page "https://lxqt-project.org")
    (synopsis "Library used to query system info and statistics")
    (description "libsysstat is a library to query system information like CPU
and memory usage or network traffic.")
    (license license:lgpl2.1+)))

(define-public libdbusmenu-lxqt
  (package
    (name "libdbusmenu-lxqt")
    (version "0.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/lxqt/libdbusmenu-lxqt")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0j9nci0h80pdmbn5sp1mn7naqdi8srrsikns3ix642ldmm9jy1kz"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f  ; Assume no tests, adjust if needed
       #:configure-flags
       (list
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules")
        (string-append "-DQt6_DIR="
                       (assoc-ref %build-inputs "qtbase")
                       "/lib/cmake/Qt6"))))
    (native-inputs
     (list pkg-config lxqt2-build-tools))
    (inputs
     (list qtbase))
    (home-page "https://github.com/lxqt/libdbusmenu-lxqt")
    (synopsis "Qt implementation of the DBusMenu protocol for LXQt")
    (description "This library provides a Qt implementation of the DBusMenu
protocol for the LXQt desktop environment.  The DBusMenu protocol makes it
possible for applications to export and import their menus over DBus.")
    (license license:lgpl2.1+)))

;; Core

(define-public lxqt-about
  (package
    (name "lxqt-about")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0iw2rxsx47ilcppfys9zlk66n7f9zaxskfq6riyp77yh0z0rck0k"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f                      ; no tests
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'setenv
           (lambda _
             (setenv "QT_RCC_SOURCE_DATE_OVERRIDE" "1")
             #t)))))
    (home-page "https://lxqt-project.org")
    (synopsis "Provides information about LXQt and the system")
    (description "lxqt-about is a dialogue window providing information about
LXQt and the system it's running on.")
    (license license:lgpl2.1+)))

(define-public lxqt-admin
  (package
    (name "lxqt-admin")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0jvlahbfbys6b17q6zfg7cq2vz2cx6bk9wlpaqk0waa1zll61ma1"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           polkit-qt6
           qtbase
           qtsvg))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (arguments
     `(#:tests? #f                      ; no tests
       #:configure-flags
       (list
         (string-append "-DCMAKE_MODULE_PATH="
                        (assoc-ref %build-inputs "lxqt2-build-tools")
                        "/share/cmake/lxqt2-build-tools/modules")
         (string-append "-DQt6_DIR="
                        (assoc-ref %build-inputs "qtbase")
                        "/lib/cmake/Qt6"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda _
             (substitute* '("lxqt-admin-user/CMakeLists.txt"
                            "lxqt-admin-time/CMakeLists.txt")
               (("DESTINATION \"\\$\\{POLKITQT-1_POLICY_FILES_INSTALL_DIR\\}")
                "DESTINATION \"share/polkit-1/actions"))
             #t)))))
    (home-page "https://lxqt-project.org")
    (synopsis "LXQt system administration tool")
    (description "lxqt-admin is providing two GUI tools to adjust settings of
the operating system LXQt is running on.")
    (license license:lgpl2.1+)))

(define-public lxqt-config
  (package
    (name "lxqt-config")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0wxcqkq0bsnj18lradd7x9r249z02zhv4rlydrnjywvz2wg4l789"))))
    (build-system cmake-build-system)
    (inputs
     (list eudev
           kwindowsystem
           liblxqt
           libqtxdg
           libxcursor
           libxi
           qtbase
           qtsvg
           qtx11extras
           solid
           xf86-input-libinput
           xkeyboard-config
           zlib
           lxqt-menu-data))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    ;; XXX: This is a workaround so libkscreen can find the backends as we
    ;; dont have a way specify them. We may want to  patch like Nix does.
    (propagated-inputs
     (list libkscreen))
    (arguments
     '(#:tests? #f                      ; no tests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-xkeyboard-config-file-name
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Set the file name to xkeyboard-config.
             (let ((xkb (assoc-ref inputs "xkeyboard-config")))
               (substitute* "lxqt-config-input/keyboardlayoutconfig.h"
                 (("/usr/share/X11/xkb/rules/base.lst")
                  (string-append xkb "/share/X11/xkb/rules/base.lst")))
               #t))))))
    (home-page "https://lxqt-project.org")
    (synopsis "Tools to configure LXQt and the underlying operating system")
    (description "lxqt-config is providing several tools involved in the
configuration of both LXQt and the underlying operating system.")
    (license license:lgpl2.1+)))

(define-public lxqt-globalkeys
  (package
    (name "lxqt-globalkeys")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/lxqt-globalkeys/"
                           "releases/download/" version "/"
                           "lxqt-globalkeys-" version ".tar.xz"))
       (sha256
        (base32 "1xs3mzkrg2qcqilmfa60zdqvjzi8xmwkrqcabnv402l9hqkagrqk"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras))
    (native-inputs
     (list pkg-config qttools lxqt2-build-tools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Daemon used to register global keyboard shortcuts")
    (description "lxqt-globalkeys is providing tools to set global keyboard
shortcuts in LXQt sessions, that is shortcuts which apply to the LXQt session
as a whole and are not limited to distinct applications.")
    (license license:lgpl2.1+)))

(define-public lxqt-notificationd
  (package
    (name "lxqt-notificationd")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "1v1a4s2a21j45sh9qxxy6r2vya01s1ccckmfnikljxr530i6cqzn"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras
           layer-shell-qt))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments '(#:tests? #f))          ; no test target
    (home-page "https://lxqt-project.org")
    (synopsis "The LXQt notification daemon")
    (description "lxqt-notificationd is LXQt's implementation of a daemon
according to the Desktop Notifications Specification.")
    (license license:lgpl2.1+)))

(define-public lxqt-openssh-askpass
  (package
    (name "lxqt-openssh-askpass")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0pxbfkag0sl58zr4ijlangig102lazxq2agr757sf4x58ik3zbb8"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "GUI to query passwords on behalf of SSH agents")
    (description "lxqt-openssh-askpass is a GUI to query credentials on behalf
of other programs.")
    (license license:lgpl2.1+)))

(define-public lxqt-panel
  (package
    (name "lxqt-panel")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "01wllnk4v5kq996cyqha62sf0smhifx5czlbjn76yj8iwhv3qj3k"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f
       #:configure-flags
       (list
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules")
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
        "-DCMAKE_VERBOSE_MAKEFILE=ON"
        "-DBUILD_SHARED_LIBS=ON"
        "-DSTATUSNOTIFIER_PLUGIN=OFF"
        "-DTRAY_PLUGIN=OFF"
        "-DKBINDICATOR_PLUGIN=OFF")
       #:make-flags
       (list "VERBOSE=1"
             "-j4"
             (string-append "LDFLAGS=-Wl,-rpath="
                            (assoc-ref %outputs "out") "/lib/lxqt-panel")
             "CXXFLAGS=-fPIC")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((xkb (assoc-ref inputs "xkeyboard-config")))
               (substitute* "plugin-kbindicator/src/x11/kbdlayout.cpp"
                 (("/usr/share/X11/xkb/rules/evdev.xml")
                  (string-append xkb "/share/X11/xkb/rules/evdev.xml"))))))
         (add-before 'configure 'set-qt-environment
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "QT_PLUGIN_PATH"
                     (string-append
                      (assoc-ref inputs "qtbase") "/lib/qt6/plugins:"
                      (assoc-ref inputs "qtwayland") "/lib/qt6/plugins:"
                      (assoc-ref inputs "libdbusmenu-lxqt") "/lib/qt6/plugins"))
             (setenv "QT_SELECT" "6"))))))
    (inputs
     (list alsa-lib
           kguiaddons
           kwindowsystem
           libdbusmenu-lxqt
           liblxqt
           libqtxdg
           libstatgrab
           libsysstat
           libxcomposite
           libxdamage
           libxdmcp
           libxkbcommon
           libxrender
           libxtst
           `(,lm-sensors "lib")
           lxqt-globalkeys
           lxqt-menu-data
           menu-cache
           pcre
           pulseaudio
           qtbase
           qtsvg
           qtwayland
           solid
           xcb-util
           xcb-util-image
           xkeyboard-config
           layer-shell-qt))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (propagated-inputs
     (list kwindowsystem))
    (home-page "https://lxqt-project.org")
    (synopsis "The LXQt desktop panel")
    (description "lxqt-panel represents the taskbar of LXQt.")
    (license license:lgpl2.1+)))

(define-public lxqt-policykit
  (package
    (name "lxqt-policykit")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "125w8cp529scrs66x3ibkfzrq0lwx88vw3gk06jss3c6dhwyzhj5"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           pcre
           polkit-qt6
           qtbase
           qtsvg
           qtx11extras))
    (native-inputs
     (list pkg-config polkit lxqt2-build-tools qttools))
    (arguments '(#:tests? #f))          ; no test target
    (home-page "https://lxqt-project.org")
    (synopsis "The LXQt PolicyKit agent")
    (description "lxqt-policykit is the polkit authentication agent of
LXQt.")
    (license license:lgpl2.1+)))

(define-public lxqt-powermanagement
  (package
    (name "lxqt-powermanagement")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "03hb0nl0fjsd32chcrb4zfihrcvspkfjwivapmbqpmqzzm84s31h"))))
    (build-system cmake-build-system)
    (inputs
     (list kidletime
           kwindowsystem
           liblxqt
           libqtxdg
           lxqt-globalkeys
           qtbase
           qtsvg
           qtx11extras
           solid))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Power management module for LXQt")
    (description "lxqt-powermanagement is providing tools to monitor power
management events and optionally trigger actions like e. g. shut down a system
when laptop batteries are low on power.")
    (license license:lgpl2.1+)))

(define-public lxqt-qtplugin
  (package
    (name "lxqt-qtplugin")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "13jx4k5k88ikis3fqzxrsrv3qkw24hifwbxz7wxiwpanmp7n75fd"))))
    (build-system cmake-build-system)
    (inputs
     (list libdbusmenu-lxqt
           libfm-qt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f                      ; no tests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda _
             (substitute* '("src/CMakeLists.txt")
               (("DESTINATION \"\\$\\{QT_PLUGINS_DIR\\}")
                "DESTINATION \"lib/qt5/plugins"))
             #t)))))
    (home-page "https://lxqt-project.org")
    (synopsis "LXQt Qt platform integration plugin")
    (description "lxqt-qtplugin is providing a library libqtlxqt to integrate
Qt with LXQt.")
    (license license:lgpl2.1+)))

(define-public lxqt-runner
  (package
    (name "lxqt-runner")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "174lks9adsjrr6x5a8fgsy0mw71l8ivs4mlv5hxiqk9hh3bk304z"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           lxqt-globalkeys
           muparser
           pcre
           qtbase
           qtsvg
           qtx11extras
           layer-shell-qt))
    (native-inputs
     (list pkg-config qttools lxqt2-build-tools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Tool used to launch programs quickly by typing their names")
    (description "lxqt-runner provides a GUI that comes up on the desktop and
allows for launching applications or shutting down the system.")
    (license license:lgpl2.1+)))

(define-public lxqt-session
  (package
    (name "lxqt-session")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0a5lbik9fwsg50qxvkzpx7yjiw8v3b1m56dhp0s0idgciyckpskl"))))
    (build-system cmake-build-system)
    (inputs
     (list bash-minimal
           eudev
           kwindowsystem
           liblxqt
           qtxdg-tools
           procps
           qtbase
           qtsvg
           qtx11extras
           xdg-user-dirs
           layer-shell-qt))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (substitute* '("xsession/lxqt.desktop.in")
                 (("Exec=startlxqt") (string-append "Exec=" out "/bin/startlxqt"))
                 (("TryExec=lxqt-session") (string-append "TryExec=" out "/bin/startlxqt"))))))

         (add-after 'unpack 'patch-openbox-permission
           (lambda _
             (substitute* "startlxqt.in"
               ;; Don't add 'etc/xdg' to XDG_CONFIG_DIRS, and 'share' to XDG_DATA_DIRS.
               (("! contains .*;") "false;")
               ;; Add write permission to lxqt-rc.xml file which is stored as
               ;; read-only in store.
               (("cp \"\\$LXQT_DEFAULT_OPENBOX_CONFIG\" \"\\$XDG_CONFIG_HOME/openbox\"")
                 (string-append "cp \"$LXQT_DEFAULT_OPENBOX_CONFIG\" \"$XDG_CONFIG_HOME/openbox\"\n"
                                "        # fix openbox permission issue\n"
                                "        chmod u+w  \"$XDG_CONFIG_HOME/openbox\"/*"))))))))
    (native-search-paths
     (list (search-path-specification
            ;; LXQt applications install their default config files into
            ;; 'share/lxqt' and search them from XDG_CONFIG_DIRS/lxqt.
            (variable "XDG_CONFIG_DIRS")
            (files '("share")))))
    (home-page "https://lxqt-project.org")
    (synopsis "Session manager for LXQt")
    (description "lxqt-session provides the standard session manager
for the LXQt desktop environment.")
    (license license:lgpl2.1+)))

(define-public lxqt-sudo
  (package
    (name "lxqt-sudo")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "05fjan4zdqax5i7zx2s75pm56ii06vdqrnv2v3ic4kfj4d3i75ga"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           liblxqt
           libqtxdg
           qtbase
           qtsvg
           qtx11extras
           sudo))
    (native-inputs
     (list pkg-config qttools lxqt2-build-tools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "GUI frontend for sudo/su")
    (description "lxqt-sudo is a graphical front-end of commands sudo and su
respectively.  As such it enables regular users to launch applications with
permissions of other users including root.")
    (license license:lgpl2.1+)))

(define-public lxqt-themes
  (package
    (name "lxqt-themes")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "07cifvgc24c3hsj7r7lyp4lx691ay5x2f878j558qwfgisys0ylj"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f                      ; no tests
       #:configure-flags
       (list
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules")
        "-DLXQT_SHARE_DIR=share/lxqt")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-cmake-files
           (lambda _
             (substitute* "CMakeLists.txt"
               (("install\\((.*)\\)" all content)
                (string-append "install(" content " DESTINATION ${LXQT_SHARE_DIR})"))))))))
    (native-inputs
     (list lxqt2-build-tools))
    (home-page "https://lxqt-project.org")
    (synopsis "Themes, graphics and icons for LXQt")
    (description "This package comprises a number of graphic files and themes
for LXQt.")
    (license license:lgpl2.1+)))


;; File Manager

(define-public libfm-qt
  (package
    (name "libfm-qt")
    (version "2.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0m97vjys2ibdmz376qviil90y0xsgzadwlwr7084vws9spby26j1"))))
    (build-system cmake-build-system)
    (arguments
     '(#:tests? #f))                    ; no tests
    (inputs
     (list glib
           libexif
           libfm
           libxcb
           menu-cache
           lxqt-menu-data
           pcre
           qtbase
           qtx11extras))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (home-page "https://lxqt-project.org")
    (synopsis "Qt binding for libfm")
    (description "libfm-qt is the Qt port of libfm, a library providing
components to build desktop file managers which belongs to LXDE.")
    (license license:lgpl2.1+)))

(define-public pcmanfm-qt
  (package
    (name "pcmanfm-qt")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "10yccd5pnpdbmrjbzzvh9k3yhiwkyr9p96vxi1vnz0hfkyhmhy8n"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ; no tests
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'patch-settings.conf.in
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((wallpaper (search-input-file inputs
                                "share/lxqt/wallpapers/waves-logo.png")))
               (substitute* "config/pcmanfm-qt/lxqt/settings.conf.in"
                 (("Wallpaper=.*")
                  (string-append "Wallpaper=" wallpaper "\n")))))))))
    (inputs
     (list libfm-qt qtbase qtx11extras lxqt-themes layer-shell-qt))
    (native-inputs
     (list pkg-config qttools lxqt2-build-tools))
    (home-page "https://lxqt-project.org")
    (synopsis "File manager and desktop icon manager")
    (description "PCManFM-Qt is the Qt port of PCManFM, the file manager of
LXDE.")
    (license license:gpl2+)))


;; Extra

(define-public compton-conf
  (package
    (name "compton-conf")
    (version "0.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0haarzhndjp0wndfhcdy6zl2whpdn3w0qzr3rr137kfqibc58lvx"))))
    (build-system cmake-build-system)
    (inputs
     (list libconfig qtbase))
    (native-inputs
     (list lxqt2-build-tools pkg-config qttools))
    (arguments '(#:tests? #f))          ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "GUI configuration tool for compton X composite manager")
    (description "@code{compton-conf} is a configuration tool for X composite
manager Compton.")
    (license license:lgpl2.1+)))

(define-public lximage-qt
  (package
    (name "lximage-qt")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "13hgqjbi030rcx2axqs0515xpv8s07g21y34wfms7kaq9yqkpjjm"))))
    (build-system cmake-build-system)
    (inputs
     (list libexif libfm-qt qtbase qtsvg qtx11extras))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "The image viewer and screenshot tool for lxqt")
    (description "LXImage-Qt is the Qt port of LXImage, a simple and fast
image viewer.")
    (license license:gpl2+)))

(define-public obconf-qt
  (package
    (name "obconf-qt")
    (version "0.16.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "15x98xqarhzldimvyih9kds2fpvp6skp1s967vw2gr9sbvzr8zdk"))))
    (build-system cmake-build-system)
    (inputs
     (list imlib2
           libsm
           (librsvg-for-system)
           libxft
           libxml2
           openbox
           pango
           pcre
           qtbase
           qtx11extras))
    (native-inputs
     (list lxqt2-build-tools pkg-config qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Openbox configuration tool")
    (description "ObConf-Qt is a Qt port of ObConf, a configuration editor for
window manager OpenBox.")
    (license license:gpl2+)))

(define-public pavucontrol-qt
  (package
    (name "pavucontrol-qt")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0x84hf7di2362xhcjd0jnfm87sjcd2g48a2j2jw2njk1f5iw7kis"))))
    (build-system cmake-build-system)
    (inputs
     (list glib pcre pulseaudio qtbase qtx11extras))
    (native-inputs
     (list pkg-config lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Pulseaudio mixer in Qt")
    (description "@code{pavucontrol-qt} is the Qt port of volume control
@code{pavucontrol} of sound server @code{PulseAudio}.")
    (license license:gpl2+)))

(define-public qps
  (package
    (name "qps")
    (version "2.9.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "0wymnbswaav4dmmk249z8lgprh0j17krv6d6698m8l7x3qzj7mn7"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem
           libxrender
           liblxqt
           libqtxdg
           qtbase
           qtx11extras
           qtsvg))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Qt-based visual process status monitor")
    (description "@code{qps} is a monitor that displays the status of the
processes currently in existence, much like code{top} or code{ps}.")
    (license license:gpl2+)))

(define-public qtermwidget
  (package
    (name "qtermwidget")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "179px68frh82n6vcrih61nzcpjk6fbzv2zn3y0yzspj3yva6005m"))))
    (build-system cmake-build-system)
    (inputs
     (list qtbase utf8proc))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "The terminal widget for QTerminal")
    (description "QTermWidget is a terminal emulator widget for Qt 5.")
    (license license:gpl2+)))

(define-public qterminal
  (package
    (name "qterminal")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
       (sha256
        (base32 "1m6vla4w302zw5pxl1r801p9pwd17avvygxn9ci4kb1xl2x8w1xx"))))
    (build-system cmake-build-system)
    (inputs
     (list qtbase qtx11extras qtermwidget layer-shell-qt))
    (native-inputs
     (list lxqt2-build-tools qttools))
    (arguments
     '(#:tests? #f))                      ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Lightweight Qt-based terminal emulator")
    (description "QTerminal is a lightweight Qt terminal emulator based on
QTermWidget.")
    (license license:gpl2+)))

(define-public screengrab
  (package
    (name "screengrab")
    (version "2.8.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/screengrab/releases/download/"
                           version "/screengrab-" version ".tar.xz"))
       (sha256
        (base32 "1cx8gfn97vgn5ayzjw6dvvk7hlbdc95z44jmp8ddb7fl6kl6wr2c"))))
    (build-system cmake-build-system)
    (inputs
     (list kwindowsystem libqtxdg qtbase qtsvg qtx11extras))
    (native-inputs
     (list pkg-config perl qttools))
    (arguments
     '(#:tests? #f))                    ; no tests
    (home-page "https://lxqt-project.org")
    (synopsis "Crossplatform tool for fast making screenshots")
    (description "ScreenGrab is a program for fast creating screenshots, and
easily publishing them on internet image hosting services.")
    (license license:gpl2+)))


(define-public lxqt-archiver
  (package
    (name "lxqt-archiver")
    (version "1.0.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/lxqt/" name "/releases/download/"
                           version "/" name "-" version ".tar.xz"))
        (sha256
          (base32 "0qv5b4scq3zv4gvrd5gv343k32qm6ycx42vcfzc3ccm1nsfaylj1"))))
    (build-system cmake-build-system)
    (inputs
      (list glib json-glib libfm-qt qtbase qtx11extras))
    (native-inputs
      (list pkg-config lxqt2-build-tools qttools))
    (arguments
      '(#:tests? #f))
    (home-page "https://lxqt-project.org")
    (synopsis "Simple & lightweight desktop-agnostic Qt file archiver")
    (description
     "This package provides a Qt graphical interface to archiving programs
like @command{tar} and @command{zip}.")
    (license license:gpl2+)))

(define-public lxqt-connman-applet
  ;; since the main developers didn't release any version yet,  their
  ;; latest commit on `master` branch at the moment used for this version.
  (let ((commit "db1618d58fd3439142c4e44b24cba0dbb68b7141")
        (revision "0"))
    (package
      (name "lxqt-connman-applet")
      (version (git-version "0.15.0" revision commit))
      (source
        (origin
          (method git-fetch)
          (uri (git-reference
            (url (string-append "https://github.com/lxqt/" name))
            (commit commit)))
          (file-name (git-file-name name version))
          (sha256
           (base32 "087641idpg7n8yhh5biis4wv52ayw3rddirwqb34bf5fwj664pw9"))))
      (build-system cmake-build-system)
      (inputs
        (list kwindowsystem
              qtbase
              qtsvg
              liblxqt
              qtx11extras
              libqtxdg))
      (native-inputs
        `(("lxqt2-build-tools" ,lxqt2-build-tools)
          ("qtlinguist" ,qttools)))
      (arguments
        `(#:tests? #f                   ; no tests
          #:phases
            (modify-phases %standard-phases
              (add-after 'unpack 'remove-definitions
                (lambda _
                  (substitute* "CMakeLists.txt"
                    (("include\\(LXQtCompilerSettings NO_POLICY_SCOPE\\)")
                     "include(LXQtCompilerSettings NO_POLICY_SCOPE)
remove_definitions(-DQT_NO_CAST_TO_ASCII -DQT_NO_CAST_FROM_ASCII)"))
                  #t)))))
      (home-page "https://github.com/lxqt/lxqt-connman-applet")
      (synopsis "System-tray applet for connman")
      (description "This package provides a Qt-based system-tray applet for
the network management tool Connman, originally developed for the LXQT
desktop.")
      (license license:lgpl2.1+))))

(define-public lxqt-menu-data
  (package
    (name "lxqt-menu-data")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/lxqt/" name "/releases"
                           "/download/" version "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0lhs1l65xw7vvw18n6gghzjpxp92ir9dip8rv6nnzin7vkaqsxj4"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f  ; No test suite available
       #:configure-flags
       (list
        (string-append "-DCMAKE_MODULE_PATH="
                       (assoc-ref %build-inputs "lxqt2-build-tools")
                       "/share/cmake/lxqt2-build-tools/modules"))))
    (native-inputs
     (list pkg-config qttools lxqt2-build-tools))
    (inputs
     (list qtbase))
    (synopsis "Freedesktop.org compliant menu files for LXQt")
    (description
     "Freedesktop.org compliant menu files for LXQt Panel, Configuration Center
and PCManFM-Qt/libfm-qt.")
    (home-page "https://lxqt-project.org/")
    (license license:lgpl2.1+)))

;; The LXQt Desktop Environment

(define-public lxqt2
  (package
    (name "lxqt2")
    (version (package-version liblxqt))
    (source #f)
    (build-system trivial-build-system)
    (arguments '(#:builder (begin (mkdir %output) #t)))
    (propagated-inputs
     (list ;; XDG
           desktop-file-utils
           hicolor-icon-theme
           xdg-user-dirs
           xdg-utils
           ;; Base
           ;; TODO: qtsvg is needed for lxqt apps to display icons. Maybe it
           ;; should be added to their propagated-inputs?
           qtsvg
           ;; Core
           lxqt-about
           lxqt-admin
           lxqt-config
           lxqt-globalkeys
           lxqt-notificationd
           lxqt-openssh-askpass
           ;lxqt-panel
           lxqt-policykit
           lxqt-powermanagement
           lxqt-qtplugin
           lxqt-runner
           lxqt-session
           lxqt-sudo
           lxqt-themes
           pcmanfm-qt
           ;; Extra
           picom
           font-dejavu
           lximage-qt
           ;obconf-qt
           ;openbox
           breeze-icons       ; default by <lxqt-session>/share/lxqt/lxqt.conf
           pavucontrol-qt
           qps
           qterminal))
    (synopsis "The Lightweight Qt Desktop Environment")
    (description "LXQt is a lightweight Qt desktop environment.")
    (home-page "https://lxqt-project.org")
    (license license:gpl2+)))

lxqt2
