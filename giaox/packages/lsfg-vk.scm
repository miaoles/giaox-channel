(define-module (giaox services lsfg-vk)
  #:use-module (giaox packages lsfg-vk)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (guix records)
  #:export (lsfg-vk-configuration
            lsfg-vk-configuration?
            lsfg-vk-configuration-package
            home-lsfg-vk-service-type))

;; Shared configuration record; see documents/lsfg-vk.txt D8.
(define-record-type* <lsfg-vk-configuration>
  lsfg-vk-configuration make-lsfg-vk-configuration
  lsfg-vk-configuration?
  (package lsfg-vk-configuration-package
           (default lsfg-vk)))

(define (lsfg-vk-profile-packages config)
  (list (lsfg-vk-configuration-package config)))

(define home-lsfg-vk-service-type
  (service-type
   (name 'home-lsfg-vk)
   (extensions
    (list (service-extension home-profile-service-type
                             lsfg-vk-profile-packages)))
   (default-value (lsfg-vk-configuration))
   (description
    "Install lsfg-vk, a Vulkan layer providing Lossless Scaling frame
generation, into the home profile.  With the default configuration this is all
it does; configuration-file management is opt-in.")))