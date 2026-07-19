(define-module (giaox packages chatterino2)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages bash)
  #:use-module (guix gexp)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages web)
  #:use-module (gnu packages gnome)
  #:use-module (giaox packages boost))

(define-public chatterino2
  (package
    (name "chatterino2")
    (version "2.5.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Chatterino/chatterino2")
             (commit (string-append "v" version))
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0qyhqb5fb10lzy5w7qii981kl2rwxbq6slffbgqdlpdw7knzpr9k"))))
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
    (license license:expat)))

chatterino2
