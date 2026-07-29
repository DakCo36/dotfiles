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

;; Requires gopls on PATH.
(add-hook 'go-ts-mode-hook #'eglot-ensure)

(provide 'languages/go)
