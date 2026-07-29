;; Requires python-lsp-server and python-lsp-ruff on PATH.
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)

(defun languages--python-detect-venv ()
  "Detect a virtual environment in the current project."
  (let* ((root (project-root (project-current)))
         (venv
          (seq-find #'file-directory-p
                    (mapcar
                     (lambda (directory)
                       (expand-file-name directory root))
                     '(".venv" "venv" ".env" "env")))))
    (when venv
      (setq-local python-shell-virtualenv-root venv))))

(add-hook 'python-ts-mode-hook #'languages--python-detect-venv)
(add-hook 'python-mode-hook #'languages--python-detect-venv)

(provide 'languages/python)
