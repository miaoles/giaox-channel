(define-module (giaox packages lsfg-vk)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system qt)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages vulkan))

;; The Vulkan layer identifier, exactly as upstream's
;; VkLayer_LSFGVK_frame_generation.json.in writes it.  Published so that
;; nothing downstream has to glob the output to learn it.
(define-public %lsfg-vk-layer-name
  "VK_LAYER_LSFGVK_frame_generation")

;; Every environment variable lsfg-vk 2.0 reads, as regexps suitable for a
;; nonguix container's preserved-env.  Enumerated from the built binaries
;; rather than from documentation: DISABLE_LSFGVK, plus LSFGVK_CONFIG,
;; _DLL_PATH, _ENV, _FLOW_SCALE, _GPU, _MULTIPLIER, _NO_FP16, _PACING,
;; _PERFORMANCE_MODE and _PROFILE.  Nothing lives outside those two
;; namespaces, so these two regexps are exactly complete; any variable this
;; channel ever introduces must keep that true.
(define-public %lsfg-vk-environment-variable-regexps
  '("^DISABLE_LSFGVK$"
    "^LSFGVK_"))

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
        ;; Upstream ships no test suite.
        #:tests? #f
        ;; The layer and the CLI are built by upstream default; the UI and
        ;; the XDG files are not.
        ;;
        ;; LSFGVK_LAYER_LIBRARY_PATH hands the Vulkan loader an absolute
        ;; store path, which is what makes a single manifest correct both on
        ;; the host and inside a nonguix container — such a container mounts
        ;; the closure of its own manifest, not the whole store, so the path
        ;; resolves there precisely when this package is a container member.
        ;; Nothing downstream may rewrite it.
        ;;
        ;; CMAKE_EXE_LINKER_FLAGS puts the Vulkan loader on the RUNPATH of
        ;; the EXECUTABLES ONLY.  lsfg-vk-common dlopens "libvulkan.so.1" by
        ;; bare soname and is a static library linked into all three targets,
        ;; so the calling object differs per target:
        ;;   CLI/UI — the caller is the executable, no loader is present in
        ;;            the process, and ld-wrapper adds RUNPATH only for
        ;;            libraries that are linked; a dlopened one never is.
        ;;            Without this the bare soname resolves against nothing
        ;;            and `lsfg-vk-cli benchmark' and the UI's GPU list fail.
        ;;   layer  — the caller is liblsfg-vk-layer.so, loaded BY a Vulkan
        ;;            loader that is already in the process, so the bare
        ;;            soname matches that loaded object.  That is the only
        ;;            correct outcome: the layer must use the application's
        ;;            loader, whichever it is.  Inside the Steam container
        ;;            that loader comes from the FHS union, and two loader
        ;;            instances in one process is not a working setup.
        ;; Hence a linker flag scoped to executables rather than a
        ;; substitution of the shared source, which would hit the layer too.
        ;;
        ;; CMAKE_SKIP_RPATH is deliberately not passed: upstream sets it with
        ;; a plain set(), which overrides any -D cache entry, so passing it is
        ;; a no-op.  It does not suppress explicit linker flags.
        #:configure-flags
        #~(list "-DLSFGVK_BUILD_UI=ON"
                "-DLSFGVK_INSTALL_XDG_FILES=ON"
                (string-append "-DLSFGVK_LAYER_LIBRARY_PATH="
                               #$output "/lib/liblsfg-vk-layer.so")
                (string-append "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath="
                               #$(this-package-input "vulkan-loader") "/lib"))))
      ;; No phases are needed, and two former ones were removed as
      ;; unnecessary.  Upstream annotates vkNegotiateLoaderLayerInterfaceVersion
      ;; with visibility("default"), which overrides the layer target's hidden
      ;; visibility preset, so the loader's entry point is exported unaided.
      ;; And upstream's manifest already carries disable_environment with
      ;; DISABLE_LSFGVK, which is 2.0's own opt-out; activation in 2.0 is a
      ;; property of profile matching, so no gate is synthesized here.
      (supported-systems '("x86_64-linux"))
      (inputs
       (list qtdeclarative
             ;; Build-time only, and never a runtime reference: upstream
             ;; vendors no Khronos headers and includes <vulkan/vulkan_core.h>
             ;; and <vulkan/vk_layer.h> directly.
             vulkan-headers
             ;; Referenced through the executables' RUNPATH; see above.
             vulkan-loader))
      (home-page "https://github.com/PancakeTAS/lsfg-vk")
      (synopsis "Vulkan layer for Lossless Scaling frame generation")
      (description
       "lsfg-vk is a Vulkan layer that hooks into Vulkan applications and
generates additional frames using the frame generation algorithm of Lossless
Scaling.  It registers as an implicit layer and activates per application
according to the profiles in @file{~/.config/lsfg-vk/conf.toml}, which
@command{lsfg-vk-ui} edits and @command{lsfg-vk-cli} validates; setting
@env{DISABLE_LSFGVK} disables it outright.  Frame generation requires
@file{Lossless.dll} from an installation of Lossless Scaling to be reachable
at run time.")
      (license license:gpl3+))))