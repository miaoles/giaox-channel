(define-module (giaox packages ungoogled-chromium)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages ninja)
  #:use-module (gnu packages node)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages regex)
  #:use-module (gnu packages python-web))

(define %chromium-version "136.0.7103.92")
(define %ungoogled-revision (string-append %chromium-version "-1"))

(define %ungoogled-origin
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/ungoogled-software/ungoogled-chromium")
          (commit %ungoogled-revision)))
    (file-name (git-file-name "ungoogled-chromium" %ungoogled-revision))
    (sha256
     (base32 "1pcdlj0cn8p057pvcsrg2rc3z79z7my3lf31lksr2a2npcdym7wr"))))

(define %preserved-third-party-files
  '("base/third_party/cityhash"
    "base/third_party/double_conversion"
    "base/third_party/icu"
    "base/third_party/superfasthash"
    "base/third_party/symbolize"
    "base/third_party/xdg_user_dirs"
    "chrome/third_party/mozilla_security_manager"
    "net/third_party/mozilla_security_manager"
    "net/third_party/nss"
    "net/third_party/quiche"
    "net/third_party/uri_template"
    "third_party/abseil-cpp"
    "third_party/angle"
    "third_party/angle/src/common/third_party/xxhash"
    "third_party/angle/src/third_party/libXNVCtrl"
    "third_party/angle/src/third_party/volk"
    "third_party/apple_apsl"
    "third_party/axe-core"
    "third_party/blink"
    "third_party/boringssl"
    "third_party/boringssl/src/third_party/fiat"
    "third_party/breakpad"
    "third_party/brotli"
    "third_party/catapult"
    "third_party/ced"
    "third_party/cld_3"
    "third_party/closure_compiler"
    "third_party/crashpad"
    "third_party/crc32c"
    "third_party/dav1d"
    "third_party/dawn"
    "third_party/devtools-frontend"
    "third_party/distributed_point_functions"
    "third_party/dom_distiller_js"
    "third_party/eigen3"
    "third_party/emoji-segmenter"
    "third_party/farmhash"
    "third_party/fdlibm"
    "third_party/fft2d"
    "third_party/flatbuffers"
    "third_party/gemmlowp"
    "third_party/google_input_tools"
    "third_party/googletest"
    "third_party/harfbuzz-ng"
    "third_party/highway"
    "third_party/hunspell"
    "third_party/inspector_protocol"
    "third_party/jinja2"
    "third_party/khronos"
    "third_party/leveldatabase"
    "third_party/libaddressinput"
    "third_party/libaom"
    "third_party/libgav1"
    "third_party/libjingle_xmpp"
    "third_party/libphonenumber"
    "third_party/libsrtp"
    "third_party/libsync"
    "third_party/liburlpattern"
    "third_party/libva_protected_content"
    "third_party/libvpx"
    "third_party/libwebm"
    "third_party/libxml/chromium"
    "third_party/libyuv"
    "third_party/lottie"
    "third_party/lss"
    "third_party/mako"
    "third_party/markupsafe"
    "third_party/mesa_headers"
    "third_party/metrics_proto"
    "third_party/minigbm"
    "third_party/modp_b64"
    "third_party/nasm"
    "third_party/node"
    "third_party/one_euro_filter"
    "third_party/openscreen"
    "third_party/ots"
    "third_party/pdfium"
    "third_party/perfetto"
    "third_party/pffft"
    "third_party/ply"
    "third_party/polymer"
    "third_party/protobuf"
    "third_party/pyjson5"
    "third_party/rnnoise"
    "third_party/rust"
    "third_party/securemessage"
    "third_party/skia"
    "third_party/smhasher"
    "third_party/snappy"
    "third_party/sqlite"
    "third_party/swiftshader"
    "third_party/tensorflow-text"
    "third_party/tflite"
    "third_party/ukey2"
    "third_party/vulkan-deps"
    "third_party/wayland"
    "third_party/webdriver"
    "third_party/webgpu-cts"
    "third_party/webrtc"
    "third_party/widevine"
    "third_party/woff2"
    "third_party/x11proto"
    "third_party/xnnpack"
    "third_party/zlib/google"
    "third_party/zxcvbn-cpp"
    "url/third_party/mozilla"
    "v8/third_party/inspector_protocol"
    "v8/third_party/v8"))

(define opus+custom
  (package/inherit opus
    (name "opus+custom")
    (arguments
     (substitute-keyword-arguments (package-arguments opus)
       ((#:configure-flags flags ''())
        `(cons "--enable-custom-modes" ,flags))))))

(define-public ungoogled-chromium
  (package
    (name "ungoogled-chromium")
    (version %ungoogled-revision)
    (source (origin
              (method url-fetch)
              (uri (string-append "https://commondatastorage.googleapis.com"
                                  "/chromium-browser-official/chromium-"
                                  %chromium-version ".tar.xz"))
              (sha256
               (base32 "1wjcrlas1xi88xjw31cjqqzpabk1y2lykwbv6r46jml6y67gi9rz"))
              (modules '((guix build utils)))
              (snippet
               #~(begin
                   (let ((chromium-dir (getcwd)))
                     (set-path-environment-variable
                      "PATH" '("bin")
                      (list #+patch #+python-wrapper #+zstd))

                     (with-directory-excursion #+%ungoogled-origin
                       (format #t "Ungooglifying...~%")
                       (force-output)
                       (invoke "python" "utils/prune_binaries.py" chromium-dir
                               "pruning.list")
                       (invoke "python" "utils/patches.py" "apply" chromium-dir
                               "patches")
                       (invoke "python" "utils/domain_substitution.py" "apply" "-r"
                               "domain_regex.list" "-f" "domain_substitution.list"
                               "-c" "/tmp/domainscache.tar.gz" chromium-dir))

                     (format #t "Pruning third party files...~%")
                     (force-output)
                     (apply invoke "python"
                            "build/linux/unbundle/remove_bundled_libraries.py"
                            "--do-remove" '#$%preserved-third-party-files)

                     (format #t "Replacing GN files...~%")
                     (force-output)
                     (invoke "python" "build/linux/unbundle/replace_gn_files.py"
                             "--system-libraries" "ffmpeg" "flac" "fontconfig" "freetype"
                             "harfbuzz-ng" "icu" "libdrm"
                             "libpng" "libwebp" "libxml" "libxslt" "opus"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list "is_debug=false"
              "is_official_build=true"
              "clang_use_chrome_plugins=false"
              "chrome_pgo_phase=0"
              "use_custom_libcxx=false"
              "use_sysroot=false"
              "use_unofficial_version_number=false"
              "treat_warnings_as_errors=false"
              "use_official_google_api_keys=false"
              "disable_fieldtrial_testing_config=true"
              "safe_browsing_mode=0"
              "enable_nacl=false"
              "enable_widevine=false"
              "enable_rust=true"
              "use_thin_lto=false"
              "custom_toolchain=\"//build/toolchain/linux/unbundle:default\""
              "host_toolchain=\"//build/toolchain/linux/unbundle:default\""
              (string-append "clang_base_path=\""
                             (dirname (dirname (search-input-file %build-inputs
                                                                  "/bin/clang")))
                             "\"")
              "use_system_freetype=true"
              "use_system_harfbuzz=true"
              "use_system_libffi=true"
              "media_use_ffmpeg=true"
              "proprietary_codecs=true"
              "ffmpeg_branding=\"Chrome\""
              "use_pulseaudio=true"
              "link_pulseaudio=true"
              "enable_hangout_services_extension=false"
              "enable_mdns=false"
              "enable_mse_mpeg2ts_stream_parser=true"
              "enable_reading_list=false"
              "enable_remoting=false"
              "enable_reporting=false"
              "enable_service_discovery=false"
              "enable_vr=false"
              "enable_js_type_check=false"
              "use_system_zlib=true"
              "use_system_libjpeg=true"
              "use_system_libpng=true"
              #$@(if (target-x86-64?)
                     '("use_vaapi=true")
                     '()))
      #:phases
      #~(modify-phases %standard-phases
(add-after 'unpack 'patch-stuff
  (lambda _
    ;; Fix the exec_script_allowlist definition to be a valid empty list
    (substitute* ".gn"
      (("exec_script_allowlist =.*\n.*build_dotfile_settings.*\n.*angle_dotfile_settings.*\n.*\\[.*\\]")
       "exec_script_allowlist = [\n    # List intentionally empty\n  ]"))

    (substitute* "third_party/pdfium/BUILD.gn"
      (("/usr/include/openjpeg-")
       (string-append #$(this-package-input "openjpeg")
                     "/include/openjpeg-")))

    (substitute* (find-files "." "\\.(h|cc)$")
      (("#include \"opus\\.h\"") "#include <opus/opus.h>")
      (("#include \"opus_custom\\.h\"") "#include <opus/opus_custom.h>")
      (("#include \"opus_defines\\.h\"") "#include <opus/opus_defines.h>")
      (("#include \"opus_multistream\\.h\"") "#include <opus/opus_multistream.h>")
      (("#include \"opus_types\\.h\"") "#include <opus/opus_types.h>"))))

          (add-before 'configure 'prepare-build-environment
            (lambda* (#:key inputs native-inputs #:allow-other-keys)
              (setenv "AR" "llvm-ar")
              (setenv "NM" "llvm-nm")
              (setenv "CC" "clang")
              (setenv "CXX" "clang++")
              (setenv "PYTHONDONTWRITEBYTECODE" "1")

              (let ((node (search-input-file (or native-inputs inputs) "/bin/node")))
                (mkdir-p "third_party/node/linux/node-linux-x64")
                (symlink (dirname node)
                         "third_party/node/linux/node-linux-x64/bin"))))

          (replace 'configure
            (lambda* (#:key configure-flags #:allow-other-keys)
              (invoke "gn" "gen" "out/Release"
                      (string-append "--args=" (string-join configure-flags " ")))))

          (replace 'build
            (lambda* (#:key (parallel-build? #t) #:allow-other-keys)
              (invoke "ninja" "-C" "out/Release"
                      "-j" (if parallel-build?
                               (number->string (parallel-job-count))
                               "1")
                      "chrome" "chrome_sandbox" "chromedriver")))

          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (lib (string-append out "/lib"))
                     (bin (string-append out "/bin"))
                     (res (string-append lib "/chromium")))

                (install-file "out/Release/chrome" bin)
                (rename-file (string-append bin "/chrome")
                            (string-append bin "/chromium"))

                (install-file "out/Release/chromedriver" bin)
                (install-file "out/Release/chrome_sandbox" bin)
                (rename-file (string-append bin "/chrome_sandbox")
                            (string-append bin "/chrome-sandbox"))

                (mkdir-p res)
                (copy-recursively "out/Release/resources"
                                  (string-append res "/resources"))
                (copy-recursively "out/Release/locales"
                                  (string-append res "/locales"))

                (for-each (lambda (file) (install-file file res))
                          (find-files "out/Release" "\\.pak$"))

                (for-each (lambda (file) (install-file file res))
                          (find-files "out/Release" "\\.so$"))

                (install-file "out/Release/chrome_crashpad_handler" res)
                (install-file "out/Release/v8_context_snapshot.bin" res)

                (let ((swift-target (string-append res "/swiftshader")))
                  (mkdir-p swift-target)
                  (for-each (lambda (file) (install-file file swift-target))
                            (find-files "out/Release/swiftshader" "\\.so$")))

                (wrap-program (string-append bin "/chromium")
                  `("LD_LIBRARY_PATH" ":" prefix
                    (,(string-append res ":" res "/swiftshader"))))))))))
    (native-inputs
     (list bison
           clang
           gn
           gperf
           lld-wrapper
           ninja
           node-lts
           pkg-config
           python-beautifulsoup4
           python-html5lib
           python-wrapper
           rust
           which
           zstd))
    (inputs
     (list alsa-lib
           at-spi2-core
           cups
           dbus
           ffmpeg
           flac
           fontconfig
           freetype
           glib
           gtk+
           harfbuzz
           icu4c
           libdrm
           libffi
           libjpeg-turbo
           libpng
           libva
           libvpx
           libwebp
           libx11
           libxrandr
           libxml2
           libxslt
           mesa
           nspr
           nss
           openh264
           openjpeg
           opus+custom
           pango
           pulseaudio
           re2
           snappy
           vulkan-headers
           vulkan-loader
           zlib))
    (synopsis "Ungoogled Chromium web browser")
    (description "Ungoogled-Chromium is the Chromium web browser, with patches
to remove Google integration and enhance privacy.")
    (home-page "https://github.com/ungoogled-software/ungoogled-chromium")
    (license license:bsd-3)))

ungoogled-chromium
