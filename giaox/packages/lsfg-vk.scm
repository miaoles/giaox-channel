(define-module (giaox packages lsfg-vk)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system qt)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages vulkan))

(define-public lsfg-vk
  (let ((commit "8b0da2661c6f3473a7fccc8ba643880050e71642")
        (revision "2"))
    (package
      (name "lsfg-vk")
      (version (git-version "2.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/PancakeTAS/lsfg-vk")
               (commit commit)
               (recursive? #t)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0b0qd8czmd4dsppyphlnlizr517mm4l816dazvmy744qwx7mfdj8"))))
      (build-system qt-build-system)
      (arguments
       (list
        #:qtbase qtbase
        #:tests? #f
        #:configure-flags
        #~(list "-DCMAKE_SKIP_RPATH=OFF"
                "-DLSFGVK_BUILD_VK_LAYER=ON"
                "-DLSFGVK_BUILD_CLI=ON"
                "-DLSFGVK_BUILD_UI=ON"
                "-DLSFGVK_INSTALL_XDG_FILES=ON"
                (string-append "-DLSFGVK_LAYER_LIBRARY_PATH="
                               #$output "/lib/liblsfg-vk-layer.so"))
        #:phases
        #~(modify-phases %standard-phases
            ;; The loader resolves the layer's entry points with dlsym;
            ;; hidden visibility makes them unreachable.
            (add-after 'unpack 'expose-layer-symbols
              (lambda _
                (substitute* "lsfg-vk-layer/CMakeLists.txt"
                  (("CXX_VISIBILITY_PRESET hidden")
                   "CXX_VISIBILITY_PRESET default"))))
            ;; enable_environment keeps an implicit layer inert unless the
            ;; variable is set; without it lsfg-vk hooks every Vulkan client
            ;; and fails their swapchains when Lossless.dll is absent.
            (add-after 'install 'make-layer-opt-in
              (lambda _
                (let ((json (car (find-files #$output "\\.json$"))))
                  (substitute* json
                    (("\"library_path\"" all)
                     (string-append
                      "\"enable_environment\": { \"LSFG_ENABLE\": \"1\" },\n"
                      "        " all)))
                  (invoke "grep" "-q" "enable_environment" json)))))))
      (native-inputs
       (list vulkan-headers))
      (inputs
       (list qtdeclarative
             vulkan-loader))
      (home-page "https://github.com/PancakeTAS/lsfg-vk")
      (synopsis "Vulkan layer for Lossless Scaling frame generation")
      (description
       "lsfg-vk is a Vulkan layer that hooks into Vulkan applications and
generates additional frames using Lossless Scaling's frame generation
algorithm.  It is registered as an implicit layer but stays inert unless
@env{LSFG_ENABLE=1} is set, and it requires @file{Lossless.dll} from a Steam
installation of Lossless Scaling to be reachable at runtime.")
      (license license:gpl3+))))

lsfg-vk