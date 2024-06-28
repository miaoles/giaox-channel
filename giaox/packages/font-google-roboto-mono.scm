(define-module (giaox packages font-google-roboto-mono)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix git-download)
  #:use-module (guix build-system font)
  #:use-module (guix gexp))

(define-public font-google-roboto-mono
  (let ((commit "3479a228ba99f69d6e504e7d798a3f8e8239bbe7")
        (revision "1"))
    (package
      (name "font-google-roboto-mono")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/googlefonts/RobotoMono")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "07sx4561msqjwnxmjbc6y8x084n0ygf05di3y6fi2hga21ylwz3g"))))
      (build-system font-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'move-fonts
              (lambda _
                (copy-recursively "fonts/ttf" "fonts"))))))
      (home-page "https://github.com/googlefonts/RobotoMono")
      (synopsis "Monospaced font family from Google")
      (description
       "Roboto Mono is a monospaced addition to the Roboto type family.
Like the other members of the Roboto family, the fonts are optimized for
readability on screens across a wide variety of devices and reading environments.")
      (license license:asl2.0))))

font-google-roboto-mono
