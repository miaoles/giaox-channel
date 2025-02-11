(define-module (giaox packages ols)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (giaox packages odin)
  #:use-module (gnu packages base)
  #:use-module (gnu packages version-control)  ; For git
  #:use-module (srfi srfi-1))

(define-public ols
  (package
    (name "ols")
    (version "0-unstable-2025-01-28")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DanielGavin/ols")
             (commit "a71caaac9f8ac113d81fc714a41c9b9e96d1fee7")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1hc5s3jjg90h9189cx9y8j5z3dqfyqddjn7431a3gi5bjdnhli39"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'unpack 'patch-build-scripts
           (lambda _
             (substitute* "build.sh"
               (("-microarch:native") ""))
             (chmod "build.sh" #o755)
             (chmod "odinfmt.sh" #o755)))
         (replace 'build
           (lambda* (#:key inputs #:allow-other-keys)
             (invoke "./build.sh")
             (invoke "./odinfmt.sh")))
         (replace 'install
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin")))
               (install-file "ols" bin)
               (install-file "odinfmt" bin)
               (wrap-program (string-append bin "/ols")
                 `("ODIN_ROOT" =
                   (,(string-append (assoc-ref inputs "odin") "/share")))))))
         (delete 'validate-runpath))))
    (native-inputs
     (list which git))  ; Added git to native-inputs
    (inputs
     (list odin))
    (home-page "https://github.com/DanielGavin/ols")
    (synopsis "Language server for the Odin programming language")
    (description
     "OLS (Odin Language Server) is a language server implementation for the
Odin programming language, providing IDE-like features through the Language
Server Protocol (LSP).  It includes the odinfmt formatting tool.")
    (license expat)))

ols

