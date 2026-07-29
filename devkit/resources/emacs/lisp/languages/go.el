;; Tree-sitter language grammars not covered by treesit-auto.
(add-to-list 'treesit-language-source-alist
             '(gomod "https://github.com/camdencheek/tree-sitter-go-mod"))

(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))

;; Go uses tabs; gofmt enforces source formatting.
(add-hook 'go-ts-mode-hook
          (lambda ()
            (languages--set-indent t 4)
            (setq-local go-ts-mode-indent-offset 4)))

(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (add-hook 'before-save-hook #'eglot-format-buffer nil t))))

(with-eval-after-load 'project
  (add-to-list 'project-vc-extra-root-markers "go.mod"))

(defun languages-go--mise-root ()
  "Return the nearest mise config directory for the current buffer."
  (locate-dominating-file
   (or (and buffer-file-name
            (file-name-directory buffer-file-name))
       default-directory)
   (lambda (directory)
     (or (file-exists-p (expand-file-name "mise.toml" directory))
         (file-exists-p (expand-file-name ".mise.toml" directory))))))

(defun languages-go--gopls-program ()
  "Return the gopls executable path."
  (or (executable-find "gopls")
      (let ((default-gopls (expand-file-name "go/bin/gopls" "~")))
        (and (file-executable-p default-gopls)
             default-gopls))
      "gopls"))

(defun languages-go--eglot-contact (_interactive _project)
  "Return the gopls Eglot contact for the current buffer."
  (let ((gopls-program (languages-go--gopls-program)))
    (if-let ((mise-root (languages-go--mise-root)))
        (list "mise" "exec" "-C"
              (directory-file-name (expand-file-name mise-root))
              "--" gopls-program)
      (list gopls-program))))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((go-mode go-ts-mode) . languages-go--eglot-contact)))

(add-hook 'go-ts-mode-hook #'eglot-ensure)

(provide 'languages/go)
