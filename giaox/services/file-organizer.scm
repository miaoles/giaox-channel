(define-module (giaox services file-organizer)
 #:use-module (gnu home services)
 #:use-module (gnu packages shepherd)
 #:use-module (gnu services configuration)
 #:use-module (guix gexp)
 #:use-module (guix records)
 #:use-module (ice-9 match)
 #:export (file-organizer-configuration
           file-organizer-service-type))

(define-record-type* <file-organizer-configuration>
 file-organizer-configuration make-file-organizer-configuration
 file-organizer-configuration?
 (watch-directories file-organizer-configuration-watch-directories
  (default '()))
 (file-types file-organizer-configuration-file-types
  (default '()))
 (interval file-organizer-configuration-interval
  (default 300)))

(define (file-organizer-shepherd-service config)
 (list (shepherd-service
  (provision '(file-organizer))
  (documentation "Run file organizer service.")
  (start #~(make-forkexec-constructor
   (list #$(file-append shepherd "/bin/shepherd")
    "start" "file-organizer")))
  (stop #~(make-kill-destructor)))))

(define (file-organizer-activation config)
 #~(begin
  (use-modules (ice-9 threads))
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
   (let ((watch-dirs '#$(file-organizer-configuration-watch-directories config))
    (file-types '#$(file-organizer-configuration-file-types config))
    (interval #$(file-organizer-configuration-interval config)))
    (let loop ()
     (for-each (lambda (dir) (organize-files dir file-types)) watch-dirs)
     (sleep interval)
     (loop))))
  (call-with-new-thread
   (lambda ()
    (watch-and-organize '#$config)))))

(define file-organizer-service-type
 (service-type
  (name 'file-organizer)
  (description "Run file organizer service.")
  (extensions
   (list (service-extension
    home-shepherd-service-type
    file-organizer-shepherd-service)
    (service-extension
     home-activation-service-type
     file-organizer-activation)))
  (default-value (file-organizer-configuration))
  (compose concatenate)
  (extend
   (lambda (config extra-config)
    (file-organizer-configuration
     (watch-directories
      (append (file-organizer-configuration-watch-directories config)
       (file-organizer-configuration-watch-directories extra-config)))
     (file-types
      (append (file-organizer-configuration-file-types config)
       (file-organizer-configuration-file-types extra-config)))
     (interval
      (file-organizer-configuration-interval extra-config)))))))
