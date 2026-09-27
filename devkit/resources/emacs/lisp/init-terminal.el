;;; init-terminal.el  -*- lexical-binding: t; -*-
(unless (eq system-type 'windows-nt)
  (use-package vterm
    :ensure t
    :hook (vterm-mode . (lambda ()
                          (display-line-numbers-mode -1)
                          (corfu-mode -1)))
    :custom
    (vterm-timer-delay 0.01)))

(provide 'init-terminal)
