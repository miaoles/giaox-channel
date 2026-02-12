(define-module (giaox packages lsfg-vk)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages qt))

(define-public lsfg-vk
  (let ((commit "997bc665f7f0f229c8d89a59cf3567ee3930927c")
        (revision "1"))
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
          (base32 "1c1jn770f5jpink95zhpbamqpmdqg23f7rdcspyz9ilc4g3r818x"))))
      (build-system cmake-build-system)
      (arguments
       `(#:tests? #f
         #:configure-flags
         (list "-DCMAKE_BUILD_TYPE=Release"
               "-DCMAKE_SKIP_RPATH=OFF"
               "-DLSFGVK_BUILD_VK_LAYER=ON"
               "-DLSFGVK_BUILD_CLI=ON"
               "-DLSFGVK_BUILD_UI=ON"
               "-DLSFGVK_INSTALL_XDG_FILES=ON"
               (string-append "-DLSFGVK_LAYER_LIBRARY_PATH="
                              (assoc-ref %outputs "out")
                              "/lib/liblsfg-vk-layer.so"))
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'fix-symbol-linkage
             (lambda _
               (substitute* "lsfg-vk-layer/src/entrypoint.cpp"
                 (("VkResult vkNegotiateLoaderLayerInterfaceVersion")
                  "extern \"C\" VkResult vkNegotiateLoaderLayerInterfaceVersion")))))))
      (native-inputs
       (list vulkan-headers
             qttools))
      (inputs
       (list vulkan-loader
             qtbase
             qtdeclarative))
      (home-page "https://github.com/PancakeTAS/lsfg-vk")
      (synopsis "Vulkan layer for LSFG frame generation")
      (description
       "lsfg-vk is a Vulkan layer that hooks into Vulkan applications and
generates additional frames using Lossless Scaling's frame generation
algorithm.  Requires the Lossless Scaling DLL (Lossless.dll) to be
available at runtime from a Steam installation of Lossless Scaling.")
      (license gpl3+))))

lsfg-vk
