(define-module (giaox packages odin)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages base)
  #:use-module (gnu packages python)
  #:use-module (srfi srfi-1))

(define-public odin
  (package
    (name "odin")
    (version "dev-2025-01")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/odin-lang/Odin")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "17xgyr0xsg3bdfn472kniyld813vprm8g0x99qhj05w8wgirlxqr"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                     ; No standard test target
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)            ; no configure script
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "LLVM_CONFIG"
                     (string-append (assoc-ref inputs "llvm")
                                  "/bin/llvm-config"))
             (setenv "CXX"
                     (string-append (assoc-ref inputs "clang")
                                  "/bin/clang++"))
             (invoke "sh" "build_odin.sh" "release")))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (share (string-append out "/share")))
               (install-file "odin" bin)
               (for-each
                (lambda (dir)
                  (copy-recursively dir (string-append share "/" dir)))
                '("base" "core" "vendor" "shared"))
               #t)))
         (add-after 'install 'compile-vendor-libraries
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share"))
                    (vendor (string-append share "/vendor")))
               ;; Compile cgltf
               (with-directory-excursion (string-append vendor "/cgltf/src")
                 (invoke "make"))
               ;; Compile stb
               (with-directory-excursion (string-append vendor "/stb/src")
                 (invoke "make"))
               ;; Compile miniaudio
               (with-directory-excursion (string-append vendor "/miniaudio/src")
                 (invoke "make"))
               #t)))
         (add-after 'compile-vendor-libraries 'wrap-program
           (lambda* (#:key inputs outputs #:allow-other-keys)
             ;; Wrap the 'odin' binary to find clang and other tools.
             (let* ((out (assoc-ref outputs "out"))
                    (clang-toolchain (assoc-ref inputs "clang-toolchain"))
                    (llvm (assoc-ref inputs "llvm")))
               (wrap-program (string-append out "/bin/odin")
                 `("PATH" prefix (,(string-append clang-toolchain "/bin")))
                 `("LIBRARY_PATH" prefix (,(string-append clang-toolchain "/lib")))
                 `("ODIN_ROOT" = (,(string-append out "/share"))))
               #t))))))
    (native-inputs
     (list llvm-18
           which
           python-minimal))
    (inputs
     (list clang-toolchain-18          ; Use the complete toolchain
           gnu-make))                  ; For vendor library compilation
    (propagated-inputs
     (list clang-18))                  ; Needed for runtime compilation
    (home-page "https://odin-lang.org/")
    (synopsis "Fast, concise, readable, pragmatic programming language")
    (description
     "Odin is a general-purpose programming language with distinct typing built
for high performance, modern systems and data-oriented programming. It includes
vendor libraries for cgltf (glTF 2.0 parser), stb (single-file public domain
libraries), and miniaudio (audio playback and capture) functionality.")
    (license bsd-3)))

odin
