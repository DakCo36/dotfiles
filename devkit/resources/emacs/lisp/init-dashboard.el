;;; -*- lexical-binding: t; -*-

;; Local init for the MELPA `dashboard` package.
;; Keep this filename different from `dashboard.el` to avoid feature clash.

(use-package dashboard
  :demand t
  :config
  (defun init-dashboard-insert-treemacs-workspaces (list-size)
    "Insert up to LIST-SIZE Treemacs workspace buttons into the dashboard.
Return nil."
    (dashboard-insert-heading "Workspaces" "w")
    (newline)
    (dolist (ws (dashboard-subseq (treemacs-workspaces) list-size))
      (let ((name (treemacs-workspace->name ws)))
        (insert "    ")
        (insert-button name
                       'action (lambda (_btn)
                                 ;; Use the non-interactive API so clicking a
                                 ;; workspace switches immediately (no "Switch to:").
                                 (treemacs-do-switch-workspace ws))
                       'follow-link t
                       'face 'dashboard-items-face)
        (newline))))

  (defun init-dashboard--jump-to-treemacs-workspaces ()
    "Move point to the first Treemacs workspace button."
    (interactive)
    (goto-char (point-min))
    (unless (search-forward "Workspaces" nil t)
      (user-error "Workspaces section not found"))
    (forward-line 1)
    (back-to-indentation))

  (define-key dashboard-mode-map
              (kbd "w")
              #'init-dashboard--jump-to-treemacs-workspaces)

  (add-to-list 'dashboard-item-generators
               '(treemacs-workspaces . init-dashboard-insert-treemacs-workspaces))

  (setq dashboard-startup-banner 'official
        dashboard-center-content t
        dashboard-items '((treemacs-workspaces . 10)
                          (recents . 5)))

  (dashboard-setup-startup-hook)

  ;; emacsclient opens an empty *dashboard* unless we refresh it.
  (setq initial-buffer-choice
        (lambda ()
          (dashboard-refresh-buffer)
          (get-buffer dashboard-buffer-name))))

(provide 'init-dashboard)
