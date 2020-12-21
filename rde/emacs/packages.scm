(define-module (rde emacs packages)
  #:use-module (guix build-system emacs)
  #:use-module (guix store)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (guix build emacs-utils)
  #:use-module (ice-9 pretty-print)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (%rde-emacs-all-packages))

(define-public emacs-rde-core
  (package
    (name "emacs-rde-core")
    (version "0.2.0")
    (build-system emacs-build-system)
    (source (local-file "rde-core.el"))
    (propagated-inputs `(("use-package" ,emacs-use-package)))
    (synopsis "use-package initialization for rde-emacs")
    (description "use-package initialization for rde-emacs")
    (home-page "https://github.com/abcdw/rde")
    (license license:gpl3+)))

(define-public emacs-rde-early-init
  (package
    (name "emacs-rde-early-init")
    (version "0.2.0")
    (build-system emacs-build-system)
    (source (local-file "early-init.el"))
    (synopsis "Different tweaks for faster startup")
    (description "In addition to tweaks, disables GUI elements")
    (home-page "https://github.com/abcdw/rde")
    (license license:gpl3+)))

;; (define emacs-rde-init
;;   (text-file
;;    "init.el"
;;    (fold (lambda (package)
;; 	   (string-append "(require '"
;; 			  (string-drop (package-name package) 6)
;; 			  ")")))))

;; (define-public emacs-rde-init
;;   (package
;;     (name "emacs-rde-early-init")
;;     (version "0.2.0")
;;     (build-system emacs-build-system)
;;     (source init-el
;;      )
;;     (synopsis "Requires all rde-* packages")
;;     (description "Requires all rde-* packages")
;;     (home-page "https://github.com/abcdw/rde")
;;     (license license:gpl3+)))

;; (symlink "./emacs-rde.el" "/home/abcdw/tmp-file.el")

;; (define rde-emacs-packages
;;   '(emacs-use-package))

(define-public emacs-next-pgtk-latest
  (let ((commit "565d8f57d349c19d9bbb5d5d5fdacf3c70b85d42")
        (revision "0"))
    (package/inherit emacs-next
      (name "emacs-next-pgtk")
      (version (git-version "28.0.50" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.savannah.gnu.org/git/emacs.git/")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0y23gn2ppphx1g1x0b7gvqh3x36byphfzllsl74giybd5j6sfyx3"))))
      (arguments
       (substitute-keyword-arguments (package-arguments emacs-next)
         ((#:configure-flags flags ''())
          `(cons* "--with-pgtk" "--with-xwidgets" ,flags))))
      (propagated-inputs
       `(("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
         ("glib-networking" ,glib-networking)))
      (inputs
       `(("webkitgtk" ,webkitgtk)
         ,@(package-inputs emacs-next)))
      (home-page "https://github.com/masm11/emacs")
      (synopsis "Emacs text editor with @code{pgtk} and @code{xwidgets} support")
      (description "This is an unofficial Emacs fork build with a pure-GTK
graphical toolkit to work natively on Wayland.  In addition to that, xwidgets
also enabled and works without glitches even on X server."))))

(define (update-package-emacs p)
  (pretty-print p)
  (pretty-print  (equal?
		  (package-build-system p)
		  emacs-build-system))
  (if (equal?
       (package-build-system p)
       emacs-build-system)
      (package (inherit p)
	       (arguments
		(substitute-keyword-arguments
		    (package-arguments p)
		  ((#:emacs e #:emacs) rde-emacs))))
      p))

(define rde-emacs-instead-of-emacs
  (package-mapping update-package-emacs
		   (lambda (p) #f)))

;; (packages->manifest
;;  ;; (append (map rde-emacs-instead-of-emacs rde-emacs-packages)
;;  ;; 	 '(rde-emacs))
;; )

(define %rde-emacs-packages
  (list emacs-rde-core))

(define %rde-emacs-all-packages
  (append
   (list emacs-next-pgtk-latest
	 emacs-guix
	 emacs-magit

	 ;; emacs-rde-early-init
	 ;; emacs-rde-init
	 )
   %rde-emacs-packages))

;; (pretty-print "test")
;; (specifications->manifest
;;  '("emacs"))
