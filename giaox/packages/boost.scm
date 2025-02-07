(define-module (giaox packages boost)
  #:use-module (guix packages)
  #:use-module (gnu packages boost)
  #:use-module (guix download))

(define-public boost
  (package
    (inherit (@ (gnu packages boost) boost))
    (version "1.85.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://boostorg.jfrog.io/artifactory/main/release/"
                                  version "/source/boost_"
                                  (string-map (lambda (x) (if (char=? x #\.) #\_ x)) version)
                                  ".tar.bz2"))
              (sha256
               (base32
                "0j4qqcb3lrcxhlh6sxldm95rdky1s7rdmk5ymy05lkj4hvwx7rkr"))))))
