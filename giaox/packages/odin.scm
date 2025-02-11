(define-module (giaox packages odin)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages base)
  #:use-module (gnu packages python)
  #:use-module (gnu packages gcc)
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
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "LLVM_CONFIG"
                     (string-append (assoc-ref inputs "llvm")
                                  "/bin/llvm-config"))
             (setenv "CXX"
                     (string-append (assoc-ref inputs "clang-toolchain")
                                  "/bin/clang++"))
             (invoke "sh" "build_odin.sh" "release")))
         (replace 'install
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (share (string-append out "/share")))
               ;; Install main executable and libraries
               (install-file "odin" bin)
               (for-each
                (lambda (dir)
                  (copy-recursively dir (string-append share "/" dir)))
                '("base" "core" "vendor" "shared"))

               ;; Compile core vendor libraries
               (setenv "CC" (string-append (assoc-ref inputs "gcc") "/bin/gcc"))
               (for-each
                (lambda (lib)
                  (with-directory-excursion
                   (string-append share "/vendor/" lib "/src")
                   (invoke "make")))
                '("cgltf" "stb" "miniaudio"))

               ;; Wrap with minimal required environment
               (wrap-program (string-append bin "/odin")
                 `("PATH" prefix
                   (,(string-append (assoc-ref inputs "clang-toolchain") "/bin")))
                 `("ODIN_ROOT" = (,share)))))))))
    (native-inputs
     (list llvm-18
           gcc
           which
           python-minimal))
    (propagated-inputs
     (list clang-toolchain-18))
    (home-page "https://odin-lang.org/")
    (synopsis "Fast, concise, readable, pragmatic programming language")
    (description
     "Odin is a general-purpose programming language with distinct typing built
for high performance, modern systems and data-oriented programming. It includes
vendor libraries for cgltf (glTF 2.0 parser), stb (single-file public domain
libraries), and miniaudio (audio playback and capture) functionality.")
    (license bsd-3)))

odin
