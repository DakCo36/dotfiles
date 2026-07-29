;; Requires rust-analyzer on PATH.
(add-hook 'rust-ts-mode-hook #'eglot-ensure)
(add-hook 'rust-mode-hook #'eglot-ensure)

(provide 'languages/rust)
