;;; my-misc.el  -*- lexical-binding: t; -*-
;; Keymap
(with-eval-after-load 'hideshow
  (keymap-set hs-minor-mode-map "C-=" #'hs-toggle-hiding))

;; Default indentation (4 spaces/tabs)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Setup exec-path-from-shell to ensure Emacs inherits the correct PATH and other environment variables from the shell
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Disable ring-bell
(setq ring-bell-function 'ignore)

;; Which-key (show available keybindings)
(use-package which-key
  :ensure t

  :init
  (which-key-mode))

(provide 'my-misc)
