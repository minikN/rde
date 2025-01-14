(define-module (rde features linux)
  #:use-module (rde packages)
  #:use-module (rde features)
  #:use-module (rde features predicates)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services shepherd)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home-services wm)
  #:use-module (guix gexp)

  #:export (feature-backlight
	    feature-pipewire))

(define* (feature-backlight
	  #:key
	  (default-brightness 100)
	  (step 10)
	  (brightnessctl brightnessctl))
  "Setup and configure brightness for various devices."
  (ensure-pred brightness? default-brightness)
  (ensure-pred any-package? brightnessctl)
  (ensure-pred brightness? step)

  (define (step->symbol op)
    (symbol-append (string->symbol (number->string step)) '% op))
  (define (backlight-home-services config)
    (list
     (simple-service
      'backlight-add-packages
      home-profile-service-type
      (list brightnessctl))
     (when (get-value 'sway config)
       (simple-service
        'backlight-add-brightness-control-to-sway
        home-sway-service-type
        `((bindsym --locked XF86MonBrightnessUp exec
		   ,(file-append brightnessctl "/bin/brightnessctl")
		   set ,(step->symbol '+))
	  (bindsym --locked XF86MonBrightnessDown exec
		   ,(file-append brightnessctl "/bin/brightnessctl")
		   set ,(step->symbol '-)))))))

  (define (backlight-system-services config)
    (list
     (simple-service
      'backlight-set-brightness-on-startup
      shepherd-root-service-type
      (list (shepherd-service
             (provision '(startup-brightness))
             (requirement '(virtual-terminal))
             (start
              #~(lambda ()
                  (invoke #$(file-append brightnessctl "/bin/brightnessctl")
			  "set" (string-append
				 (number->string #$default-brightness) "%"))))
             (one-shot? #t))))
     (udev-rules-service
      'backlight-add-udev-rules
      brightnessctl)))

  (feature
   (name 'backlight)
   (values `((backlight . #t)))
   (home-services-getter backlight-home-services)
   (system-services-getter backlight-system-services)))


(define* (feature-pipewire
          #:key
          (pipewire pipewire-0.3)
          (wireplumber wireplumber)
          (pulseaudio pulseaudio))
  ""
  (define (home-pipewire-services config)
    (list
     ;; TODO: Make home-alsa-service-type
     (simple-service
      'pipewire-add-asoundrd
      home-files-service-type
      `(("config/alsa/asoundrc"
         ,(mixed-text-file
           "asoundrc"
           #~(string-append
              "<"
	      #$(file-append
                 pipewire "/share/alsa/alsa.conf.d/50-pipewire.conf")
	      ">\n<"
	      #$(file-append
                 pipewire "/share/alsa/alsa.conf.d/99-pipewire-default.conf")
              ">\n"
              "
pcm_type.pipewire {
  lib " #$(file-append pipewire "/lib/alsa-lib/libasound_module_pcm_pipewire.so")
  "
}

ctl_type.pipewire {
  lib " #$(file-append pipewire "/lib/alsa-lib/libasound_module_ctl_pipewire.so")
  "
}
")))))


     (simple-service
      'pipewire-add-shepherd-daemons
      home-shepherd-service-type
      (list
       (shepherd-service
        (requirement '(dbus-home))
        (provision '(pipewire))
        (stop  #~(make-kill-destructor))
        (start #~(make-forkexec-constructor
                  (list #$(file-append pipewire "/bin/pipewire"))
                  #:environment-variables
                  (append (list "DISABLE_RTKIT=1")
                          (default-environment-variables)))))
       (shepherd-service
        (requirement '(pipewire))
        (provision '(wireplumber))
        (stop  #~(make-kill-destructor))
        (start #~(make-forkexec-constructor
                  (list #$(file-append wireplumber "/bin/wireplumber"))
                  #:environment-variables
                  (append (list "DISABLE_RTKIT=1")
                          (default-environment-variables)))))
       (shepherd-service
        (requirement '(pipewire))
        (provision '(pipewire-pulse))
        (stop  #~(make-kill-destructor))
        (start #~(make-forkexec-constructor
                  (list #$(file-append pipewire "/bin/pipewire-pulse"))
                  #:environment-variables
                  (append (list "DISABLE_RTKIT=1")
                          (default-environment-variables)))))))

     (when (get-value 'sway config)
       (simple-service
        'pipewire-add-volume-and-player-bindings-to-sway
        home-sway-service-type
        `((bindsym --locked XF86AudioRaiseVolume "\\\n"
                   exec ,(file-append pulseaudio "/bin/pactl")
                   set-sink-mute @DEFAULT_SINK@ "false; \\\n"
                   exec ,(file-append pulseaudio "/bin/pactl")
                   set-sink-volume @DEFAULT_SINK@ +5%)
          (bindsym --locked XF86AudioLowerVolume "\\\n"
                   exec ,(file-append pulseaudio "/bin/pactl")
                   set-sink-mute @DEFAULT_SINK@ "false; \\\n"
                   exec ,(file-append pulseaudio "/bin/pactl")
                   set-sink-volume @DEFAULT_SINK@ -5%)
          (bindsym --locked XF86AudioMute exec
                   ,(file-append pulseaudio "/bin/pactl")
                   set-sink-mute @DEFAULT_SINK@ toggle)
          (bindsym --locked XF86AudioMicMute exec
                   ,(file-append pulseaudio "/bin/pactl")
                   set-source-mute @DEFAULT_SOURCE@ toggle))))

     (simple-service
      'pipewire-add-packages
      home-profile-service-type
      (list pipewire wireplumber))))

  (define (system-pipewire-services _)
    (list
     (udev-rules-service
      'pipewire-add-udev-rules
      pipewire)))

  (feature
   (name 'pipewire)
   (values (make-feature-values pipewire wireplumber))
   (home-services-getter home-pipewire-services)
   (system-services-getter system-pipewire-services)))
