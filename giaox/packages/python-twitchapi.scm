(define-module (giaox packages python-twitchapi)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages time)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages check)
  #:use-module (gnu packages python-check)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages )
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (srfi srfi-1))

(define-public python-twitchapi
  (package
    (name "python-twitchapi")
    (version "4.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "twitchapi" version))
       (sha256
        (base32 "130c56g9hcr6j5n4p37fmkgcbwljvx2714s7s61grpciv29kiir4"))))
    (build-system pyproject-build-system)
    (propagated-inputs (list python-aiohttp python-dateutil
                             python-typing-extensions))
    (home-page "https://github.com/Teekeks/pyTwitchAPI")
    (synopsis
     "A Python 3.7+ implementation of the Twitch Helix API, PubSub, EventSub and Chat")
    (description
     "This package provides a Python 3.7+ implementation of the Twitch Helix API,
@code{PubSub}, @code{EventSub} and Chat.")
    (license license:expat)))

(define-public python-aiohttp
  (package
    (name "python-aiohttp")
    (version "3.9.5")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "aiohttp" version))
       (sha256
        (base32 "0l9md5njzq1dd3r49q8c2spbdksb5m45xxdgnjfv5vicfwapvspd"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f  ; Temporarily disable tests
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'set-build-env
           (lambda _
             (setenv "AIOHTTP_NO_EXTENSIONS" "1")))
         (delete 'check))))  ; Remove the default check phase
    (native-inputs
     (list python-setuptools))
    (propagated-inputs
     (list python-aiosignal
           python-async-timeout
           python-attrs
           python-frozenlist
           python-multidict
           python-yarl
           python-typing-extensions))
    (home-page "https://github.com/aio-libs/aiohttp")
    (synopsis "Async http client/server framework (asyncio)")
    (description "Async http client/server framework (asyncio).")
    (license license:asl2.0)))

(define-public python-aiodns
  (package
    (name "python-aiodns")
    (version "3.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "aiodns" version))
       (sha256
        (base32
         "0wlgfvl1gqz8arbnfdlyk9626srik24yr0r80wdw4jck80irp1k2"))))
    (build-system python-build-system)
    (propagated-inputs (list python-pycares))
    (arguments
     `(#:tests? #f))                    ;tests require internet access
    (home-page "https://github.com/saghul/aiodns")
    (synopsis "Simple DNS resolver for asyncio")
    (description "@code{aiodns} provides a simple way for doing
asynchronous DNS resolutions with a synchronous looking interface by
using @url{https://github.com/saghul/pycares,pycares}.")
    (license license:expat)))

(define-public python-aiosignal
  (package
    (name "python-aiosignal")
    (version "1.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "aiosignal" version))
       (sha256
        (base32 "1z4cnqww6j0xl6f3vx2r6kfv1hdny1pnlll7difvfj8nbvhrdkal"))))
    (build-system pyproject-build-system)
    (arguments (list #:test-flags #~(list "tests")))
    (propagated-inputs (list python-frozenlist))
    (native-inputs (list python-pytest python-pytest-asyncio python-pytest-cov))
    (home-page "https://github.com/aio-libs/aiosignal")
    (synopsis "Callback manager for Python @code{asyncio} projects")
    (description "This Python module provides @code{Signal}, an abstraction to
register asynchronous callbacks.  The @code{Signal} abstraction can be used
for adding, removing and dropping callbacks.")
    (license license:asl2.0)))

(define-public python-frozenlist
  (package
    (name "python-frozenlist")
    (version "1.4.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "frozenlist" version))
       (sha256
        (base32 "0as0xp4fhxy8x4ycxak9dfdrs2xrgf0lvfma2ck9l18khmpahdy0"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f  ; Disable tests
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'set-build-env
           (lambda _
             (setenv "FROZENLIST_NO_EXTENSIONS" "1")))
         (add-after 'unpack 'fix-build-backend
           (lambda _
             (substitute* "pyproject.toml"
               (("backend-path.*") "")
               (("build-backend.*") "build-backend = \"setuptools.build_meta\"\n")))))))
    (native-inputs
     (list python-pytest))
    (propagated-inputs
     (list python-setuptools
           python-wheel
           python-expandvars
           python-tomli))
    (home-page "https://github.com/aio-libs/frozenlist")
    (synopsis "List-like data structure for Python")
    (description "@code{frozenlist.FrozenList} is a list-like structure which
implements @code{collections.abc.MutableSequence}.  It can be made immutable
by calling @code{FrozenList.freeze}.")
    (license license:asl2.0)))

(define-public python-expandvars
  (package
    (name "python-expandvars")
    (version "0.12.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "expandvars" version))
       (sha256
        (base32 "0i6q4i8dzsax85w1l2hc7saymyh3fw43vkifh5flpkr8ayjxy6kx"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f))  ; Disable tests
    (native-inputs
     (list python-hatchling))
    (propagated-inputs
     (list python-setuptools))
    (home-page "https://github.com/sayanarijit/expandvars")
    (synopsis "Expand system variables Unix style")
    (description "Expand system variables Unix style.")
    (license license:expat)))

(define-public python-yarl
  (package
    (name "python-yarl")
    (version "1.9.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "yarl" version))
       (sha256
        (base32 "1gs6hapnz5wsb1zfi0b6y10aw259ffvq7c2qkfwq106g2xkvhvan"))))
    (build-system pyproject-build-system)
    (arguments
     '(#:tests? #f  ; Disable tests
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'set-build-env
           (lambda _
             (setenv "YARL_NO_EXTENSIONS" "1")))
         (add-after 'unpack 'fix-build-backend
           (lambda _
             (substitute* "pyproject.toml"
               (("backend-path.*") "")
               (("build-backend.*") "build-backend = \"setuptools.build_meta\"\n")))))))
    (native-inputs
     (list python-pytest))
    (propagated-inputs
     (list python-idna
           python-multidict
           python-typing-extensions
           python-setuptools
           python-wheel
           python-expandvars
           python-tomli))
    (home-page "https://github.com/aio-libs/yarl")
    (synopsis "Yet another URL library")
    (description "Yet another URL library.")
    (license license:asl2.0)))

(define-public python-pycares
  (package
    (name "python-pycares")
    (version "4.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pycares" version))
       (sha256
        (base32
         "1hp16c3v78dnwacqc2bqnsrv3lrag12j1rvcs7fnxxgj13apjxgl"))))
    (build-system python-build-system)
    (arguments `(#:tests? #f))          ;tests require internet access
    (propagated-inputs (list python-cffi))
    (home-page "https://github.com/saghul/pycares")
    (synopsis "Python interface for @code{c-ares}")
    (description "@code{pycares} is a Python module which provides an
interface to @code{c-ares}, a C library that performs DNS requests and
name resolutions asynchronously.")
    (license license:expat)))

python-twitchapi
