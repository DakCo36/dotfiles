(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

(dolist (hook '(js-ts-mode-hook js-mode-hook))
  (add-hook hook
            (lambda ()
              (languages--set-indent nil 2)
              (setq-local js-indent-level 2))))

(dolist (hook '(typescript-ts-mode-hook typescript-mode-hook tsx-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (languages--set-indent nil 2)
              (setq-local typescript-indent-level 2)
              (setq-local typescript-ts-mode-indent-offset 2))))

;; Requires typescript-language-server and typescript on PATH.
(dolist (hook '(js-ts-mode-hook
                typescript-ts-mode-hook
                tsx-ts-mode-hook
                js-mode-hook
                typescript-mode-hook))
  (add-hook hook #'eglot-ensure))

(provide 'languages/javascript)
