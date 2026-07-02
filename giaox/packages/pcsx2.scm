(define-module (giaox packages pcsx2)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xorg)
  #:use-module (guix gexp))

(define-public libretro-pcsx2
  ;; Use the specific commit from the Nix package
  (let ((commit "6cc162de2162a0ffe92a4e0470141b9c7c095bf3")
        (revision "0"))
    (package
      (name "libretro-pcsx2")
      ;; Version based on date as there are no official releases
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/libretro/ps2")
               (commit commit)
               (recursive? #t)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0sz90knj1iwkd7r51a94bfw22mx94r3fnimvgivbk9y2vsg3hcw7"))))
      (build-system gnu-build-system)
      (arguments
       (list
        #:tests? #f                     ;no test suite
        #:phases
        #~(modify-phases %standard-phases
            (delete 'configure)         ;no configure script
            (add-after 'unpack 'setup-build-environment
              (lambda* (#:key inputs #:allow-other-keys)
                ;; Find where libretro-common headers are
                (let ((dirs '("3rdparty/libretro-common"
                             "libretro-common"
                             "deps/libretro-common")))
                  (for-each
                   (lambda (dir)
                     (when (file-exists? dir)
                       (format #t "Found libretro-common at: ~a~%" dir)
                       ;; Copy the include directory to the root
                       (when (file-exists? (string-append dir "/include"))
                         (copy-recursively (string-append dir "/include") "include"))))
                   dirs))

                ;; Create missing Config.h
                (mkdir-p "pcsx2")
                (with-output-to-file "pcsx2/Config.h"
                  (lambda ()
                    (display "#ifndef __PS2EMU_CONFIG_H__\n")
                    (display "#define __PS2EMU_CONFIG_H__\n")
                    (display "#define ENABLE_OPENGL 0\n")
                    (display "#define ENABLE_VULKAN 0\n")
                    (display "#endif\n")))

                ;; Check if we have the headers where expected
                (when (file-exists? "include/libretro.h")
                  (format #t "Found libretro.h in include/~%"))

                ;; Set up include paths for the build
                (setenv "C_INCLUDE_PATH"
                        (string-append (getcwd) "/include:"
                                     (or (getenv "C_INCLUDE_PATH") "")))
                (setenv "CPLUS_INCLUDE_PATH"
                        (string-append (getcwd) "/include:"
                                     (or (getenv "CPLUS_INCLUDE_PATH") "")))))
            (replace 'build
              (lambda* (#:key make-flags #:allow-other-keys)
                ;; Build with the correct flags
                (apply invoke "make"
                       (append make-flags
                              (list
                               (string-append "CC=" #$(cc-for-target))
                               (string-append "CXX=" #$(cxx-for-target))
                               (string-append "GIT_VERSION=" #$commit)
                               (string-append "CFLAGS=-msse -msse2 -msse4.1 -mfxsr -I"
                                            (getcwd) "/include")
                               (string-append "CXXFLAGS=-msse -msse2 -msse4.1 -mfxsr -I"
                                            (getcwd) "/include"))))))
            (replace 'install
              (lambda _
                (let ((libretro-dir (string-append #$output "/lib/libretro")))
                  (mkdir-p libretro-dir)
                  ;; Find and install the libretro core
                  (for-each
                   (lambda (file)
                     (format #t "Found potential core: ~a~%" file)
                     (install-file file libretro-dir))
                   (find-files "." ".*_libretro\\.so$"))
                  ;; If no _libretro.so found, look for any .so
                  (when (null? (find-files libretro-dir "\\.so$"))
                    (for-each
                     (lambda (file)
                       (format #t "Found .so file: ~a~%" file)
                       (install-file file libretro-dir))
                     (find-files "bin" "\\.so$")))))))))
      (native-inputs
       (list perl
             pkg-config))
      (inputs
       (list mesa
             glu
             xz))
      (home-page "https://github.com/libretro/ps2")
      (synopsis "Port of PCSX2 to libretro")
      (description
       "This package provides a port of PCSX2, the PlayStation 2 emulator, to
the libretro API.  It can be used with RetroArch and other libretro
frontends.")
      (supported-systems '("x86_64-linux" "i686-linux"))
      (license license:gpl3+))))

libretro-pcsx2
