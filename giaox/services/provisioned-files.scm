;;; Generic file provisioning for home environments.
;;;
;;; A provisioned file is a relative name, realised in one or more roots,
;;; bound by a declared method to a declared source, under a declared policy,
;;; and owned by the home generation that declares it.  Design, invariants,
;;; manifest format, and the rule identifiers raised below:
;;; documents/provisioned-files.txt.

(define-module (giaox services provisioned-files)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module (guix modules)
  #:use-module (guix monads)
  #:use-module (guix records)
  #:use-module (guix store)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (provisioning-root
            provisioning-root?
            provisioning-root-name
            provisioning-root-path
            provisioning-root-mount
            %home-root
            root-shell-path

            live-file
            live-file?
            live-file-path
            live-file-root

            provisioned-file
            provisioned-file?
            provisioned-file-source
            provisioned-file-target
            provisioned-file-roots
            provisioned-file-method
            provisioned-file-policy
            provisioned-file-permissions

            provisioned-files-configuration
            provisioned-files-configuration?
            provisioned-files-configuration-roots
            provisioned-files-configuration-files

            %provisioned-file-methods
            %provisioned-file-policies

            store-source?
            live-source?
            normalize-path
            lookup-provisioning-root
            resolve-live-file
            provisioned-file-host-path
            provisioned-file-namespace-path
            provisioned-files-configuration-targets

            validate-provisioning-root
            validate-provisioned-file
            validate-provisioned-files-configuration

            home-provisioned-files-service-type))


;;;
;;; Paths.  One syntax: targets are relative, everything else is '~'-anchored
;;; or absolute.  Expansion of '~' happens at activation, never here.
;;;

(define (path-components path)
  (filter (lambda (component) (not (string-null? component)))
          (string-split path #\/)))

(define (normalize-path path)
  "Collapse repeated slashes and drop trailing ones, preserving a leading /."
  (let ((body (string-join (path-components path) "/")))
    (if (string-prefix? "/" path)
        (string-append "/" body)
        body)))

(define (home-anchored-path? path)
  (and (string? path)
       (or (string=? path "~")
           (string-prefix? "~/" path))))

(define (absolute-path? path)
  (and (string? path) (string-prefix? "/" path)))

(define (anchored-path? path)
  (or (home-anchored-path? path) (absolute-path? path)))

(define (relative-path? path)
  (and (string? path)
       (not (string-null? path))
       (not (string-prefix? "/" path))
       (not (string-prefix? "~" path))
       (let ((components (path-components path)))
         (and (pair? components)
              (not (any (lambda (component)
                          (or (string=? component ".")
                              (string=? component "..")))
                        components))))))

(define (path-join base relative)
  (normalize-path (string-append base "/" relative)))

(define (provisioning-error rule message . irritants)
  (apply error (string-append "provisioned-files: " rule ": " message)
         irritants))


;;;
;;; Roots.  A root whose MOUNT differs from its PATH is a namespace root.
;;;

(define-record-type* <provisioning-root>
  provisioning-root make-provisioning-root
  provisioning-root?
  this-provisioning-root
  (name  provisioning-root-name)
  (path  provisioning-root-path)
  (mount provisioning-root-mount
         (thunked)
         (default (provisioning-root-path this-provisioning-root))))

(define %home-root
  (provisioning-root (name 'home) (path "~")))

(define (root-shell-path root)
  "Render ROOT's host path for a shell context: a leading ~ becomes $HOME."
  (let ((path (provisioning-root-path root)))
    (cond ((string=? path "~") "$HOME")
          ((string-prefix? "~/" path)
           (string-append "$HOME/" (substring path 2)))
          (else path))))


;;;
;;; Sources.  A file-like is the store; a <live-file> is the filesystem.
;;;

(define-record-type* <live-file>
  live-file make-live-file
  live-file?
  (path live-file-path)
  (root live-file-root (default #f)))

(define (live-source? source)
  (live-file? source))

(define (store-source? source)
  (and (not (live-file? source))
       (file-like? source)))


;;;
;;; Entries and configuration.
;;;

(define %provisioned-file-methods '(copy hard-link symlink))
(define %provisioned-file-policies '(seed enforce))

(define-record-type* <provisioned-file>
  provisioned-file make-provisioned-file
  provisioned-file?
  (source      provisioned-file-source)
  (target      provisioned-file-target)
  (roots       provisioned-file-roots       (default '(home)))
  (method      provisioned-file-method      (default 'copy))
  (policy      provisioned-file-policy      (default 'seed))
  (permissions provisioned-file-permissions (default #f)))

(define-record-type* <provisioned-files-configuration>
  provisioned-files-configuration make-provisioned-files-configuration
  provisioned-files-configuration?
  (roots provisioned-files-configuration-roots (default (list %home-root)))
  (files provisioned-files-configuration-files (default '())))


;;;
;;; Resolution.  Host paths answer "where is it"; namespace paths answer
;;; "what absolute path names it inside its namespace" — the string that may
;;; legitimately be written into provisioned content.
;;;

(define (lookup-provisioning-root roots name)
  (or (find (lambda (root) (eq? (provisioning-root-name root) name)) roots)
      (provisioning-error "V10" "entry names an undeclared root:" name)))

(define (resolve-live-file source roots)
  (let ((path (live-file-path source))
        (name (live-file-root source)))
    (if name
        (path-join (provisioning-root-path (lookup-provisioning-root roots name))
                   path)
        (normalize-path path))))

(define (provisioned-file-host-path file root)
  (path-join (provisioning-root-path root) (provisioned-file-target file)))

(define (provisioned-file-namespace-path file root)
  (path-join (provisioning-root-mount root) (provisioned-file-target file)))

(define (provisioned-files-configuration-targets config)
  "Return every host path CONFIG provisions, in declaration order."
  (let ((roots (provisioned-files-configuration-roots config)))
    (append-map
     (lambda (file)
       (map (lambda (name)
              (provisioned-file-host-path
               file (lookup-provisioning-root roots name)))
            (provisioned-file-roots file)))
     (provisioned-files-configuration-files config))))


;;;
;;; Validation.  V2 and V7 are runtime facts and are enforced at activation.
;;;

;; Reserved: `copy' writes through a sibling of this name (S5).  V5 keeps it
;; out of the target namespace, so a temp can never be another entry's target.
(define %temp-file-prefix ".provisioned-files-tmp-")

(define %default-permissions #o644)

(define (validate-provisioning-root root)
  (unless (symbol? (provisioning-root-name root))
    (provisioning-error "V10" "root name is not a symbol:"
                        (provisioning-root-name root)))
  (unless (anchored-path? (provisioning-root-path root))
    (provisioning-error "V5" "root path is neither ~-anchored nor absolute:"
                        (provisioning-root-path root)))
  (unless (anchored-path? (provisioning-root-mount root))
    (provisioning-error "V5" "root mount is neither ~-anchored nor absolute:"
                        (provisioning-root-mount root)))
  root)

(define (validate-provisioned-file file)
  "Check every rule an entry decides without the root table."
  (let ((source      (provisioned-file-source file))
        (target      (provisioned-file-target file))
        (roots       (provisioned-file-roots file))
        (method      (provisioned-file-method file))
        (policy      (provisioned-file-policy file))
        (permissions (provisioned-file-permissions file)))

    (when (string? source)
      (provisioning-error "V9"
                          "a bare string is not a source; use (local-file ...) or (live-file (path ...)):"
                          source))
    (unless (or (live-source? source) (store-source? source))
      (provisioning-error "V9" "source is neither a file-like nor a <live-file>:"
                          source))

    (unless (memq method %provisioned-file-methods)
      (provisioning-error "V10" "unknown method:" method))
    (unless (memq policy %provisioned-file-policies)
      (provisioning-error "V10" "unknown policy:" policy))
    (unless (and (pair? roots) (every symbol? roots))
      (provisioning-error "V10" "roots is not a non-empty list of symbols:"
                          roots))
    (unless (= (length roots) (length (delete-duplicates roots eq?)))
      (provisioning-error "V10" "roots repeats a name:" roots))

    (unless (relative-path? target)
      (provisioning-error "V5" "target is not a clean relative path:" target))
    (when (string-prefix? %temp-file-prefix (basename target))
      (provisioning-error "V5" "target uses the reserved temp-file prefix:"
                          target))

    (when (live-source? source)
      (let ((path (live-file-path source)))
        (if (live-file-root source)
            (unless (relative-path? path)
              (provisioning-error "V5" "rooted live-file path is not relative:"
                                  path))
            (unless (anchored-path? path)
              (provisioning-error "V5"
                                  "unrooted live-file path is neither ~-anchored nor absolute:"
                                  path)))))

    (when (and (eq? method 'hard-link) (not (live-source? source)))
      (provisioning-error "V1"
                          "hard-link requires a <live-file> source; target:"
                          target))

    (unless (or (not permissions)
                (and (exact-integer? permissions)
                     (>= permissions 0)
                     (<= permissions #o7777)))
      (provisioning-error "V4" "permissions is neither #f nor an octal mode:"
                          permissions))
    (when (and permissions (not (eq? method 'copy)))
      (provisioning-error "V4" "permissions is meaningful only with copy; method:"
                          method))

    file))

(define (validate-provisioned-files-configuration config)
  "Check CONFIG in full and return it.  Raises on the first violation, naming
the rule."
  (let* ((roots (provisioned-files-configuration-roots config))
         (files (provisioned-files-configuration-files config))
         (names (map provisioning-root-name roots)))

    (for-each validate-provisioning-root roots)
    (unless (= (length names) (length (delete-duplicates names eq?)))
      (provisioning-error "V10" "two roots share a name:" names))

    (for-each validate-provisioned-file files)

    (for-each
     (lambda (file)
       (when (eq? (provisioned-file-method file) 'symlink)
         (for-each
          (lambda (name)
            (let ((root (lookup-provisioning-root roots name)))
              (unless (string=? (normalize-path (provisioning-root-path root))
                                (normalize-path (provisioning-root-mount root)))
                (provisioning-error "V3"
                                    "symlink in a namespace root is ambiguous; root, target:"
                                    name (provisioned-file-target file)))))
          (provisioned-file-roots file))))
     files)

    (let ((targets (provisioned-files-configuration-targets config)))
      (unless (= (length targets) (length (delete-duplicates targets string=?)))
        (provisioning-error "V6" "two entries resolve to one target; targets:"
                            targets))

      (for-each
       (lambda (file)
         (let ((source (provisioned-file-source file)))
           (when (live-source? source)
             (let ((path (resolve-live-file source roots)))
               (when (member path targets string=?)
                 (provisioning-error "V8"
                                     "a live source is also a provisioned target:"
                                     path))))))
       files))

    config))


;;;
;;; The manifest.  A record is
;;;   (TARGET ROOT METHOD POLICY PERMISSIONS KIND SOURCE)
;;; with TARGET resolved and '~'-prefixed, and SOURCE a store path when KIND
;;; is `store'.  See documents/provisioned-files.txt, MANIFEST FORMAT.
;;;

(define %manifest-version 1)
(define %manifest-name "provisioned-files")

(define (provisioned-files-records config)
  "Validate CONFIG and return one record gexp per (entry, root)."
  (validate-provisioned-files-configuration config)
  (let ((roots (provisioned-files-configuration-roots config)))
    (append-map
     (lambda (file)
       (let* ((source (provisioned-file-source file))
              (live?  (live-source? source))
              (origin (if live? (resolve-live-file source roots) source)))
         (map (lambda (name)
                (let ((root (lookup-provisioning-root roots name)))
                  #~(#$(provisioned-file-host-path file root)
                     #$name
                     #$(provisioned-file-method file)
                     #$(provisioned-file-policy file)
                     #$(provisioned-file-permissions file)
                     #$(if live? 'live 'store)
                     #$origin)))
              (provisioned-file-roots file))))
     (provisioned-files-configuration-files config))))

(define (provisioned-files-manifest config)
  (scheme-file %manifest-name
               #~(provisioned-files
                  (version #$%manifest-version)
                  (files #$(provisioned-files-records config)))))

(define (provisioned-files-generation-entry config)
  (with-monad %store-monad
    (return `((,%manifest-name ,(provisioned-files-manifest config))))))


;;;
;;; Activation.  Collection precedes materialisation (S6); classification is
;;; four-way against both records (S3); only `enforce' backs up (S1) and only
;;; `enforce' is collected (C6); nothing is deleted that cannot be proven ours
;;; (C4); no precondition is discovered after a destructive step (S10).  The
;;; old generation is $GUIX_OLD_HOME and nothing else (C10).
;;;

(define (provisioned-files-activation-program config)
  "Return a program-file that reconciles CONFIG against the previous
generation's manifest.  Its TOP LEVEL is a real top level, which is the whole
reason it exists; see provisioned-files-activation."
  (let ((records (provisioned-files-records config)))
    (program-file
     "provisioned-files-activate"
     (with-imported-modules (source-module-closure '((guix build utils)))
       #~(begin
           (use-modules (guix build utils)
                        (ice-9 binary-ports)
                        (ice-9 match)
                        (srfi srfi-1))

           (define %version #$%manifest-version)
           (define %records '#$records)
           (define %home (getenv "HOME"))
           (define %old-home (or (getenv "GUIX_OLD_HOME")
                                 "/gnu/store/non-existing-generation"))
           (define %backup-directory
             (string-append %home "/" (number->string (current-time))
                            "-provisioned-files-backup"))

           (define (say format-string . arguments)
             (apply format #t
                    (string-append "provisioned-files: " format-string "~%")
                    arguments))

           (define (expand path)
             (cond ((string=? path "~") %home)
                   ((string-prefix? "~/" path)
                    (string-append %home "/" (substring path 2)))
                   (else path)))

           (define (lstat* path) (false-if-exception (lstat path)))

           (define (file-type* path)
             (let ((st (lstat* path)))
               (and st (stat:type st))))

           (define (device-of path) (stat:dev (stat path)))

           (define (temp-path target)
             (string-append (dirname target) "/"
                            #$%temp-file-prefix (basename target)))

           (define (regular-source! source)
             (let ((st (false-if-exception (stat source))))
               (cond ((not st)
                      (error "provisioned-files: source does not exist" source))
                     ((not (eq? (stat:type st) 'regular))
                      (error "provisioned-files: V7: source is not a regular file"
                             source))
                     (else #t))))

           ;; Every precondition an entry has, asserted before the first
           ;; destructive call on its behalf (S10).  TARGET's parent exists.
           (define (assert-source! method target source)
             (case method
               ((copy) (regular-source! source))
               ((hard-link)
                (regular-source! source)
                (let ((canonical (canonicalize-path source)))
                  (unless (= (device-of canonical) (device-of (dirname target)))
                    (error "provisioned-files: S9: hard link across filesystems"
                           canonical target))))
               (else #t)))

           (define (files-equal? target source)
             (let ((ts (lstat* target))
                   (ss (false-if-exception (stat source))))
               (and ts ss
                    (eq? (stat:type ts) 'regular)
                    (eq? (stat:type ss) 'regular)
                    (= (stat:size ts) (stat:size ss))
                    (call-with-input-file target
                      (lambda (target-port)
                        (call-with-input-file source
                          (lambda (source-port)
                            (let loop ()
                              (let ((a (get-bytevector-n target-port 65536))
                                    (b (get-bytevector-n source-port 65536)))
                                (cond ((and (eof-object? a) (eof-object? b)) #t)
                                      ((or (eof-object? a) (eof-object? b)) #f)
                                      ((equal? a b) (loop))
                                      (else #f)))))
                          #:binary #t))
                      #:binary #t))))

           ;; The shape test of S3, per method.  `hard-link' is identity, not
           ;; content: one inode on one device.  `stat' follows, matching what
           ;; create! linked after canonicalisation.
           (define (matches? method target source)
             (case method
               ((symlink)
                (and (eq? (file-type* target) 'symlink)
                     (string=? (readlink target) source)))
               ((copy) (files-equal? target source))
               ((hard-link)
                (let ((ts (lstat* target))
                      (ss (false-if-exception (stat source))))
                  (and ts ss
                       (= (stat:dev ts) (stat:dev ss))
                       (= (stat:ino ts) (stat:ino ss)))))
               (else #f)))

           (define (remove! target)
             (if (eq? (file-type* target) 'directory)
                 (delete-file-recursively target)
                 (delete-file target)))

           ;; create! owns replacement: symlink(2) and link(2) refuse an
           ;; existing name, and rename(2) replaces atomically, so a failed copy
           ;; leaves the old content intact rather than a hole.  link(2) does
           ;; not dereference a symlink, hence canonicalize-path.
           (define (create! method target source permissions)
             (assert-source! method target source)
             (case method
               ((symlink)
                (when (lstat* target) (remove! target))
                (symlink source target))
               ((copy)
                (let ((temporary (temp-path target)))
                  (when (lstat* temporary) (remove! temporary))
                  (copy-file source temporary)
                  (chmod temporary (or permissions #$%default-permissions))
                  (rename-file temporary target)))
               ((hard-link)
                (when (lstat* target) (remove! target))
                (link (canonicalize-path source) target))
               (else
                (error "provisioned-files: unknown method" method))))

           (define (store-symlink? target)
             (and (eq? (file-type* target) 'symlink)
                  (string-prefix? "/gnu/store/" (readlink target))))

           (define (backup! target)
             (let* ((prefix (string-append %home "/"))
                    (relative (if (string-prefix? prefix target)
                                  (substring target (string-length prefix))
                                  (substring target 1)))
                    (destination (string-append %backup-directory "/" relative)))
               (mkdir-p (dirname destination))
               (case (file-type* target)
                 ((symlink) (symlink (readlink target) destination)
                            (delete-file target))
                 ((directory) (copy-recursively target destination)
                              (delete-file-recursively target))
                 (else
                  ;; A hard link preserves the inode at no cost; copy only when
                  ;; the backup directory is on another filesystem (S4).
                  (if (= (device-of target) (device-of (dirname destination)))
                      (link target destination)
                      (copy-file target destination))
                  (delete-file target)))
               (say "backed up ~a to ~a" target destination)))

           (define (read-manifest directory)
             (let ((file (string-append directory "/" #$%manifest-name)))
               (if (file-exists? file)
                   (match (call-with-input-file file read)
                     (('provisioned-files ('version version) ('files records))
                      (unless (= version %version)
                        (error "provisioned-files: C7: unrecognised manifest version"
                               version file))
                      records)
                     (_ (error "provisioned-files: C7: malformed manifest" file)))
                   '())))

           (define (target-of record) (car record))

           (define (ours? record target)
             (match record
               ((_ _ method _ _ _ source)
                (matches? method target (expand source)))))

           (define (collect! old new-targets)
             (for-each
              (lambda (record)
                (match record
                  ((target root method policy permissions kind source)
                   (when (and (eq? policy 'enforce)
                              (not (member target new-targets string=?)))
                     (let ((t (expand target)))
                       (cond ((not (lstat* t)) #t)
                             ((ours? record t)
                              (remove! t)
                              (let ((temporary (temp-path t)))
                                (when (lstat* temporary) (remove! temporary)))
                              (say "collected ~a" t))
                             (else
                              (say "kept, modified since provisioned: ~a" t))))))))
              old))

           (define (materialise! records old)
             (for-each
              (lambda (record)
                (match record
                  ((target root method policy permissions kind source)
                   (let* ((t (expand target))
                          (s (expand source))
                          (previous (find (lambda (r)
                                            (string=? (target-of r) target))
                                          old)))
                     (mkdir-p (dirname t))
                     (cond
                      ((matches? method t s) #t)              ; ALREADY
                      ((eq? policy 'seed)                     ; never clobbers
                       (unless (lstat* t)
                         (create! method t s permissions)
                         (say "seeded ~a" t)))
                      ((not (lstat* t))                       ; ABSENT
                       (create! method t s permissions)
                       (say "created ~a" t))
                      ((and previous (ours? previous t))      ; OURS
                       (create! method t s permissions)
                       (say "updated ~a" t))
                      (else                                   ; FOREIGN
                       (when (store-symlink? t)
                         (error (string-append
                                 "provisioned-files: S2: " t
                                 " is a symlink into the store; home-files owns it")))
                       (assert-source! method t s)
                       (backup! t)
                       (create! method t s permissions)
                       (say "created ~a" t)))))))
              records))

           (let ((old (read-manifest %old-home)))
             (collect! old (map target-of %records))
             (materialise! %records old)))))))

;; compute-activation-script splices extension gexps into a NESTED body, where
;; `use-modules' cannot introduce a MACRO for the forms that follow it — the
;; expander sees (match …) as an application and chokes on `_'.  Load a
;; program-file instead: its top level is a real top level.  primitive-load
;; stays in this process, so the wrapper's GUIX_OLD_HOME is still in scope.
;; home-symlink-manager does the same.  See documents/provisioned-files.txt D10.
(define (provisioned-files-activation config)
  #~(primitive-load #$(provisioned-files-activation-program config)))


;;;
;;; The service type.  compose/extend exist so that `simple-service' works;
;;; nothing in this channel uses them (D4).
;;;

(define home-provisioned-files-service-type
  (service-type
   (name 'home-provisioned-files)
   (extensions
    (list (service-extension home-service-type
                             provisioned-files-generation-entry)
          (service-extension home-activation-service-type
                             provisioned-files-activation)))
   (compose concatenate)
   (extend (lambda (config files)
             (provisioned-files-configuration
              (inherit config)
              (files (append (provisioned-files-configuration-files config)
                             files)))))
   (default-value (provisioned-files-configuration))
   (description
    "Provision files into one or more roots by copy, hard link or symlink.
Each provisioned file is owned by the home generation that declares it, and is
collected when that declaration goes away.")))