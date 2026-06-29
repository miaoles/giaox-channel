(define-module (giaox packages obs-backgroundremoval)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages video)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages image-processing)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages curl))

(define-public obs-backgroundremoval
  (package
    (name "obs-backgroundremoval")
    (version "1.1.13")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/occ-ai/obs-backgroundremoval")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0ggm9qzkb0mjshsaz3dck40cn8hq4ha3pp6v2hl76f9hg7ybv022")))) ; You'll need to compute this
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f ; no tests
      #:configure-flags
      #~(list (string-append "-DLIBOBS_INCLUDE_DIR="
                             #$(this-package-input "obs") "/lib")
              (string-append "-DCMAKE_MODULE_PATH=" #$source "/cmake")
              "-DUSE_SYSTEM_OPENCV=ON"
              "-DDISABLE_ONNXRUNTIME_GPU=ON"
              "-DBUILD_OUT_OF_TREE=On"
              "-Wno-dev")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'disable-onnxruntime
            (lambda _
              ;; Patch CMakeLists.txt to skip onnxruntime entirely
              (substitute* "CMakeLists.txt"
                (("include\\(cmake/FetchOnnxruntime\\.cmake\\)")
                 "# include(cmake/FetchOnnxruntime.cmake) # Disabled for Guix"))
              ;; Also try to disable in other places
              (when (file-exists? "cmake/FetchOnnxruntime.cmake")
                (substitute* "cmake/FetchOnnxruntime.cmake"
                  (("FetchContent_MakeAvailable.*")
                   "# FetchContent_MakeAvailable disabled for Guix\n")))))
          (replace 'configure
            (lambda* (#:key configure-flags #:allow-other-keys)
              (mkdir-p "build_x86_64")
              (with-directory-excursion "build_x86_64"
                (apply invoke "cmake" ".." configure-flags))))
          (replace 'build
            (lambda _
              (invoke "cmake" "--build" "build_x86_64" "--parallel")))
          (replace 'install
            (lambda _
              (invoke "cmake" "--install" "build_x86_64" "--prefix" #$output))))))
    (native-inputs (list cmake ninja pkg-config))
    (inputs (list obs
                  opencv
                  qtbase ; Assuming Qt5, change to qtbase-6 if Qt6 is available and preferred
                  curl))
    (home-page "https://github.com/occ-ai/obs-backgroundremoval")
    (synopsis "OBS plugin to replace the background in portrait images and video")
    (description "This OBS plugin uses machine learning to detect and remove
or replace backgrounds in portrait images and videos in real-time, providing
green screen-like functionality without requiring an actual green screen.")
    (license license:expat)))

obs-backgroundremoval
