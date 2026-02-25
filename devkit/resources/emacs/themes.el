;; catpuccin-theme
(use-package catppuccin-theme
  :config
  (setq catppuccin-flavor 'macchiato))

;; gruvbox
(use-package gruvbox-theme)

;; doom-theme
;; Support list: https://melpa.org/#/doom-themes
(use-package doom-themes)

;; 8bit(256) vs 24bit
;; (if (or (display-graphic-p)
;;	(string= (getenv "COLORTERM") "truecolor"))
;;    (load-theme 'catppuccin t)
;;  (load-theme 'gruvbox-dark-medium t))

(defun select-theme ()
  ;; Disable all custom themes
  (mapc #'disable-theme custom-enabled-themes)
  (let ((truecolor (or (display-graphic-p)
		       (string= (getenv "COLORTERM") "truecolor")))
	(workspace (treemacs-workspace->name
		    (treemacs-current-workspace))))
    (cond
     ;; dotfiles
     ((string-match "dotfiles" workspace)
      (if truecolor
	  (load-theme 'doom-monokai-classic t)
	(load-theme 'gruvbox-dark-medium t)))
     (t
      (if truecolor
	  (load-theme 'catppuccin t)
	(load-theme 'gruvbox-dark-medium t))))))

(add-hook 'treemacs-switch-workspace-hook #'select-theme)
(select-theme)

(provide 'themes)
