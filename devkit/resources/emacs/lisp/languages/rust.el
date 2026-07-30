;; Tree-sitter language grammars not covered by treesit-auto.
(add-to-list 'treesit-language-source-alist
             '(rust "https://github.com/tree-sitter/tree-sitter-rust"))

(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

(with-eval-after-load 'project
  (add-to-list 'project-vc-extra-root-markers "Cargo.toml"))

(defun languages-rust--mise-root ()
  "Return the nearest mise config directory for the current buffer."
  (locate-dominating-file
   (or (and buffer-file-name
            (file-name-directory buffer-file-name))
       default-directory)
   (lambda (directory)
     (or (file-exists-p (expand-file-name "mise.toml" directory))
         (file-exists-p (expand-file-name ".mise.toml" directory))))))

(defun languages-rust--eglot-contact (_interactive _project)
  "Return the rust-analyzer Eglot contact for the current buffer."
  (if-let ((mise-root (languages-rust--mise-root)))
      (list "mise" "exec" "-C"
            (directory-file-name (expand-file-name mise-root))
            "--" "rust-analyzer")
    (user-error "No mise.toml found for Rust buffer")))

(defun languages-rust--eglot-ensure ()
  "Start Eglot only when the current Rust buffer has a mise config."
  (when (languages-rust--mise-root)
    (eglot-ensure)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((rust-mode rust-ts-mode) . languages-rust--eglot-contact)))

(remove-hook 'rust-ts-mode-hook #'eglot-ensure)
(remove-hook 'rust-mode-hook #'eglot-ensure)
(add-hook 'rust-ts-mode-hook #'languages-rust--eglot-ensure)
(add-hook 'rust-mode-hook #'languages-rust--eglot-ensure)

(provide 'languages/rust)
