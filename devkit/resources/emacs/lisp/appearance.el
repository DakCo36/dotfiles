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

;; Matching paren: theme colors + bold/underline on the paren chars.
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'parenthesis
      show-paren-highlight-openparen t
      show-paren-when-point-inside-paren t
      show-paren-when-point-in-periphery t)

(defun init-appearance-apply-paren-faces (&rest _)
  (set-face-attribute 'show-paren-match nil
                      :weight 'ultra-bold
                      :underline t)
  (set-face-attribute 'show-paren-mismatch nil
                      :weight 'ultra-bold
                      :underline t))

(defun init-appearance-apply-treemacs-faces (&rest _)
  "Normalize Treemacs faces after a theme is enabled."
  (when (facep 'treemacs-root-face)
    (set-face-attribute 'treemacs-root-face nil :height 1.0)))

(add-hook 'enable-theme-functions #'init-appearance-apply-paren-faces)
(add-hook 'enable-theme-functions
          #'init-appearance-apply-treemacs-faces)

(with-eval-after-load 'treemacs-faces
  (init-appearance-apply-treemacs-faces))

(provide 'appearance)
