;; Treemacs
(use-package treemacs
  :demand t

  :config
  (setq treemacs-space-between-root-nodes nil)
  (setq treemacs-read-string-input 'from-minibuffer)

  :bind
  (("C-c t t" . treemacs)
   ("C-c t s" . treemacs-select-window)
   ("C-c t f" . treemacs-find-file)
   ("C-c t ." . treemacs-find-tag)
   ("C-c t 1" . treemacs-delete-other-windows)
   ("C-c t d" . treemacs-select-directory)
   ("C-c t b" . treemacs-bookmark)
   ("C-c t w" . treemacs-switch-workspace)
   ("C-c t a" . treemacs-add-project-to-workspace)
   ("C-c t e" . treemacs-edit-workspaces)
   ("C-c t p" . treemacs-display-current-project-exclusively)))

;; Nerd Icons support
(use-package nerd-icons)

;; Treemacs and Nerd Icons integration
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(provide 'my-treemacs)
