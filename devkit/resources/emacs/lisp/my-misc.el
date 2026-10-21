;;; my-misc.el  -*- lexical-binding: t; -*-
;; Keymap
(with-eval-after-load 'hideshow
  (keymap-set hs-minor-mode-map "C-=" #'hs-toggle-hiding))

;; Default indentation (4 spaces/tabs)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Encoding
(prefer-coding-system 'utf-8-unix)

;; In Zsh(or Bash), Setup exec-path-from-shell to ensure Emacs inherits the correct PATH and other environment variables from the shell
;; No supported in Windows
(use-package exec-path-from-shell
  :if (memq system-type '(darwin gnu/linux))
  :config
  (add-to-list 'exec-path-from-shell-variables "KILO_API_KEY")
  (exec-path-from-shell-initialize))

;; Disable ring-bell
(setq ring-bell-function 'ignore)

;; Which-key (show available keybindings)
(use-package which-key
  :ensure t

  :init
  (which-key-mode))

;;;; Configurations
;; Windows
(when (eq system-type 'windows-nt)
  ;; Set pipe buffer size 64KB for minuet
  (setq w32-pipe-buffer-size (* 64 1024))

  (let* ((git (executable-find "git"))
         (git-sh-path
          (when git
            (condition-case nil
                (car (process-lines "git" "var" "GIT_SHELL_PATH"))
              (error nil))))
         (diff-path
          (when git-sh-path
            (expand-file-name
             "diff.exe" (file-name-directory git-sh-path)))))
    (when (and diff-path (file-executable-p diff-path))
      (setq diff-command diff-path))))

(provide 'my-misc)
