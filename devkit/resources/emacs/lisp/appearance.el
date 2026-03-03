;; Font (GUI only)
(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "Hack Nerd Font"
                      :height 130))

;; UI Cleanup (GUI Only)
(when (display-graphic-p)
  (menu-bar-mode -1)        ;; Remove menubar
  (tool-bar-mode -1)        ;; Remove toolbar
  (scroll-bar-mode -1)      ;; Remove scrollbar
  (set-fringe-mode 8))      ;; Add padding left/right

(provide 'appearance)
