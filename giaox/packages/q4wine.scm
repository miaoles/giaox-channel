(define-module (giaox packages q4wine)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (gnu packages base)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages wine)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages image)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages sqlite))

(define-public q4wine
  (package
    (name "q4wine")
    (version "1.3.13")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/brezerk/q4wine")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "04gw5y3dxdpivm2xqacqq85fdzx7xkl0c3h3hdazljb0c3cxxs6h"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f
       #:configure-flags
       '("-DCMAKE_INSTALL_LIBDIR=lib"
         "-DCMAKE_SKIP_BUILD_RPATH=FALSE"
         "-DCMAKE_SKIP_INSTALL_RPATH=FALSE"
         "-DWITH_ICOUTILS=ON"
         "-DWITH_WINEAPPDB=ON"
         "-DWITH_DBUS=ON")
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'wrap-program
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (wrap-program (string-append out "/bin/q4wine")
                 `("PATH" ":" prefix
                   ,(map (lambda (input)
                           (string-append (assoc-ref inputs input) "/bin"))
                         '("icoutils" "wget" "wine"))))))))))
    (inputs
     (list qtbase-5
           qtsvg-5
           sqlite
           icoutils
           wget
           wine))
    (native-inputs
     (list qttools-5))
    (home-page "https://q4wine.brezblock.org.ua/")
    (synopsis "Qt GUI for Wine")
    (description
     "Q4Wine is a Qt GUI for Wine that helps manage Wine prefixes and installed applications.")
    (license gpl3+)))

q4wine
