(define-module (giaox services file-organizer)
 #:use-module (gnu services)
 #:use-module (gnu services shepherd)
 #:use-module (guix gexp)
 #:use-module (ice-9 ftw)
 #:use-module (ice-9 match)
 #:use-module (srfi srfi-1)
 #:use-module (ice-9 threads)
 #:export (file-organizer-service-type))

(define (get-file-type file-name file-types)
 (let ((extension (string-downcase (file-extension file-name))))
  (find (lambda (type)
   (member extension (cdr type)))
   file-types)))

(define (move-file source dest)
 (let ((dir (dirname dest)))
  (unless (file-exists? dir)
   (mkdir-p dir))
  (rename-file source dest)))

(define (organize-files source-dir file-types)
 (let ((files (scandir source-dir)))
  (for-each
   (lambda (file)
    (let* ((full-path (string-append source-dir "/" file))
     (file-type (and (file-regular? full-path)
      (get-file-type file file-types))))
    (when file-type
     (let ((dest-dir (car file-type)))
      (move-file full-path (string-append dest-dir "/" file))))))
   files)))

(define (watch-and-organize config)
 (let ((watch-dirs (assoc-ref config 'watch-directories))
  (file-types (assoc-ref config 'file-types))
  (interval (or (assoc-ref config 'interval) 300)))
  (let loop ()
   (for-each (lambda (dir) (organize-files dir file-types)) watch-dirs)
   (sleep interval)
   (loop))))

(define file-organizer-service-type
 (service-type
  (name 'file-organizer)
  (description "File organizer service")
  (extensions
   (list (service-extension
    shepherd-root-service-type
    (lambda (config)
     (list (shepherd-service
      (provision '(file-organizer))
      (start #~(make-forkexec-constructor
       (list #$(scheme-file "file-organizer-script.scm"
        #~(begin
         (use-modules (ice-9 threads))s
         (define config '#$config)
         #$watch-and-organize)))))
      (stop #~(make-kill-destructor))
      (respawn? #t)))))))
  (default-value '())
  (compose concatenate)
  (extend
   (lambda (config extra-config)
    (append config extra-config)))))
