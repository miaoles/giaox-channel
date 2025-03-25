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
    (version "0-unstable-2025-03-12")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DanielGavin/ols")
             (commit "1e44e3d78ad8a74ef09c7f54a6f6d3f7df517f8e")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "16f7b8ijcaj5m2bdgbbl1q1mzgpgzzazrap2g17hkgy63aqq8qmf"))))
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

