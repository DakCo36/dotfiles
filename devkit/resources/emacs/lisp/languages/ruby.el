(add-hook 'ruby-mode-hook
          (lambda ()
            (languages--set-indent nil 2)))
(add-hook 'ruby-ts-mode-hook
          (lambda ()
            (languages--set-indent nil 2)))

;; Requires ruby-lsp on PATH.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((ruby-mode ruby-ts-mode) . ("ruby-lsp"))))
(add-hook 'ruby-mode-hook #'eglot-ensure)
(add-hook 'ruby-ts-mode-hook #'eglot-ensure)

(provide 'languages/ruby)
