;; workspaces

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

     ;; Ohouse
     ((string-match "onboarding-ai-cd-pipeline" workspace)
      (if truecolor
          (load-theme 'doom-one-light t)
        (load-theme 'gruvbox-dark-medium t)))
     
     (t
      (if truecolor
	      (load-theme 'catppuccin t)
	    (load-theme 'gruvbox-dark-medium t))))))

(add-hook 'treemacs-switch-workspace-hook #'select-theme)
(select-theme)

(provide 'workspaces)
