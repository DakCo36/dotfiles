;;; init-appearance.el  -*- lexical-binding: t; -*-
(setq frame-resize-pixelwise t)

;; Line number
(setq display-line-numbers-type t)
;; Turn on line number
(global-display-line-numbers-mode 1)

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

;; Header line
(defun init-appearance--format-eglot-status ()
  "Return the current buffer's Eglot status as a header-line string."
  (if (not (fboundp 'languages-common-eglot-connection-info))
      "None"
    (let* ((info (languages-common-eglot-connection-info))
           (state (plist-get info :state))
           (name (plist-get info :name))
           (version (plist-get info :version)))
      (cond
       ((eq state 'loading) "Loading...")
       ((eq state 'connected) name)
       (t "None")))))

(defun init-appearance--refresh-header-line ()
  "Request mode-line and header-line updates for all windows."
  (force-mode-line-update t))

(with-eval-after-load 'languages/common
  (add-hook 'languages-common-eglot-connection-change-hook
            #'init-appearance--refresh-header-line))

(setq-default header-line-format
            '(" " mode-name
              " | Eglot: "
              (:eval (init-appearance--format-eglot-status))))

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

(provide 'init-appearance)
