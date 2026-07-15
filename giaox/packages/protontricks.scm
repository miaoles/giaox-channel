(define-module (giaox packages python-protontricks)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system python)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages python-build))

(define-public python-protontricks
  (package
    (name "python-protontricks")
    (version "1.11.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Matoking/protontricks")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "01ww6w4qmvfpm9hqlqi5b1rwyix7ifzjj5yah2l4jhzkb800i3bb"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'build 'set-version
           (lambda _
             (setenv "SETUPTOOLS_SCM_PRETEND_VERSION" ,version)))
         (add-after 'unpack 'patch-steam-path
  (lambda _
    (substitute* "src/protontricks/steam.py"
      (("subprocess\\.run\\(\\[\"steam\"")
       "subprocess.run([\"steam-container\"")
      (("def find_steam_path\\(\\):")
       "def find_steam_path():
    guix_sandbox_home = os.environ.get('GUIX_SANDBOX_HOME')
    if guix_sandbox_home:
        steam_path = os.path.join(guix_sandbox_home, '.local', 'share', 'Steam')
        if os.path.isdir(steam_path):
            return steam_path
    # Continue with the original function if GUIX_SANDBOX_HOME is not set")
      (("def find_proton_app\\(")
       "def find_proton_app(steam_apps, appid=None, compat_tool=None, steam_path=None):
    guix_sandbox_home = os.environ.get('GUIX_SANDBOX_HOME')
    if guix_sandbox_home and steam_path:
        proton_path = os.path.join(steam_path, 'steamapps', 'common', 'Proton - Experimental')
        if os.path.isdir(proton_path):
            return SteamApp(appid='0', name='Proton - Experimental', install_path=proton_path)
    # Continue with the original function if GUIX_SANDBOX_HOME is not set or Proton is not found")
      (("def get_proton_app\\(")
       "def get_proton_app(steam_path, appid=None, compat_tool=None):
    proton_app = find_proton_app(None, appid, compat_tool, steam_path)
    if proton_app:
        proton_app.install_path = os.path.join(steam_path, 'steamapps', 'common', 'Proton - Experimental')
    return proton_app"))))
(add-after 'install 'wrap-binary
  (lambda* (#:key inputs outputs #:allow-other-keys)
    (let* ((out (assoc-ref outputs "out"))
           (winetricks (assoc-ref inputs "winetricks"))
           (yad (assoc-ref inputs "yad")))
      (wrap-program (string-append out "/bin/protontricks")
        `("PATH" ":" prefix
          (,(string-append winetricks "/bin:"
                           yad "/bin")))
        `("STEAM_RUNTIME" = ("0"))
        `("STEAM_DIR" = ("$GUIX_SANDBOX_HOME/.local/share/Steam"))
        `("PROTONTRICKS_CACHE_DIR" = ("$GUIX_SANDBOX_HOME/.cache/protontricks"))))))
         (delete 'check))))
    (native-inputs
     (list python-setuptools-scm))
    (inputs
     (list winetricks yad))
    (propagated-inputs
     (list python-pillow python-setuptools python-vdf))
    (home-page "https://github.com/Matoking/protontricks")
    (synopsis "Wrapper for running Winetricks commands for Proton-enabled games")
    (description
     "Protontricks is a simple wrapper that allows you to run Winetricks commands
for Steam Play/Proton games.  This is often useful when a game requires closed-source
runtime libraries that are not included with Proton.")
    (license license:gpl3+)))

python-protontricks
