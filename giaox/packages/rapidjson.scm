(define-module (giaox packages rapidjson)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages check)
  #:use-module (gnu packages valgrind)
  #:use-module (guix gexp))

(define-public rapidjson
  ;; Last release was in 2016, but this commit is from 2023.
  (let ((commit "24b5e7a8b27f42fa16b96fc70aade9106cf7102f")
        (revision "1"))
    (package
      (name "rapidjson")
      (version (git-version "1.1.0" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/Tencent/rapidjson")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1gwzhp43h8j0id82h87nba16abiw67dv3c20jczvcvyc21hwnwd0"))
                (modules '((guix build utils)))
                (snippet
                 '(begin
                    ;; Remove code using the problematic JSON license (see
                    ;; <https://www.gnu.org/licenses/license-list.html#JSON>).
                    (delete-file-recursively "bin/jsonchecker")))))
      (build-system cmake-build-system)
      (arguments
       '(#:configure-flags (list "-DCMAKE_CXX_FLAGS=-Wno-free-nonheap-object -Wno-stringop-overflow")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'fix-march=native
             (lambda _
               (substitute* "CMakeLists.txt"
                 (("-m[^-]*=native") ""))))
           (add-after 'fix-march=native 'skip-deleted-tests
             (lambda _
               (substitute* "test/unittest/CMakeLists.txt"
                 (("jsoncheckertest.cpp") ""))))
           (add-after 'fix-march=native 'fix-dependencies
             (lambda _
               (substitute* "test/CMakeLists.txt"
                 (("^find_package\\(GTestSrc\\)")
                  "find_package(GTest REQUIRED)")
                 ((".*GTEST_SOURCE_DIR.*") "")
                 (("GTESTSRC_FOUND)")
                  "GTest_FOUND)")))))))
      (native-inputs (list valgrind/pinned))
      (inputs (list googletest))
      (home-page "https://github.com/Tencent/rapidjson")
      (synopsis "JSON parser/generator for C++ with both SAX/DOM style API")
      (description
       "RapidJSON is a fast JSON parser/generator for C++ with both SAX/DOM
style API.")
      (license expat))))

rapidjson
