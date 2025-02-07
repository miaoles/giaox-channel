(define-module (giaox packages obs-cef)
  #:use-module (gnu packages video)
  #:use-module (nongnu packages chromium)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp))

(define-public obs-cef
  (package
    (inherit obs)
    (name "obs-cef")
    (arguments
     (substitute-keyword-arguments (package-arguments obs)
       ((#:configure-flags flags)
        #~(cons* "-DBUILD_BROWSER=ON"
                 "-DCEF_ROOT_DIR=<CEF_ROOT_DIR>"
                 (delete "-DBUILD_BROWSER=OFF" #$flags)))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'configure-cef-root
              (lambda* (#:key inputs #:allow-other-keys)
                (substitute* "plugins/obs-browser/CMakeLists.txt"
                  (("<CEF_ROOT_DIR>")
                   (assoc-ref inputs "chromium-embedded-framework")))))))))
    (inputs
     (modify-inputs (package-inputs obs)
       (prepend chromium-embedded-framework)))))
