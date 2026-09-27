;;; init.el  -*- lexical-binding: t; -*-
;; 패키지 매니저 설정
(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; use-package 설치
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((copilot :vc-backend Git :url
              "https://github.com/copilot-emacs/copilot.el"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(add-to-list 'load-path
             (expand-file-name "lisp" user-emacs-directory))

;; Misc
(require 'my-misc)

;; Treemacs
(require 'init-treemacs)

;; Completion
(require 'init-completion)

;; Vterm
(require 'init-terminal)

;; Appearance
(require 'init-appearance)

;; Themes
(require 'init-themes)

;; Dashboard
(require 'init-dashboard)

;; Languages
(require 'init-languages)

;; Artificial Intelligence
(require 'init-agent)

;; Eldoc-box
(use-package eldoc-box
  :ensure t
  ;; Popup eldoc box on cursor functions
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)

  :config
  ;; Popup box after 1500 ms
  (setq eldoc-idle-delay 1.5)
  
  ;; Show eldoc buffer manually
  (defun popup-eldoc-buffer ()
    (interactive)
    (let* ((buf (eldoc-doc-buffer))
           (doc-window (and buf (get-buffer-window buf))))
      (if doc-window
          (delete-window doc-window)
        (when buf
          (display-buffer buf
                          '(display-buffer-at-bottom
                            (window-height . fit-window-to-buffer)))))))

  :bind
  ("C-c h" . popup-eldoc-buffer))

;; Magit
(use-package magit
  :ensure t

  :bind
  ("C-c g" . magit-status))

;; diff-hl (git change indicators in the gutter)
(use-package diff-hl
  :ensure t

  :init
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)

  :hook
  (magit-post-refresh . diff-hl-magit-post-refresh))

;; Windows gpg
(when (eq system-type 'windows-nt)
  (let ((gpg (expand-file-name "scoop/apps/gpg/current/bin/gpg.exe"
                               (getenv "USERPROFILE"))))
    (when (file-exists-p gpg)
      (setq epg-gpg-program gpg))))
