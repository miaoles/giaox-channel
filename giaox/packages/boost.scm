(define-module (giaox packages boost)
  #:use-module (guix packages)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages file)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages base)
  #:use-module (guix utils)
  #:use-module (guix gexp))

(define-public boost
  (package
    (inherit (@ (gnu packages boost) boost))
    (version "1.85.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://archives.boost.io/release/"
                                  version "/source/boost_"
                                  (string-map (lambda (x) (if (char=? x #\.) #\_ x)) version)
                                  ".tar.bz2"))
              (sha256
               (base32
                "05w63ybpn23b13asl2vvkf24xf5d5cx709vhvimlg5qnm8gzw2bh"))))
    (arguments
     (substitute-keyword-arguments (package-arguments (@ (gnu packages boost) boost))
       ((#:phases phases)
        #~(modify-phases #$phases
            (replace 'build
              (lambda* (#:key make-flags #:allow-other-keys)
                (apply invoke "./b2"
                       (format #f "-j~a" 8)  ; Use 8 parallel jobs
                       make-flags)))
            (replace 'install
              (lambda* (#:key make-flags #:allow-other-keys)
                (apply invoke "./b2"
                       "install"
                       (format #f "-j~a" 8)  ; Use 8 parallel jobs
                       make-flags)))))))
    (native-inputs
     (modify-inputs (package-native-inputs (@ (gnu packages boost) boost))
       (append which file)))))

boost
