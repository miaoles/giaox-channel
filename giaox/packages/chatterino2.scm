(define-module (giaox packages chatterino2)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages vulkan)
  #:use-module (boost boost))

(define-public chatterino2
  (package
    (name "chatterino2")
    (version "2.5.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/Chatterino/chatterino2")
                    (commit (string-append "v" version))
                    (recursive? #t)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "04f0jngdmlzjbq0wbhc9hny50nkqynq7y3jx57ii5qrrxg6n2xbk"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f
       #:configure-flags '("-DBUILD_WITH_QT6=ON")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-build
           (lambda _
             (substitute* "CMakeLists.txt"
               (("find_package\\(Qt6 COMPONENTS Widgets Multimedia Network Svg Concurrent REQUIRED\\)")
                "find_package(Qt6 COMPONENTS Widgets Multimedia Network Svg Concurrent OpenGLWidgets REQUIRED)")
               (("target_link_libraries\\(\\$\\{PROJECT_NAME\\} PRIVATE Qt::Widgets Qt::Multimedia Qt::Network Qt::Svg Qt::Concurrent\\)")
                "target_link_libraries(${PROJECT_NAME} PRIVATE Qt::Widgets Qt::Multimedia Qt::Network Qt::Svg Qt::Concurrent Qt::OpenGLWidgets)")))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list qtbase
           qtsvg
           qtmultimedia
           qtimageformats
           qttools
           qt5compat
           boost
           openssl
           libsecret
           qtwayland
           libxkbcommon
           vulkan-headers))
    (home-page "https://github.com/Chatterino/chatterino2")
    (synopsis "Chat client for Twitch chat")
    (description
     "Chatterino is a chat client for Twitch chat.  It aims to be an
improved/extended version of the Twitch web chat.  Chatterino 2 is the second
installment of the Twitch chat client series \"Chatterino\".")
    (license license:expat)))

chatterino2
