(define-module (giaox packages onnxruntime)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix specifications)  ; For specification->package
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages python)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image-processing)
  #:use-module (gnu packages image)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages benchmark))

(define-public onnxruntime
  (package
    (name "onnxruntime")
    (version "1.16.3")  ; Start with this version first
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/microsoft/onnxruntime")
                    (commit (string-append "v" version))
                    (recursive? #t)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0pihb8ngkyma08wjcmx3qvg80z015lqhq9ajy6f7zg7brlyvsdbd"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
              "-DCMAKE_INSTALL_LIBDIR=lib"
              "-DCMAKE_VERBOSE_MAKEFILE=ON"
              ;; Minimal ONNX Runtime configuration
              "-Donnxruntime_BUILD_SHARED_LIB=ON"
              "-Donnxruntime_BUILD_UNIT_TESTS=OFF"
              "-Donnxruntime_USE_FULL_PROTOBUF=OFF"
              "-Donnxruntime_USE_CUDA=OFF"
              "-Donnxruntime_USE_NCCL=OFF"
              "-Donnxruntime_ENABLE_LTO=OFF"  ; Disable LTO to avoid issues
              "-Donnxruntime_ENABLE_PYTHON=OFF"
              ;; Try to use system dependencies where possible
              "-Donnxruntime_USE_PREINSTALLED_EIGEN=ON"
              ;; Allow network downloads for now (we can disable later)
              "-DFETCHCONTENT_FULLY_DISCONNECTED=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'change-to-cmake-dir
            (lambda _
              (chdir "cmake")))
          (add-after 'change-to-cmake-dir 'patch-sources
            (lambda _
              ;; Fix runtime path
              (substitute* "../onnxruntime/core/platform/env.h"
                (("GetRuntimePath\\(\\) const \\{ return PathString\\(\\); \\}")
                 (string-append "GetRuntimePath() const { return PathString(\""
                                #$output "/lib/\"); }")))))
          (add-after 'install 'install-additional-headers
            (lambda _
              ;; Install key headers
              (for-each
                (lambda (header)
                  (when (file-exists? header)
                    (install-file header (string-append #$output "/include"))))
                (list "../include/onnxruntime/core/framework/provider_options.h"
                      "../include/onnxruntime/core/providers/cpu/cpu_provider_factory.h"))
              ;; Install session headers
              (when (file-exists? "../include/onnxruntime/core/session")
                (for-each
                  (lambda (header)
                    (install-file header (string-append #$output "/include")))
                  (find-files "../include/onnxruntime/core/session"
                             "onnxruntime_.*\\.h$"))))))))
    (native-inputs
     (list (specification->package "cmake@4.0.1")  ; Specify the exact version
           pkg-config
           python
           protobuf))
    (inputs
     (list eigen
           libpng
           nlohmann-json
           zlib))
    (home-page "https://github.com/microsoft/onnxruntime")
    (synopsis "Cross-platform, high performance scoring engine for ML models")
    (description
     "ONNX Runtime is a performance-focused complete scoring engine for Open
Neural Network Exchange (ONNX) models, with an open extensible architecture to
continually address the latest developments in AI and Deep Learning.  This is
a minimal build with network dependencies enabled for simplicity.")
    (license license:expat)))

onnxruntime
