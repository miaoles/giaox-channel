
;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015, 2023 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2016, 2019, 2020, 2022, 2023 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016-2019 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;; Copyright © 2016 David Craven <david@craven.ch>
;;; Copyright © 2017 Thomas Danckaert <post@thomasdanckaert.be>
;;; Copyright © 2018, 2019 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2019 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2020 Vincent Legoll <vincent.legoll@gmail.com>
;;; Copyright © 2020 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2021 Alexandros Theodotou <alex@zrythm.org>
;;; Copyright © 2022 Brendan Tildesley <mail@brendan.scot>
;;; Copyright © 2022 Petr Hodina <phodina@protonmail.com>
;;; Copyright © 2023 Zheng Junjie <873216071@qq.com>
;;; Copyright © 2024 Maxim Cournoyer <maxim.cournoyer@gmail.com>
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

(define-module (giaox packages kde-frameworks)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system python)
  #:use-module (guix build-system qt)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu packages acl)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages aspell)
  #:use-module (gnu packages attr)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages base)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages calendar)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages ebook)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages hunspell)
  #:use-module (gnu packages image)
  #:use-module (gnu packages iso-codes)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages kde)
  #:use-module (gnu packages kde-plasma)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages libcanberra)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages openbox)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages text-editors)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (srfi srfi-1))

(define-public extra-cmake-modules-custom
  (package
    (name "extra-cmake-modules-custom")
    (version "6.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kde/stable/frameworks/"
                    (version-major+minor version) "/"
                    "extra-cmake-modules" "-" version ".tar.xz"))
              (sha256
               (base32
                "067qb9w8dj5z094yklc9b1jx5k29my5zf1gzkr05liswm7xzhs0k"))))
    (build-system cmake-build-system)
    (native-inputs
     (list qtbase))
    (arguments
     (list
      #:tests? #f  ; Disable tests for now
      #:configure-flags
      #~(list (string-append "-DCMAKE_INSTALL_PREFIX=" #$output)
              "-DBUILD_HTML_DOCS=OFF"
              "-DBUILD_MAN_DOCS=OFF")))
    (home-page "https://community.kde.org/Frameworks")
    (synopsis "CMake module files for common software used by KDE")
    (description "The Extra CMake Modules package, or ECM, adds to the
modules provided by CMake to find common software.  In addition, it provides
common build settings used in software produced by the KDE community.")
    (license license:bsd-3)))

(define-public kwindowsystem-custom
  (package
    (name "kwindowsystem-custom")
    (version "6.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kde/stable/frameworks/"
                    (version-major+minor version) "/"
                    "kwindowsystem" "-" version ".tar.xz"))
              (sha256
               (base32
                "1fdax3c2q3fm56pvr99z0rwf1nwz7jmksblj9d42gg1l55ckrqs0"))))
    (build-system cmake-build-system)
    (native-inputs
     (list extra-cmake-modules-custom
           pkg-config
           qttools
           wayland-utils)) ; For wayland-scanner
    (inputs
     (list qtbase
           qtdeclarative
           qtwayland
           wayland
           wayland-protocols
           libxcb
           xcb-util
           xcb-util-keysyms
           xcb-util-wm
           plasma-wayland-protocols
           libxkbcommon))
    (arguments
     (list
      #:tests? #f  ; Disable running the test suite
      #:configure-flags
      #~(list "-DBUILD_TESTING=OFF"
              "-DQT_MAJOR_VERSION=6"
              (string-append "-DCMAKE_PREFIX_PATH="
                             (assoc-ref %build-inputs "extra-cmake-modules-custom"))
              (string-append "-DCMAKE_MODULE_PATH="
                             (assoc-ref %build-inputs "extra-cmake-modules-custom")
                             "/share/ECM/cmake/")
              (string-append "-DKDE_INSTALL_LIBDIR=" #$output "/lib")
              (string-append "-DKDE_INSTALL_QTPLUGINDIR=" #$output "/lib/qt6/plugins")
              (string-append "-DKDE_INSTALL_QMLDIR=" #$output "/lib/qt6/qml")
              (string-append "-DKDE_INSTALL_QTQUICKIMPORTSDIR=" #$output "/lib/qt6/QtQuick2/imports")
              (string-append "-DKDE_INSTALL_BINDIR=" #$output "/bin")
              (string-append "-DKDE_INSTALL_INCLUDEDIR=" #$output "/include")
              (string-append "-DKDE_INSTALL_DATADIR=" #$output "/share"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'fix-ecm-qt-install-logging-categories
            (lambda _
              (substitute* "src/CMakeLists.txt"
                (("ecm_qt_install_logging_categories\\(EXPORT KWINDOWSYSTEM\\)")
                 "ecm_qt_install_logging_categories(EXPORT KWINDOWSYSTEM DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR})"))))
          (delete 'check))))  ; Explicitly delete the check phase
    (home-page "https://community.kde.org/Frameworks")
    (synopsis "KDE access to the windowing system")
    (description "KWindowSystem provides information about and allows
interaction with the windowing system.")
    (license license:lgpl2.1+)))

;;extra-cmake-modules
kwindowsystem-custom
