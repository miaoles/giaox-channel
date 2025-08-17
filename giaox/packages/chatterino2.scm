(define-module (giaox packages chatterino2)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages bash)
  #:use-module (guix gexp)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages web)
  #:use-module (gnu packages gnome)
  #:use-module (giaox packages boost))

;; (define-public chatterino2
;;   (package
;;     (name "chatterino2")
;;     (version "2.5.3")
;;     (source (origin
;;               (method git-fetch)
;;               (uri (git-reference
;;                     (url "https://github.com/Chatterino/chatterino2")
;;                     (commit "3f3a31db4ddf3b634eff78b3201f15e6b8ce7b14")
;;                     (recursive? #t)))
;;               (file-name (git-file-name name version))
;;               (sha256
;;                (base32
;;                 "1fs13vdxbq2dbxr21wp9mvn33bhvnmg17rqdd6yawsgslab2lssv"))))
;;     (build-system cmake-build-system)
;;     (arguments
;;      `(#:tests? #f
;;        #:configure-flags '("-DBUILD_WITH_QT6=ON"
;;                           "-DUSE_SEVENTV=ON"
;;                           "-DBUILD_WITH_QTKEYCHAIN=OFF")
;;        #:phases
;;        (modify-phases %standard-phases
;;          (add-after 'unpack 'fix-build-and-update-7tv
;;            (lambda _
;;              (substitute* "CMakeLists.txt"
;;                (("find_package\\(Qt6 COMPONENTS Widgets Multimedia Network Svg Concurrent REQUIRED\\)")
;;                 "find_package(Qt6 COMPONENTS Widgets Multimedia Network Svg Concurrent OpenGLWidgets REQUIRED)")
;;                (("target_link_libraries\\(\\$\\{PROJECT_NAME\\} PRIVATE Qt::Widgets Qt::Multimedia Qt::Network Qt::Svg Qt::Concurrent\\)")
;;                 "target_link_libraries(${PROJECT_NAME} PRIVATE Qt::Widgets Qt::Multimedia Qt::Network Qt::Svg Qt::Concurrent Qt::OpenGLWidgets)"))
;;              (substitute* "src/providers/seventv/SeventvEmotes.cpp"
;;                (("https://api.7tv.app/v2")
;;                 "https://7tv.io/v3"))))
;;          (add-after 'install 'wrap-program
;;            (lambda* (#:key inputs outputs #:allow-other-keys)
;;              (let ((out (assoc-ref outputs "out")))
;;                (wrap-program (string-append out "/bin/chatterino")
;;                  `("QT_PLUGIN_PATH" ":" prefix
;;                    ,(map (lambda (label)
;;                            (string-append (assoc-ref inputs label)
;;                                         "/lib/qt6/plugins"))
;;                          '("qtsvg" "qtimageformats"))))))))))
;;     (native-inputs
;;      (list pkg-config))
;;     (inputs
;;      (list qtbase
;;            qtsvg
;;            qtmultimedia
;;            qtimageformats
;;            qt5compat
;;            boost
;;            openssl
;;            rapidjson
;;            libnotify))
;;     (home-page "https://github.com/Chatterino/chatterino2")
;;     (synopsis "Chat client for Twitch chat")
;;     (description
;;      "Chatterino is a chat client for Twitch chat.  It aims to be an
;; improved/extended version of the Twitch web chat.  Chatterino 2 is the second
;; installment of the Twitch chat client series \"Chatterino\".")
;;     (license expat)))


(define-public chatterino2
  (package
    (name "chatterino2")
    (version "2.5.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Chatterino/chatterino2")
             (commit (string-append "v" version))
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1fs13vdxbq2dbxr21wp9mvn33bhvnmg17rqdd6yawsgslab2lssv"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "-DCMAKE_BUILD_TYPE=Release" "-DCHATTERINO_UPDATER=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'check)
          (add-before 'configure 'setvars
            (lambda _
              (setenv "GIT_HASH" "3f3a31db")))
          (add-after 'install 'wrap-executable
            (lambda* _
              (let ((plugin-path (getenv "QT_PLUGIN_PATH")))
                (wrap-program (string-append #$output "/bin/chatterino")
                  `("QT_PLUGIN_PATH" ":" prefix
                    (,plugin-path)))))))))
    (native-inputs (list pkg-config))
    (inputs (list qtbase
                  qtsvg
                  qttools
                  qt5compat
                  boost
                  bash-minimal
                  openssl
                  libsecret
                  libnotify
                  qtwayland
                  qtimageformats))
    (synopsis "Chat client for Twitch")
    (description
     "Chatterino is a chat client for Twitch chat.
It aims to be an improved/extended version of the Twitch web chat.")
    (home-page "https://chatterino.com")
    (license expat)))

chatterino2
