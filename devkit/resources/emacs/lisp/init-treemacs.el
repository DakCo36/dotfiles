;;; init-treemacs.el  -*- lexical-binding: t; -*-
;; Treemacs

(defun init-treemacs--apply-collapsed-directory-git-state
    (original button path buffer git-future)
  "Use the same Git cache for a collapsed directory's key and path."
  (when (and (eq treemacs--git-mode 'deferred)
             (buffer-live-p buffer))
    (with-current-buffer buffer
      (let ((key (treemacs-button-get button :key)))
        (unless (equal key path)
          (puthash key (treemacs--get-or-parse-git-result git-future)
                   treemacs--git-cache)))))
  (funcall original button path buffer git-future))

(use-package treemacs
  :demand t

  :config
  (setq treemacs-width-is-initially-locked nil)
  (setq treemacs-space-between-root-nodes nil)
  (setq treemacs-read-string-input 'from-minibuffer)
  (setq treemacs-expand-after-init nil) ;; Disable expand automatically
  (treemacs-follow-mode -1)
  (advice-add 'treemacs--apply-annotations-deferred :around
              #'init-treemacs--apply-collapsed-directory-git-state)

  :bind
  (("C-c t t" . treemacs)
   ("C-c t s" . treemacs-select-window)
   ("C-c t f" . treemacs-find-file)
   ("C-c t 1" . treemacs-delete-other-windows)
   ("C-c t d" . treemacs-select-directory)
   ("C-c t b" . treemacs-bookmark)
   ("C-c t w" . treemacs-switch-workspace)
   ("C-c t a" . treemacs-add-project-to-workspace)
   ("C-c t e" . treemacs-edit-workspaces)
   ("C-c t p" . treemacs-display-current-project-exclusively)))

;; Nerd Icons support
;; Default is "Symbols Nerd Font Mono", which devkit does not install.
(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Hack Nerd Font Mono"))

;; Treemacs and Nerd Icons integration
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(provide 'init-treemacs)
